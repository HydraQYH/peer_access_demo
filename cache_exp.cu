#include <cstdio>
#include <cuda.h>
#include "mpi.h"

constexpr int _PageSize = 4096;

#define CUDACHECK(cmd)                                              \
  do {                                                              \
    cudaError_t e = cmd;                                            \
    if (e != cudaSuccess) {                                         \
      printf("Failed: Cuda error %s:%d '%s'\n", __FILE__, __LINE__, \
             cudaGetErrorString(e));                                \
      exit(EXIT_FAILURE);                                           \
    }                                                               \
  } while (0)

#define MPICHECK(cmd)                                                  \
  do {                                                                 \
    int e = cmd;                                                       \
    if (e != MPI_SUCCESS) {                                            \
      printf("Failed: MPI error %s:%d '%d'\n", __FILE__, __LINE__, e); \
      exit(EXIT_FAILURE);                                              \
    }                                                                  \
  } while (0)

__global__ void initPeerMemory(int* dev_ptr) {
  int tid = threadIdx.x;
  *(dev_ptr + tid) = tid;
}

__global__ void loadPeerMemory(int* dev_ptr, int* peer_dev_ptr) {
  int tid = threadIdx.x;
  int* peer_ptr = peer_dev_ptr + tid;
  
  // First normal load, cache data
  int val = *peer_ptr;
  val *= 2;

  // Second load
#ifdef ENABLE_VOLATILE
  volatile int* volatile_peer_ptr = (volatile int*)peer_ptr;
  int val_new = *volatile_peer_ptr;
#elif ENABLE_LDCV
  int val_new = __ldcv(peer_ptr);
#else
  int val_new = *peer_ptr;
#endif

  val += val_new;
  *(dev_ptr + tid) = val;
}

int run(int rank) {
  int* dev_ptr;
  cudaIpcMemHandle_t ipc_memory_handle;
  cudaIpcMemHandle_t ipc_memory_handle_array[2];
  CUDACHECK(cudaMalloc(&dev_ptr, _PageSize));
  CUDACHECK(cudaMemset(dev_ptr, 0, _PageSize));
  // Init memory handle
  CUDACHECK(cudaIpcGetMemHandle(&ipc_memory_handle, dev_ptr));
  MPICHECK(MPI_Allgather(&ipc_memory_handle, sizeof(cudaIpcMemHandle_t),
    MPI_BYTE, ipc_memory_handle_array, sizeof(cudaIpcMemHandle_t), MPI_BYTE, MPI_COMM_WORLD));

  // Get peer device pointer
  int* peer_dev_ptr;
  if (rank == 0) {
    CUDACHECK(cudaIpcOpenMemHandle((void**)&peer_dev_ptr, ipc_memory_handle_array[1], cudaIpcMemLazyEnablePeerAccess));
  } else {
    CUDACHECK(cudaIpcOpenMemHandle((void**)&peer_dev_ptr, ipc_memory_handle_array[0], cudaIpcMemLazyEnablePeerAccess));
  }

  if (rank == 1) {
    dim3 grid(1, 1, 1);
    dim3 block(32, 1, 1);
    initPeerMemory<<<grid, block>>>(dev_ptr);
    CUDACHECK(cudaDeviceSynchronize());
  }

  MPICHECK(MPI_Barrier(MPI_COMM_WORLD));

  if (rank == 0) {
    dim3 grid(1, 1, 1);
    dim3 block(32, 1, 1);
    loadPeerMemory<<<grid, block>>>(dev_ptr, peer_dev_ptr);
    CUDACHECK(cudaDeviceSynchronize());
    int* host_ptr = (int*)malloc(_PageSize);
    CUDACHECK(cudaMemcpy(host_ptr, dev_ptr, _PageSize, cudaMemcpyDeviceToHost));
    printf("3x Peer Values: ");
    for (int i = 0; i < 32; i++) {
      printf("%d  ", *(host_ptr + i));
    }
    printf("\n");
    free(host_ptr);
  }
  MPICHECK(MPI_Barrier(MPI_COMM_WORLD));

  CUDACHECK(cudaFree(dev_ptr));
  return 0;
}

int main(int argc, char** argv) {
  int nRanks, myRank;
  MPICHECK(MPI_Init(&argc, &argv));
  MPICHECK(MPI_Comm_rank(MPI_COMM_WORLD, &myRank));
  MPICHECK(MPI_Comm_size(MPI_COMM_WORLD, &nRanks));
  if (nRanks != 2) {
    printf("Error: Wrong World Size %d\n", nRanks);
    MPICHECK(MPI_Finalize());
    return 0;
  }
  CUDACHECK(cudaSetDevice(myRank));
  run(myRank);
  MPICHECK(MPI_Finalize());
  return 0;
}

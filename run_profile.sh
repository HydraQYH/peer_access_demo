#!/bin/bash

# Use $PMI_RANK for MPICH and $SLURM_PROCID with srun.
if [ $OMPI_COMM_WORLD_LOCAL_RANK -eq 0 ]; then
  ncu -f -o ${NCU_REP_PREFIX} -k loadPeerMemory \
    --section MemoryWorkloadAnalysis --section MemoryWorkloadAnalysis_Chart \
    --section MemoryWorkloadAnalysis_Tables --set nvlink \
    "$@"
else
  "$@"
fi

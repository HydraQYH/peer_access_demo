#!/bin/bash
set -ex
MPI_HOME=/usr/local/openmpi
nvcc -O0 -g -G --ptx -arch=native -std=c++17 cache_exp.cu -o cache_exp.ptx -I${MPI_HOME}/include -L${MPI_HOME}/lib -lmpi
nvcc -O0 -g -G --ptx -arch=native -std=c++17 cache_exp.cu -DENABLE_LDCV -o cache_exp_ldcv.ptx -I${MPI_HOME}/include -L${MPI_HOME}/lib -lmpi
nvcc -O0 -g -G --ptx -arch=native -std=c++17 cache_exp.cu -DENABLE_VOLATILE -o cache_exp_volatile.ptx -I${MPI_HOME}/include -L${MPI_HOME}/lib -lmpi

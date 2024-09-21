#!/bin/bash
set -ex
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 ./cache_exp
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 ./cache_exp_ldcv
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 ./cache_exp_volatile

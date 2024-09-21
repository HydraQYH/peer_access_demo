#!/bin/bash
set -ex
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 -x NCU_REP_PREFIX="H20_load_peer" ./run_profile.sh ./cache_exp
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 -x NCU_REP_PREFIX="H20_load_peer_ldcv" ./run_profile.sh ./cache_exp_ldcv
mpirun --allow-run-as-root -np 2 -x CUDA_VISIBLE_DEVICES=6,7 -x NCU_REP_PREFIX="H20_load_peer_volatile" ./run_profile.sh ./cache_exp_volatile

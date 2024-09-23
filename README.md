# Cache Operator in Peer Memory Access
Here is a code example that demonstrates peer memory access. The loadPeerMemory kernel performs two peer memory accesses. The first access uses the normal ld instruction and the data in the peer memory will be cached. In the second peer memory access, we use three instructions: ld, ld.volatile, and ld.cv respectively. We observe peer memory access through ncu.

## ld
Normal ld instructions will hit the cache.
![alt text](images/ld_memory_table.png)
The received data volume shown in the NVLink Table also only includes one ld.
![alt text](images/ld_nvlink.png)
SASS Code:
```asm
LD.E R6, desc[UR4][R2.64]
```

## ld.volatile
ld.volatile instructions WILL NOT the cache.
![alt text](images/ld_volatile_memory_table.png)
The received data volume shown in the NVLink Table includes 2 * ld.
![alt text](images/ld_volatile_nvlink.png)
SASS Code:
```asm
LD.E.STRONG.SYS R8, desc[UR4][R6.64]
```

## ld.cv
ld.cv instructions WILL NOT the cache.
![alt text](images/ld_cv_memory_table.png)
The received data volume shown in the NVLink Table includes 2 * ld.
![alt text](images/ld_cv_nvlink.png)
SASS Code:
```asm
LDG.E.STRONG.SYS R0, desc[UR4][R4.64]
```

## Conclusion
Both ld.volatile and ld.cv can bypass cache. The SASS code of `ld.volatile` and `ld.cv` contains the same `STRONG.SYS`, this may be the reason why they behave in the same way.

## How to reproduce?
+ compile.sh -- Build program.
+ compile_ptx.sh -- Compile PTX code for checking.
+ run.sh -- Run program.
+ run_profile_entry.sh -- Profile with ncu.


# ArmleoCPU_plic

RISC-V PLIC implementation. Implements AXI4-Lite interface.


# State
Currently it implements basic RTL and test. Work in progress to meet all the specification

# Building and testing
You need working verilator (all deps included e.g. GCC, Linker, etc), make.

Just do:
```
cd testbench
make
```

This will auto test the core.

Structure:
```
src/ contains source code of core
testbench/ Testbenches
```

# License
This core is licensed under standart copyright and is owned by Arman Avetisyan  
Feel free to read.  
No gurantee or warranty provided do anything on your own risk.  

# Documentation
Refer to https://github.com/riscv/riscv-plic-spec/

# Parameters
CONTEXT_COUNT contains amount of contexts
INTERRUPT_SOURCE_COUNT contains possible interrupt count
PRIORITY_WIDTH width of priority, should be set 3, because that's what default in original plic is


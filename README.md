# RISC-V AXI IO-PMP
TODO: add description


### Install & Requirements
All relevant linux packages and the python virtual environment can be setup by calling
```bash
source setup_env.sh
```

### Run Tests
```bash
cd tb/
make
```


### Frequenty Asked Questions

#### Errors & Solutions

Error `Error: System task/function $from_myhdl()/$to_myhdl() is not defined by any module`: 
```bash
./myhdl.vpi: Unable to find module file `./myhdl.vpi' or `./myhdl.vpi.vpl.vpi'.
test_axi_register.v:153: Error: System task/function $from_myhdl() is not defined by any module.
test_axi_register.v:202: Error: System task/function $to_myhdl() is not defined by any module.
```

Solution: (Re-)build `myhdl.vpi` and copy it to a search path location
```bash
git clone https://github.com/myhdl/myhdl.git
cd myhdl/cosimulation/icarus
make
```

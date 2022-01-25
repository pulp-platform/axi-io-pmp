[![AXI IO-PMP Tests](https://github.com/andreaskuster/axi-io-pmp/actions/workflows/main.yml/badge.svg)](https://github.com/andreaskuster/axi-io-pmp/actions/workflows/main.yml)

# RISC-V AXI IO-PMP 
TODO: add description


### Install & Requirements
All relevant linux packages and the python virtual environment can be setup by calling
```bash
source setup_env.sh
```

### Run Tests
Pytest:
```bash
pytest tb/
```

Show waveform of the simulation:
```bash
gtkwave tb/axi_io_pmp.vcd
```


### Modules List

| Name                                                            | Description |
|-----------------------------------------------------------------|-------------|
| [`axi_io_pmp`](src/axi_io_pmp.sv)                               |             |
| [`dut`](src/dut.sv)                                             |             |
| [`axi_conf`](src/connector/axi_conf.sv)                         |             |
| [`axi_master_connector`](src/connector/axi_master_connector.sv) |             |
| [`axi_slave_connector`](src/connector/axi_slave_connector.sv)   |             |
| [`riscv`](src/include/riscv.sv)                                 |             |
| [`pmp`](src/pmp/pmp.sv)                                         |             |


### Frequently Asked Questions

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

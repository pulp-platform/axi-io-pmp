[![SHL-0.51 license](https://img.shields.io/badge/license-SHL--0.51-green)](LICENSE)

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
gtkwave sim_build/axi_io_pmp.vcd
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


### AXI Compliance and PMP Correctness

Even though a AXI4 burst transaction could theoretically be 256 transfers with a burst size of 128 (given 128bit data width) resulting in a total burst size of 8KB (INCR type), however a burst must not cross a 4KB address boundary, which means that the maximal burst size is 4KB. 

- Write Burst

With a granularity of 4KB, we can check every burst in a single cycle (given the PMP can check one address per cycle). This is a trade-off. One could also multi-cycle check the whole burst interval while stalling the transaction until ready. And then signal the response. A hybrid version is to buffer all write, while checking the regions, and letting them through upon success, or throw them away upon failure (while sending feedback afterwards)

- Read Burst

With a granularity of 4KB, we can check every burst in a single cycle (given the PMP can check one address per cycle). This is a trade-off. One could also multi-cycle check the whole burst interval while stalling the transaction until ready.

This makes the read response compliant to AXI specs as well (i.e. every transfer gets a SLVERR, AXI states to sent OKAY/SLVERR/.. per transfer, and generally not for the whole burst). This is a trade-off. One could also split the burst, and assemble it again (signaling the ones that are OKAY, as OKAY, and inserting those that were blocked as SLVERR with no valid data)



### Register Generation
TODO: add a few words about OpenTitan & regtool.py

```bash
cd src/register
make
```

More information can be found in the [OpenTitan Register Tool Doc](https://docs.opentitan.org/doc/rm/register_tool/).


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

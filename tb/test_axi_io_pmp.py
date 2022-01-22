import os
import logging
import pytest
import bitarray

import cocotb
import cocotb_test.simulator

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam


class TB:

    def __init__(self, dut):
        # activate for remote debugging
        # import pydevd_pycharm
        # pydevd_pycharm.settrace('localhost', port=8080, stdoutToServer=True, stderrToServer=True)

        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        # connect simulation axi master
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.clk, dut.rst)

        # connect a simulation axi ram (slave)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.clk, dut.rst, size=2 ** 16)

    async def cycle_reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


async def run_test(dut):
    # get testbed instance
    tb = TB(dut)

    # reset dut
    await tb.cycle_reset()

    # write data to RAM (in order to have a deterministic value to read)
    addr = 0x0000_cbc0
    length = 8
    test_data = bytearray([x % 2**8 for x in range(length)])
    tb.log.info("TEST: addr %d, length %d, data %s", addr, length, test_data.hex())  # ("_", 1))
    tb.axi_ram.write(addr, test_data)


    # setup pmp entry

    # at the moment, we do this directly in the sv code


    # read data through the IO-PMP
    data = await tb.axi_master.read(addr, length)




    tb.log.info("Exposed signals: %s", tb.dut.pmp0.allow_o.value)
    #tb.log.info("TEST: pmp_allow %d", asdf)

    # check result
    assert data.data == test_data


if cocotb.SIM_NAME:

    data_width = len(cocotb.top.s_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes - 1).bit_length()

    for test in [run_test]:
        factory = TestFactory(test)
        # factory.add_option("size", [None] + list(range(max_burst_size)))
        factory.generate_tests()


@pytest.mark.parametrize("reg_type", [1])  # [None, 0, 1, 2]
@pytest.mark.parametrize("data_width", [64])  # [8, 16, 32, 64]
@pytest.mark.parametrize("addr_width", [64])  # [8, 16, 32, 64]
def test_axi_io_pmp(request, addr_width, data_width, reg_type):
    # extract & setup relevant information
    dut = "axi_io_pmp"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    src_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))
    simulator = "questa"

    # verilog source list
    verilog_sources = [
        # toplevel
        f"{dut}.v",
        # LibreCores source
        "axi_register/axi_register.v",
        "axi_register/axi_register_rd.v",
        "axi_register/axi_register_wr.v",
        # pmp sources
        #"pmp/include/riscv.sv",
        "pmp/pmp_entry.sv",
        "pmp/pmp.sv",
        # # pulp-platform source
        "common_cells/src/lzc.sv",
        # "axi/include/axi/assign.svh",
        # "axi/include/axi/typedef.svh",
        # "common_cells/src/spill_register.sv",
        # "axi/src/axi_pkg.sv",
        # "axi/src/axi_cut.sv",
        # # axi connector
        # "connector/axi_conf.sv",
        # "connector/axi_master_connector.v",
        # "connector/axi_slave_connector.v"
    ]
    verilog_sources = list(map(lambda x: os.path.join(src_dir, x), verilog_sources))

    # alternatively add sources recursive
    # verilog_sources = list()
    # for root, dirs, files in os.walk(src_dir):
    #     for file in files:
    #         if os.path.splitext(file)[1] in [".v", ".sv", ".svh"]:
    #             verilog_sources.append(os.path.join(root, file))

    # AXI parameters
    parameters = {
        'DATA_WIDTH': data_width,
        'ADDR_WIDTH': addr_width,
        'STRB_WIDTH': data_width // 8,
        'ID_WIDTH': 8,
        'AWUSER_ENABLE': 0,
        'AWUSER_WIDTH': 1,
        'WUSER_ENABLE': 0,
        'WUSER_WIDTH': 1,
        'BUSER_ENABLE': 0,
        'BUSER_WIDTH': 1,
        'ARUSER_ENABLE': 0,
        'ARUSER_WIDTH': 1,
        'RUSER_ENABLE': 0,
        'RUSER_WIDTH': 1,
        'REG_TYPE': reg_type
    }
    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build", request.node.name.replace('[', '-').replace(']', ''))

    if simulator == "verilator":
        sim = cocotb_test.simulator.Verilator(
            toplevel=toplevel,
            module=module
        )
        # suppress some verilator specific warnings (i.e. missing timescale information, ..) 
        sim.compile_args += ["-Wno-TIMESCALEMOD", "-Wno-WIDTH", "-Wno-UNOPT"] # -Wno-SELRANGE  -Wno-CASEINCOMPLETE

    elif simulator == "questa":
        sim = cocotb_test.simulator.Questa(
            toplevel=toplevel,
            module=module
        )

    else:
        sim = cocotb_test.simulator.Icarus(
            toplevel=toplevel,
            module=module
        )

    # add wave generation
    parameters["WAVES"] = 1

    sim.python_search = [tests_dir]
    sim.verilog_sources = verilog_sources
    sim.toplevel = toplevel
    sim.module = module
    sim.parameters = parameters
    sim.sim_build = sim_build
    sim.extra_env = extra_env
    sim.includes = list(map(lambda x: os.path.abspath(os.path.join(src_dir,x)), [ "pmp/include/", "common_cells/src/"]))
    sim.run()

    # cocotb_test.simulator.run(
    #     python_search=[tests_dir],
    #     verilog_sources=verilog_sources,
    #     toplevel=toplevel,
    #     module=module,
    #     parameters=parameters,
    #     sim_build=sim_build,
    #     extra_env=extra_env,
    # )

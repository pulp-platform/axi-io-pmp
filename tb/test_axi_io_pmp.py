import os
import re
import logging
import pytest

import cocotb
import cocotb_test.simulator

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiSlave

import numpy as np

import math
from enum import Enum
from bitarray import bitarray
from bitarray.util import int2ba, ba2int


class TB:

    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        # connect simulation axi master
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.clk, dut.rst)

        # connect a simulation axi ram (slave)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.clk, dut.rst, size=2 ** 16)

        # connect simulation axi PMP config
        self.axi_pmp_cfg = AxiMaster(AxiBus.from_prefix(dut, "cfg_axi"), dut.clk, dut.rst)

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


class PMPMode(Enum):
    OFF = bitarray("00")
    TOR = bitarray("01")
    NA4 = bitarray("10")
    NAPOT = bitarray("11")


class PMPAccess(Enum):
    ACCESS_NONE = bitarray("000")
    ACCESS_READ = bitarray("001")
    ACCESS_WRITE = bitarray("010")
    ACCESS_EXEC = bitarray("100")


def get_addr_offset():
    # extract address offset from auto-generated pmp header
    file = os.path.abspath(os.path.join(os.path.abspath(os.path.dirname(__file__)), '..', 'src/register/io_pmp.h'))
    with open(file) as f:
        header = f.read()
        params = {
            "IO_PMP_PMP_ADDR_0_REG_OFFSET": None,
            "IO_PMP_PMP_CFG_0_REG_OFFSET": None
        }
        for param in params:
            x = re.search(
                f"{param}[^/]0x([0-9a-fA-F]+)",
                header
            )
            params[param] = int(x.group(1), 16)
    return params


async def set_pmp_napot(tb, base: int, range: int, access: bitarray, pmp_no: int, PMP_LEN=54):
    # read base addresses (addr & cfg from header)
    params = get_addr_offset()

    # config
    locked = bitarray("0")
    reserved = bitarray("00")
    mode = PMPMode.NAPOT.value
    conf: bitarray = locked + reserved + mode + access
    tb.log.info("PMP cfg: %s", conf.to01())
    # address
    PMP_LEN = tb.dut.axi_io_pmp0.PMP_LEN.value
    napot_addr = int(base + (range / 2 - 1)) >> 2
    tb.log.info("PMP NAPOT addr: %s", int2ba(napot_addr, PMP_LEN).to01())

    # write config
    pmp0_addr = params["IO_PMP_PMP_ADDR_0_REG_OFFSET"] + 8 * pmp_no
    res = await tb.axi_pmp_cfg.read(pmp0_addr + 8, 8)
    pmp_next = int.from_bytes(res.data,
                              byteorder="little")  # workaround: we can only write  >= 16bytes (axi_to_reg issue), therefore we read address above first, and write back both
    await tb.axi_pmp_cfg.write(pmp0_addr, (napot_addr + (pmp_next * (2 ** 64))).to_bytes(16, byteorder='little'))

    pmp0_cfg = params["IO_PMP_PMP_CFG_0_REG_OFFSET"]
    res = await tb.axi_pmp_cfg.read(pmp0_cfg, 16)
    pmp_cfg_data = int.from_bytes(res.data, byteorder="little")

    # remove old value
    pmp_cfg_data = pmp_cfg_data & (0xf << (8 * pmp_no))

    # insert new value
    pmp_cfg_data = pmp_cfg_data | (ba2int(conf) << (8 * pmp_no))

    # send back
    await tb.axi_pmp_cfg.write(pmp0_cfg, (pmp_cfg_data).to_bytes(16, byteorder='little'))


async def run_test(dut):
    # get testbed instance
    tb = TB(dut)

    # reset dut
    await tb.cycle_reset()

    ##################
    # write data to RAM (in order to have a deterministic value to read)
    ##################
    addr = 0x0000_0000  # allowed range with address below: 0000_0000 - 0000_000f
    length = 4
    test_data = bytearray([x % 2 ** 8 for x in range(length)])
    tb.log.info("TEST: addr %d, length %d, data %s", addr, length, test_data.hex())  # ("_", 1))
    tb.axi_ram.write(addr, test_data)

    ###################
    # setup pmp entry
    ###################

    # extract granularity according to RISC-V privileged specs
    #
    locked = bitarray("0")
    reserved = bitarray("00")
    mode = PMPMode.OFF.value
    access = PMPAccess.ACCESS_NONE.value
    conf: bitarray = locked + reserved + mode + access

    await tb.axi_pmp_cfg.write(16*8, ba2int(conf).to_bytes(16, byteorder="little"))
    await tb.axi_pmp_cfg.write(0, ((2**128) -1).to_bytes(16, byteorder="little"))

    res = await tb.axi_pmp_cfg.read(0, 8)
    
    g = 0
    while(int.from_bytes(res.data, byteorder="little") & (0x1 << g) == 0):
        g = g + 1
    g = g + 2
    tb.log.info(f"RETURN VALUE FOR GRANULARITY: {g}")


  
    # configuration
    pmp_range_len = 8  # 2**12
    await set_pmp_napot(tb, 0, pmp_range_len, PMPAccess.ACCESS_READ.value | PMPAccess.ACCESS_WRITE.value, 0)

    ##########################
    # read data through the IO-PMP
    ###########################
    data = await tb.axi_master.read(addr, length)
    tb.log.info("PMP read allow: %s", dut.axi_io_pmp0.pmp0.allow_o.value)
    tb.log.info("PMP write allow: %s", dut.axi_io_pmp0.pmp1.allow_o.value)

    ###################
    # check result
    ###################
    assert data.data == test_data

    #####
    # check highest valid addr
    #####
    test = 4 * 1024 - 4  # highest address that is still valid for 4byte read
    await tb.axi_master.write(addr + test, test_data)
    data = await tb.axi_master.read(addr + test, length)

    tb.log.info("PMP read allow: %s", dut.axi_io_pmp0.pmp0.allow_o.value)
    tb.log.info("PMP write allow: %s", dut.axi_io_pmp0.pmp1.allow_o.value)

    assert (dut.axi_io_pmp0.pmp0.allow_o.value == 1)
    assert (dut.axi_io_pmp0.pmp1.allow_o.value == 1)

    #####
    # check lowest invalid addr
    #####
    test = 4 * 1024  # lowest address that is out of PMP region
    await tb.axi_master.write(addr + test, test_data)
    data = await tb.axi_master.read(addr + test, length)

    tb.log.info("PMP read allow: %s", dut.axi_io_pmp0.pmp0.allow_o.value)
    tb.log.info("PMP write allow: %s", dut.axi_io_pmp0.pmp1.allow_o.value)

    assert (dut.axi_io_pmp0.pmp0.allow_o.value == 0)
    assert (dut.axi_io_pmp0.pmp1.allow_o.value == 0)

    #####
    # check boundary crossing
    #####
    test = 4 * 1024 - 8
    await tb.axi_master.write(addr + test, (42).to_bytes(16, byteorder="little"))
    data = await tb.axi_master.read(addr + test, 16)

    assert (data.data != 42)


if cocotb.SIM_NAME:

    data_width = len(cocotb.top.s_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes - 1).bit_length()

    for test in [run_test]:
        factory = TestFactory(test)
        # factory.add_option("size", [None] + list(range(max_burst_size)))
        factory.generate_tests()


@pytest.mark.parametrize("reg_type", [1])  # [None, 0, 1, 2]
@pytest.mark.parametrize("data_width", [64])  # [8, 16, 32, 64, 128]
@pytest.mark.parametrize("addr_width", [64])  # [32, 64]
@pytest.mark.parametrize("simulator", ["questa"])  # ["verilator", "questa"]
def test_axi_io_pmp(request, simulator, addr_width, data_width, reg_type):
    # activate for remote debugging
    if "REMOTE" in os.environ:
        import pydevd_pycharm
        pydevd_pycharm.settrace('localhost', port=8080, stdoutToServer=True, stderrToServer=True)

    # extract & setup relevant information
    dut = "dut"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    src_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))

    # verilog source list
    verilog_sources = [

        # pulp-platform common_cells
        "common_cells/src/cf_math_pkg.sv",
        "common_cells/src/lzc.sv",
        "common_cells/src/spill_register_flushable.sv",
        "common_cells/src/spill_register.sv",
        "common_cells/src/deprecated/fifo_v2.sv",
        "common_cells/src/fifo_v3.sv",
        "common_cells/src/stream_register.sv",
        "common_cells/src/stream_arbiter_flushable.sv",
        "common_cells/src/stream_arbiter.sv",
        "common_cells/src/delta_counter.sv",
        "common_cells/src/counter.sv",
        "common_cells/src/id_queue.sv",
        "common_cells/src/rr_arb_tree.sv",
        "common_cells/src/onehot_to_bin.sv",

        # pulp-platform axi
        "axi/src/axi_pkg.sv",
        "axi/src/axi_intf.sv",
        "axi/src/axi_err_slv.sv",
        "axi/src/axi_demux.sv",
        "axi/src/axi_atop_filter.sv",
        "axi/src/axi_burst_splitter.sv",
        "axi/src/axi_to_axi_lite.sv",
        "axi/src/axi_cut.sv",

        # pulp-platform register interface
        "register/io_pmp_reg_pkg.sv",
        "register/io_pmp_reg_top.sv",
        "register_interface/src/axi_to_reg.sv",
        "register_interface/src/axi_lite_to_reg.sv",
        "register_interface/vendor/lowrisc_opentitan/src/prim_subreg.sv",
        "register_interface/vendor/lowrisc_opentitan/src/prim_subreg_arb.sv",
        "register_interface/vendor/lowrisc_opentitan/src/prim_subreg_ext.sv",
        "register_interface/vendor/lowrisc_opentitan/src/prim_subreg_shadow.sv",

        # axi connector
        "connector/axi_master_connector.sv",
        "connector/axi_slave_connector.sv",

        # pmp sources
        "pmp/include/riscv.sv",
        "pmp/pmp_entry.sv",
        "pmp/pmp.sv",

        # toplevel
        "axi_io_pmp.sv",
        f"{dut}.sv",
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
        sim.compile_args += ["-Wno-UNOPT", "-Wno-TIMESCALEMOD", "-Wno-CASEINCOMPLETE", "-Wno-WIDTH", "-Wno-SELRANGE",
                             "-Wno-CMPCONST", "-Wno-UNSIGNED"]

    elif simulator == "questa":
        sim = cocotb_test.simulator.Questa(
            toplevel=toplevel,
            module=module
        )

        sim.compile_args += ["+define+TARGET_VSIM"]  # activate axi_demux workaround

        # sim.gui = True

        # add coverage to questa
        sim.compile_args += ["+cover bcs"]
        coverage_file = "axi_io_pmp"
        sim.simulation_args += ["-coverage -coveranalysis -cvgperinstance",
                                f'-do "coverage save -codeAll -cvg -onexit {coverage_file}.ucdb;"']

    else:
        sim = cocotb_test.simulator.Simulator(
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
    sim.includes = list(map(lambda x: os.path.abspath(os.path.join(src_dir, x)),
                            ["axi/include/", "common_cells/include/", "register_interface/include/"]))
    sim.run()

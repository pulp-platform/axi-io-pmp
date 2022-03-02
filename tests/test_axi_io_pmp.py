import os
import re
import logging
import pytest

import cocotb
import cocotb_test.simulator

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam, AxiSlave, AxiResp

import numpy as np

import math
from enum import Enum
from bitarray import bitarray
from bitarray.util import int2ba, ba2int
import itertools
import random


class TB:

    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        # connect simulation axi master
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "in_axi"), dut.clk, dut.rst)

        # connect a simulation axi ram (slave)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "out_axi"), dut.clk, dut.rst, size=2 ** 16)

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


async def set_pmp_napot(tb, base: int, length: int, access: bitarray, pmp_no: int, PMP_LEN=54):
    """
    TODO
    """
    if length < 2 ** 12:
        tb.log.info(f"set_pmp_napot: length is below granularity level, range is extended to 2**12")

    # read base addresses (addr & cfg from header)
    params = get_addr_offset()

    # config
    locked = bitarray("0")
    reserved = bitarray("00")
    mode = PMPMode.NAPOT.value
    conf: bitarray = locked + reserved + mode + access
    tb.log.info("PMP cfg: %s", conf.to01())
    # address
    PMP_LEN = tb.dut.i_axi_io_pmp.PMP_LEN.value
    napot_addr = int(base + (length / 2 - 1)) >> 2
    tb.log.info("PMP NAPOT addr: %s", int2ba(napot_addr, PMP_LEN).to01())

    # write config
    pmp0_addr = params["IO_PMP_PMP_ADDR_0_REG_OFFSET"] + 8 * pmp_no
    await tb.axi_pmp_cfg.write(pmp0_addr, (napot_addr).to_bytes(8, byteorder='little'))

    pmp0_cfg = params["IO_PMP_PMP_CFG_0_REG_OFFSET"]
    res = await tb.axi_pmp_cfg.read(pmp0_cfg, 8)
    pmp_cfg_data = int.from_bytes(res.data, byteorder="little")

    # remove old value
    pmp_cfg_data = pmp_cfg_data & (0xf << (8 * pmp_no))

    # insert new value
    pmp_cfg_data = pmp_cfg_data | (ba2int(conf) << (8 * pmp_no))

    # send back
    await tb.axi_pmp_cfg.write(pmp0_cfg, (pmp_cfg_data).to_bytes(16, byteorder='little'))


async def run_test_write_read(dut, length: int, size: int, block: bool, mem_region=(0, 2 ** 16), pmp_slot=0):
    """
    Allow the full AxiRAM range (0 .. 2**16 -1), and run extensive tests (different burst length & offsets) to check if all transactions
    succeed (Note: boundary crossings would still cause a AxiResp.SLVERR, however the AxiMaster module splits them)
    """
    # get testbed instance & reset
    tb = TB(dut)
    await tb.cycle_reset()

    # allow/block all PMP, we check for that
    if block:  # block access
        await set_pmp_napot(tb, mem_region[0], mem_region[1], PMPAccess.ACCESS_NONE.value, pmp_slot)
    else:
        await set_pmp_napot(tb, mem_region[0], mem_region[1],
                            PMPAccess.ACCESS_READ.value | PMPAccess.ACCESS_WRITE.value, pmp_slot)

    # run extensive AXI write-then-read tests
    addresses = [mem_region[0], mem_region[1] - length] + [random.randint(0, 2 ** 16 - length) for _ in range(2)]
    for base_addr in addresses:  # test boundaries + 2 random addresses (in the valid range)

        # prepare
        tb.log.info("AXI transaction info: length %d, base_addr %d, size %d", length, base_addr, size)
        test_data = bytearray([x % 256 for x in range(length)])

        # initiate write transfer
        if os.environ["SIM"] == "icarus" and block:  # workaround for icarus: blocks on AxiResp.SLVERR write: write to AxiRAM directly instead
            if base_addr < 2 ** 16:
                tb.axi_ram.write(base_addr, test_data)
        else:
            res = await tb.axi_master.write(base_addr, test_data, size=size)
            if block:
                assert res.resp == AxiResp.SLVERR
            else:
                assert res.resp == AxiResp.OKAY

        # initiate read transfer
        data = await tb.axi_master.read(base_addr, length, size=size)

        # check result
        if block:
            assert data.data != test_data
            assert data.resp == AxiResp.SLVERR
        else:
            assert data.data == test_data
            assert data.resp == AxiResp.OKAY

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_bounds(dut, base: int = 0, length: int = 2 ** 12):
    """
     Test the PMP address boundaries for perfect match
    """
    # get testbed instance & reset
    tb = TB(dut)
    await tb.cycle_reset()

    # prepare data
    test_len = 16
    test_data = bytearray([x % 256 for x in range(test_len)])


    ##################
    # write data to RAM (in order to have a deterministic value to read)
    ##################
    tb.log.info("TEST: addr %d, length %d, data %s", base, test_len, test_data.hex())
    tb.axi_ram.write(base, test_data)

    ###################
    # setup pmp entry
    ###################
    # configuration: allow first 4KB interval
    await set_pmp_napot(tb, base, length, PMPAccess.ACCESS_READ.value | PMPAccess.ACCESS_WRITE.value, 0)

    ##########################
    # read data through the IO-PMP (at base address)
    ###########################
    data = await tb.axi_master.read(base, test_len)
    tb.log.info("PMP read allow: %s", dut.i_axi_io_pmp.i_read_pmp.allow_o.value)
    tb.log.info("PMP write allow: %s", dut.i_axi_io_pmp.i_write_pmp.allow_o.value)
    assert data.resp == AxiResp.OKAY
    assert data.data == test_data

    #####
    # check highest valid addr
    #####
    addr = base + length - test_len
    res = await tb.axi_master.write(addr, test_data)  # highest address that is still valid for 4byte read
    data = await tb.axi_master.read(addr, test_len)

    tb.log.info("PMP read allow: %s", dut.i_axi_io_pmp.i_read_pmp.allow_o.value)
    tb.log.info("PMP write allow: %s", dut.i_axi_io_pmp.i_write_pmp.allow_o.value)

    assert res.resp == AxiResp.OKAY
    assert data.resp == AxiResp.OKAY
    assert data.data == test_data

    #####
    # check lowest invalid addr
    #####
    addr = base + (length)
    if os.environ["SIM"] == "icarus":  # workaround for icarus: blocks on AxiResp.SLVERR write: write to AxiRAM directly instead
        if addr < 2**15:
            tb.axi_ram.write(addr, test_data)
    else:
        res = await tb.axi_master.write(addr, test_data)
        assert res.resp == AxiResp.SLVERR

    data = await tb.axi_master.read(addr, test_len)
    assert data.resp == AxiResp.SLVERR
    assert data.data != test_data

    #####
    # check boundary crossing
    #####
    addr = base + length - (test_len // 2)

    if os.environ["SIM"] == "icarus":  # workaround for icarus: blocks on AxiResp.SLVERR write: write to AxiRAM directly instead
        if addr < 2**15:
            tb.axi_ram.write(addr, test_data)
    else:
        res = await tb.axi_master.write(addr, test_data)
        assert res.resp == AxiResp.SLVERR

    data = await tb.axi_master.read(addr, test_len)
    assert data.data != test_data
    assert data.resp == AxiResp.SLVERR



async def run_test_prio(dut, base: int = 0, length: int = 64):
    """
     Test the PMP priority scheme (i.e. port 0 (max) to port 15 (min)) by stacking a fixed memory region on top of each
     other, once locked and once unlocked
    """
    # get testbed instance & reset
    tb = TB(dut)
    await tb.cycle_reset()

    # define r/w and no access
    access_rw = PMPAccess.ACCESS_READ.value | PMPAccess.ACCESS_WRITE.value
    access_none = PMPAccess.ACCESS_NONE.value

    # loop over all slots
    PMP_NUM = tb.dut.i_axi_io_pmp.NR_ENTRIES.value
    lock = False
    for i in reversed(range(PMP_NUM)):
        # write config
        if lock:
            await set_pmp_napot(tb, base, length, access_none, i)
        else:
            await set_pmp_napot(tb, base, length, access_rw, i)

        # read from configured range
        res = await tb.axi_master.read(base, length)

        # check locked/unlocked
        if lock:
            assert res.resp == AxiResp.SLVERR
        else:
            assert res.resp == AxiResp.OKAY

        # toggle for next layer
        lock = not lock


async def run_test_granularity(dut):
    """
     Extract granularity according to RISC-V privileged specs
     (1) set PMP OFF
     (2) set all address bits
     (3) read back address: g = 2 + NUM_LSB_ZERO_BITS
    """
    # get testbed instance & reset
    tb = TB(dut)
    await tb.cycle_reset()

    # setup PMP config
    locked = bitarray("0")
    reserved = bitarray("00")
    mode = PMPMode.OFF.value
    access = PMPAccess.ACCESS_NONE.value
    conf: bitarray = locked + reserved + mode + access
    await tb.axi_pmp_cfg.write(16 * 8, ba2int(conf).to_bytes(8, byteorder="little"))

    # write & read address
    await tb.axi_pmp_cfg.write(0, ((2 ** 64) - 1).to_bytes(8, byteorder="little"))
    res = await tb.axi_pmp_cfg.read(0, 8)

    # compute granularity: 2 + NUM_LSB_ZERO_BITS i.e. 0b101010000 -> g=2+4=6
    g = 0
    while int.from_bytes(res.data, byteorder="little") & (0x1 << g) == 0:
        g = g + 1
    g = g + 2
    tb.log.info(f"IO-PMP granularity: {g}")

    # should be g=12 (i.e. 2^12=4K)
    assert g == 12


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:
    """
    TODO
    """
    # define and extract bus information
    data_width = len(cocotb.top.in_axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes - 1).bit_length()
    mem_range = (0, 2 ** 16)

    # run PMP tests
    for test in [ run_test_bounds ]:
        factory = TestFactory(test)
        factory.add_option("length", [2**x for x in range(12, 56-1, 1)]) # test from minimal to maximal (2**56 cannot be tested with this test, since we test out-of-bound, which is not a valid physical address anymore)
        factory.generate_tests()

    for test in [ run_test_granularity, run_test_prio ]:
        factory = TestFactory(test)
        factory.generate_tests()

    # exhaustive AXI tests with minimal PMP rules (allow / block all)
    for test in [run_test_write_read]:
        factory = TestFactory(test)
        factory.add_option("length", [1, 2**12] + [random.randint(1, 2**12) for _ in range(2)]) # test boundaries + 2 random lengths
        factory.add_option("size", list(range(max_burst_size)) + [max_burst_size]) # test all sizes
        factory.add_option("block", [True, False]) # test allow and blocking
        factory.generate_tests()


@pytest.mark.parametrize("data_width", [64])  # [8, 16, 32, 64, 128]
@pytest.mark.parametrize("addr_width", [64])  # [32, 64]
@pytest.mark.parametrize("simulator", ["icarus"])  # ["icarus", "verilator", "questa"]
def test_axi_io_pmp(request, simulator, addr_width, data_width):
    """
    TODO
    """
    # activate for remote debugging
    if "REMOTE" in os.environ:
        import pydevd_pycharm
        pydevd_pycharm.settrace('localhost', port=8080, stdoutToServer=True, stderrToServer=True)

    # extract & setup relevant information
    dut = "dut"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut
    tests_dir = os.path.abspath(os.path.dirname(__file__))
    root_dir = os.path.abspath(os.path.join(tests_dir, '..'))
    src_dir = os.path.abspath(os.path.join(root_dir, 'src'))
    os.environ["SIM"] = simulator

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

        # connectors
        "connector/axi_master_connector.sv",
        "connector/axi_slave_connector.sv",
        "connector/reg_cut.sv",

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
        'RUSER_WIDTH': 1
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
        sim.verilog_sources = verilog_sources

    elif simulator == "questa":
        sim = cocotb_test.simulator.Questa(
            toplevel=toplevel,
            module=module
        )

        sim.compile_args += ["+define+TARGET_VSIM"]  # activate axi_demux workaround

        if "GUI" in os.environ:
            sim.gui = True

        # add coverage to questa
        sim.compile_args += ["+cover bcs"]
        coverage_file = "axi_io_pmp"
        sim.simulation_args += ["-coverage -coveranalysis -cvgperinstance",
                                f'-do "coverage save -codeAll -cvg -onexit {coverage_file}.ucdb;"']
        sim.verilog_sources = verilog_sources

    elif simulator == "icarus":

        # convert design from SystemVerilog to Verilog
        import subprocess
        subprocess.call(["make", "install_sv2v"], cwd=os.path.join(root_dir, "extras"))
        subprocess.call(["make", "sv2v"], cwd=os.path.join(root_dir, "extras"))

        sim = cocotb_test.simulator.Icarus(
            toplevel=toplevel,
            module=module
        )
        with open(os.path.join(root_dir, "cmdfile"), "w") as f:
            f.write("+timescale+1ns/1ps")

        # replace unsupported $fatal
        f = open(os.path.join(root_dir, "extras/iopmp.v"), "r")
        newlines = []
        for line in f.readlines():
            newlines.append(line.replace("$fatal", "//$fatal"))
        f.close()
        f = open(os.path.join(root_dir, "extras/iopmp.v"), "w")
        f.writelines(newlines)
        f.close()

        sim.compile_args += [f'-c{os.path.join(root_dir, "cmdfile")}']
        sim.verilog_sources = [f'{os.path.join(root_dir, "extras/iopmp.v")}']
        sim.force_compile = True

    else:
        raise NotImplementedError(f"Simulator {simulator} not implemented")

    # add wave generation
    parameters["WAVES"] = 1

    sim.python_search = [tests_dir]
    sim.toplevel = toplevel
    sim.module = module
    sim.parameters = parameters
    sim.sim_build = sim_build
    sim.extra_env = extra_env
    sim.includes = list(map(lambda x: os.path.abspath(os.path.join(src_dir, x)),
                            ["axi/include/", "common_cells/include/", "register_interface/include/"]))
    sim.run()

"""
Copyright (c) 2020 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

import itertools
import logging
import os

import cocotb
import cocotb_test.simulator
import pytest
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiBus, AxiMaster, AxiRam


class Testbed:

    def __init__(self, dut):
        # import pydevd_pycharm
        # pydevd_pycharm.settrace('localhost', port=9090, stdoutToServer=True, stderrToServer=True)

        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())

        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "axi"), dut.clk, dut.rst)
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "axi"), dut.clk, dut.rst, size=2 ** 16)

        #self.axi_ram.write_if.log.setLevel(logging.DEBUG)
        #self.axi_ram.read_if.log.setLevel(logging.DEBUG)

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


async def run_test_read(dut, idle_inserter=None, backpressure_inserter=None, size=None):
    tb = Testbed(dut)

    byte_lanes = tb.axi_master.write_if.byte_lanes
    max_burst_size = tb.axi_master.write_if.max_burst_size

    if size is None:
        size = max_burst_size

    await tb.cycle_reset()

    for length in [8]:
        for offset in [0]:
            tb.log.info("length %d, offset %d", length, offset)
            addr = offset + 0x1000

            test_data = bytearray([x % 256 for x in range(length)])

            # store data to AXI RAM module
            tb.axi_ram.write(addr, test_data)

            # read data using the AXI master
            data = await tb.axi_master.read(addr, length, size=size)

            assert data.data == test_data

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


if cocotb.SIM_NAME:

    data_width = len(cocotb.top.axi_wdata)
    byte_lanes = data_width // 8
    max_burst_size = (byte_lanes - 1).bit_length()

    for test in [run_test_read]:
        factory = TestFactory(test)
        #factory.add_option("size", [None] + list(range(max_burst_size)))
        factory.generate_tests()

# cocotb-test
tests_dir = os.path.dirname(__file__)


@pytest.mark.parametrize("data_width", [32])
def test_axi(request, data_width):
    dut = "test_axi"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(tests_dir, "..", "src", f"{dut}.v"),
    ]

    parameters = dict()
    parameters['DATA_WIDTH'] = data_width
    parameters['ADDR_WIDTH'] = 32
    parameters['STRB_WIDTH'] = parameters['DATA_WIDTH'] // 8
    parameters['ID_WIDTH'] = 8
    parameters['AWUSER_WIDTH'] = 1
    parameters['WUSER_WIDTH'] = 1
    parameters['BUSER_WIDTH'] = 1
    parameters['ARUSER_WIDTH'] = 1
    parameters['RUSER_WIDTH'] = 1

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
                             request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )

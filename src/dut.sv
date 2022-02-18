// Copyright 2022 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author:      Andreas Kuster, <kustera@ethz.ch>
// Description: Design under test (AXI IO-PMP). Convert from AXI master/slave to 
//              request/response pairs (pulp-platform) and feed them into DUT. 

`timescale 1ns / 1ps

`include "axi/typedef.svh"
`include "register_interface/typedef.svh"

module dut #(
    // Width of data bus in bits
    parameter DATA_WIDTH    = 64,
    // Width of address bus in bits
    parameter ADDR_WIDTH    = 64,
    // Width of strobe (width of data bus in words)
    parameter STRB_WIDTH    = (DATA_WIDTH / 8),
    // Width of id signal
    parameter ID_WIDTH      = 8,
    // Propagate awuser signal
    parameter AWUSER_ENABLE = 0,
    // Width of awuser signal
    parameter AWUSER_WIDTH  = 1,
    // Propagate wuser signal
    parameter WUSER_ENABLE  = 0,
    // Width of wuser signal
    parameter WUSER_WIDTH   = 1,
    // Propagate buser signal
    parameter BUSER_ENABLE  = 0,
    // Width of buser signal
    parameter BUSER_WIDTH   = 1,
    // Propagate aruser signal
    parameter ARUSER_ENABLE = 0,
    // Width of aruser signal
    parameter ARUSER_WIDTH  = 1,
    // Propagate ruser signal
    parameter RUSER_ENABLE  = 0,
    // Width of ruser signal
    parameter RUSER_WIDTH   = 1,
    // register type { Bypass = 0, Registered = 1, Skid Buffer = 2 }
    parameter REG_TYPE      = 1,
    // Waveform generation { Off=0, On=1 }
    parameter WAVES         = 0
) (
    input  logic                    clk,
    input  logic                    rst,
    /*
     * AXI master interface
     */
    // Write address channel
    output logic [    ID_WIDTH-1:0] m_axi_awid,
    output logic [  ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [             7:0] m_axi_awlen,
    output logic [             2:0] m_axi_awsize,
    output logic [             1:0] m_axi_awburst,
    output logic                    m_axi_awlock,
    output logic [             3:0] m_axi_awcache,
    output logic [             2:0] m_axi_awprot,
    output logic [             3:0] m_axi_awqos,
    output logic [             3:0] m_axi_awregion,
    output logic [AWUSER_WIDTH-1:0] m_axi_awuser,
    output logic                    m_axi_awvalid,
    input  logic                    m_axi_awready,
    // Write data channel
    output logic [  DATA_WIDTH-1:0] m_axi_wdata,
    output logic [  STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                    m_axi_wlast,
    output logic [ WUSER_WIDTH-1:0] m_axi_wuser,
    output logic                    m_axi_wvalid,
    input  logic                    m_axi_wready,
    // Write response channel
    input  logic [    ID_WIDTH-1:0] m_axi_bid,
    input  logic [             1:0] m_axi_bresp,
    input  logic [ BUSER_WIDTH-1:0] m_axi_buser,
    input  logic                    m_axi_bvalid,
    output logic                    m_axi_bready,
    // Read address channel
    output logic [    ID_WIDTH-1:0] m_axi_arid,
    output logic [  ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [             7:0] m_axi_arlen,
    output logic [             2:0] m_axi_arsize,
    output logic [             1:0] m_axi_arburst,
    output logic                    m_axi_arlock,
    output logic [             3:0] m_axi_arcache,
    output logic [             2:0] m_axi_arprot,
    output logic [             3:0] m_axi_arqos,
    output logic [             3:0] m_axi_arregion,
    output logic [ARUSER_WIDTH-1:0] m_axi_aruser,
    output logic                    m_axi_arvalid,
    input  logic                    m_axi_arready,
    // Read data channel
    input  logic [    ID_WIDTH-1:0] m_axi_rid,
    input  logic [  DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [             1:0] m_axi_rresp,
    input  logic                    m_axi_rlast,
    input  logic [ RUSER_WIDTH-1:0] m_axi_ruser,
    input  logic                    m_axi_rvalid,
    output logic                    m_axi_rready,
    /*
     * AXI slave interface
     */
    // Write address channel
    input  logic [    ID_WIDTH-1:0] s_axi_awid,
    input  logic [  ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic [             7:0] s_axi_awlen,
    input  logic [             2:0] s_axi_awsize,
    input  logic [             1:0] s_axi_awburst,
    input  logic                    s_axi_awlock,
    input  logic [             3:0] s_axi_awcache,
    input  logic [             2:0] s_axi_awprot,
    input  logic [             3:0] s_axi_awqos,
    input  logic [             3:0] s_axi_awregion,
    input  logic [AWUSER_WIDTH-1:0] s_axi_awuser,
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,
    // Write data channel
    input  logic [  DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [  STRB_WIDTH-1:0] s_axi_wstrb,
    input  logic                    s_axi_wlast,
    input  logic [ WUSER_WIDTH-1:0] s_axi_wuser,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,
    // Write response channel
    output logic [    ID_WIDTH-1:0] s_axi_bid,
    output logic [             1:0] s_axi_bresp,
    output logic [ BUSER_WIDTH-1:0] s_axi_buser,
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,
    // Read address channel
    input  logic [    ID_WIDTH-1:0] s_axi_arid,
    input  logic [  ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic [             7:0] s_axi_arlen,
    input  logic [             2:0] s_axi_arsize,
    input  logic [             1:0] s_axi_arburst,
    input  logic                    s_axi_arlock,
    input  logic [             3:0] s_axi_arcache,
    input  logic [             2:0] s_axi_arprot,
    input  logic [             3:0] s_axi_arqos,
    input  logic [             3:0] s_axi_arregion,
    input  logic [ARUSER_WIDTH-1:0] s_axi_aruser,
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,
    // Read data channel
    output logic [    ID_WIDTH-1:0] s_axi_rid,
    output logic [  DATA_WIDTH-1:0] s_axi_rdata,
    output logic [             1:0] s_axi_rresp,
    output logic                    s_axi_rlast,
    output logic [ RUSER_WIDTH-1:0] s_axi_ruser,
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready,
    /*
     * AXI slave configuration interface
     */
    // Write address channel
    input  logic [    ID_WIDTH-1:0] cfg_axi_awid,
    input  logic [  ADDR_WIDTH-1:0] cfg_axi_awaddr,
    input  logic [             7:0] cfg_axi_awlen,
    input  logic [             2:0] cfg_axi_awsize,
    input  logic [             1:0] cfg_axi_awburst,
    input  logic                    cfg_axi_awlock,
    input  logic [             3:0] cfg_axi_awcache,
    input  logic [             2:0] cfg_axi_awprot,
    input  logic [             3:0] cfg_axi_awqos,
    input  logic [             3:0] cfg_axi_awregion,
    input  logic [AWUSER_WIDTH-1:0] cfg_axi_awuser,
    input  logic                    cfg_axi_awvalid,
    output logic                    cfg_axi_awready,
    // Write data channel
    input  logic [  DATA_WIDTH-1:0] cfg_axi_wdata,
    input  logic [  STRB_WIDTH-1:0] cfg_axi_wstrb,
    input  logic                    cfg_axi_wlast,
    input  logic [ WUSER_WIDTH-1:0] cfg_axi_wuser,
    input  logic                    cfg_axi_wvalid,
    output logic                    cfg_axi_wready,
    // Write response channel
    output logic [    ID_WIDTH-1:0] cfg_axi_bid,
    output logic [             1:0] cfg_axi_bresp,
    output logic [ BUSER_WIDTH-1:0] cfg_axi_buser,
    output logic                    cfg_axi_bvalid,
    input  logic                    cfg_axi_bready,
    // Read address channel
    input  logic [    ID_WIDTH-1:0] cfg_axi_arid,
    input  logic [  ADDR_WIDTH-1:0] cfg_axi_araddr,
    input  logic [             7:0] cfg_axi_arlen,
    input  logic [             2:0] cfg_axi_arsize,
    input  logic [             1:0] cfg_axi_arburst,
    input  logic                    cfg_axi_arlock,
    input  logic [             3:0] cfg_axi_arcache,
    input  logic [             2:0] cfg_axi_arprot,
    input  logic [             3:0] cfg_axi_arqos,
    input  logic [             3:0] cfg_axi_arregion,
    input  logic [ARUSER_WIDTH-1:0] cfg_axi_aruser,
    input  logic                    cfg_axi_arvalid,
    output logic                    cfg_axi_arready,
    // Read data channel
    output logic [    ID_WIDTH-1:0] cfg_axi_rid,
    output logic [  DATA_WIDTH-1:0] cfg_axi_rdata,
    output logic [             1:0] cfg_axi_rresp,
    output logic                    cfg_axi_rlast,
    output logic [ RUSER_WIDTH-1:0] cfg_axi_ruser,
    output logic                    cfg_axi_rvalid,
    input  logic                    cfg_axi_rready
);

  /*
     * Master/slave (AXI) and register interface request/response structs
     */
  `REG_BUS_TYPEDEF_ALL(iopmp_reg, logic[7:0], logic[DATA_WIDTH-1:0],
                       logic[STRB_WIDTH-1:0])  // name, addr_t, data_t, strb_t
  iopmp_reg_req_t cfg_reg_req_o;
  iopmp_reg_rsp_t cfg_reg_rsp_i;

  `AXI_TYPEDEF_AW_CHAN_T(iopmp_axi_aw_chan_t, logic[ADDR_WIDTH-1:0], logic[ID_WIDTH-1:0],
                         logic[AWUSER_WIDTH-1:0])
  `AXI_TYPEDEF_W_CHAN_T(iopmp_axi_w_chan_t, logic[DATA_WIDTH-1:0], logic[STRB_WIDTH-1:0],
                        logic[AWUSER_WIDTH-1:0])
  `AXI_TYPEDEF_B_CHAN_T(iopmp_axi_b_chan_t, logic[ID_WIDTH-1:0], logic[AWUSER_WIDTH-1:0])
  `AXI_TYPEDEF_AR_CHAN_T(iopmp_axi_ar_chan_t, logic[ADDR_WIDTH-1:0], logic[ID_WIDTH-1:0],
                         logic[AWUSER_WIDTH-1:0])
  `AXI_TYPEDEF_R_CHAN_T(iopmp_axi_r_chan_t, logic[DATA_WIDTH-1:0], logic[ID_WIDTH-1:0],
                        logic[AWUSER_WIDTH-1:0])
  `AXI_TYPEDEF_REQ_T(iopmp_axi_req_t, iopmp_axi_aw_chan_t, iopmp_axi_w_chan_t, iopmp_axi_ar_chan_t)
  `AXI_TYPEDEF_RESP_T(iopmp_axi_rsp_t, iopmp_axi_b_chan_t, iopmp_axi_r_chan_t)
  iopmp_axi_req_t m_axi_req_i, mq_axi_req_i, s_axi_req_o, sq_axi_req_o, cfg_axi_req_o;
  iopmp_axi_rsp_t m_axi_rsp_o, mq_axi_rsp_o, s_axi_rsp_i, sq_axi_rsp_i, cfg_axi_rsp_i;

  /*
     * Traditional AXI slave signal to (req/resp) pair conversion
     */
  axi_slave_connector #(
      .DATA_WIDTH  (DATA_WIDTH),
      .ADDR_WIDTH  (ADDR_WIDTH),
      .STRB_WIDTH  (STRB_WIDTH),
      .ID_WIDTH    (ID_WIDTH),
      .AWUSER_WIDTH(AWUSER_WIDTH),
      .WUSER_WIDTH (WUSER_WIDTH),
      .BUSER_WIDTH (BUSER_WIDTH),
      .ARUSER_WIDTH(ARUSER_WIDTH),
      .RUSER_WIDTH (RUSER_WIDTH),
      .axi_req_t   (iopmp_axi_req_t),
      .axi_rsp_t   (iopmp_axi_rsp_t)
  ) slave_connector0 (
      /*
         * AXI signals
         */
      .s_axi_awid    (s_axi_awid),
      .s_axi_awaddr  (s_axi_awaddr),
      .s_axi_awlen   (s_axi_awlen),
      .s_axi_awsize  (s_axi_awsize),
      .s_axi_awburst (s_axi_awburst),
      .s_axi_awlock  (s_axi_awlock),
      .s_axi_awcache (s_axi_awcache),
      .s_axi_awprot  (s_axi_awprot),
      .s_axi_awqos   (s_axi_awqos),
      .s_axi_awregion(s_axi_awregion),
      .s_axi_awuser  (s_axi_awuser),
      .s_axi_awvalid (s_axi_awvalid),
      .s_axi_awready (s_axi_awready),
      .s_axi_wdata   (s_axi_wdata),
      .s_axi_wstrb   (s_axi_wstrb),
      .s_axi_wlast   (s_axi_wlast),
      .s_axi_wuser   (s_axi_wuser),
      .s_axi_wvalid  (s_axi_wvalid),
      .s_axi_wready  (s_axi_wready),
      .s_axi_bid     (s_axi_bid),
      .s_axi_bresp   (s_axi_bresp),
      .s_axi_buser   (s_axi_buser),
      .s_axi_bvalid  (s_axi_bvalid),
      .s_axi_bready  (s_axi_bready),
      .s_axi_arid    (s_axi_arid),
      .s_axi_araddr  (s_axi_araddr),
      .s_axi_arlen   (s_axi_arlen),
      .s_axi_arsize  (s_axi_arsize),
      .s_axi_arburst (s_axi_arburst),
      .s_axi_arlock  (s_axi_arlock),
      .s_axi_arcache (s_axi_arcache),
      .s_axi_arprot  (s_axi_arprot),
      .s_axi_arqos   (s_axi_arqos),
      .s_axi_arregion(s_axi_arregion),
      .s_axi_aruser  (s_axi_aruser),
      .s_axi_arvalid (s_axi_arvalid),
      .s_axi_arready (s_axi_arready),
      .s_axi_rid     (s_axi_rid),
      .s_axi_rdata   (s_axi_rdata),
      .s_axi_rresp   (s_axi_rresp),
      .s_axi_rlast   (s_axi_rlast),
      .s_axi_ruser   (s_axi_ruser),
      .s_axi_rvalid  (s_axi_rvalid),
      .s_axi_rready  (s_axi_rready),
      /*
         * AXI request/response pair
         */
      .axi_req_o     (s_axi_req_o),
      .axi_rsp_i     (s_axi_rsp_i)
  );

  axi_slave_connector #(
      .DATA_WIDTH  (DATA_WIDTH),
      .ADDR_WIDTH  (ADDR_WIDTH),
      .STRB_WIDTH  (STRB_WIDTH),
      .ID_WIDTH    (ID_WIDTH),
      .AWUSER_WIDTH(AWUSER_WIDTH),
      .WUSER_WIDTH (WUSER_WIDTH),
      .BUSER_WIDTH (BUSER_WIDTH),
      .ARUSER_WIDTH(ARUSER_WIDTH),
      .RUSER_WIDTH (RUSER_WIDTH),
      .axi_req_t   (iopmp_axi_req_t),
      .axi_rsp_t   (iopmp_axi_rsp_t)
  ) slave_connector1 (
      /*
         * AXI signals
         */
      .s_axi_awid    (cfg_axi_awid),
      .s_axi_awaddr  (cfg_axi_awaddr),
      .s_axi_awlen   (cfg_axi_awlen),
      .s_axi_awsize  (cfg_axi_awsize),
      .s_axi_awburst (cfg_axi_awburst),
      .s_axi_awlock  (cfg_axi_awlock),
      .s_axi_awcache (cfg_axi_awcache),
      .s_axi_awprot  (cfg_axi_awprot),
      .s_axi_awqos   (cfg_axi_awqos),
      .s_axi_awregion(cfg_axi_awregion),
      .s_axi_awuser  (cfg_axi_awuser),
      .s_axi_awvalid (cfg_axi_awvalid),
      .s_axi_awready (cfg_axi_awready),
      .s_axi_wdata   (cfg_axi_wdata),
      .s_axi_wstrb   (cfg_axi_wstrb),
      .s_axi_wlast   (cfg_axi_wlast),
      .s_axi_wuser   (cfg_axi_wuser),
      .s_axi_wvalid  (cfg_axi_wvalid),
      .s_axi_wready  (cfg_axi_wready),
      .s_axi_bid     (cfg_axi_bid),
      .s_axi_bresp   (cfg_axi_bresp),
      .s_axi_buser   (cfg_axi_buser),
      .s_axi_bvalid  (cfg_axi_bvalid),
      .s_axi_bready  (cfg_axi_bready),
      .s_axi_arid    (cfg_axi_arid),
      .s_axi_araddr  (cfg_axi_araddr),
      .s_axi_arlen   (cfg_axi_arlen),
      .s_axi_arsize  (cfg_axi_arsize),
      .s_axi_arburst (cfg_axi_arburst),
      .s_axi_arlock  (cfg_axi_arlock),
      .s_axi_arcache (cfg_axi_arcache),
      .s_axi_arprot  (cfg_axi_arprot),
      .s_axi_arqos   (cfg_axi_arqos),
      .s_axi_arregion(cfg_axi_arregion),
      .s_axi_aruser  (cfg_axi_aruser),
      .s_axi_arvalid (cfg_axi_arvalid),
      .s_axi_arready (cfg_axi_arready),
      .s_axi_rid     (cfg_axi_rid),
      .s_axi_rdata   (cfg_axi_rdata),
      .s_axi_rresp   (cfg_axi_rresp),
      .s_axi_rlast   (cfg_axi_rlast),
      .s_axi_ruser   (cfg_axi_ruser),
      .s_axi_rvalid  (cfg_axi_rvalid),
      .s_axi_rready  (cfg_axi_rready),
      /*
         * AXI request/response pair
         */
      .axi_req_o     (cfg_axi_req_o),
      .axi_rsp_i     (cfg_axi_rsp_i)
  );

  /*
     * Traditional AXI master signal to (req/resp) pair conversion
     */
  axi_master_connector #(
      .DATA_WIDTH  (DATA_WIDTH),
      .ADDR_WIDTH  (ADDR_WIDTH),
      .STRB_WIDTH  (STRB_WIDTH),
      .ID_WIDTH    (ID_WIDTH),
      .AWUSER_WIDTH(AWUSER_WIDTH),
      .WUSER_WIDTH (WUSER_WIDTH),
      .BUSER_WIDTH (BUSER_WIDTH),
      .ARUSER_WIDTH(ARUSER_WIDTH),
      .RUSER_WIDTH (RUSER_WIDTH),
      .axi_req_t   (iopmp_axi_req_t),
      .axi_rsp_t   (iopmp_axi_rsp_t)
  ) master_connector0 (
      /*
         * AXI signals
         */
      .m_axi_awid    (m_axi_awid),
      .m_axi_awaddr  (m_axi_awaddr),
      .m_axi_awlen   (m_axi_awlen),
      .m_axi_awsize  (m_axi_awsize),
      .m_axi_awburst (m_axi_awburst),
      .m_axi_awlock  (m_axi_awlock),
      .m_axi_awcache (m_axi_awcache),
      .m_axi_awprot  (m_axi_awprot),
      .m_axi_awqos   (m_axi_awqos),
      .m_axi_awregion(m_axi_awregion),
      .m_axi_awuser  (m_axi_awuser),
      .m_axi_awvalid (m_axi_awvalid),
      .m_axi_awready (m_axi_awready),
      .m_axi_wdata   (m_axi_wdata),
      .m_axi_wstrb   (m_axi_wstrb),
      .m_axi_wlast   (m_axi_wlast),
      .m_axi_wuser   (m_axi_wuser),
      .m_axi_wvalid  (m_axi_wvalid),
      .m_axi_wready  (m_axi_wready),
      .m_axi_bid     (m_axi_bid),
      .m_axi_bresp   (m_axi_bresp),
      .m_axi_buser   (m_axi_buser),
      .m_axi_bvalid  (m_axi_bvalid),
      .m_axi_bready  (m_axi_bready),
      .m_axi_arid    (m_axi_arid),
      .m_axi_araddr  (m_axi_araddr),
      .m_axi_arlen   (m_axi_arlen),
      .m_axi_arsize  (m_axi_arsize),
      .m_axi_arburst (m_axi_arburst),
      .m_axi_arlock  (m_axi_arlock),
      .m_axi_arcache (m_axi_arcache),
      .m_axi_arprot  (m_axi_arprot),
      .m_axi_arqos   (m_axi_arqos),
      .m_axi_arregion(m_axi_arregion),
      .m_axi_aruser  (m_axi_aruser),
      .m_axi_arvalid (m_axi_arvalid),
      .m_axi_arready (m_axi_arready),
      .m_axi_rid     (m_axi_rid),
      .m_axi_rdata   (m_axi_rdata),
      .m_axi_rresp   (m_axi_rresp),
      .m_axi_rlast   (m_axi_rlast),
      .m_axi_ruser   (m_axi_ruser),
      .m_axi_rvalid  (m_axi_rvalid),
      .m_axi_rready  (m_axi_rready),
      /*
         * AXI request/response pair
         */
      .axi_req_i     (mq_axi_req_i),
      .axi_rsp_o     (mq_axi_rsp_o)
  );

  /*
     * Register bus interface (for the pmp configuration)
     */
  axi_to_reg #(
      // width of the address
      .ADDR_WIDTH(ADDR_WIDTH),
      // width of the data
      .DATA_WIDTH(DATA_WIDTH),
      // width of the id.
      .ID_WIDTH  (ID_WIDTH),
      // width of the user signal.
      .USER_WIDTH(AWUSER_WIDTH),
      // AXI request struct type
      .axi_req_t (iopmp_axi_req_t),
      // AXI response struct type
      .axi_rsp_t (iopmp_axi_rsp_t),
      // regbus request struct type
      .reg_req_t (iopmp_reg_req_t),
      // regbus response struct type
      .reg_rsp_t (iopmp_reg_rsp_t)
  ) axi_to_reg0 (
      .clk_i     (clk),
      .rst_ni    (!rst),
      .testmode_i(1'b0),
      .axi_req_i (cfg_axi_req_o),
      .axi_rsp_o (cfg_axi_rsp_i),
      .reg_req_o (cfg_reg_req_o),
      .reg_rsp_i (cfg_reg_rsp_i)
  );


  axi_cut #(
      // bypass enable
      .Bypass   (1'b0),
      // AXI channel structs
      .aw_chan_t(iopmp_axi_aw_chan_t),
      .w_chan_t (iopmp_axi_w_chan_t),
      .b_chan_t (iopmp_axi_b_chan_t),
      .ar_chan_t(iopmp_axi_ar_chan_t),
      .r_chan_t (iopmp_axi_r_chan_t),
      // AXI request & response structs
      .req_t    (iopmp_axi_req_t),
      .resp_t   (iopmp_axi_rsp_t)
  ) axi_cut0 (
      .clk_i     (clk),
      .rst_ni    (!rst),
      // slave port
      .slv_req_i (s_axi_req_o),
      .slv_resp_o(s_axi_rsp_i),
      // master port
      .mst_req_o (sq_axi_req_o),
      .mst_resp_i(sq_axi_rsp_i)
  );

  /*
     * Device under test, AXI IO-PMP
     */
  axi_io_pmp #(
      .axi_aw_chan_t(iopmp_axi_aw_chan_t),
      .axi_w_chan_t (iopmp_axi_w_chan_t),
      .axi_b_chan_t (iopmp_axi_b_chan_t),
      .axi_ar_chan_t(iopmp_axi_ar_chan_t),
      .axi_r_chan_t (iopmp_axi_r_chan_t),
      .axi_req_t    (iopmp_axi_req_t),
      .axi_rsp_t    (iopmp_axi_rsp_t),
      .reg_req_t    (iopmp_reg_req_t),
      .reg_rsp_t    (iopmp_reg_rsp_t)
  ) axi_io_pmp0 (
      .clk_i    (clk),
      .rst_ni   (!rst),
      .slv_req_i(sq_axi_req_o),
      .slv_rsp_o(sq_axi_rsp_i),
      .mst_req_o(m_axi_req_i),
      .mst_rsp_i(m_axi_rsp_o),
      .cfg_req_i(cfg_reg_req_o),
      .cfg_rsp_o(cfg_reg_rsp_i)
  );


  axi_cut #(
      // bypass enable
      .Bypass   (1'b0),
      // AXI channel structs
      .aw_chan_t(iopmp_axi_aw_chan_t),
      .w_chan_t (iopmp_axi_w_chan_t),
      .b_chan_t (iopmp_axi_b_chan_t),
      .ar_chan_t(iopmp_axi_ar_chan_t),
      .r_chan_t (iopmp_axi_r_chan_t),
      // AXI request & response structs
      .req_t    (iopmp_axi_req_t),
      .resp_t   (iopmp_axi_rsp_t)
  ) axi_cut1 (
      .clk_i     (clk),
      .rst_ni    (!rst),
      // slave port
      .slv_req_i (m_axi_req_i),
      .slv_resp_o(m_axi_rsp_o),
      // master port
      .mst_req_o (mq_axi_req_i),
      .mst_resp_i(mq_axi_rsp_o)
  );

  /*
     * Simulation / Debugging
     */
`ifdef COCOTB_SIM
  initial begin
    if (WAVES == 1) begin
      // generate trace file
      $dumpfile("axi_io_pmp.vcd");
      $dumpvars(0, dut);
    end
  end
`endif

endmodule

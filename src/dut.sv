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
// Description: Design under test


`timescale 1ns / 1ps

// `include "axi_conf.sv"


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
    // register type { Bypass = 0, Registered = 1, Skid Buffer = 2}
    parameter REG_TYPE      = 1,
    // Waveform generation { Off=0, On=1 }
    parameter WAVES         = 0
) (
    input  wire                     clk,
    input  wire                     rst,

    /*
     * AXI master interface
     */
    output [ID_WIDTH-1:0]      m_axi_awid,
    output [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output [7:0]               m_axi_awlen,
    output [2:0]               m_axi_awsize,
    output [1:0]               m_axi_awburst,
    output                     m_axi_awlock,
    output [3:0]               m_axi_awcache,
    output [2:0]               m_axi_awprot,
    output [3:0]               m_axi_awqos,
    output [3:0]               m_axi_awregion,
    output [AWUSER_WIDTH-1:0]  m_axi_awuser,
    output                     m_axi_awvalid,
    input                      m_axi_awready,
    output [DATA_WIDTH-1:0]    m_axi_wdata,
    output [STRB_WIDTH-1:0]    m_axi_wstrb,
    output                     m_axi_wlast,
    output [WUSER_WIDTH-1:0]   m_axi_wuser,
    output                     m_axi_wvalid,
    input                      m_axi_wready,
    input  [ID_WIDTH-1:0]      m_axi_bid,
    input  [1:0]               m_axi_bresp,
    input  [BUSER_WIDTH-1:0]   m_axi_buser,
    input                      m_axi_bvalid,
    output                     m_axi_bready,
    output [ID_WIDTH-1:0]      m_axi_arid,
    output [ADDR_WIDTH-1:0]    m_axi_araddr,
    output [7:0]               m_axi_arlen,
    output [2:0]               m_axi_arsize,
    output [1:0]               m_axi_arburst,
    output                     m_axi_arlock,
    output [3:0]               m_axi_arcache,
    output [2:0]               m_axi_arprot,
    output [3:0]               m_axi_arqos,
    output [3:0]               m_axi_arregion,
    output [ARUSER_WIDTH-1:0]  m_axi_aruser,
    output                      m_axi_arvalid,
    input                      m_axi_arready,
    input  [ID_WIDTH-1:0]      m_axi_rid,
    input  [DATA_WIDTH-1:0]    m_axi_rdata,
    input  [1:0]               m_axi_rresp,
    input                      m_axi_rlast,
    input  [RUSER_WIDTH-1:0]   m_axi_ruser,
    input                      m_axi_rvalid,
    output                     m_axi_rready,

    /*
     * AXI slave interface
     */
    input [ID_WIDTH-1:0]     s_axi_awid,
    input [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input [7:0]              s_axi_awlen,
    input [2:0]              s_axi_awsize,
    input [1:0]              s_axi_awburst,
    input                    s_axi_awlock,
    input [3:0]              s_axi_awcache,
    input [2:0]              s_axi_awprot,
    input [3:0]              s_axi_awqos,
    input [3:0]              s_axi_awregion,
    input [AWUSER_WIDTH-1:0] s_axi_awuser,
    input                    s_axi_awvalid,
    output                   s_axi_awready,
    input [DATA_WIDTH-1:0]   s_axi_wdata,
    input [STRB_WIDTH-1:0]   s_axi_wstrb,
    input                    s_axi_wlast,
    input [WUSER_WIDTH-1:0]  s_axi_wuser,
    input                    s_axi_wvalid,
    output                   s_axi_wready,
    output [ID_WIDTH-1:0]    s_axi_bid,
    output [1:0]             s_axi_bresp,
    output [BUSER_WIDTH-1:0] s_axi_buser,
    output                   s_axi_bvalid,
    input                    s_axi_bready,
    input [ID_WIDTH-1:0]     s_axi_arid,
    input [ADDR_WIDTH-1:0]   s_axi_araddr,
    input [7:0]              s_axi_arlen,
    input [2:0]              s_axi_arsize,
    input [1:0]              s_axi_arburst,
    input                    s_axi_arlock,
    input [3:0]              s_axi_arcache,
    input [2:0]              s_axi_arprot,
    input [3:0]              s_axi_arqos,
    input [3:0]              s_axi_arregion,
    input [ARUSER_WIDTH-1:0] s_axi_aruser,
    input                    s_axi_arvalid,
    output                   s_axi_arready,
    output [ID_WIDTH-1:0]    s_axi_rid,
    output [DATA_WIDTH-1:0]  s_axi_rdata,
    output [1:0]             s_axi_rresp,
    output                   s_axi_rlast,
    output [RUSER_WIDTH-1:0] s_axi_ruser,
    output                   s_axi_rvalid,
    input                    s_axi_rready
);


    // AXI_BUS #(
    // .AXI_ADDR_WIDTH(ADDR_WIDTH),
    // .AXI_DATA_WIDTH(DATA_WIDTH),
    // .AXI_ID_WIDTH(ID_WIDTH),
    // .AXI_USER_WIDTH(BUSER_WIDTH)
    // ) from_master(), to_slave();


    // /*
    // * Write address channel
    // */
    // assign m_axi_awid          = from_master.Slave.aw_id;
    // assign m_axi_awaddr        = from_master.Slave.aw_addr;
    // assign m_axi_awlen         = from_master.Slave.aw_len;
    // assign m_axi_awsize        = from_master.Slave.aw_size;
    // assign m_axi_awburst       = from_master.Slave.aw_burst;
    // assign m_axi_awlock        = from_master.Slave.aw_lock;
    // assign m_axi_awcache       = from_master.Slave.aw_cache;
    // assign m_axi_awprot        = from_master.Slave.aw_prot;
    // assign m_axi_awqos         = from_master.Slave.aw_qos;
    // // assign master.aw_atop      = from_master.Master.aw.atop; // TODO: check if we should/can add this field to the axi interface
    // assign m_axi_awregion      = from_master.Slave.aw_region;
    // assign m_axi_awuser        = from_master.Slave.aw_user;
    // assign m_axi_awvalid       = from_master.Slave.aw_valid;
    // assign from_master.Slave.aw_ready = m_axi_awready;


    // /*
    //     * Write data channel
    //     */
    // assign m_axi_wdata        = from_master.Master.w_data;
    // assign m_axi_wstrb        = from_master.Master.w_strb;
    // assign m_axi_wlast        = from_master.Master.w_last;
    // assign m_axi_wuser        = from_master.Master.w_user;
    // assign m_axi_wvalid       = from_master.Master.w_valid;
    // assign from_master.Master.w_ready = m_axi_wready;

    // /*
    //  * Write response channel
    //  */
    // assign from_master.Master.b_id    = m_axi_bid;
    // assign from_master.Master.b_resp  = m_axi_bresp;
    // assign from_master.Master.b_user  = m_axi_buser;
    // assign from_master.Master.b_valid = m_axi_bvalid;
    // assign m_axi_bready       = from_master.Master.b_ready;

    // /*
    //  * Read address channel
    //  */
    // assign m_axi_arid          = from_master.Master.ar_id;
    // assign m_axi_araddr        = from_master.Master.ar_addr;
    // assign m_axi_arlen         = from_master.Master.ar_len;
    // assign m_axi_arsize        = from_master.Master.ar_size;
    // assign m_axi_arburst       = from_master.Master.ar_burst;
    // assign m_axi_arlock        = from_master.Master.ar_lock;
    // assign m_axi_arcache       = from_master.Master.ar_cache;
    // assign m_axi_arprot        = from_master.Master.ar_prot;
    // assign m_axi_arqos         = from_master.Master.ar_qos;
    // assign m_axi_arregion      = from_master.Master.ar_region;
    // assign m_axi_aruser        = from_master.Master.ar_user;
    // assign m_axi_arvalid       = from_master.Master.ar_valid;
    // assign from_master.Master.ar_ready = m_axi_arready;

    // /*
    //  * Read data channel
    //  */
    // assign from_master.Master.r_id    = m_axi_rid;
    // assign from_master.Master.r_data  = m_axi_rdata;
    // assign from_master.Master.r_resp  = m_axi_rresp;
    // assign from_master.Master.r_last  = m_axi_rlast;
    // assign from_master.Master.r_user  = m_axi_ruser;
    // assign from_master.Master.r_valid = m_axi_rvalid;
    // assign m_axi_rready       = from_master.Master.r_ready;



//   modport Master (
//     output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, input aw_ready,
//     output w_data, w_strb, w_last, w_user, w_valid, input w_ready,
//     input b_id, b_resp, b_user, b_valid, output b_ready,
//     output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, input ar_ready,
//     input r_id, r_data, r_resp, r_last, r_user, r_valid, output r_ready
//   );

//   modport Slave (
//     input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_atop, aw_user, aw_valid, output aw_ready,
//     input w_data, w_strb, w_last, w_user, w_valid, output w_ready,
//     output b_id, b_resp, b_user, b_valid, input b_ready,
//     input ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_valid, output ar_ready,
//     output r_id, r_data, r_resp, r_last, r_user, r_valid, input r_ready
//   );


axi_conf::req_t m_axi_req_i, s_axi_req_o;
axi_conf::resp_t m_axi_resp_o, s_axi_resp_i;



axi_slave_connector #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_WIDTH(WUSER_WIDTH),
    .BUSER_WIDTH(BUSER_WIDTH),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_WIDTH(RUSER_WIDTH)
) slave_connector0 (
    .s_axi_awid(s_axi_awid),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awlock(s_axi_awlock),
    .s_axi_awcache(s_axi_awcache),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awqos(s_axi_awqos),
    .s_axi_awregion(s_axi_awregion),
    .s_axi_awuser(s_axi_awuser),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wuser(s_axi_wuser),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bid(s_axi_bid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_buser(s_axi_buser),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_arid(s_axi_arid),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arlock(s_axi_arlock),
    .s_axi_arcache(s_axi_arcache),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arqos(s_axi_arqos),
    .s_axi_arregion(s_axi_arregion),
    .s_axi_aruser(s_axi_aruser),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_ruser(s_axi_ruser),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    
    .axi_req_o(s_axi_req_o),
    .axi_resp_i(s_axi_resp_i)
);


axi_master_connector #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_WIDTH(WUSER_WIDTH),
    .BUSER_WIDTH(BUSER_WIDTH),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_WIDTH(RUSER_WIDTH)
) master_connector0 (
    .m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awqos(m_axi_awqos),
    .m_axi_awregion(m_axi_awregion),
    .m_axi_awuser(m_axi_awuser),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wuser(m_axi_wuser),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_buser(m_axi_buser),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arqos(m_axi_arqos),
    .m_axi_arregion(m_axi_arregion),
    .m_axi_aruser(m_axi_aruser),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_ruser(m_axi_ruser),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),

    .axi_req_i(m_axi_req_i),
    .axi_resp_o(m_axi_resp_o)
);

axi_io_pmp #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .AWUSER_ENABLE(AWUSER_ENABLE),
    .AWUSER_WIDTH(AWUSER_WIDTH),
    .WUSER_ENABLE(WUSER_ENABLE),
    .WUSER_WIDTH(WUSER_WIDTH),
    .BUSER_ENABLE(BUSER_ENABLE),
    .BUSER_WIDTH(BUSER_WIDTH),
    .ARUSER_ENABLE(ARUSER_ENABLE),
    .ARUSER_WIDTH(ARUSER_WIDTH),
    .RUSER_ENABLE(RUSER_ENABLE),
    .RUSER_WIDTH(RUSER_WIDTH),
    .REG_TYPE(REG_TYPE),
    .WAVES(WAVES)
) axi_io_pmp0 (
    .clk(clk),
    .rst(clk),
    .slv_req_i(s_axi_req_o),
    .slv_resp_o(s_axi_resp_i), 
    .mst_req_o(m_axi_req_i),
    .mst_resp_i(m_axi_resp_o)
);


endmodule

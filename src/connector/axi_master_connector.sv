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
// Description: AXI master to (req_t, resp_t) pair connector (pulp-platform interface)

`timescale 1ns / 1ps

module axi_master_connector #(
    // Width of data bus in bits
    parameter DATA_WIDTH     = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH     = 32,
    // Width of strobe (width of data bus in words)
    parameter STRB_WIDTH     = (DATA_WIDTH / 8),
    // Width of id signal
    parameter ID_WIDTH       = 8,
    // Width of awuser signal
    parameter AWUSER_WIDTH   = 1,
    // Width of wuser signal
    parameter WUSER_WIDTH    = 1,
    // Width of buser signal
    parameter BUSER_WIDTH    = 1,
    // Width of aruser signal
    parameter ARUSER_WIDTH   = 1,
    // Width of ruser signal
    parameter RUSER_WIDTH    = 1,
    // AXI request/response
    parameter type axi_req_t = logic,
    parameter type axi_rsp_t = logic
) (
    /*
     * Write address channel
     */
    output logic [ID_WIDTH-1:0]      m_axi_awid,
    output logic [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output logic [7:0]               m_axi_awlen,
    output logic [2:0]               m_axi_awsize,
    output logic [1:0]               m_axi_awburst,
    output logic                     m_axi_awlock,
    output logic [3:0]               m_axi_awcache,
    output logic [2:0]               m_axi_awprot,
    output logic [3:0]               m_axi_awqos,
    output logic [3:0]               m_axi_awregion,
    output logic [AWUSER_WIDTH-1:0]  m_axi_awuser,
    output logic                     m_axi_awvalid,
    input  logic                     m_axi_awready,
    /*
     * Write data channel
     */
    output logic [DATA_WIDTH-1:0]    m_axi_wdata,
    output logic [STRB_WIDTH-1:0]    m_axi_wstrb,
    output logic                     m_axi_wlast,
    output logic [WUSER_WIDTH-1:0]   m_axi_wuser,
    output logic                     m_axi_wvalid,
    input  logic                     m_axi_wready,
    /*
     * Write response channel
     */
    input  logic [ID_WIDTH-1:0]      m_axi_bid,
    input  logic [1:0]               m_axi_bresp,
    input  logic [BUSER_WIDTH-1:0]   m_axi_buser,
    input  logic                     m_axi_bvalid,
    output logic                     m_axi_bready,
    /*
     * Read address channel
     */
    output logic [ID_WIDTH-1:0]      m_axi_arid,
    output logic [ADDR_WIDTH-1:0]    m_axi_araddr,
    output logic [7:0]               m_axi_arlen,
    output logic [2:0]               m_axi_arsize,
    output logic [1:0]               m_axi_arburst,
    output logic                     m_axi_arlock,
    output logic [3:0]               m_axi_arcache,
    output logic [2:0]               m_axi_arprot,
    output logic [3:0]               m_axi_arqos,
    output logic [3:0]               m_axi_arregion,
    output logic [ARUSER_WIDTH-1:0]  m_axi_aruser,
    output logic                     m_axi_arvalid,
    input  logic                     m_axi_arready,
    /*
     * Read data channel
     */
    input  logic [ID_WIDTH-1:0]      m_axi_rid,
    input  logic [DATA_WIDTH-1:0]    m_axi_rdata,
    input  logic [1:0]               m_axi_rresp,
    input  logic                     m_axi_rlast,
    input  logic [RUSER_WIDTH-1:0]   m_axi_ruser,
    input  logic                     m_axi_rvalid,
    output logic                     m_axi_rready,
    /*
     * AXI request/response pair
     */
    input  axi_req_t                 axi_req_i,
    output axi_rsp_t                 axi_rsp_o
    );

    /*
     * Write address channel
     */
    assign m_axi_awid          = axi_req_i.aw.id;
    assign m_axi_awaddr        = axi_req_i.aw.addr;
    assign m_axi_awlen         = axi_req_i.aw.len;
    assign m_axi_awsize        = axi_req_i.aw.size;
    assign m_axi_awburst       = axi_req_i.aw.burst;
    assign m_axi_awlock        = axi_req_i.aw.lock;
    assign m_axi_awcache       = axi_req_i.aw.cache;
    assign m_axi_awprot        = axi_req_i.aw.prot;
    assign m_axi_awqos         = axi_req_i.aw.qos;
    // assign master.aw_atop      = axi_req_i.aw.atop; // TODO: check if we should/can add this field to the axi interface
    assign m_axi_awregion      = axi_req_i.aw.region;
    assign m_axi_awuser        = axi_req_i.aw.user;
    assign m_axi_awvalid       = axi_req_i.aw_valid;
    assign axi_rsp_o.aw_ready  = m_axi_awready;

    /*
     * Write data channel
     */
    assign m_axi_wdata        = axi_req_i.w.data;
    assign m_axi_wstrb        = axi_req_i.w.strb;
    assign m_axi_wlast        = axi_req_i.w.last;
    assign m_axi_wuser        = axi_req_i.w.user;
    assign m_axi_wvalid       = axi_req_i.w_valid;
    assign axi_rsp_o.w_ready  = m_axi_wready;

    /*
     * Write response channel
     */
    assign axi_rsp_o.b.id    = m_axi_bid;
    assign axi_rsp_o.b.resp  = m_axi_bresp;
    assign axi_rsp_o.b.user  = m_axi_buser;
    assign axi_rsp_o.b_valid = m_axi_bvalid;
    assign m_axi_bready      = axi_req_i.b_ready;

    /*
     * Read address channel
     */
    assign m_axi_arid          = axi_req_i.ar.id;
    assign m_axi_araddr        = axi_req_i.ar.addr;
    assign m_axi_arlen         = axi_req_i.ar.len;
    assign m_axi_arsize        = axi_req_i.ar.size;
    assign m_axi_arburst       = axi_req_i.ar.burst;
    assign m_axi_arlock        = axi_req_i.ar.lock;
    assign m_axi_arcache       = axi_req_i.ar.cache;
    assign m_axi_arprot        = axi_req_i.ar.prot;
    assign m_axi_arqos         = axi_req_i.ar.qos;
    assign m_axi_arregion      = axi_req_i.ar.region;
    assign m_axi_aruser        = axi_req_i.ar.user;
    assign m_axi_arvalid       = axi_req_i.ar_valid;
    assign axi_rsp_o.ar_ready  = m_axi_arready;

    /*
     * Read data channel
     */
    assign axi_rsp_o.r.id    = m_axi_rid;
    assign axi_rsp_o.r.data  = m_axi_rdata;
    assign axi_rsp_o.r.resp  = m_axi_rresp;
    assign axi_rsp_o.r.last  = m_axi_rlast;
    assign axi_rsp_o.r.user  = m_axi_ruser;
    assign axi_rsp_o.r_valid = m_axi_rvalid;
    assign m_axi_rready      = axi_req_i.r_ready;

endmodule

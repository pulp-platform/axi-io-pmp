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
// Description: AXI slave to (req_t, resp_t) pair connector (pulp-platform interface)

`timescale 1ns / 1ps

module axi_slave_connector #(
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
    input  [ID_WIDTH-1:0]      s_axi_awid,
    input  [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  [7:0]               s_axi_awlen,
    input  [2:0]               s_axi_awsize,
    input  [1:0]               s_axi_awburst,
    input                      s_axi_awlock,
    input  [3:0]               s_axi_awcache,
    input  [2:0]               s_axi_awprot,
    input  [3:0]               s_axi_awqos,
    input  [3:0]               s_axi_awregion,
    input  [AWUSER_WIDTH-1:0]  s_axi_awuser,
    input                      s_axi_awvalid,
    output                     s_axi_awready,
    /*
     * Write data channel
     */
    input  [DATA_WIDTH-1:0]    s_axi_wdata,
    input  [STRB_WIDTH-1:0]    s_axi_wstrb,
    input                      s_axi_wlast,
    input  [WUSER_WIDTH-1:0]   s_axi_wuser,
    input                      s_axi_wvalid,
    output                     s_axi_wready,
    /*
     * Write response channel
     */
    output [ID_WIDTH-1:0]      s_axi_bid,
    output [1:0]               s_axi_bresp,
    output [BUSER_WIDTH-1:0]   s_axi_buser,
    output                     s_axi_bvalid,
    input                      s_axi_bready,
    /*
     * Read address channel
     */
    input  [ID_WIDTH-1:0]      s_axi_arid,
    input  [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  [7:0]               s_axi_arlen,
    input  [2:0]               s_axi_arsize,
    input  [1:0]               s_axi_arburst,
    input                      s_axi_arlock,
    input  [3:0]               s_axi_arcache,
    input  [2:0]               s_axi_arprot,
    input  [3:0]               s_axi_arqos,
    input  [3:0]               s_axi_arregion,
    input  [ARUSER_WIDTH-1:0]  s_axi_aruser,
    input                      s_axi_arvalid,
    output                     s_axi_arready,
    /*
     * Read data channel
     */
    output [ID_WIDTH-1:0]      s_axi_rid,
    output [DATA_WIDTH-1:0]    s_axi_rdata,
    output [1:0]               s_axi_rresp,
    output                     s_axi_rlast,
    output [RUSER_WIDTH-1:0]   s_axi_ruser,
    output                     s_axi_rvalid,
    input                      s_axi_rready,
    /*
     * AXI request/response pair
     */
    output axi_req_t           axi_req_o,
    input  axi_rsp_t           axi_resp_i
);

    /*
     * Write address channel
     */
    assign axi_req_o.aw.id     = s_axi_awid;
    assign axi_req_o.aw.addr   = s_axi_awaddr;
    assign axi_req_o.aw.len    = s_axi_awlen;
    assign axi_req_o.aw.size   = s_axi_awsize;
    assign axi_req_o.aw.burst  = s_axi_awburst;
    assign axi_req_o.aw.lock   = s_axi_awlock;
    assign axi_req_o.aw.cache  = s_axi_awcache;
    assign axi_req_o.aw.prot   = s_axi_awprot;
    assign axi_req_o.aw.qos    = s_axi_awqos;
    // assign axi_req_o.aw.atop   = slave.aw_atop; // TODO: check if we should/can add this field to the axi interface
    assign axi_req_o.aw.region = s_axi_awregion;
    assign axi_req_o.aw.user   = s_axi_awuser;
    assign axi_req_o.aw_valid  = s_axi_awvalid;
    assign s_axi_awready       = axi_resp_i.aw_ready;    

    /*
     * Write data channel
     */
    assign axi_req_o.w.data  = s_axi_wdata;
    assign axi_req_o.w.strb  = s_axi_wstrb;
    assign axi_req_o.w.last  = s_axi_wlast;
    assign axi_req_o.w.user  = s_axi_wuser;
    assign axi_req_o.w_valid = s_axi_wvalid;
    assign s_axi_wready      = axi_resp_i.w_ready;

    /*
     * Write response channel
     */
    assign s_axi_bid         = axi_resp_i.b.id;
    assign s_axi_bresp       = axi_resp_i.b.resp;
    assign s_axi_bvalid      = axi_resp_i.b_valid;
    assign s_axi_buser       = axi_resp_i.b.user;
    assign axi_req_o.b_ready = s_axi_bready;

    /*
     * Read address channel
     */
    assign axi_req_o.ar.id     = s_axi_arid;
    assign axi_req_o.ar.addr   = s_axi_araddr;
    assign axi_req_o.ar.len    = s_axi_arlen;
    assign axi_req_o.ar.size   = s_axi_arsize;
    assign axi_req_o.ar.burst  = s_axi_arburst;
    assign axi_req_o.ar.lock   = s_axi_arlock;
    assign axi_req_o.ar.cache  = s_axi_arcache;
    assign axi_req_o.ar.prot   = s_axi_arprot;
    assign axi_req_o.ar.qos    = s_axi_arqos;
    assign axi_req_o.ar.region = s_axi_arregion;
    assign axi_req_o.ar.user   = s_axi_aruser;
    assign axi_req_o.ar_valid  = s_axi_arvalid;
    assign s_axi_arready       = axi_resp_i.ar_ready;

    /*
     * Read data channel
     */
    assign s_axi_rid         = axi_resp_i.r.id;
    assign s_axi_rdata       = axi_resp_i.r.data;
    assign s_axi_rresp       = axi_resp_i.r.resp;
    assign s_axi_rlast       = axi_resp_i.r.last;
    assign s_axi_rvalid      = axi_resp_i.r_valid;
    assign s_axi_ruser       = axi_resp_i.r.user;
    assign axi_req_o.r_ready = s_axi_rready;

endmodule

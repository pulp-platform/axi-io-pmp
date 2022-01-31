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
// Description: Traditional style AXI IO-PMP module

`timescale 1ns / 1ps

module axi_io_pmp #(
    // register parameters (bypass { read, write } x { pre pmp, post pmp })
    // TODO
    // AXI channel structs
    parameter type axi_aw_chan_t       = logic,
    parameter type  axi_w_chan_t       = logic,
    parameter type  axi_b_chan_t       = logic,
    parameter type axi_ar_chan_t       = logic,
    parameter type  axi_r_chan_t       = logic,
    // AXI request/response
    parameter type axi_req_t           = logic,
    parameter type axi_rsp_t           = logic,
    // register interface request/response
    parameter type reg_req_t           = logic,
    parameter type reg_rsp_t           = logic,
    // PMP parameters
    parameter int unsigned PLEN        = 56, // rv64: 56, rv32: 34
    parameter int unsigned PMP_LEN     = 54, // rv64: 54, rv32: 32
    parameter int unsigned NR_ENTRIES  = 16,
    parameter int unsigned MAX_ENTRIES = 16
) (
    input  logic     clk_i,
    input  logic     rst_ni,
    // slave port
    input  axi_req_t slv_req_i,
    output axi_rsp_t slv_resp_o,
    // master port
    output axi_req_t mst_req_o,
    input  axi_rsp_t mst_resp_i,
    // configuration port
    input  reg_req_t cfg_req_i,
    output reg_rsp_t cfg_resp_o
);

    localparam Bypass = 1'b1;


    /*
     * Device configuration and status registers
     */
    io_pmp_reg_pkg::io_pmp_reg2hw_t io_pmp_reg2hw;
    io_pmp_reg_top #(
        .AW       ( $bits(cfg_req_i.addr) ),
        .reg_req_t( reg_req_t             ),
        .reg_rsp_t( reg_rsp_t             )
    ) io_pmp_reg_top0 (
        .clk_i    ( clk_i         ),
        .rst_ni   ( rst_ni        ),
        .devmode_i( 1'b0          ), // if 1, explicit error return for unmapped register access
        // register interface
        .reg_req_i( cfg_req_i     ),
        .reg_rsp_o( cfg_resp_o    ),
        // to HW
        .reg2hw   ( io_pmp_reg2hw ) // from registers to hardware
    ); 

    /*
     * Read check PMP
     */
    wire pmp_allow_r;
    pmp #(
        .PLEN      ( PLEN       ),
        .PMP_LEN   ( PMP_LEN    ),
        .NR_ENTRIES( NR_ENTRIES )
    ) pmp0 (
        // input
        .addr_i       ( slv_req_i.ar.addr[PLEN-1:0] ), // [PLEN-1:0]
        .access_type_i( riscv::ACCESS_READ          ), // riscv::pmp_access_t, TODO: adjust to R/W transaction
        .priv_lvl_i   ( riscv::PRIV_LVL_S           ), // riscv::priv_lvl_t, all accesses here are unprivileged
        // configuration
        .conf_addr_i  ( io_pmp_reg2hw.pmp_addr      ), // [MAX_ENTRIES-1:0][PMP_LEN-1:0] 
        .conf_i       ( io_pmp_reg2hw.pmp_cfg       ), // riscv::pmpcfg_t [MAX_ENTRIES-1:0]
        // output
        .allow_o      ( pmp_allow_r                 )
    );


    /*
     * Read channels
     */
    spill_register #(
    .T       ( axi_ar_chan_t       ),
    .Bypass  ( Bypass              )
    ) i_reg_ar (
    .clk_i   ( clk_i               ),
    .rst_ni  ( rst_ni              ),
    .valid_i ( slv_req_i.ar_valid  ),
    .ready_o ( slv_resp_o.ar_ready ),
    .data_i  ( slv_req_i.ar        ),
    .valid_o ( mst_req_o.ar_valid  ),
    .ready_i ( mst_resp_i.ar_ready ),
    .data_o  ( mst_req_o.ar        )
    );


    axi_r_chan_t r_chan;
    assign r_chan.id = mst_resp_i.r.id;
    assign r_chan.data = pmp_allow_r ? mst_resp_i.r.data : '1; // TODO: this should not even be necessary (we should block the transaction earlier)
    assign r_chan.resp = pmp_allow_r ? axi_pkg::RESP_OKAY : axi_pkg::RESP_SLVERR;
    assign r_chan.last = mst_resp_i.r.last;
    assign r_chan.user = mst_resp_i.r.user;

    spill_register #(
    .T       ( axi_r_chan_t       ),
    .Bypass  ( Bypass             )
    ) i_reg_r  (
    .clk_i   ( clk_i              ),
    .rst_ni  ( rst_ni             ),
    .valid_i ( mst_resp_i.r_valid ),
    .ready_o ( mst_req_o.r_ready  ),
    .data_i  ( r_chan             ), // mst_resp_i.r 
    .valid_o ( slv_resp_o.r_valid ),
    .ready_i ( slv_req_i.r_ready  ),
    .data_o  ( slv_resp_o.r       )
    );

    /*
     * Write check PMP
     */
    wire pmp_allow_w;
    pmp #(
        .PLEN      ( PLEN       ),
        .PMP_LEN   ( PMP_LEN    ),
        .NR_ENTRIES( NR_ENTRIES )
    ) pmp1 (
        // input
        .addr_i       ( slv_req_i.aw.addr[PLEN-1:0] ), // [PLEN-1:0]
        .access_type_i( riscv::ACCESS_WRITE         ), // riscv::pmp_access_t, TODO: adjust to R/W transaction
        .priv_lvl_i   ( riscv::PRIV_LVL_S           ), // riscv::priv_lvl_t, all accesses here are unprivileged
        // configuration
        .conf_addr_i  ( io_pmp_reg2hw.pmp_addr      ), // [MAX_ENTRIES-1:0][PMP_LEN-1:0] 
        .conf_i       ( io_pmp_reg2hw.pmp_cfg       ), // riscv::pmpcfg_t [MAX_ENTRIES-1:0]
        // output
        .allow_o      ( pmp_allow_w                 )
    );


    /*
     * Write channels
     */
    spill_register #(
    .T       ( axi_aw_chan_t       ),
    .Bypass  ( Bypass              )
    ) i_reg_aw (
    .clk_i   ( clk_i               ),
    .rst_ni  ( rst_ni              ),
    .valid_i ( slv_req_i.aw_valid  ),
    .ready_o ( slv_resp_o.aw_ready ),
    .data_i  ( slv_req_i.aw        ),
    .valid_o ( mst_req_o.aw_valid  ),
    .ready_i ( mst_resp_i.aw_ready ),
    .data_o  ( mst_req_o.aw        )
    );

    spill_register #(
    .T       ( axi_w_chan_t       ),
    .Bypass  ( Bypass             )
    ) i_reg_w  (
    .clk_i   ( clk_i              ),
    .rst_ni  ( rst_ni             ),
    .valid_i ( slv_req_i.w_valid  ),
    .ready_o ( slv_resp_o.w_ready ),
    .data_i  ( slv_req_i.w        ),
    .valid_o ( mst_req_o.w_valid  ),
    .ready_i ( mst_resp_i.w_ready ),
    .data_o  ( mst_req_o.w        )
    );

    spill_register #(
    .T       ( axi_b_chan_t       ),
    .Bypass  ( Bypass             )
    ) i_reg_b  (
    .clk_i   ( clk_i              ),
    .rst_ni  ( rst_ni             ),
    .valid_i ( mst_resp_i.b_valid ),
    .ready_o ( mst_req_o.b_ready  ),
    .data_i  ( mst_resp_i.b       ),
    .valid_o ( slv_resp_o.b_valid ),
    .ready_i ( slv_req_i.b_ready  ),
    .data_o  ( slv_resp_o.b       )
    );


endmodule

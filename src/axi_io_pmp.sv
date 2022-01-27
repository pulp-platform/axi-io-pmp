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

//`include "riscv.sv"
//`include "cf_math_pkg.sv"

module axi_io_pmp #(
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
    input                   clk_i,
    input                   rst_ni,
    // slave port
    input  axi_conf::req_t  slv_req_i,
    output axi_conf::resp_t slv_resp_o,
    // master port
    output axi_conf::req_t  mst_req_o,
    input  axi_conf::resp_t mst_resp_i
);

    localparam PLEN        = 56; // rv64: 56, rv32: 34
    localparam PMP_LEN     = 54; // rv64: 54, rv32: 32
    localparam NR_ENTRIES  = 16;
    localparam MAX_ENTRIES = 16;


    logic [MAX_ENTRIES-1:0][PMP_LEN-1:0] cfg_addr_reg;
    logic [$bits(riscv::pmpcfg_t)-1:0] [MAX_ENTRIES-1:0] cfg_reg;

    wire pmp_allow;

    initial begin
        // reset all entries
        for (int i = 0; i < MAX_ENTRIES; i = i + 1) begin
            cfg_addr_reg[i] = '0;
            cfg_reg[i]      = '0;
        end
    end

    /*
     * Read check PMP
     */
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
        .conf_addr_i  ( cfg_addr_reg                ), // [MAX_ENTRIES-1:0][PMP_LEN-1:0] 
        .conf_i       ( cfg_reg                     ), // riscv::pmpcfg_t [MAX_ENTRIES-1:0]
        // output
        .allow_o      ( pmp_allow                   )
    );

    // /*
    //  * Write check PMP
    //  */
    // pmp #(
    //     .PLEN      ( PLEN       ),
    //     .PMP_LEN   ( PMP_LEN    ),
    //     .NR_ENTRIES( NR_ENTRIES )
    // ) pmp1 (
    //     // input
    //     .addr_i       ( slv_req_i.aw.addr[PLEN-1:0] ), // [PLEN-1:0]
    //     .access_type_i( riscv::ACCESS_WRITE         ), // riscv::pmp_access_t, TODO: adjust to R/W transaction
    //     .priv_lvl_i   ( riscv::PRIV_LVL_S           ), // riscv::priv_lvl_t, all accesses here are unprivileged
    //     // configuration
    //     .conf_addr_i  ( cfg_addr_reg                ), // [MAX_ENTRIES-1:0][PMP_LEN-1:0] 
    //     .conf_i       ( cfg_reg                     ), // riscv::pmpcfg_t [MAX_ENTRIES-1:0]
    //     // output
    //     .allow_o      ( pmp_allow                   )
    // );



    localparam Bypass = 1'b1;

    /*
     * Write channels
     */
    spill_register #(
    .T       ( axi_conf::aw_chan_t ),
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
    .T       ( axi_conf::w_chan_t ),
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
    .T       ( axi_conf::b_chan_t ),
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

    /*
     * Read channels
     */
    spill_register #(
    .T       ( axi_conf::ar_chan_t ),
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


    axi_conf::r_chan_t r_chan;
    assign r_chan.id = mst_resp_i.r.id;
    assign r_chan.data = pmp_allow ? mst_resp_i.r.data : '1; // TODO: this should not even be necessary (we should block the transaction earlier)
    assign r_chan.resp = pmp_allow ? axi_conf::RESP_OKAY : axi_conf::RESP_SLVERR;
    assign r_chan.last = mst_resp_i.r.last;
    assign r_chan.user = mst_resp_i.r.user;

    spill_register #(
    .T       ( axi_conf::r_chan_t ),
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

endmodule

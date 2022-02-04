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
    parameter int unsigned MAX_ENTRIES = 16,
    parameter int unsigned PMPGranularity = 9, // 4K
    // AXI parameters
    // maximum number of AXI bursts outstanding at the same time
    parameter int unsigned MaxTxns  = 32'd1
) (
    // rising-edge clock 
    input  logic     clk_i,
    // asynchronous reset, active low
    input  logic     rst_ni,
    // slave port
    input  axi_req_t slv_req_i,
    output axi_rsp_t slv_rsp_o,
    // master port
    output axi_req_t mst_req_o,
    input  axi_rsp_t mst_rsp_i,
    // configuration port
    input  reg_req_t cfg_req_i,
    output reg_rsp_t cfg_rsp_o
);

    /*
     * Device configuration and status registers
     */
    io_pmp_reg_pkg::io_pmp_reg2hw_t io_pmp_reg2hw;
    io_pmp_reg_pkg::io_pmp_hw2reg_t io_pmp_hw2reg;

    /*
     * RISC-V Privilege Specs: 
     *  - "When G ≥ 2 and pmpcfgi.A[1] is set, i.e. the mode is NAPOT, then bits pmpaddri[G-2:0] read as all ones."
     *  - "When G ≥ 1 and pmpcfgi.A[1] is clear, i.e. the mode is OFF or TOR, then bits pmpaddri[G-1:0] read as all zeros."
     */
    reg_rsp_t cfg_rsp_mod;
    always_comb begin

        // default pass through
        cfg_rsp_o.rdata = cfg_rsp_mod.rdata;
        cfg_rsp_o.error = cfg_rsp_mod.error;
        cfg_rsp_o.ready = cfg_rsp_mod.ready;

        // modify response with granularity
        if(!cfg_req_i.write) begin // read access

            static int index = (cfg_req_i.addr - io_pmp_reg_pkg::IO_PMP_PMP_ADDR_0_OFFSET) >> 3;

            if(!io_pmp_reg2hw.pmp_cfg[index][4] &&  PMPGranularity >= 1) begin  // riscv::OFF or riscv::TOR -> force 0 for bits [G-1:0] where G is the granularity

                cfg_rsp_o.rdata[PMPGranularity-1:0] = { PMPGranularity{1'b0} };
            end

            if(io_pmp_reg2hw.pmp_cfg[index][4] &&  PMPGranularity >= 2) begin // riscv::NAPOT -> force 1 for bits [G-2:0] where G is the granularity
                
                cfg_rsp_o.rdata[PMPGranularity-2:0] = { (PMPGranularity-1){1'b1} };
            end

            // TODO: handle case PMPGranularity ==1 && riscv::NAPOT ?

        end
    end



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
        .reg_rsp_o( cfg_rsp_mod   ),
        // from hardware to register
        .hw2reg   ( io_pmp_hw2reg ),
        // from registers to hardware 
        .reg2hw   ( io_pmp_reg2hw ) 
    ); 


    /*
     * Read channel PMP
     */
    logic [PLEN-1:0] pmp_addr_r;
    logic pmp_allow_r;

    // extract relevant address to check TODO: bursts are not fully checked yet!
    always_comb begin
        case (slv_req_i.ar.burst)
            axi_pkg::BURST_FIXED, axi_pkg::BURST_INCR, axi_pkg::BURST_WRAP: begin
                pmp_addr_r = slv_req_i.ar.addr[PLEN-1:0];
            end
        endcase
    end

    // address check
    pmp #(
        .PLEN      ( PLEN       ),
        .PMP_LEN   ( PMP_LEN    ),
        .NR_ENTRIES( NR_ENTRIES ),
        .PMPGranularity(PMPGranularity)
    ) pmp0 (
        // input
        .addr_i       ( pmp_addr_r             ), // [PLEN-1:0], TODO: check if we slice the right bits
        .access_type_i( riscv::ACCESS_READ     ), // handle read accesses
        .priv_lvl_i   ( riscv::PRIV_LVL_S      ), // all accesses here are unprivileged
        // configuration
        .conf_addr_i  ( io_pmp_reg2hw.pmp_addr ), // pmp address
        .conf_i       ( io_pmp_reg2hw.pmp_cfg  ), // pmp conf
        // output
        .allow_o      ( pmp_allow_r            )
    );

    /*
     * Write channel PMP
     */
    logic [PLEN-1:0] pmp_addr_w;
    logic pmp_allow_w;

    // extract relevant address to check: TODO: bursts are not fully checked yet!
    always_comb begin
        case (slv_req_i.aw.burst)
            axi_pkg::BURST_FIXED, axi_pkg::BURST_INCR, axi_pkg::BURST_WRAP: begin
                pmp_addr_w = slv_req_i.aw.addr[PLEN-1:0];
            end
        endcase
    end

    // address check
    pmp #(
        .PLEN      ( PLEN       ),
        .PMP_LEN   ( PMP_LEN    ),
        .NR_ENTRIES( NR_ENTRIES ),
        .PMPGranularity(PMPGranularity)
    ) pmp1 (
        // input
        .addr_i       ( pmp_addr_w             ), // [PLEN-1:0], TODO: check if we slice the right bits
        .access_type_i( riscv::ACCESS_WRITE    ), // handle write accesses
        .priv_lvl_i   ( riscv::PRIV_LVL_S      ), // all accesses here are unprivileged
        // configuration
        .conf_addr_i  ( io_pmp_reg2hw.pmp_addr ), // pmp address
        .conf_i       ( io_pmp_reg2hw.pmp_cfg  ), // pmp conf
        // output
        .allow_o      ( pmp_allow_w            )
    );


    /*
     * Demultiplex between authorized and unauthorized transactions
     */
    axi_req_t error_req;
    axi_rsp_t error_rsp;
    axi_demux #(
        .AxiIdWidth ( $bits(error_req.aw.id) ),
        .aw_chan_t  ( axi_aw_chan_t          ),
        .w_chan_t   ( axi_w_chan_t           ),
        .b_chan_t   ( axi_b_chan_t           ),
        .ar_chan_t  ( axi_ar_chan_t          ),
        .r_chan_t   ( axi_r_chan_t           ),
        .req_t      ( axi_req_t              ),
        .resp_t     ( axi_rsp_t              ),
        .NoMstPorts ( 2                      ),
        .MaxTrans   ( MaxTxns                ),
        .AxiLookBits( $bits(error_req.aw.id) ), // TODO: not sure what this is?
        .FallThrough( 1'b0                   ), // TODO: check what the right value is for them
        .SpillAw    ( 1'b1                   ), 
        .SpillW     ( 1'b0                   ),
        .SpillB     ( 1'b0                   ),
        .SpillAr    ( 1'b1                   ),
        .SpillR     ( 1'b0                   )
    ) axi_demux0 (
        .clk_i          ( clk_i                    ),
        .rst_ni         ( rst_ni                   ),
        .test_i         ( 1'b0                     ),
        .slv_aw_select_i( pmp_allow_w              ),
        .slv_ar_select_i( pmp_allow_r              ),
        .slv_req_i      ( slv_req_i                ),
        .slv_resp_o     ( slv_rsp_o                ),
        .mst_reqs_o     ( { mst_req_o, error_req } ), // { 1: mst, 0: error }
        .mst_resps_i    ( { mst_rsp_i, error_rsp } ) 
    );

    /*
     * Respond to unauthorized transactions with slave errors
     */
    axi_err_slv #(
        .AxiIdWidth( $bits(error_req.aw.id)  ),
        .req_t     ( axi_req_t               ),
        .resp_t    ( axi_rsp_t               ),
        .Resp      ( axi_pkg::RESP_SLVERR    ), // Error generated by this slave.
        .RespWidth ( $bits(error_rsp.r.data) ), // Data response width, gets zero extended or truncated to r.data.
        .RespData  ( 64'hCA11AB1EBADCAB1E    ), // Hexvalue for data return value
        .ATOPs     ( 1'b1                    ), // The burst splitter does not support ATOPs.
        .MaxTrans  ( 2                       )  // TODO: find best value (area/power vs performance)
    ) i_err_slv (
        .clk_i     ( clk_i     ),
        .rst_ni    ( rst_ni    ),
        .test_i    ( 1'b0      ),
        .slv_req_i ( error_req ),
        .slv_resp_o( error_rsp )
    );

endmodule

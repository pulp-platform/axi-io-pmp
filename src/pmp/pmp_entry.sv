// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Moritz Schneider, ETH Zurich
//         Andreas Kuster, <kustera@ethz.ch>
// Description: Single PMP entry

`timescale 1ns / 1ps

module pmp_entry #(
    parameter int unsigned PLEN           = 56,
    parameter int unsigned PMP_LEN        = 54,
    // 0 = 4bytes NA4 / 8bytes NAPOT (default), 1 = 16 byte NAPOT, 2 = 32 byte NAPOT, 3 = 64 byte NAPOT, etc.
    parameter int unsigned PMPGranularity = 0
) (
    // Input
    input logic [PLEN-1:0]       addr_i,
    // Configuration
    input logic [PMP_LEN-1:0]    conf_addr_i,
    input logic [PMP_LEN-1:0]    conf_addr_prev_i,
    input riscv::pmp_addr_mode_t conf_addr_mode_i,
    // Output
    output logic                 match_o
);
    logic [PLEN-1:0] conf_addr_n;
    logic [$clog2(PLEN)-1:0] trail_ones;
    assign conf_addr_n = ~conf_addr_i;
    lzc #(.WIDTH(PLEN), .MODE(1'b0)) i_lzc(
        .in_i    ( conf_addr_n ),
        .cnt_o   ( trail_ones  ),
        .empty_o (             )
    );

    always_comb begin
        case (conf_addr_mode_i)
            riscv::TOR:     begin
                // check that the requested address is in between the two
                // configuration addresses
                if (addr_i >= (conf_addr_prev_i << (2 + PMPGranularity)) && addr_i < (conf_addr_i << (2 + PMPGranularity))) begin
                    match_o = 1'b1;
                end else match_o = 1'b0;

                `ifdef FORMAL
                if (match_o == 0) begin
                    assert(addr_i >= (conf_addr_i << (2 + PMPGranularity)) || addr_i < (conf_addr_prev_i << (2 + PMPGranularity)));
                end else begin
                    assert(addr_i < (conf_addr_i << (2 + PMPGranularity)) && addr_i >= (conf_addr_prev_i << (2 + PMPGranularity)));
                end
                `endif
            end
            riscv::NA4, riscv::NAPOT:   begin

                if (conf_addr_mode_i == riscv::NA4 && PMPGranularity > 0) begin
                    match_o = 1'b0; // not selectable for G > 0
                end else begin

                    logic [PLEN-1:0] base;
                    logic [PLEN-1:0] mask;
                    int unsigned size;

                    if (conf_addr_mode_i == riscv::NA4) begin
                        size = 2;
                    end else begin
                        // use the extracted trailing ones
                        size = trail_ones + 3 + PMPGranularity;
                    end

                    mask = '1 << size;
                    base = (conf_addr_i << (2 + PMPGranularity)) & mask;
                    match_o = (addr_i & mask) == base ? 1'b1 : 1'b0;

                    // `ifdef FORMAL // TODO: update them to support granularity in the calculation
                    // // size extract checks
                    // assert(size >= 2);
                    // if (conf_addr_mode_i == riscv::NAPOT) begin
                    //     assert(size > 2);
                    //     if (size < PMP_LEN) assert(conf_addr_i[size - 3] == 0);
                    //     for (int i = 0; i < PMP_LEN; i++) begin
                    //         if (size > 3 && i <= size - 4) begin
                    //             assert(conf_addr_i[i] == 1); // check that all the rest are ones
                    //         end
                    //     end
                    // end

                    // if (size < PLEN-1) begin
                    //     if (base + 2**size > base) begin // check for overflow
                    //         if (match_o == 0) begin
                    //             assert(addr_i >= base + 2**size || addr_i < base);
                    //         end else begin
                    //             assert(addr_i < base + 2**size && addr_i >= base);
                    //         end
                    //     end else begin
                    //         if (match_o == 0) begin
                    //             assert(addr_i - 2**size >= base || addr_i < base);
                    //         end else begin
                    //             assert(addr_i - 2**size < base && addr_i >= base);
                    //         end
                    //     end
                    // end
                    // `endif
                end
            end
            riscv::OFF: match_o = 1'b0;
            default:    match_o = 0;
        endcase
    end

endmodule

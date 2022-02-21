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
    // Width of data bus in bits
    parameter              DATA_WIDTH     = 64,
    // Width of address bus in bits
    parameter              ADDR_WIDTH     = 64,
    // Width of strobe (width of data bus in words)
    parameter              STRB_WIDTH     = (DATA_WIDTH / 8),
    // Width of id signal
    parameter              ID_WIDTH       = 8,
    // Propagate awuser signal
    parameter              USER_WIDTH     = 0,
    // AXI channel structs
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic,
    // AXI request/response
    parameter type         axi_req_t      = logic,
    parameter type         axi_rsp_t      = logic,
    // register interface request/response
    parameter type         reg_req_t      = logic,
    parameter type         reg_rsp_t      = logic,
    // PMP parameters TODO: better naming (i.e for the person that instantiates them)
    parameter int unsigned PLEN           = 56,                // rv64: 56, rv32: 34
    parameter int unsigned PMP_LEN        = 54,                // rv64: 54, rv32: 32
    parameter int unsigned NR_ENTRIES     = 16,
    parameter int unsigned MAX_ENTRIES    = 16,
    parameter int unsigned PMPGranularity = 10,                // 4K
    // AXI parameters
    // maximum number of AXI bursts outstanding at the same time
    parameter int unsigned MaxTxns        = 32'd2
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


  //
  // Device configuration and status registers
  //
  io_pmp_reg_pkg::io_pmp_reg2hw_t io_pmp_reg2hw;
  reg_req_t cfg_req_mod;
  reg_rsp_t cfg_rsp_mod;


  //
  // RISC-V Privilege Specs:
  //  - "When G ≥ 2 and pmpcfgi.A[1] is set, i.e. the mode is NAPOT, then bits pmpaddri[G-2:0] read as all ones."
  //  - "When G ≥ 1 and pmpcfgi.A[1] is clear, i.e. the mode is OFF or TOR, then bits pmpaddri[G-1:0] read as all zeros."
  //
  always_comb begin

    // read: default pass through
    cfg_rsp_o.rdata   = cfg_rsp_mod.rdata;
    cfg_rsp_o.error   = cfg_rsp_mod.error;
    cfg_rsp_o.ready   = cfg_rsp_mod.ready;

    // write: default pass through
    cfg_req_mod.addr  = cfg_req_i.addr;
    cfg_req_mod.write = cfg_req_i.write;
    cfg_req_mod.wdata = cfg_req_i.wdata;
    cfg_req_mod.wstrb = cfg_req_i.wstrb;
    cfg_req_mod.valid = cfg_req_i.valid;

    // modify response with granularity > 0
    if(PMPGranularity > 0 && cfg_req_i.addr >= io_pmp_reg_pkg::IO_PMP_PMP_ADDR_0_OFFSET && cfg_req_i.addr < io_pmp_reg_pkg::IO_PMP_PMP_ADDR_15_OFFSET + 8) begin
      if (!cfg_req_i.write) begin  // read access

        logic [3:0] index;
        index = (cfg_req_i.addr - io_pmp_reg_pkg::IO_PMP_PMP_ADDR_0_OFFSET) >> 3;

        if(!io_pmp_reg2hw.pmp_cfg[index][4] &&  PMPGranularity >= 1) begin  // riscv::OFF or riscv::TOR -> force 0 for bits [G-1:0] where G is the granularity
          cfg_rsp_o.rdata[PMPGranularity-1:0] = {PMPGranularity{1'b0}};
        end

        if(io_pmp_reg2hw.pmp_cfg[index][4] &&  PMPGranularity >= 2) begin // riscv::NAPOT -> force 1 for bits [G-2:0] where G is the granularity
          cfg_rsp_o.rdata[PMPGranularity-2:0] = {(PMPGranularity - 1) {1'b1}};
        end

      end else begin  // write access

        // enforce granularity
        //cfg_req_mod.wdata[PMPGranularity-1:0] = {(PMPGranularity) {1'b0}};
      end
    end
  end

  io_pmp_reg_top #(
      .reg_req_t(reg_req_t),
      .reg_rsp_t(reg_rsp_t)
  ) io_pmp_reg_top0 (
      .clk_i    (clk_i),
      .rst_ni   (rst_ni),
      .devmode_i(1'b0),          // if 1, explicit error return for unmapped register access
      // register interface
      .reg_req_i(cfg_req_mod),
      .reg_rsp_o(cfg_rsp_mod),
      // from registers to hardware 
      .reg2hw   (io_pmp_reg2hw)
  );


  //
  // Read channel PMP
  //
  logic [PLEN-1:0] pmp_addr_r;
  logic pmp_allow_r, allow_r;

  // check boundaries and assemble allow signal
  // TODO: for now, we expect granularity of 4K i.e. we can do the PMP check in one cycle for the whole burst and only have to check if the AXI 4k boundary constraint has been followed. Later, we can multi-cycle check and allow smaller granularity levels (or us the burst splitter)
  always_comb begin

    // reject by default
    allow_r = 1'b0;
    pmp_addr_r = slv_req_i.ar.addr[PLEN-1:0]; // extract relevant address to check, default (for BURST_WRAP, we have to compute the base address first!)

    case (slv_req_i.ar.burst)
      axi_pkg::BURST_FIXED: begin
        // reading from same location: simply check that base_addr + burst_size does not cross the 4K boundary
        if ((slv_req_i.ar.addr & 12'hfff) + (1'b1 << slv_req_i.ar.size) < (1'b1 << 12)) begin
          allow_r = pmp_allow_r;
        end else begin  // boundary violation
          allow_r = 1'b0;
        end

      end
      axi_pkg::BURST_WRAP: begin
        // wrap_boundary = (start_address/(number_bytes*burst_length)) * (number_bytes*burst_length)
        // address_n = wrap_boundary + (number_bytes * burst_length)
        logic [11:0] wrap_boundary, address_n;

        // by spec, burst lenth must be e {2, 4, 8, 16}
        logic [2:0] log2_len;
        case (slv_req_i.ar.len)
          8'd2: log2_len = 3'b001;
          8'd4: log2_len = 3'b010;
          8'd8: log2_len = 3'b011;
          8'd16: log2_len = 3'b100;
          default: log2_len = 3'b111;  // invalid
        endcase

        wrap_boundary = (slv_req_i.ar.addr >> (log2_len + slv_req_i.ar.size)) << (log2_len + slv_req_i.ar.size);
        // address_n = wrap_boundary + (slv_req_i.ar.len << slv_req_i.ar.size);

        pmp_addr_r = wrap_boundary; // BURST_WRAP has to check from the wrap_boundary aka lower bound address

        if(log2_len != 3'b111 && (wrap_boundary & 12'hfff) + (slv_req_i.ar.len << slv_req_i.ar.size) < (1'b1 << 12) ) begin
          allow_r = pmp_allow_r;
        end else begin
          allow_r = 1'b0;
        end

      end
      axi_pkg::BURST_INCR: begin
        // check if burst is within 4K range
        if((slv_req_i.ar.addr & 12'hfff) + (slv_req_i.ar.len << slv_req_i.ar.size) < (1'b1 << 12)) begin
          allow_r = pmp_allow_r;
        end else begin  // boundary violation
          allow_r = 1'b0;
        end
      end
    endcase
  end

  // address check
  pmp #(
      .PLEN          (PLEN),
      .PMP_LEN       (PMP_LEN),
      .NR_ENTRIES    (NR_ENTRIES),
      .PMPGranularity(PMPGranularity)
  ) pmp0 (
      // input
      .addr_i       (pmp_addr_r),              // [PLEN-1:0], TODO: check if we slice the right bits
      .access_type_i(riscv::ACCESS_READ),      // handle read accesses
      .priv_lvl_i   (riscv::PRIV_LVL_S),       // all accesses here are unprivileged
      // configuration
      .conf_addr_i  (io_pmp_reg2hw.pmp_addr),  // pmp address
      .conf_i       (io_pmp_reg2hw.pmp_cfg),   // pmp conf
      // output
      .allow_o      (pmp_allow_r)
  );

  //
  // Write channel PMP
  //
  logic [PLEN-1:0] pmp_addr_w;
  logic pmp_allow_w, allow_w;

  // check boundaries and assemble allow signal
  // TODO: for now, we expect granularity of 4K i.e. we can do the PMP check in one cycle for the whole burst and only have to check if the AXI 4k boundary constraint has been followed. Later, we can multi-cycle check and allow smaller granularity levels (or us the burst splitter)
  always_comb begin

    // reject by default
    allow_w = 1'b0;
    pmp_addr_w = slv_req_i.aw.addr[PLEN-1:0]; // extract relevant address to check, default (for BURST_WRAP, we have to compute the base address first!)

    case (slv_req_i.aw.burst)
      axi_pkg::BURST_FIXED: begin
        // writing to same location: simply check that base_addr + burst_size does not cross the 4K boundary
        if ((slv_req_i.aw.addr & 12'hfff) + (1'b1 << slv_req_i.aw.size) < (1'b1 << 12)) begin
          allow_w = pmp_allow_w;
        end else begin  // boundary violation
          allow_w = 1'b0;
        end

      end
      axi_pkg::BURST_WRAP: begin

        // wrap_boundary = (start_address/(number_bytes*burst_length)) * (number_bytes*burst_length) // lower address
        // address_n = wrap_boundary + (number_bytes * burst_length) // upper address
        logic [11:0] wrap_boundary, address_n;

        // by spec, burst lenth must be e {2, 4, 8, 16}
        logic [2:0] log2_len;
        case (slv_req_i.aw.len)
          8'd2: log2_len = 3'b001;
          8'd4: log2_len = 3'b010;
          8'd8: log2_len = 3'b011;
          8'd16: log2_len = 3'b100;
          default: log2_len = 3'b111;  // invalid
        endcase

        wrap_boundary = (slv_req_i.aw.addr >> (log2_len + slv_req_i.aw.size)) << (log2_len + slv_req_i.aw.size);
        // address_n = wrap_boundary + (slv_req_i.aw.len << slv_req_i.aw.size);

        pmp_addr_w = wrap_boundary; // BURST_WRAP has to check from the wrap_boundary aka lower bound address

        if(log2_len != 3'b111 && (wrap_boundary & 12'hfff) + (slv_req_i.aw.len << slv_req_i.aw.size) < (1'b1 << 12) ) begin
          allow_w = pmp_allow_w;
        end else begin
          allow_w = 1'b0;
        end
      end
      axi_pkg::BURST_INCR: begin
        // check if burst is within 4K range
        if((slv_req_i.aw.addr & 12'hfff) + (slv_req_i.aw.len << slv_req_i.aw.size) < (1'b1 << 12)) begin
          allow_w = pmp_allow_w;
        end else begin  // boundary violation
          allow_w = 1'b0;
        end
      end
    endcase
  end

  // address check
  pmp #(
      .PLEN          (PLEN),
      .PMP_LEN       (PMP_LEN),
      .NR_ENTRIES    (NR_ENTRIES),
      .PMPGranularity(PMPGranularity)
  ) pmp1 (
      // input
      .addr_i       (pmp_addr_w),              // [PLEN-1:0], TODO: check if we slice the right bits
      .access_type_i(riscv::ACCESS_WRITE),     // handle write accesses
      .priv_lvl_i   (riscv::PRIV_LVL_S),       // all accesses here are unprivileged
      // configuration
      .conf_addr_i  (io_pmp_reg2hw.pmp_addr),  // pmp address
      .conf_i       (io_pmp_reg2hw.pmp_cfg),   // pmp conf
      // output
      .allow_o      (pmp_allow_w)
  );


  //
  // Demultiplex between authorized and unauthorized transactions
  //
  axi_req_t error_req;
  axi_rsp_t error_rsp;
  axi_demux #(
      .AxiIdWidth (ID_WIDTH),
      .aw_chan_t  (axi_aw_chan_t),
      .w_chan_t   (axi_w_chan_t),
      .b_chan_t   (axi_b_chan_t),
      .ar_chan_t  (axi_ar_chan_t),
      .r_chan_t   (axi_r_chan_t),
      .req_t      (axi_req_t),
      .resp_t     (axi_rsp_t),
      .NoMstPorts (2),
      .MaxTrans   (MaxTxns),
      .AxiLookBits(ID_WIDTH),       // TODO: not sure what this is?
      .FallThrough(1'b0),           // TODO: check what the right value is for them
      .SpillAw    (1'b0),
      .SpillW     (1'b0),
      .SpillB     (1'b0),
      .SpillAr    (1'b0),
      .SpillR     (1'b0)
  ) axi_demux0 (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .test_i         (1'b0),
      .slv_aw_select_i(allow_w),
      .slv_ar_select_i(allow_r),
      .slv_req_i      (slv_req_i),
      .slv_resp_o     (slv_rsp_o),
      .mst_reqs_o     ({mst_req_o, error_req}),  // { 1: mst, 0: error }
      .mst_resps_i    ({mst_rsp_i, error_rsp})   // { 1: mst, 0: error }
  );


  //
  // Respond to unauthorized transactions with slave errors
  //
  axi_err_slv #(
      .AxiIdWidth(ID_WIDTH),
      .req_t(axi_req_t),
      .resp_t(axi_rsp_t),
      .Resp(axi_pkg::RESP_SLVERR),  // error generated by this slave.
      .RespWidth(DATA_WIDTH),  // data response width, gets zero extended or truncated to r.data.
      .RespData(64'hCA11AB1EBADCAB1E),  // hexvalue for data return value
      .ATOPs(1'b1),
      .MaxTrans(1)
  ) i_err_slv (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .test_i    (1'b0),
      .slv_req_i (error_req),
      .slv_resp_o(error_rsp)
  );

endmodule

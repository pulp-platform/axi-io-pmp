// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package io_pmp_reg_pkg;

  // Address widths within the block
  parameter int BlockAw = 8;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {logic [53:0] q;} io_pmp_reg2hw_pmp_addr_mreg_t;

  typedef struct packed {logic [7:0] q;} io_pmp_reg2hw_pmp_cfg_mreg_t;

  // Register -> HW type
  typedef struct packed {
    io_pmp_reg2hw_pmp_addr_mreg_t [15:0] pmp_addr;  // [991:128]
    io_pmp_reg2hw_pmp_cfg_mreg_t [15:0]  pmp_cfg;   // [127:0]
  } io_pmp_reg2hw_t;

  // Register offsets
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_0_OFFSET = 8'h0;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_1_OFFSET = 8'h8;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_2_OFFSET = 8'h10;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_3_OFFSET = 8'h18;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_4_OFFSET = 8'h20;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_5_OFFSET = 8'h28;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_6_OFFSET = 8'h30;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_7_OFFSET = 8'h38;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_8_OFFSET = 8'h40;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_9_OFFSET = 8'h48;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_10_OFFSET = 8'h50;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_11_OFFSET = 8'h58;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_12_OFFSET = 8'h60;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_13_OFFSET = 8'h68;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_14_OFFSET = 8'h70;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_ADDR_15_OFFSET = 8'h78;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_CFG_0_OFFSET = 8'h80;
  parameter logic [BlockAw-1:0] IO_PMP_PMP_CFG_1_OFFSET = 8'h88;

  // Register index
  typedef enum int {
    IO_PMP_PMP_ADDR_0,
    IO_PMP_PMP_ADDR_1,
    IO_PMP_PMP_ADDR_2,
    IO_PMP_PMP_ADDR_3,
    IO_PMP_PMP_ADDR_4,
    IO_PMP_PMP_ADDR_5,
    IO_PMP_PMP_ADDR_6,
    IO_PMP_PMP_ADDR_7,
    IO_PMP_PMP_ADDR_8,
    IO_PMP_PMP_ADDR_9,
    IO_PMP_PMP_ADDR_10,
    IO_PMP_PMP_ADDR_11,
    IO_PMP_PMP_ADDR_12,
    IO_PMP_PMP_ADDR_13,
    IO_PMP_PMP_ADDR_14,
    IO_PMP_PMP_ADDR_15,
    IO_PMP_PMP_CFG_0,
    IO_PMP_PMP_CFG_1
  } io_pmp_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] IO_PMP_PERMIT[18] = '{
      4'b1111,  // index[ 0] IO_PMP_PMP_ADDR_0
      4'b1111,  // index[ 1] IO_PMP_PMP_ADDR_1
      4'b1111,  // index[ 2] IO_PMP_PMP_ADDR_2
      4'b1111,  // index[ 3] IO_PMP_PMP_ADDR_3
      4'b1111,  // index[ 4] IO_PMP_PMP_ADDR_4
      4'b1111,  // index[ 5] IO_PMP_PMP_ADDR_5
      4'b1111,  // index[ 6] IO_PMP_PMP_ADDR_6
      4'b1111,  // index[ 7] IO_PMP_PMP_ADDR_7
      4'b1111,  // index[ 8] IO_PMP_PMP_ADDR_8
      4'b1111,  // index[ 9] IO_PMP_PMP_ADDR_9
      4'b1111,  // index[10] IO_PMP_PMP_ADDR_10
      4'b1111,  // index[11] IO_PMP_PMP_ADDR_11
      4'b1111,  // index[12] IO_PMP_PMP_ADDR_12
      4'b1111,  // index[13] IO_PMP_PMP_ADDR_13
      4'b1111,  // index[14] IO_PMP_PMP_ADDR_14
      4'b1111,  // index[15] IO_PMP_PMP_ADDR_15
      4'b1111,  // index[16] IO_PMP_PMP_CFG_0
      4'b1111  // index[17] IO_PMP_PMP_CFG_1
  };

endpackage


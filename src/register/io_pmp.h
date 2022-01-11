// Generated register defines for io_pmp

#ifndef _IO_PMP_REG_DEFS_
#define _IO_PMP_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define IO_PMP_PARAM_REG_WIDTH 64

// PMP address (common parameters)
#define IO_PMP_PMP_ADDR_PMP_ADDR_FIELD_WIDTH 54
#define IO_PMP_PMP_ADDR_PMP_ADDR_FIELDS_PER_REG 1
#define IO_PMP_PMP_ADDR_MULTIREG_COUNT 16

// PMP address
#define IO_PMP_PMP_ADDR_0_REG_OFFSET 0x0
#define IO_PMP_PMP_ADDR_0_PMP_ADDR_0_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_0_PMP_ADDR_0_OFFSET 0
#define IO_PMP_PMP_ADDR_0_PMP_ADDR_0_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_0_PMP_ADDR_0_MASK,             \
                        .index = IO_PMP_PMP_ADDR_0_PMP_ADDR_0_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_1_REG_OFFSET 0x8
#define IO_PMP_PMP_ADDR_1_PMP_ADDR_1_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_1_PMP_ADDR_1_OFFSET 0
#define IO_PMP_PMP_ADDR_1_PMP_ADDR_1_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_1_PMP_ADDR_1_MASK,             \
                        .index = IO_PMP_PMP_ADDR_1_PMP_ADDR_1_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_2_REG_OFFSET 0x10
#define IO_PMP_PMP_ADDR_2_PMP_ADDR_2_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_2_PMP_ADDR_2_OFFSET 0
#define IO_PMP_PMP_ADDR_2_PMP_ADDR_2_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_2_PMP_ADDR_2_MASK,             \
                        .index = IO_PMP_PMP_ADDR_2_PMP_ADDR_2_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_3_REG_OFFSET 0x18
#define IO_PMP_PMP_ADDR_3_PMP_ADDR_3_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_3_PMP_ADDR_3_OFFSET 0
#define IO_PMP_PMP_ADDR_3_PMP_ADDR_3_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_3_PMP_ADDR_3_MASK,             \
                        .index = IO_PMP_PMP_ADDR_3_PMP_ADDR_3_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_4_REG_OFFSET 0x20
#define IO_PMP_PMP_ADDR_4_PMP_ADDR_4_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_4_PMP_ADDR_4_OFFSET 0
#define IO_PMP_PMP_ADDR_4_PMP_ADDR_4_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_4_PMP_ADDR_4_MASK,             \
                        .index = IO_PMP_PMP_ADDR_4_PMP_ADDR_4_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_5_REG_OFFSET 0x28
#define IO_PMP_PMP_ADDR_5_PMP_ADDR_5_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_5_PMP_ADDR_5_OFFSET 0
#define IO_PMP_PMP_ADDR_5_PMP_ADDR_5_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_5_PMP_ADDR_5_MASK,             \
                        .index = IO_PMP_PMP_ADDR_5_PMP_ADDR_5_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_6_REG_OFFSET 0x30
#define IO_PMP_PMP_ADDR_6_PMP_ADDR_6_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_6_PMP_ADDR_6_OFFSET 0
#define IO_PMP_PMP_ADDR_6_PMP_ADDR_6_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_6_PMP_ADDR_6_MASK,             \
                        .index = IO_PMP_PMP_ADDR_6_PMP_ADDR_6_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_7_REG_OFFSET 0x38
#define IO_PMP_PMP_ADDR_7_PMP_ADDR_7_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_7_PMP_ADDR_7_OFFSET 0
#define IO_PMP_PMP_ADDR_7_PMP_ADDR_7_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_7_PMP_ADDR_7_MASK,             \
                        .index = IO_PMP_PMP_ADDR_7_PMP_ADDR_7_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_8_REG_OFFSET 0x40
#define IO_PMP_PMP_ADDR_8_PMP_ADDR_8_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_8_PMP_ADDR_8_OFFSET 0
#define IO_PMP_PMP_ADDR_8_PMP_ADDR_8_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_8_PMP_ADDR_8_MASK,             \
                        .index = IO_PMP_PMP_ADDR_8_PMP_ADDR_8_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_9_REG_OFFSET 0x48
#define IO_PMP_PMP_ADDR_9_PMP_ADDR_9_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_9_PMP_ADDR_9_OFFSET 0
#define IO_PMP_PMP_ADDR_9_PMP_ADDR_9_FIELD                                     \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_9_PMP_ADDR_9_MASK,             \
                        .index = IO_PMP_PMP_ADDR_9_PMP_ADDR_9_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_10_REG_OFFSET 0x50
#define IO_PMP_PMP_ADDR_10_PMP_ADDR_10_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_10_PMP_ADDR_10_OFFSET 0
#define IO_PMP_PMP_ADDR_10_PMP_ADDR_10_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_10_PMP_ADDR_10_MASK,           \
                        .index = IO_PMP_PMP_ADDR_10_PMP_ADDR_10_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_11_REG_OFFSET 0x58
#define IO_PMP_PMP_ADDR_11_PMP_ADDR_11_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_11_PMP_ADDR_11_OFFSET 0
#define IO_PMP_PMP_ADDR_11_PMP_ADDR_11_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_11_PMP_ADDR_11_MASK,           \
                        .index = IO_PMP_PMP_ADDR_11_PMP_ADDR_11_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_12_REG_OFFSET 0x60
#define IO_PMP_PMP_ADDR_12_PMP_ADDR_12_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_12_PMP_ADDR_12_OFFSET 0
#define IO_PMP_PMP_ADDR_12_PMP_ADDR_12_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_12_PMP_ADDR_12_MASK,           \
                        .index = IO_PMP_PMP_ADDR_12_PMP_ADDR_12_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_13_REG_OFFSET 0x68
#define IO_PMP_PMP_ADDR_13_PMP_ADDR_13_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_13_PMP_ADDR_13_OFFSET 0
#define IO_PMP_PMP_ADDR_13_PMP_ADDR_13_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_13_PMP_ADDR_13_MASK,           \
                        .index = IO_PMP_PMP_ADDR_13_PMP_ADDR_13_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_14_REG_OFFSET 0x70
#define IO_PMP_PMP_ADDR_14_PMP_ADDR_14_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_14_PMP_ADDR_14_OFFSET 0
#define IO_PMP_PMP_ADDR_14_PMP_ADDR_14_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_14_PMP_ADDR_14_MASK,           \
                        .index = IO_PMP_PMP_ADDR_14_PMP_ADDR_14_OFFSET})

// PMP address
#define IO_PMP_PMP_ADDR_15_REG_OFFSET 0x78
#define IO_PMP_PMP_ADDR_15_PMP_ADDR_15_MASK 0x3fffffffffffff
#define IO_PMP_PMP_ADDR_15_PMP_ADDR_15_OFFSET 0
#define IO_PMP_PMP_ADDR_15_PMP_ADDR_15_FIELD                                   \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_ADDR_15_PMP_ADDR_15_MASK,           \
                        .index = IO_PMP_PMP_ADDR_15_PMP_ADDR_15_OFFSET})

// PMP configuration (common parameters)
#define IO_PMP_PMP_CFG_PMP_CFG_FIELD_WIDTH 8
#define IO_PMP_PMP_CFG_PMP_CFG_FIELDS_PER_REG 8
#define IO_PMP_PMP_CFG_MULTIREG_COUNT 2

// PMP configuration
#define IO_PMP_PMP_CFG_0_REG_OFFSET 0x80
#define IO_PMP_PMP_CFG_0_PMP_CFG_0_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_0_OFFSET 0
#define IO_PMP_PMP_CFG_0_PMP_CFG_0_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_0_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_0_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_1_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_1_OFFSET 8
#define IO_PMP_PMP_CFG_0_PMP_CFG_1_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_1_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_1_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_2_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_2_OFFSET 16
#define IO_PMP_PMP_CFG_0_PMP_CFG_2_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_2_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_2_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_3_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_3_OFFSET 24
#define IO_PMP_PMP_CFG_0_PMP_CFG_3_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_3_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_3_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_4_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_4_OFFSET 32
#define IO_PMP_PMP_CFG_0_PMP_CFG_4_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_4_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_4_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_5_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_5_OFFSET 40
#define IO_PMP_PMP_CFG_0_PMP_CFG_5_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_5_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_5_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_6_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_6_OFFSET 48
#define IO_PMP_PMP_CFG_0_PMP_CFG_6_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_6_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_6_OFFSET})
#define IO_PMP_PMP_CFG_0_PMP_CFG_7_MASK 0xff
#define IO_PMP_PMP_CFG_0_PMP_CFG_7_OFFSET 56
#define IO_PMP_PMP_CFG_0_PMP_CFG_7_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_0_PMP_CFG_7_MASK,               \
                        .index = IO_PMP_PMP_CFG_0_PMP_CFG_7_OFFSET})

// PMP configuration
#define IO_PMP_PMP_CFG_1_REG_OFFSET 0x88
#define IO_PMP_PMP_CFG_1_PMP_CFG_8_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_8_OFFSET 0
#define IO_PMP_PMP_CFG_1_PMP_CFG_8_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_8_MASK,               \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_8_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_9_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_9_OFFSET 8
#define IO_PMP_PMP_CFG_1_PMP_CFG_9_FIELD                                       \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_9_MASK,               \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_9_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_10_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_10_OFFSET 16
#define IO_PMP_PMP_CFG_1_PMP_CFG_10_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_10_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_10_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_11_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_11_OFFSET 24
#define IO_PMP_PMP_CFG_1_PMP_CFG_11_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_11_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_11_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_12_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_12_OFFSET 32
#define IO_PMP_PMP_CFG_1_PMP_CFG_12_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_12_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_12_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_13_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_13_OFFSET 40
#define IO_PMP_PMP_CFG_1_PMP_CFG_13_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_13_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_13_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_14_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_14_OFFSET 48
#define IO_PMP_PMP_CFG_1_PMP_CFG_14_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_14_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_14_OFFSET})
#define IO_PMP_PMP_CFG_1_PMP_CFG_15_MASK 0xff
#define IO_PMP_PMP_CFG_1_PMP_CFG_15_OFFSET 56
#define IO_PMP_PMP_CFG_1_PMP_CFG_15_FIELD                                      \
  ((bitfield_field32_t){.mask = IO_PMP_PMP_CFG_1_PMP_CFG_15_MASK,              \
                        .index = IO_PMP_PMP_CFG_1_PMP_CFG_15_OFFSET})

#ifdef __cplusplus
} // extern "C"
#endif
#endif // _IO_PMP_REG_DEFS_
       // End generated register defines for io_pmp
module axi_master_to_req #(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 32,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Width of ID signal
    parameter ID_WIDTH = 8,
    // Width of awuser signal
    parameter AWUSER_WIDTH = 1,
    // Width of wuser signal
    parameter WUSER_WIDTH = 1,
    // Width of buser signal
    parameter BUSER_WIDTH = 1,
    // Width of aruser signal
    parameter ARUSER_WIDTH = 1,
    // Width of ruser signal
    parameter RUSER_WIDTH = 1
) (
    // axi master
    output wire [ID_WIDTH-1:0]      m_axi_awid,
    output wire [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output wire [7:0]               m_axi_awlen,
    output wire [2:0]               m_axi_awsize,
    output wire [1:0]               m_axi_awburst,
    output wire                     m_axi_awlock,
    output wire [3:0]               m_axi_awcache,
    output wire [2:0]               m_axi_awprot,
    output wire [3:0]               m_axi_awqos,
    output wire [3:0]               m_axi_awregion,
    output wire [AWUSER_WIDTH-1:0]  m_axi_awuser,
    output wire                     m_axi_awvalid,
    input  wire                     m_axi_awready,
    output wire [DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire                     m_axi_wlast,
    output wire [WUSER_WIDTH-1:0]   m_axi_wuser,
    output wire                     m_axi_wvalid,
    input  wire                     m_axi_wready,
    input  wire [ID_WIDTH-1:0]      m_axi_bid,
    input  wire [1:0]               m_axi_bresp,
    input  wire [BUSER_WIDTH-1:0]   m_axi_buser,
    input  wire                     m_axi_bvalid,
    output wire                     m_axi_bready,
    output wire [ID_WIDTH-1:0]      m_axi_arid,
    output wire [ADDR_WIDTH-1:0]    m_axi_araddr,
    output wire [7:0]               m_axi_arlen,
    output wire [2:0]               m_axi_arsize,
    output wire [1:0]               m_axi_arburst,
    output wire                     m_axi_arlock,
    output wire [3:0]               m_axi_arcache,
    output wire [2:0]               m_axi_arprot,
    output wire [3:0]               m_axi_arqos,
    output wire [3:0]               m_axi_arregion,
    output wire [ARUSER_WIDTH-1:0]  m_axi_aruser,
    output wire                     m_axi_arvalid,
    input  wire                     m_axi_arready,
    input  wire [ID_WIDTH-1:0]      m_axi_rid,
    input  wire [DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]               m_axi_rresp,
    input  wire                     m_axi_rlast,
    input  wire [RUSER_WIDTH-1:0]   m_axi_ruser,
    input  wire                     m_axi_rvalid,
    output wire                     m_axi_rready,
    // axi request
    input  ariane_axi::req_t        axi_req_i,
    // axi response 
    output ariane_axi::resp_t       axi_resp_o
    );

    /*
     * Write address channel
     */
    assign m_axi_awid           = axi_req_i.aw.id;
    assign m_axi_awaddr         = axi_req_i.aw.addr;
    assign m_axi_awlen          = axi_req_i.aw.len;
    assign m_axi_awsize         = axi_req_i.aw.size;
    assign m_axi_awburst        = axi_req_i.aw.burst;
    assign m_axi_awlock         = axi_req_i.aw.lock;
    assign m_axi_awcache        = axi_req_i.aw.cache;
    assign m_axi_awprot         = axi_req_i.aw.prot;
    assign m_axi_awqos          = axi_req_i.aw.qos;
    //assign master.aw_atop       = axi_req_i.aw.atop; // TODO: check what this is
    assign m_axi_awregion       = axi_req_i.aw.region;
    assign m_axi_awuser         = '0;
    assign m_axi_awvalid        = axi_req_i.aw_valid;
    assign axi_resp_o.aw_ready  = m_axi_awready;

    /*
     * Write data channel
     */
    assign m_axi_wdata         = axi_req_i.w.data;
    assign m_axi_wstrb         = axi_req_i.w.strb;
    assign m_axi_wlast         = axi_req_i.w.last;
    assign m_axi_wuser         = '0;
    assign m_axi_wvalid        = axi_req_i.w_valid;
    assign axi_resp_o.w_ready  = m_axi_wready;

    /*
     * Write response channel
     */
    assign axi_resp_o.b.id      = m_axi_bid;
    assign axi_resp_o.b.resp    = m_axi_bresp;
    // assign axi_resp_o.b.user = m_axi_buser; TODO: check why this is missing here
    assign axi_resp_o.b_valid   = m_axi_bvalid;
    assign m_axi_bready         = axi_req_i.b_ready;

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
    assign m_axi_aruser        = '0;
    assign m_axi_arvalid       = axi_req_i.ar_valid;
    assign axi_resp_o.ar_ready = m_axi_arready;

    /*
     * Read data channel
     */
    assign axi_resp_o.r.id    = m_axi_rid;
    assign axi_resp_o.r.data  = m_axi_rdata;
    assign axi_resp_o.r.resp  = m_axi_rresp;
    assign axi_resp_o.r.last  = m_axi_rlast;
    // assign axi_resp_o.r_user   = m_axi_ruser; TODO: check why this is missing here
    assign axi_resp_o.r_valid = m_axi_rvalid;
    assign m_axi_rready       = axi_req_i.r_ready;

endmodule

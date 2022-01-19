module axi_slave_to_req #(
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
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awlock,
    input  wire [3:0]               s_axi_awcache,
    input  wire [2:0]               s_axi_awprot,
    input  wire [3:0]               s_axi_awqos,
    input  wire [3:0]               s_axi_awregion,
    input  wire [AWUSER_WIDTH-1:0]  s_axi_awuser,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]   s_axi_wuser,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    output wire [ID_WIDTH-1:0]      s_axi_bid,
    output wire [1:0]               s_axi_bresp,
    output wire [BUSER_WIDTH-1:0]   s_axi_buser,
    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready,
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arlock,
    input  wire [3:0]               s_axi_arcache,
    input  wire [2:0]               s_axi_arprot,
    input  wire [3:0]               s_axi_arqos,
    input  wire [3:0]               s_axi_arregion,
    input  wire [ARUSER_WIDTH-1:0]  s_axi_aruser,
    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    output wire [ID_WIDTH-1:0]      s_axi_rid,
    output wire [DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]               s_axi_rresp,
    output wire                     s_axi_rlast,
    output wire [RUSER_WIDTH-1:0]   s_axi_ruser,
    output wire                     s_axi_rvalid,
    input  wire                     s_axi_rready
    // axi request
    output ariane_axi::req_t        axi_req_o,
    // axi response 
    input  ariane_axi::resp_t       axi_resp_i
    );

    /*
     * Write address channel
     */
    assign  axi_req_o.aw.id      = s_axi_awid;
    assign  axi_req_o.aw.addr    = s_axi_awaddr;
    assign  axi_req_o.aw.len     = s_axi_awlen;
    assign  axi_req_o.aw.size    = s_axi_awsize;
    assign  axi_req_o.aw.burst   = s_axi_awburst;
    assign  axi_req_o.aw.lock    = s_axi_awlock;
    assign  axi_req_o.aw.cache   = s_axi_awcache;
    assign  axi_req_o.aw.prot    = s_axi_awprot;
    assign  axi_req_o.aw.qos     = s_axi_awqos;
    // assign  axi_req_o.aw.atop    = slave.aw_atop; TODO: what is that?
    assign  axi_req_o.aw.region  = s_axi_awregion;
    // assign                     = s_axi_awuser;
    assign  axi_req_o.aw_valid   = s_axi_awvalid;
    assign  s_axi_awready       = axi_resp_i.aw_ready;    


    /*
     * Write data channel
     */
    assign  axi_req_o.w.data     = s_axi_wdata;
    assign  axi_req_o.w.strb     = s_axi_wstrb;
    assign  axi_req_o.w.last     = s_axi_wlast;
    // assign                     = s_axi_wuser;
    assign  axi_req_o.w_valid    = s_axi_wvalid;
    assign  s_axi_wready        = axi_resp_i.w_ready;


    /*
     * Write response channel
     */
    assign  s_axi_bid           = axi_resp_i.b.id;
    assign  s_axi_bresp         = axi_resp_i.b.resp;
    assign  s_axi_bvalid        = axi_resp_i.b_valid;
    assign  s_axi_buser         = 1'b0;
    assign  axi_req_o.b_ready    = s_axi_bready;


    /*
     * Read address channel
     */
    assign  axi_req_o.ar.id      = s_axi_arid;
    assign  axi_req_o.ar.addr    = s_axi_araddr;
    assign  axi_req_o.ar.len     = s_axi_arlen;
    assign  axi_req_o.ar.size    = s_axi_arsize;
    assign  axi_req_o.ar.burst   = s_axi_arburst;
    assign  axi_req_o.ar.lock    = s_axi_arlock;
    assign  axi_req_o.ar.cache   = s_axi_arcache;
    assign  axi_req_o.ar.prot    = s_axi_arprot;
    assign  axi_req_o.ar.qos     = s_axi_arqos;
    assign  axi_req_o.ar.region  = s_axi_arregion;
    // assign                     = s_axi_aruser; // TODO
    assign  axi_req_o.ar_valid   = s_axi_arvalid;
    assign  s_axi_arready       = axi_resp_i.ar_ready;


    /*
     * Read data channel
     */
    assign  s_axi_rid           = axi_resp_i.r.id;
    assign  s_axi_rdata         = axi_resp_i.r.data;
    assign  s_axi_rresp         = axi_resp_i.r.resp;
    assign  s_axi_rlast         = axi_resp_i.r.last;
    assign  s_axi_rvalid        = axi_resp_i.r_valid;
    // assign  s_axi_ruser         = 1'b0; TODO
    assign  axi_req_o.r_ready    = s_axi_rready;

endmodule

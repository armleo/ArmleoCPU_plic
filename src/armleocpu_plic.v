module armleocpu_plic(
    clk, rst_n,
    AXI_AWADDR, AXI_AWVALID, AXI_AWREADY,
    AXI_WDATA, AXI_WSTRB, AXI_WVALID, AXI_WREADY,
    AXI_BRESP, AXI_BVALID, AXI_BREADY,
    AXI_ARADDR, AXI_ARVALID, AXI_ARREADY,
    AXI_RDATA, AXI_RRESP, AXI_RVALID, AXI_RREADY,
    irq_in, context_irq_pending
);

    parameter CONTEXT_COUNT = 4;
    parameter INTERRUPT_SOURCE_COUNT = 32;
    parameter PRIORITY_WIDTH = 32;
    localparam INTERRUPT_SOURCE_COUNT_CLOG2 = $clog2(INTERRUPT_SOURCE_COUNT);
    
    input clk;
    input rst_n;


    // address write bus
    input [15:0]                AXI_AWADDR;
    input                       AXI_AWVALID;
    output reg                  AXI_AWREADY;
    


    // Write bus
    input  [31:0]               AXI_WDATA;
    input   [3:0]               AXI_WSTRB;
    input                       AXI_WVALID;
    output reg                  AXI_WREADY;

    // Burst response bus
    output reg [1:0]            AXI_BRESP;
    reg [1:0]                   AXI_BRESP_nxt;
    output reg                  AXI_BVALID;
    input                       AXI_BREADY;


    // Address read bus
    input  [15:0]               AXI_ARADDR;
    input                       AXI_ARVALID;
    output reg                  AXI_ARREADY;

    // Read data bus
    output reg [31:0]           AXI_RDATA;
    output reg [1:0]            AXI_RRESP;
    reg [1:0]                   AXI_RRESP_nxt;
    output reg                  AXI_RVALID;
    input                       AXI_RREADY;

    input [INTERRUPT_SOURCE_COUNT-1:0]      irq_in;
    output reg [CONTEXT_COUNT-1:0]          context_irq_pending;



wire [31:0] address;
wire write, read;
wire [31:0] write_data;
wire [3:0] write_byteenable;
reg [31:0] read_data;
reg address_error;
reg write_error;

AXI4LiteConverter converter(
    .clk(clk),
    .rst_n(rst_n),

    .AXI_AWADDR(AXI_AWADDR),
    .AXI_AWVALID(AXI_AWVALID),
    .AXI_AWREADY(AXI_AWREADY),

    .AXI_WDATA(AXI_WDATA),
    .AXI_WSTRB(AXI_WSTRB),
    .AXI_WVALID(AXI_WVALID),
    .AXI_WREADY(AXI_WREADY),

    .AXI_BRESP(AXI_BRESP),
    .AXI_BVALID(AXI_BVALID),
    .AXI_BREADY(AXI_BREADY),

    .AXI_ARADDR(AXI_ARADDR),
    .AXI_ARVALID(AXI_ARVALID),
    .AXI_ARREADY(AXI_ARREADY),

    .AXI_RDATA(AXI_RDATA),
    .AXI_RRESP(AXI_RRESP),
    .AXI_RVALID(AXI_RVALID),
    .AXI_RREADY(AXI_RREADY),

    .address(address),
    .write(write),
    .read(read),
    .write_data(write_data),
    .write_byteenable(write_byteenable),
    .read_data(read_data),
    .address_error(address_error),
    .write_error(write_error)
);


reg [PRIORITY_WIDTH-1:0] irq_priority [INTERRUPT_SOURCE_COUNT-1:0];
reg [INTERRUPT_SOURCE_COUNT-1:0] irq_pending;
reg [INTERRUPT_SOURCE_COUNT-1:0] irq_enabled [CONTEXT_COUNT-1:0];
reg [PRIORITY_WIDTH-1:0] irq_threshold [CONTEXT_COUNT-1:0];
reg [INTERRUPT_SOURCE_COUNT_CLOG2:0] irq_context_claimed_id [CONTEXT_COUNT-1:0];

wire [PRIORITY_WIDTH-1:0] irq_calculated_priority [INTERRUPT_SOURCE_COUNT-1:0];


always @* begin
    for(i = 0; i < INTERRUPT_SOURCE_COUNT; i = i + 1)
        irq_calculated_priority[i] = irq_pending[i] ? irq_priority[i] : 0;
end





reg [PRIORITY_WIDTH-1:0]  priority_mux_output [INTERRUPT_SOURCE_COUNT-1:0] [CONTEXT_COUNT-1:0];
reg [INTERRUPT_SOURCE_COUNT_CLOG2-1:0] maximum_id_mux_output [INTERRUPT_SOURCE_COUNT-1:0] [CONTEXT_COUNT-1:0];

genvar context_num;
genvar interrupt_num;

generate : generate_matrix
    for(context_num = 0; context_num < CONTEXT_COUNT; context_num = context_num + 1) begin
        for(interrupt_num = 0; interrupt_num < INTERRUPT_SOURCE_COUNT; interrupt_num = interrupt_num + 1) begin
            matrix_cell #(
                PRIORITY_WIDTH, INTERRUPT_SOURCE_COUNT_CLOG2, interrupt_num
            ) cell (
                .calculated_priority(irq_calculated_priority[interrupt_num]),
                .enabled(irq_enabled[context_num][interrupt_num]),
                .previous_cell_priority_mux(
                    interrupt_num == 0 ? 0 : 
                    priority_mux_output[interrupt_num-1][context_num]),
                .previous_cell_maximum_id_mux(
                    interrupt_num == 0 ? 0 : 
                    maximum_id_mux_output[interrupt_num-1][context_num]),
                .priority_mux_output(priority_mux_output[interrupt_num][context_num]),
                .maximum_id_mux_output(maximum_id_mux_output[interrupt_num][context_num])
            );
        end
    end
endgenerate

genvar pending_num;
generate : irq_pending_generate
    for(pending_num = 0; pending_num < INTERRUPT_SOURCE_COUNT; pending_num = pending_num + 1)
        always @(posedge clk) begin
            if(!rst_n) begin
                irq_pending[i] <= 0;
            end else begin
                if(irq_in[i])
                    irq_pending[i] <= 1;
            end
        end
endgenerate


always @* begin : address_nxt_match_logic_always_comb
    address_match_any = 0;
    _sel = 0;
    if(address[15:6] == 0) begin
        _sel = ;
        address_match_any = ;
    end
end


always @(posedge clk) begin : main_always_ff
    if(!rst_n) begin
        
    end else begin
        
        if(write) begin
            if(_sel) begin
                // TODO: Write with strobes
            end
        end
    end
end


always @* begin : main_always_comb
    // TODO: Read data output
end



endmodule

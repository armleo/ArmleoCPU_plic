module armleocpu_plic(
    clk, rst_n,
    AXI_AWADDR, AXI_AWVALID, AXI_AWREADY,
    AXI_WDATA, AXI_WSTRB, AXI_WVALID, AXI_WREADY,
    AXI_BRESP, AXI_BVALID, AXI_BREADY,
    AXI_ARADDR, AXI_ARVALID, AXI_ARREADY,
    AXI_RDATA, AXI_RRESP, AXI_RVALID, AXI_RREADY,
    hart_swi, hart_timeri
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

reg [INTERRUPT_SOURCE_COUNT_CLOG2-1:0] maximum_id [CONTEXT_COUNT-1:0];
// TODO: Calculate maximum_id



reg [PRIORITY_WIDTH-1:0]  priority_mux_output [INTERRUPT_SOURCE_COUNT-1:0] [CONTEXT_COUNT-1:0];
reg [INTERRUPT_SOURCE_COUNT_CLOG2-1:0] maximum_id_mux_output [INTERRUPT_SOURCE_COUNT-1:0] [CONTEXT_COUNT-1:0];
// TODO: Calculate priority_mux_output, maximum_id_mux_output



always @* begin
    for(context_num = 0; context_num < CONTEXT_COUNT; context_num = context_num + 1) begin
        for(interrupt_num = 0; interrupt_num < INTERRUPT_SOURCE_COUNT; interrupt_num = interrupt_num + 1) begin
            if(interrupt_num == 0) begin
                mux_select[interrupt_num][context_num] = irq_enabled[context_num][interrupt_num] && (irq_calculated_priority[interrupt_num] > 0);
            end
            priority_mux_output[interrupt_num][context_num] = mux_select[interrupt_num][context_num] ? : ;
            maximum_id_mux_output[interrupt_num][context_num] = mux_select[interrupt_num][context_num] ? interrupt_num + 1 : interrupt_num == 0 ? 0 : maximum_id_mux_output[interrupt_num-1][context_num];
        end
    end
end

always @(posedge clk) begin
    if(!rst_n) begin
        irq_pending <= 0;
    end else begin
        if(irq_in)
            irq_pending <= 1;
        
    end
end



reg [2:0] state;
reg [2:0] state_nxt;  // COMB
localparam STATE_WAIT_ADDRESS = 3'd0,
    STATE_WRITE_DATA = 3'd1,
    STATE_OUTPUT_READDATA = 3'd2,
    STATE_SKIP_WRITE_DATA = 3'd3,
    STATE_WRITE_RESPOND = 3'd4;

reg [15:0] address;
reg [15:0] address_nxt; // COMB

 // COMB ->

always @* begin : address_nxt_match_logic_always_comb
    address_nxt_match_any = 0;
    
    if(address_nxt[15:6] == 0) begin
        _sel = ;
        address_nxt_match_any = address_hart_id < HART_COUNT;
    end
end


always @(posedge clk) begin : main_always_ff
    if(!rst_n) begin
        
        state <= STATE_WAIT_ADDRESS;
        AXI_RRESP <= 0;
        AXI_BRESP <= 0;
    end else begin
        mtime <= mtime + 1'b1;
        state <= state_nxt;
        address <= address_nxt;
        AXI_RRESP <= AXI_RRESP_nxt;
        AXI_BRESP <= AXI_BRESP_nxt;
        if(state == STATE_WRITE_DATA) begin
            if(msip_sel) begin
                /* verilator lint_off WIDTH */
                if(AXI_WSTRB[0])
                    hart_swi[address_hart_id] <= AXI_WDATA[0];
                /* verilator lint_on WIDTH */
            end else if(mtimecmp_low_sel) begin
                /* verilator lint_off WIDTH */
                if(AXI_WSTRB[0])
                    mtimecmp[address_hart_id][7:0] <= AXI_WDATA[7:0];
                if(AXI_WSTRB[1])
                    mtimecmp[address_hart_id][15:8] <= AXI_WDATA[15:8];
                if(AXI_WSTRB[2])
                    mtimecmp[address_hart_id][23:16] <= AXI_WDATA[23:16];
                if(AXI_WSTRB[3])
                    mtimecmp[address_hart_id][31:24] <= AXI_WDATA[31:24];
            end else if(mtimecmp_high_sel) begin
                if(AXI_WSTRB[0])
                    mtimecmp[address_hart_id][39:32] <= AXI_WDATA[7:0];
                if(AXI_WSTRB[1])
                    mtimecmp[address_hart_id][47:40] <= AXI_WDATA[15:8];
                if(AXI_WSTRB[2])
                    mtimecmp[address_hart_id][55:48] <= AXI_WDATA[23:16];
                if(AXI_WSTRB[3])
                    mtimecmp[address_hart_id][63:56] <= AXI_WDATA[31:24];
                /* verilator lint_on WIDTH */
            end
        end
    end
end


always @* begin : main_always_comb
    address_nxt = address;
    AXI_AWREADY = 0;
    AXI_ARREADY = 0;
    state_nxt = state;
    AXI_WREADY = 0;
    AXI_BVALID = 0;
    AXI_BRESP_nxt = AXI_BRESP;
    AXI_RRESP_nxt = AXI_RRESP;
    AXI_RVALID = 0;
    AXI_RDATA = 0;
    /* verilator lint_off WIDTH */
    if(msip_sel)
        AXI_RDATA = hart_swi[address_hart_id];
    else if(mtimecmp_high_sel)
        AXI_RDATA = mtimecmp[address_hart_id][63:32];
    else if(mtimecmp_low_sel)
        AXI_RDATA = mtimecmp[address_hart_id][31:0];
    else if(mtime_low_sel)
        AXI_RDATA = mtime[31:0];
    else if(mtime_high_sel)
        AXI_RDATA = mtime[63:32];
    /* verilator lint_on WIDTH */
    case(state)
        STATE_WAIT_ADDRESS: begin
            if(AXI_AWVALID) begin
                address_nxt = AXI_AWADDR; // address
                AXI_AWREADY = 1; // Address write request accepted

                if(AXI_AWADDR[1:0] == 2'b00 // Alligned only
                    && address_nxt_match_any
                    )
                begin
                    state_nxt = STATE_WRITE_DATA;
                    AXI_BRESP_nxt = 2'b00;
                end else begin
                    if(!address_nxt_match_any)
                        AXI_BRESP_nxt = 2'b11;
                    else
                        AXI_BRESP_nxt = 2'b10;
                    state_nxt = STATE_SKIP_WRITE_DATA;
                end
            end else if(AXI_ARVALID) begin
                address_nxt = AXI_ARADDR;
                state_nxt = STATE_OUTPUT_READDATA;
                if(AXI_ARADDR[1:0] == 2'b00
                    && address_nxt_match_any 
                ) begin
                    AXI_RRESP_nxt = 2'b00;
                    AXI_ARREADY = 1;
                end else begin
                    AXI_RRESP_nxt = 2'b10;
                    AXI_ARREADY = 1;
                end
            end
        end
        STATE_WRITE_DATA: begin
            if(AXI_WVALID) begin
                AXI_WREADY = 1;
                state_nxt = STATE_WRITE_RESPOND;
                
                if(mtime_low_sel || mtime_high_sel)
                    AXI_BRESP_nxt = 2'b10/*ADDRESS ERROR*/;
                else
                    AXI_BRESP_nxt = 2'b00/*OKAY*/;
            end
        end
        STATE_OUTPUT_READDATA: begin
            AXI_RVALID = 1;
            if(AXI_RREADY)
                state_nxt = STATE_WAIT_ADDRESS;
        end
        STATE_SKIP_WRITE_DATA: begin
            AXI_WREADY = 1;
            if(AXI_WVALID) begin
                state_nxt = STATE_WRITE_RESPOND;
                `ifdef DEBUG_CLINT
                    if(AXI_BRESP == 0) begin
                        $display("SKIP WRITE DATA with zero BRESP");
                        $finish;
                    end
                `endif
            end
        end
        STATE_WRITE_RESPOND: begin
            AXI_BVALID = 1;
            // BRESP is already set in previous stage
            if(AXI_BREADY) begin
                state_nxt = STATE_WAIT_ADDRESS;
            end
        end
        default: begin
            
        end
    endcase
end



endmodule

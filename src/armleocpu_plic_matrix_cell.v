module armleocpu_plic_matrix_cell(
calculated_priority, enabled,
previous_cell_priority_mux, previous_cell_maximum_id_mux
, priority_mux_output, maximum_id_mux_output);
parameter PRIORITY_WIDTH = 32;
parameter INTERRUPT_SOURCE_COUNT_CLOG2 = 4;
parameter IRQ_ID = 1;

input [PRIORITY_WIDTH-1:0]              calculated_priority;
input                                   enabled;
input [PRIORITY_WIDTH-1:0]              previous_cell_priority_mux;
input [INTERRUPT_SOURCE_COUNT_CLOG2:0]  previous_cell_maximum_id_mux;

output [PRIORITY_WIDTH-1:0]             priority_mux_output;
output [INTERRUPT_SOURCE_COUNT_CLOG2:0] maximum_id_mux_output;

wire select = enabled && (calculated_priority > previous_cell_priority_mux);

assign maximum_id_mux_output = select ? IRQ_ID : previous_cell_maximum_id_mux;
assign priority_mux_output = select ? calculated_priority : previous_cell_priority_mux;

endmodule
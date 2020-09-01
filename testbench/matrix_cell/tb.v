`timescale 1ns/1ns
module matix_cell_testbench;

`include "../sync_clk_gen_template.vh"

initial begin
	#1000
	`assert(1, 0);
	$finish;
end

reg [31:0] calculated_priority = 32;
reg enabled = 0;
reg [31:0] previous_cell_priority_mux = 31;
reg [4:0] previous_cell_maximum_id_mux = 9;
wire [31:0] priority_mux_output;
wire [4:0] maximum_id_mux_output;

armleocpu_plic_matrix_cell #(32, 4, 10) some_cell(
	.calculated_priority(calculated_priority),
	.enabled(enabled),
	.previous_cell_priority_mux(previous_cell_priority_mux),
	.previous_cell_maximum_id_mux(previous_cell_maximum_id_mux),
	.priority_mux_output(priority_mux_output),
	.maximum_id_mux_output(maximum_id_mux_output)
);

initial begin
	$display("Test 0");

	@(negedge clk)
	enabled = 0;
	previous_cell_priority_mux = 31;
	previous_cell_maximum_id_mux = 9;
	@(posedge clk)
	`assert(priority_mux_output, previous_cell_priority_mux);
	`assert(maximum_id_mux_output, previous_cell_maximum_id_mux);

	$display("Test 1");
	@(negedge clk)
	enabled = 1;
	previous_cell_priority_mux = 32;
	previous_cell_maximum_id_mux = 9;
	@(posedge clk)
	`assert(priority_mux_output, previous_cell_priority_mux);
	`assert(maximum_id_mux_output, previous_cell_maximum_id_mux);
	
	$display("Test 2");
	@(negedge clk)
	enabled = 1;
	previous_cell_priority_mux = 33;
	previous_cell_maximum_id_mux = 9;
	@(posedge clk)
	`assert(priority_mux_output, previous_cell_priority_mux);
	`assert(maximum_id_mux_output, previous_cell_maximum_id_mux);
	
	$display("Test 3");
	@(negedge clk)
	enabled = 1;
	previous_cell_priority_mux = 31;
	previous_cell_maximum_id_mux = 9;
	@(posedge clk)
	`assert(priority_mux_output, calculated_priority);
	`assert(maximum_id_mux_output, 10);
	

	// Enabled = 0;
	// Enabled = 1; calculated priority = 32; previous_cell_priority_mux = 32;
	// Enabled = 1; calculated priority = 32; previous_cell_priority_mux = 33;

	
	// Enabled = 1; calculated priority = 32; previous_cell_priority_mux = 31;
	
	
	@(negedge clk)
	
	$finish;
end
endmodule
`timescale 1ns/1ps

module tb_data_prod_proc;

reg clk = 0;
reg sensor_clk = 0;

always #5 clk = ~clk;
always #2.5 sensor_clk = ~sensor_clk;

reg [5:0] reset_cnt = 0;
wire resetn = &reset_cnt;
always @(posedge clk) begin
if (!resetn) reset_cnt <= reset_cnt + 1'b1;
end

reg [5:0] sensor_reset_cnt = 0;
wire sensor_resetn = &sensor_reset_cnt;
always @(posedge sensor_clk) begin
if (!sensor_resetn) sensor_reset_cnt <= sensor_reset_cnt + 1'b1;
end

wire [7:0] prod_pixel;
wire prod_valid;
wire prod_ready;

wire [7:0] fifo_pixel;
wire fifo_valid;
wire fifo_ready;

wire [7:0] pixel_out;
wire valid_out;

reg write_reg = 0;
reg read_reg = 0;
reg [7:0] address = 0;
reg [71:0] data_in = 0;
wire [71:0] data_out;

data_producer #(.IMAGE_SIZE(1024)) producer (
.sensor_clk(sensor_clk),
.rst_n(sensor_resetn),
.ready(prod_ready),
.pixel(prod_pixel),
.valid(prod_valid)
);

async_fifo fifo (
.wr_clk(sensor_clk),
.wr_rst_n(sensor_resetn),
.wr_data(prod_pixel),
.wr_valid(prod_valid),
.wr_ready(prod_ready),
.rd_clk(clk),
.rd_rst_n(resetn),
.rd_data(fifo_pixel),
.rd_valid(fifo_valid),
.rd_ready(fifo_ready)
);

data_proc processor (
.clk(clk),
.rstn(resetn),
.pixel_in(fifo_pixel),
.valid_in(fifo_valid),
.pixel_out(pixel_out),
.ready_in(fifo_ready),
.valid_out(valid_out),
.write_reg(write_reg),
.read_reg(read_reg),
.address(address),
.data_in(data_in),
.data_out(data_out)
);

integer proc_out_count = 0;
integer mode0_errors = 0;
integer mode1_errors = 0;

reg [1:0] current_mode = 0;

initial begin
    
#1000;
if (producer.image_mem[0] === 8'hxx) begin
    
$display("\n*** CRITICAL ERROR: image.hex not loaded! ***");
$display("*** Please create image.hex file in simulation directory ***\n");
$finish;
    
end 

else begin
    
$display("\n*** image.hex loaded successfully ***");
$display("First pixel value: %h", producer.image_mem[0]);
    
end
    
end

// Monitor Output (errors only)
always @(posedge clk) begin
    
if (resetn && valid_out) begin
    
proc_out_count = proc_out_count + 1;

if (current_mode == 2'b00 && fifo_valid) begin
    
if (pixel_out !== fifo_pixel) begin
    
$display("*** ERROR Mode 0: Expected=%h, Got=%h", fifo_pixel, pixel_out);
mode0_errors = mode0_errors + 1;
    
end
    
end

if (current_mode == 2'b01 && fifo_valid) begin
    
if (pixel_out !== ~fifo_pixel) begin
    
$display("*** ERROR Mode 1: Expected=%h, Got=%h", ~fifo_pixel, pixel_out);
mode1_errors = mode1_errors + 1;
    
end
    
end

end
    
end

initial begin

$display("================================================================================");
$display("          DATA PRODUCER-PROCESSOR TESTBENCH WITH ASYNC FIFO");
$display("================================================================================");
$display("Clock: sensor_clk=200MHz, clk=100MHz, FIFO depth=16");
$display("================================================================================\n");

wait(resetn);
wait(sensor_resetn);
repeat(20) @(posedge clk);

$display("\n*** Starting Tests ***\n");

$display("========================================");
$display("TEST 1: MODE 0 - BYPASS");
$display("========================================");

current_mode = 2'b00;
write_reg = 1; address = 8'h00; data_in = 72'd0;
@(posedge clk); write_reg = 0;

repeat(150) @(posedge clk);

$display("\n[Mode 0] Pixels=%0d, Errors=%0d\n", proc_out_count, mode0_errors);
proc_out_count = 0;

$display("========================================");
$display("TEST 2: MODE 1 - INVERT");
$display("========================================");

current_mode = 2'b01;
write_reg = 1; address = 8'h00; data_in = 72'd1;
@(posedge clk); write_reg = 0;

repeat(150) @(posedge clk);

$display("\n[Mode 1] Pixels=%0d, Errors=%0d\n", proc_out_count, mode1_errors);
proc_out_count = 0;

$display("========================================");
$display("TEST 3: MODE 2 - CONVOLUTION");
$display("========================================");

current_mode = 2'b10;

write_reg = 1; address = 8'h04;
data_in = {8'd1, 8'd0, 8'd255, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0, 8'd255};
@(posedge clk); write_reg = 0;

write_reg = 1; address = 8'h00; data_in = 72'd2;
@(posedge clk); write_reg = 0;

repeat(2000) @(posedge clk);

$display("\n[Mode 2] Pixels=%0d\n", proc_out_count);

$display("\n================================================================================");
$display("                           FINAL SUMMARY");
$display("================================================================================");
$display("Total processed:       %0d", proc_out_count);
$display("");
$display("Mode 0 errors:         %0d", mode0_errors);
$display("Mode 1 errors:         %0d", mode1_errors);

if (mode0_errors == 0 && mode1_errors == 0) begin
    
$display("\n*** ALL TESTS PASSED! ✓ ***");

end 

else begin

$display("\n*** TESTS FAILED! ✗ ***");

end

$display("================================================================================\n");

$finish;

end

initial begin
    
#50000;
$display("\n*** Timeout ***\n");
$finish;
    
end

endmodule

`timescale 1 ns / 1 ps

module dataproc_tb;
	reg clk;
	always #5 clk = (clk === 1'b0);  //100MHz

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	localparam ser_half_period = 53;
	event ser_sample;

	wire ser_rx;
	wire ser_tx;

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

	/* Write your tb logic for your dataprocessing module here */
	initial begin
		$dumpfile("dataproc_tb.vcd");
		$dumpvars(0, dataproc_tb);
		
		$dumpvars(1, uut.soc.cpu);
		$dumpvars(1, uut.soc.data_proc_accel);
		
		$display("  Data Processor Integration Test");
		
		repeat (20) begin
			repeat (100000) @(posedge clk);
			$display("Time: %0t ns", $time);
		end
		
		$finish;
	end
	/*----------------------------------------------------------*/


	rvsoc_wrapper #(
		.MEM_WORDS(256)
	) uut (
		.clk      (clk),
		.resetn   (resetn),
		.ser_rx   (ser_rx),
		.ser_tx   (ser_tx),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.flash_io2(flash_io2),
		.flash_io3(flash_io3)
	);

	spiflash spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(flash_io2),
		.io3(flash_io3)
	);

reg [7:0] buffer;
	integer char_count = 0;
	always begin
		@(negedge ser_tx);  
		repeat (ser_half_period) @(posedge clk);
		repeat (8) begin
			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			buffer = {ser_tx, buffer[7:1]};
		end
		repeat (ser_half_period) @(posedge clk);
		repeat (ser_half_period) @(posedge clk);
		$write("%c", buffer);
		$fflush();
		char_count = char_count + 1;
		if (buffer == "!") begin
			$display("\nDetected completion marker at char %0d", char_count);
		end
	end

	initial begin
		#200000000;  
		$display("\n ERROR: Simulation timeout!");
		$finish;
	end

always @(posedge clk) begin
	if (uut.soc.data_proc_accel.mem_valid && uut.soc.data_proc_accel.mem_ready) begin
		if (|uut.soc.data_proc_accel.mem_wstrb) begin
			$display("[%0t] Data Proc Write: addr=0x%08x data=0x%08x", 
				$time, 
				uut.soc.data_proc_accel.mem_addr,
				uut.soc.data_proc_accel.mem_wdata);
		end else begin
			$display("[%0t] Data Proc Read:  addr=0x%08x data=0x%08x", 
				$time,
				uut.soc.data_proc_accel.mem_addr,
				uut.soc.data_proc_accel.mem_rdata);
		end
	end
end
endmodule

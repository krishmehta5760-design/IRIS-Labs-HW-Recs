// Memory-mapped wrapper for data_proc accelerator
// Base address: 0x03000000
// Register Map:
// 0x03000000: Control/Status register [R] - bit[0]: ready_in, bit[1]: pixel_valid
// 0x03000004: Mode register [R/W] - 2 bits (00: bypass, 01: invert, 10: convolution)
// 0x03000008: Kernel coefficients 0-3 [R/W] - 4 bytes packed
// 0x0300000C: Kernel coefficients 4-8 [R/W] - 5 bytes (last byte overlaps)
// 0x03000010: Pixel input [W] - Write pixel to process
// 0x03000014: Pixel output [R] - Read processed pixel

module data_proc_wrapper (
    input clk,
    input resetn,
    
    // Memory-mapped interface (connects to iomem bus)
    input         mem_valid,
    output reg    mem_ready,
    input  [3:0]  mem_wstrb,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    output reg [31:0] mem_rdata
);

    // Address decoding
    wire is_control_reg = (mem_addr[7:0] == 8'h00);
    wire is_mode_reg    = (mem_addr[7:0] == 8'h04);
    wire is_kernel_0    = (mem_addr[7:0] == 8'h08);
    wire is_kernel_1    = (mem_addr[7:0] == 8'h0C);
    wire is_pixel_in    = (mem_addr[7:0] == 8'h10);
    wire is_pixel_out   = (mem_addr[7:0] == 8'h14);
    
    // Data processor signals
    wire [7:0] pixel_out;
    wire ready_in;
    wire valid_out;
    
    reg [7:0] pixel_in_reg;
    reg valid_in_reg;
    reg write_reg_sig;
    reg read_reg_sig;
    reg [7:0] address_reg;
    reg [71:0] data_in_reg;
    wire [71:0] data_out_sig;
    
    // Local storage for registers
    reg [1:0] mode_reg;
    reg [7:0] kernel_regs [0:8];
    reg [7:0] pixel_out_reg;
    reg pixel_valid_reg;
    
    integer i;
    
    // Instantiate data_proc
    data_proc dp_inst (
        .clk(clk),
        .rstn(resetn),
        .pixel_in(pixel_in_reg),
        .valid_in(valid_in_reg),
        .pixel_out(pixel_out),
        .ready_in(ready_in),
        .valid_out(valid_out),
        .write_reg(write_reg_sig),
        .read_reg(read_reg_sig),
        .address(address_reg),
        .data_in(data_in_reg),
        .data_out(data_out_sig)
    );
    
    // Memory-mapped interface logic
    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 0;
            mem_rdata <= 0;
            mode_reg <= 0;
            for (i = 0; i < 9; i = i + 1)
                kernel_regs[i] <= 0;
            pixel_in_reg <= 0;
            pixel_out_reg <= 0;
            pixel_valid_reg <= 0;
            write_reg_sig <= 0;
            read_reg_sig <= 0;
            valid_in_reg <= 0;
            address_reg <= 0;
            data_in_reg <= 0;
        end else begin
            // Default: deassert control signals
            mem_ready <= 0;
            write_reg_sig <= 0;
            read_reg_sig <= 0;
            valid_in_reg <= 0;
            
            // Handle memory-mapped access
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1;
                
                // WRITE operations
                if (|mem_wstrb) begin
                    if (is_mode_reg) begin
                        mode_reg <= mem_wdata[1:0];
                        // Write mode to data_proc
                        address_reg <= 8'h00;
                        data_in_reg <= {70'b0, mem_wdata[1:0]};
                        write_reg_sig <= 1;
                    end
                    else if (is_kernel_0) begin
                        // Store kernel coefficients 0-3
                        kernel_regs[0] <= mem_wdata[7:0];
                        kernel_regs[1] <= mem_wdata[15:8];
                        kernel_regs[2] <= mem_wdata[23:16];
                        kernel_regs[3] <= mem_wdata[31:24];
                    end
                    else if (is_kernel_1) begin
                        // Store kernel coefficients 4-8
                        kernel_regs[4] <= mem_wdata[7:0];
                        kernel_regs[5] <= mem_wdata[15:8];
                        kernel_regs[6] <= mem_wdata[23:16];
                        kernel_regs[7] <= mem_wdata[31:24];
                        
                        // Write all 9 kernel coefficients to data_proc
                        address_reg <= 8'h04;
                        data_in_reg <= {kernel_regs[8], kernel_regs[7], kernel_regs[6], 
                                       kernel_regs[5], kernel_regs[4], kernel_regs[3], 
                                       kernel_regs[2], kernel_regs[1], kernel_regs[0]};
                        write_reg_sig <= 1;
                    end
                    else if (is_pixel_in) begin
                        // Send pixel to data_proc for processing
                        pixel_in_reg <= mem_wdata[7:0];
                        valid_in_reg <= 1;
                    end
                end
                // READ operations
                else begin
                    if (is_control_reg) begin
                        // Return status: [1]: pixel_valid, [0]: ready_in
                        mem_rdata <= {30'b0, pixel_valid_reg, ready_in};
                    end
                    else if (is_mode_reg) begin
                        mem_rdata <= {30'b0, mode_reg};
                    end
                    else if (is_kernel_0) begin
                        mem_rdata <= {kernel_regs[3], kernel_regs[2], kernel_regs[1], kernel_regs[0]};
                    end
                    else if (is_kernel_1) begin
                        mem_rdata <= {kernel_regs[7], kernel_regs[6], kernel_regs[5], kernel_regs[4]};
                    end
                    else if (is_pixel_out) begin
                        mem_rdata <= {24'b0, pixel_out_reg};
                        pixel_valid_reg <= 0;  // Clear valid flag after read
                    end
                    else begin
                        mem_rdata <= 32'h0;
                    end
                end
            end
            
            // Capture output pixel when valid
            if (valid_out) begin
                pixel_out_reg <= pixel_out;
                pixel_valid_reg <= 1;
            end
        end
    end

endmodule

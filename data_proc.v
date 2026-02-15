module data_proc (

    input clk,
    input rstn,
    
    input [7:0] pixel_in,
    input valid_in,
    
    output reg [7:0] pixel_out,
    output reg ready_in,
    output reg valid_out,
    
    input write_reg,
    input read_reg,
    input [7:0] address,
    input [71:0] data_in,
    output reg [71:0] data_out
    //Fill the rest of the signals


);

reg [1:0] mode;
reg [7:0] kernel [0:8];
reg [31:0] pixel_count;
reg [7:0] status;

reg [7:0] buf_line_0 [0:31];
reg [7:0] buf_line_1 [0:31];
reg [7:0] buf_line_2 [0:31];

reg [4:0] col_no;
reg [4:0] row_no;

reg [7:0] prev_pixel_1;
reg [7:0] prev_pixel_2;

reg signed [15:0] sum;
reg [7:0] conv_pixel;

wire convolution;

wire [7:0] p00,p01,p02,p10,p11,p12,p20,p21,p22;

integer i;

always@(*)begin

case(mode)

2'b00 : pixel_out = pixel_in;
2'b01 : pixel_out = ~pixel_in;
2'b10 : pixel_out = conv_pixel;
default : pixel_out = 8'd0; 

endcase

end

always@(*)begin

case(mode)

2'b00 : ready_in = 1'b1;
2'b01 : ready_in = 1'b1;
2'b10 : ready_in = 1'b1;
default : ready_in = 1'b0; 

endcase 

end

always@(posedge clk,negedge rstn)begin

if(!rstn) valid_out = 1'b0;

else begin

case(mode)

2'b00 : valid_out <= 1'b1;
2'b01 : valid_out <= 1'b1;
2'b10 : begin

if(valid_in && convolution) valid_out <= 1'b1;

else valid_out <= 1'b0;

end

default : valid_out <= 1'b0; 

endcase

end

end

always@(posedge clk,negedge rstn)begin

if(!rstn)begin

mode <= 2'b00;
kernel[0] <= 8'd0;
kernel[1] <= 8'd0;
kernel[2] <= 8'd0;
kernel[3] <= 8'd0;
kernel[4] <= 8'd0;
kernel[5] <= 8'd0;
kernel[6] <= 8'd0;
kernel[7] <= 8'd0;
kernel[8] <= 8'd0;

end

else if(write_reg)begin

case(address)

8'h00 : mode <= data_in[1:0];
8'h04 : begin
        
        kernel[0] <= data_in[7:0];
        kernel[1] <= data_in[15:8];
        kernel[2] <= data_in[23:16];
        kernel[3] <= data_in[31:24];
        kernel[4] <= data_in[39:32];
        kernel[5] <= data_in[47:40];
        kernel[6] <= data_in[55:48];
        kernel[7] <= data_in[63:56];
        kernel[8] <= data_in[71:64];
        
        end

endcase

end

else if(read_reg)begin

case(address)

8'h00 : data_out <= {70'd0,mode};
8'h04 : begin
        
        data_out[7:0] <= kernel[0];
        data_out[15:8] <= kernel[1];
        data_out[23:16] <= kernel[2];
        data_out[31:24] <= kernel[3];
        data_out[39:32] <= kernel[4];
        data_out[47:40] <= kernel[5];
        data_out[55:48] <= kernel[6];   
        data_out[63:56] <= kernel[7];
        data_out[71:64] <= kernel[8];
        
        end
8'h10 : data_out <= {64'd0,status};
default: data_out <= 72'd0;

endcase

end

end

always@(posedge clk,negedge rstn)begin

if(!rstn) begin

{col_no,row_no,prev_pixel_1,prev_pixel_2} <= 26'd0;

for(i = 0; i < 32; i = i + 1)begin

buf_line_0[i] <= 8'd0;
buf_line_1[i] <= 8'd0;
buf_line_2[i] <= 8'd0;

end

end

else if(valid_in && ready_in && (mode == 2'b10))begin

buf_line_0[col_no] <= pixel_in;
prev_pixel_2 <= prev_pixel_1;
prev_pixel_1 <= pixel_in;

if(col_no == 31)begin

col_no <= 5'd0;
row_no <= row_no + 1;

for(i = 0; i < 32; i = i + 1)begin

buf_line_2[i] <= buf_line_1[i];
buf_line_1[i] <= buf_line_0[i];

end

prev_pixel_1 <= 8'd0;
prev_pixel_2 <= 8'd0;

end

else col_no <= col_no + 1;

end

end

assign convolution = (row_no >= 2);

assign p00 = ((col_no > 0) && (convolution)) ? buf_line_2[col_no - 1] : 8'd0 ;
assign p01 = (convolution) ? buf_line_2[col_no] : 8'd0 ;
assign p02 = ((col_no < 31) && (convolution)) ? buf_line_2[col_no + 1] : 8'd0 ;

assign p10 = ((col_no > 0) && (convolution)) ? buf_line_1[col_no - 1] : 8'd0 ;
assign p11 = (convolution) ? buf_line_1[col_no] : 8'd0 ;
assign p12 = ((col_no < 31) && (convolution)) ? buf_line_1[col_no + 1] : 8'd0 ;

assign p20 = ((col_no > 0) && (convolution)) ? prev_pixel_2 : 8'd0 ;
assign p21 = (convolution) ? prev_pixel_1 : 8'd0 ;
assign p22 = ((col_no < 31) && (convolution)) ? pixel_in : 8'd0 ;

always@(*)begin

if((mode == 2'b10) && (convolution))begin

sum = ($signed({1'b0, p00})*$signed(kernel[0]))+
      ($signed({1'b0, p01})*$signed(kernel[1]))+
      ($signed({1'b0, p02})*$signed(kernel[2]))+
      ($signed({1'b0, p10})*$signed(kernel[3]))+
      ($signed({1'b0, p11})*$signed(kernel[4]))+
      ($signed({1'b0, p12})*$signed(kernel[5]))+
      ($signed({1'b0, p20})*$signed(kernel[6]))+
      ($signed({1'b0, p21})*$signed(kernel[7]))+
      ($signed({1'b0, p22})*$signed(kernel[8]));

if(sum < 0) conv_pixel = 8'd0;

else if(sum > 255) conv_pixel = 8'd255;

else conv_pixel = sum[7:0];

end

else conv_pixel = 8'd0;

end

always@(posedge clk,negedge rstn)begin

if(!rstn) pixel_count <= 32'd0;

else if(valid_in && ready_in) pixel_count <= pixel_count + 1;

end

always@(*)begin

status = pixel_count[7:0];  

end

endmodule

/* --------------------------------------------------------------------------
Purpose of this module : This module should perform certain operations
based on the mode register and pixel values streamed out by data_prod module.

mode[1:0]:
00 - Bypass
01 - Invert the pixel 
10 - Convolution with a kernel of your choice (kernel is 3x3 2d array)
11 - Not implemented

Memory map of registers:

0x00 - Mode (2 bits)    [R/W]
0x04 - Kernel (9 * 8 = 72 bits)     [R/W]
0x10 - Status reg   [R]
----------------------------------------------------------------------------*/

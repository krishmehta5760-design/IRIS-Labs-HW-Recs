# IRIS Labs Hardware Recruitments - 2026

Thank you for showing your interest in joining IRIS Labs


## Submission Guidelines :

1. Fork this repository
2. Complete the design of all the modules with the provided boilerplate code with your own creativity
3. Verify all modules thoroughly as per the assignment requirements
4. Replace this README file in your fork with your own detailed README that includes:
    - Design approach and architectural decisions
    - Architectural diagrams (wherever required)
    - Simulation waveforms
    - Any assumptions or design trade-offs made
5. Do not use AI tools to generate your README file. The documentation should reflect your own understanding and explanation of the work.


All the best!
## PART - A : 

Already attached as IRIS_LABS_ASSIGN1_PARTA in the repository outside README.

## PART - B : 

The core design aim is to make an Image processing module whose source of pixels operates on a clock domain different from the clock domain of the processor which cause synchronization and CDC issues.

Architecturally to solve the CDC issue , I have used asynchronous fifo to connect the clock domains of two modules : 

data_prod (200MHz) -> asyn fifo -> data_proc (100MHz)

1) data_proc module :

It is the main Image processing module which is mode based : 
Mode 0 (Bypass) -> Buffer the incoming pixels out 
Mode 1 (Invert) -> Invert the incoming pixels  
Mode 2 (Convolution) -> Perform convolution with a predefined 3x3 kernel

I have used the concept of line buffers in making the convolution kernel. In that method each line buffer stores the incoming pixels like in my code , line buffer 2 stores the oldest of incoming pixels and then when it gets full line 1 gets full and then line 0 stores the youngest of incoming pixels. We need 9 of incoming pixels in a 3x3 grid which will be sign multiplied by the Vertical Edge detection Kernel (manually set in the testbench) 

Vertical Edge detection Kernel :  |-1   0   1 |
                                  | 0   0   0 |  
                                  |-1   0   1 |

2) asyn_fifo module : 

I have used the concept of asynchrounous fifo to eliminate CDC issues. I also used the concept of Binary to Gray COde conversion to reduce the skew and error when multi bits are passed.

So, wr_ptr_bin -> wr_ptr_gray -> 2 flop sync -> rd_ptr_gray_sync2
and, rd_ptr_bin -> rd_ptr_gray -> 2 flop sync -> wr_ptr_gray_sync2

I also used an extra bit to account for true full and true empty conditions.

3) tb_data_prod_proc module : 

I used the help of tools to make a comprehensive testbench which check the functioning of all modes if they are working or not.
For kernel I used the Vertical edge detection kernel.

Simulation Outputs :

(Attached in the repository outside README)

## PART - C : 

1) Memory Map Design : 
Allocated data processor to 0x0300_0000 with 64KB space.Moved GPIO to 0x04000000 to avoid conflicts.Register map has 6 registers: status , mode , two kernel coefficient registers , pixel input , and pixel output.

2) Bus Interface Wrapper : 
Created data_proc_wrapper to bridge SoC memory bus and data processor.Uses 16-bit upper address for peripheral select , lower 16 bits for register select.It implements valid/ready handshake matching PicoRV32 protocol.

3) SoC Integration : 
Added three wires in rvsoc: dataproc_valid, dataproc_ready, dataproc_rdata.OR'd ready signal into mem_ready arbiter.Prioritized data processor in read mux to prevent response conflicts.

4) Wrapper Module Changes : 
In rvsoc_wrapper , added address decode signals for data processor and GPIO.Changed GPIO address check from direct comparison to using gpio_sel signal for cleaner logic.

5) Firmware Design : 
Used volatile pointers for hardware registers to prevent compiler optimization.Implemented process_pixel() with polling and timeout protection.Test suite validates register access , bypass mode , invert mode , convolution , and streaming.





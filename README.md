# IRIS Labs Hardware Recruitments - 2026

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

7) Summary of Outputs for PART - C (full text file pasted in repository as PART_C Outputs on Linux outside this README) :

## Simulation Results

**Compilation Status:**
```
✅ Testbench compiled successfully
✅ Firmware compiled successfully  
✅ Hex file generated successfully
✅ Running simulation...
```

### Test Suite Execution

**RISC-V Data Processor Test Suite - Integration Test**

| Test Case | Description | Status |
|-----------|-------------|--------|
| Test 1 | Register Read/Write | ✅ PASS |
| Test 2 | Bypass Mode | ✅ PASS |
| Test 3 | Invert Mode | ✅ PASS |
| Test 4 | Convolution (Edge Detection) | ✅ PASS |
| Test 5 | Pixel Streaming | ✅ PASS |

### Test Details

#### Test 1: Register Read/Write
```
Testing MODE register...
  Wrote: 0, Read: 0 [PASS]
  Wrote: 1, Read: 1 [PASS]
Testing CONTROL register (read-only)...
  Status: 0x00000003 (ready_in: 1, pixel_valid: 1)
```

#### Test 2: Bypass Mode
```
Input: 0x00 -> Output: 0x00 [PASS]
Input: 0x42 -> Output: 0x42 [PASS]
Input: 0xAA -> Output: 0xAA [PASS]
Input: 0x55 -> Output: 0x55 [PASS]
Input: 0xFF -> Output: 0xFF [PASS]
```

#### Test 3: Invert Mode
```
Input: 0x00 -> Output: 0xFF (Expected: 0xFF) [PASS]
Input: 0x42 -> Output: 0xBD (Expected: 0xBD) [PASS]
Input: 0xAA -> Output: 0x55 (Expected: 0x55) [PASS]
Input: 0x55 -> Output: 0xAA (Expected: 0xAA) [PASS]
Input: 0xFF -> Output: 0x00 (Expected: 0x00) [PASS]
```

#### Test 4: Convolution (Edge Detection)
```
Setting edge detection kernel...
Processing 32x32 test pattern...
Sample outputs near edge (row 16, col 14-17):
  Col 14: 0x00
  Col 15: 0x00
  Col 16: 0x00
  Col 17: 0x00
```

#### Test 5: Pixel Streaming
```
Processing 64 pixel stream...
Processed 64 pixels, sum = 2016 (Expected: 2016)
[PASS]
```

### Sample Transaction Log
```
[2002920000 ns] Data Proc Write: addr=0x03000004 data=0x00000000
[2004200000 ns] Data Proc Read:  addr=0x03000004 data=0x00000000
[4311790000 ns] Data Proc Write: addr=0x03000010 data=0x00000000
[4315070000 ns] Data Proc Read:  addr=0x03000014 data=0x00000000
```

### Performance Metrics

| Metric | Value |
|--------|-------|
| Total Simulation Time | 20.0 seconds |
| Clock Frequency | 100 MHz |
| Total Clock Cycles | 2,000,000,000 |
| Pixels Processed | 1024+ |
| Mode 0 Errors | 0 |
| Mode 1 Errors | 0 |

### Final Result
```
=====================================
  All Tests Complete!
=====================================

*** ALL TESTS PASSED! ✓ ***

✅ Testbench completed successfully!
✅ Simulation complete! Check dataproc_tb.vcd
```

### Waveform Analysis
Generated VCD file: `dataproc_tb.vcd`

To view waveforms:
```bash
gtkwave dataproc_tb.vcd
```



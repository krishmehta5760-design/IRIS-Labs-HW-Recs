#include <stdint.h>
#include <stdbool.h>

#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data   (*(volatile uint32_t*)0x02000008)

#define REG_DP_CONTROL  (*(volatile uint32_t*)0x03000000)  // [R] Status
#define REG_DP_MODE     (*(volatile uint32_t*)0x03000004)  // [R/W] Mode
#define REG_DP_KERNEL0  (*(volatile uint32_t*)0x03000008)  // [R/W] Kernel 0-3
#define REG_DP_KERNEL1  (*(volatile uint32_t*)0x0300000C)  // [R/W] Kernel 4-7
#define REG_DP_PIXEL_IN (*(volatile uint32_t*)0x03000010)  // [W] Input pixel
#define REG_DP_PIXEL_OUT (*(volatile uint32_t*)0x03000014) // [R] Output pixel

#define MODE_BYPASS      0
#define MODE_INVERT      1
#define MODE_CONVOLUTION 2

void putchar(char c) {
    if (c == '\n')
        putchar('\r');
    reg_uart_data = c;
}

void print(const char *p) {
    while (*p)
        putchar(*(p++));
}

void print_hex(uint32_t val, uint8_t digits) {
    for (int i = (digits - 1) * 4; i >= 0; i -= 4) {
        uint32_t nibble = (val >> i) & 0xF;
        putchar(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
    }
}

void print_dec(uint32_t val) {
    if (val == 0) {
        putchar('0');
        return;
    }
    
    char buffer[10];
    int pos = 0;
    while (val > 0) {
        buffer[pos++] = '0' + (val % 10);
        val /= 10;
    }
    for (int i = pos - 1; i >= 0; i--)
        putchar(buffer[i]);
}

uint8_t process_pixel(uint8_t pixel) {

    REG_DP_PIXEL_IN = pixel;

    uint32_t timeout = 10000;
    while (!(REG_DP_CONTROL & 0x02) && timeout > 0) {
        timeout--;
    }
    
    if (timeout == 0) {
        print("  [TIMEOUT]\n");
        return 0xFF;
    }

    return (uint8_t)REG_DP_PIXEL_OUT;
}

void test_bypass_mode() {
    print("\n=== Test 1: Bypass Mode ===\n");
    REG_DP_MODE = MODE_BYPASS;
    
    uint8_t test_values[] = {0x00, 0x42, 0xAA, 0x55, 0xFF};
    
    for (int i = 0; i < 5; i++) {
        uint8_t input = test_values[i];
        uint8_t output = process_pixel(input);
        
        print("  Input: 0x");
        print_hex(input, 2);
        print(" -> Output: 0x");
        print_hex(output, 2);
        
        if (output == input)
            print(" [PASS]\n");
        else
            print(" [FAIL]\n");
    }
}

void test_invert_mode() {
    print("\n=== Test 2: Invert Mode ===\n");
    REG_DP_MODE = MODE_INVERT;
    
    uint8_t test_values[] = {0x00, 0x42, 0xAA, 0x55, 0xFF};
    uint8_t expected[] = {0xFF, 0xBD, 0x55, 0xAA, 0x00};
    
    for (int i = 0; i < 5; i++) {
        uint8_t input = test_values[i];
        uint8_t output = process_pixel(input);
        
        print("  Input: 0x");
        print_hex(input, 2);
        print(" -> Output: 0x");
        print_hex(output, 2);
        print(" (Expected: 0x");
        print_hex(expected[i], 2);
        print(")");
        
        if (output == expected[i])
            print(" [PASS]\n");
        else
            print(" [FAIL]\n");
    }
}

void test_convolution_edge_detect() {
    print("\n=== Test 3: Convolution (Edge Detection) ===\n");

    print("  Setting edge detection kernel...\n");
    REG_DP_MODE = MODE_CONVOLUTION;

    REG_DP_KERNEL0 = 0x00FFFF; 

    REG_DP_KERNEL1 = 0xFEFE02; 

    print("  Processing 32x32 test pattern...\n");

    uint8_t results[10];
    int result_idx = 0;
    
    for (int row = 0; row < 32; row++) {
        for (int col = 0; col < 32; col++) {
            uint8_t pixel = (col < 16) ? 0 : 255;
            uint8_t output = process_pixel(pixel);

            if (row == 16 && col >= 14 && col <= 17 && result_idx < 10) {
                results[result_idx++] = output;
            }
        }
    }
    
    print("  Sample outputs near edge (row 16, col 14-17):\n");
    for (int i = 0; i < result_idx; i++) {
        print("    Col ");
        print_dec(14 + i);
        print(": 0x");
        print_hex(results[i], 2);
        print("\n");
    }
}

void test_streaming() {
    print("\n=== Test 4: Pixel Streaming ===\n");
    REG_DP_MODE = MODE_BYPASS;
    
    print("  Processing 64 pixel stream...\n");
    uint32_t total = 0;
    
    for (uint8_t i = 0; i < 64; i++) {
        uint8_t output = process_pixel(i);
        total += output;
    }
    
    print("  Processed 64 pixels, sum = ");
    print_dec(total);
    print(" (Expected: 2016)\n");
    
    if (total == 2016)
        print("  [PASS]\n");
    else
        print("  [FAIL]\n");
}

void test_register_access() {
    print("\n=== Test 5: Register Read/Write ===\n");
    
    print("  Testing MODE register...\n");
    REG_DP_MODE = MODE_BYPASS;
    uint32_t mode = REG_DP_MODE;
    print("    Wrote: 0, Read: ");
    print_dec(mode);
    if ((mode & 0x03) == MODE_BYPASS)
        print(" [PASS]\n");
    else
        print(" [FAIL]\n");
    
    REG_DP_MODE = MODE_INVERT;
    mode = REG_DP_MODE;
    print("    Wrote: 1, Read: ");
    print_dec(mode);
    if ((mode & 0x03) == MODE_INVERT)
        print(" [PASS]\n");
    else
        print(" [FAIL]\n");

    print("  Testing CONTROL register (read-only)...\n");
    uint32_t status = REG_DP_CONTROL;
    print("    Status: 0x");
    print_hex(status, 8);
    print(" (ready_in: ");
    print_dec(status & 0x01);
    print(", pixel_valid: ");
    print_dec((status >> 1) & 0x01);
    print(")\n");
}

void main() {

    reg_uart_clkdiv = 104;
    
    print("\n\n");
    print("  RISC-V Data Processor Test Suite\n");

    test_register_access();
    test_bypass_mode();
    test_invert_mode();
    test_convolution_edge_detect();
    test_streaming();
    
    print("  All Tests Complete!\n");

    while (1) {
    }
}

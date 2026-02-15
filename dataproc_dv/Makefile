# Complete this make file such that when invoked "make all" it should run the simulation and dump the vcd file.
# Also implement "make clean" to remove the build files.
# ✅ Makefile for data_proc integration testbench
# RISC-V Cross-compiler setup
CROSS = riscv32-unknown-elf-
CFLAGS = -march=rv32ic -mabi=ilp32 -O2
LDFLAGS = -Wl,-Bstatic,-T,sections.ld,--strip-debug -ffreestanding -nostdlib

# RTL source files
RTL_SRC = data_proc.v \
          data_proc_wrapper.v \
          rvsoc.v \
          dataproc_tb.v

# Required RTL modules (assume they exist in current or ../rtl directory)
# If they're in ../rtl, adjust the path accordingly
# For this setup, we'll assume they're in the same directory or you'll provide them

.PHONY: all sim clean help

all: sim

# Main simulation target
sim: dataproc_tb.vvp dataproc_firmware.hex
	@echo "✅ Running simulation..."
	vvp -N $< +firmware=dataproc_firmware.hex
	@echo "✅ Simulation complete! Check dataproc_tb.vcd"

# Compile testbench with Icarus Verilog
dataproc_tb.vvp: $(RTL_SRC)
	@echo "✅ Compiling testbench..."
	iverilog -g2012 -s dataproc_tb -o $@ \
		data_proc.v \
		data_proc_wrapper.v \
		rvsoc.v \
		dataproc_tb.v \
		rvsoc_wrapper.v \
		picorv32.v \
		simpleuart.v \
		spimemio.v \
		spiflash.v
	@echo "✅ Testbench compiled successfully"

# Link firmware ELF
dataproc_firmware.elf: sections.ld start.s firmware.c
	@echo "✅ Compiling firmware..."
	$(CROSS)gcc $(CFLAGS) $(LDFLAGS) -o $@ start.s firmware.c
	@echo "✅ Firmware compiled successfully"

# Generate HEX file for simulation
dataproc_firmware.hex: dataproc_firmware.elf
	@echo "✅ Generating hex file..."
	$(CROSS)objcopy -O verilog $< $@
	@echo "✅ Hex file generated successfully"

# Generate binary (optional, for hardware)
dataproc_firmware.bin: dataproc_firmware.elf
	@echo "✅ Generating binary file..."
	$(CROSS)objcopy -O binary $< $@
	@echo "✅ Binary file generated successfully"

# Disassembly for debugging
dataproc_firmware.dis: dataproc_firmware.elf
	@echo "✅ Generating disassembly..."
	$(CROSS)objdump -D $< > $@
	@echo "✅ Disassembly saved to $@"

# View waveform (requires GTKWave)
wave: dataproc_tb.vcd
	@echo "✅ Opening waveform viewer..."
	gtkwave $< &

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build files..."
	rm -f dataproc_tb.vvp dataproc_tb.vcd
	rm -f dataproc_firmware.elf dataproc_firmware.hex dataproc_firmware.bin
	rm -f dataproc_firmware.dis
	rm -f *.o
	@echo "✅ Clean complete!"

# Show help
help:
	@echo "Available targets:"
	@echo "  make all    - Build and run simulation (default)"
	@echo "  make sim    - Run simulation"
	@echo "  make clean  - Remove build files"
	@echo "  make wave   - View waveform with GTKWave"
	@echo "  make help   - Show this help message"

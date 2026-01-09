# Makefile for Arty A7-35T Blinky Project
# Tools
SBT ?= sbt
YOSYS ?= yosys
NEXTPNR ?= nextpnr-xilinx
FASM2FRAMES ?= fasm2frames
PACK ?= xc7frames2bit

# Project configuration
PROJECT = Blinky
BUILD_DIR = generated
TOP_MODULE = Blinky
VERILOG_FILE = $(BUILD_DIR)/$(TOP_MODULE).v
XDC_FILE = constraints/$(PROJECT).xdc
BITSTREAM = $(BUILD_DIR)/$(PROJECT).bit

# Part configuration
DEVICE = xc7a35t
PART = xc7a35tcsg324-1
# Default path, might be overridden in CI
CHIPDB_DIR ?= /usr/share/nextpnr/xilinx-chipdb

.PHONY: all clean verilog synth pnr bitstream

all: bitstream

# 1. Generate Verilog from Chisel
verilog: $(VERILOG_FILE)
$(VERILOG_FILE): src/main/scala/*.scala
	$(SBT) "runMain blinky.BlinkyMain"

# 2. Synthesis (Yosys)
synth: $(BUILD_DIR)/$(PROJECT).json
$(BUILD_DIR)/$(PROJECT).json: $(VERILOG_FILE)
	$(YOSYS) -p "synth_xilinx -flatten -abc9 -top $(TOP_MODULE); write_json $@" $<

# 3. Place and Route (Nextpnr)
# Note: --chipdb argument is essential if not in default location
pnr: $(BUILD_DIR)/$(PROJECT).fasm
$(BUILD_DIR)/$(PROJECT).fasm: $(BUILD_DIR)/$(PROJECT).json $(XDC_FILE)
	$(NEXTPNR) --chipdb $(CHIPDB_DIR)/$(DEVICE).bin --json $< --xdc $(XDC_FILE) --write $(BUILD_DIR)/$(PROJECT)_routed.json --fasm $@

# 4. Bitstream Generation (fasm2frames -> xc7frames2bit)
# Convert FASM to Frames
$(BUILD_DIR)/$(PROJECT).frames: $(BUILD_DIR)/$(PROJECT).fasm
	$(FASM2FRAMES) --part $(PART) --db-root $(XRAY_DATABASE_DIR)/artix7 $< > $@

# Generate Bitstream from Frames
bitstream: $(BITSTREAM)
$(BITSTREAM): $(BUILD_DIR)/$(PROJECT).frames
	$(PACK) --part_name $(PART) --part_file $(XRAY_DATABASE_DIR)/artix7/$(PART)/part.yaml --frames_file $< --bit_file $@

clean:
	rm -rf $(BUILD_DIR) test_run_dir

SIM = ghdl
TOPLEVEL_LANG = vhdl
TOPLEVEL = toplevel_wrapper
COCOTB_TEST_MODULES = tb_toplevel_wrapper

# Use absolute paths and compile in current dir
VHDL_SOURCES = $(shell pwd)/seven_seg_decoder.vhd $(shell pwd)/toplevel_wrapper.vhd

COMPILE_ARGS = --std=08
SIM_BUILD = .

export COCOTB_REDUCED_LOG_FMT = 1

include $(shell cocotb-config --makefiles)/Makefile.sim

seven_seg_decoder.vhd: ../vhdl/seven_seg_decoder.vhd
	cp $< $@

toplevel_wrapper.vhd: ../vhdl/toplevel_wrapper.vhd
	cp $< $@

clean::
	rm -rf *.o *.cf work-obj*.cf e~*.o results.xml __pycache__
	rm -f seven_seg_decoder.vhd toplevel_wrapper.vhd

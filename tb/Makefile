FILES := \
		../seven_segment_pkg.vhd	\
		../adc_fsm1.vhd	\
		../adc_fsm50.vhd	\
		../binarytogray.vhd	\
		../graytobinary.vhd	\
		../sync_flop.vhd	\
		../syncronizer.vhd \
		../dp_ram.vhd	\
		max10_adc.vhd	\
		pll.vhd	\
		../ADS_Project3_TopLevel.vhd	\
		tb_toplevel.vhd

all: $(FILES)
	for f in $(FILES); do \
		ghdl analyze $$f; \
	done

	ghdl elaborate tb_toplevel

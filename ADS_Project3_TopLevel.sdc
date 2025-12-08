#main 50 MHz clock
create_clock -period 20.0 [ get_ports P11 ]
create_clock -period 20.0 -name main_clock_virt

#ADC 10 MHz clock
create_clock -period 100.0 [ get_ports N5 ]
create_clock -period 100.0 -name adc_clock_virt

#ADC derived clock
create_generated_clock -name clk_div -source [ get_pins ??? ]
	-divide_by ???? -mulitply_by ??? [ get_pins ???]

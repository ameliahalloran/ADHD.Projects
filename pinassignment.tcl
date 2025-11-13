set color_pins {
		red { AA1 V1 Y2 Y1 }
		green { W1 T2 R2 R1 }
		blue { P1 T1 P4 N2 }
	}
	
foreach { color pin_list } ${color_pins} {
	for { set i 0 } { ${i} < 4 } { incr i } {
		set pin [ lindex ${pin_list} ${i} ]
		set_location_assignment PIN_${pin} -to color_out.${color}\[${i}\]
		set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to \
				color_out.${color}\[${i}\]
	}
}

set extra_pins {
		clk_50mhz	P11	"3.3-V LVTTL"
		reset_n		B8		"3.3 V SCHMITT TRIGGER"
		vga_vs		N1		"3.3-V LVTTL"
		vga_hs		N3		"3.3-V LVTTL"
	}

foreach { signal pin iostd } ${extra_pins} {
	set_location_assignment PIN_${pin} -to ${signal}
	set_instance_assignment -name IO_STANDARD ${iostd} -to ${signal}
}

set switch_pins { C10 C11 D12 C12 A12 B12 A13 A14 B14 F15}

for { set i 0 } { ${i} < 10 } { incr i } {
	set pin [ lindex ${switch_pins} ${i} ]
	set_location_assignment PIN_${pin} -to sw\[${i}\]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sw\[${i}\]
}

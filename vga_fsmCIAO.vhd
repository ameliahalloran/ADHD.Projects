library ieee;
use ieee.std_logic_1164.all;

library vga;
use vga.vga_data.all;

entity vga_fsm is
	generic (
		vga_res:	vga_timing := vga_res_default
	);
	port (
		vga_clock:		in	std_logic;
		reset:			in	std_logic;

		point:			out	coordinate;
		point_valid:	out	boolean;

		h_sync:			out	std_logic;
		v_sync:			out std_logic
	);
end entity vga_fsm;

architecture fsm of vga_fsm is
	-- internal signal for current position
	signal current_point: coordinate := make_coordinate(0,0);
begin
	-- implement methodology to drive outputs here
	-- use vga_data functions and types to make your life easier
	-- main process will advance through all pixel positions
	process(vga_clock, reset)
    begin
        if reset = '0' then  -- active-low reset
            current_point <= make_coordinate(0, 0);
        elsif rising_edge(vga_clock) then
            -- move to next coordinate every clock cycle
            current_point <= next_coordinate(current_point, vga_res);
        end if;
    end process;

    -- output current point
    point <= current_point;
    
    -- check if current point is in visible area
    point_valid <= point_visible(current_point, vga_res);
    
    -- horizontal sync signal
    h_sync <= do_horizontal_sync(current_point, vga_res);
    
    -- vertical sync signal
    v_sync <= do_vertical_sync(current_point, vga_res);


end architecture fsm;

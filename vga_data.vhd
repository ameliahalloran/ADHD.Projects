library ieee;
use ieee.std_logic_1164.all;

package vga_data is

	type timing_data is record
		active:			natural;
		front_porch:	natural;
		sync_width:		natural;
		back_porch:		natural;
	end record timing_data;

	type polarity is ( active_low, active_high );

	type vga_timing is record
		horizontal:		timing_data;
		vertical:		timing_data;
		sync_polarity:	polarity;
	end record vga_timing;

	type coordinate is record
		x:	natural;
		y:	natural;
	end record coordinate;

	type vga_data_rom_type is array (natural range<>) of vga_timing;

	-- fill in the missing values based on your research for homework 2
	constant vga_res_data:	vga_data_rom_type := (
			(
				-- 1920x1080 @ 60 Hz
				-- clock 148.5 MHz
				horizontal => (
						active => ,				-- active area in pixels
						front_porch => ,		-- in pixels
						sync_width => ,			-- in pixels
						back_porch => 			-- in pixels
					),
				vertical => (
						active => ,				-- active area in lines
						front_porch => ,		-- in lines
						sync_width => ,			-- in lines
						back_porch => 			-- in lines
					),
				sync_polarity => active_high
			), (
				-- 640x480 @ 60 Hz
				-- clock 25.175 MHz
				horizontal => (
						active => ,
						front_porch => ,
						sync_width => ,
						back_porch => 
					),
				vertical => (
						active => ,
						front_porch => ,
						sync_width => ,
						back_porch => 
					),
				sync_polarity => 
			), (
				-- add data here
				-- 800x600 @ 60Hz
				-- clock 40 MHz
			)
		);

	constant vga_res_1920x1080:	vga_timing := vga_res_data(0);
	constant vga_res_640x480:	vga_timing := vga_res_data(1);
	constant vga_res_800x600:	vga_timing := ;	-- TODO: initialize
	constant vga_res_default:	vga_timing := ;	-- TODO: initialize to your
												-- target resolution

	---- TODO: some functions need to be implemented
	-- return true if the x coordinate is on the visible area
	function x_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean;

	-- return true if the y coordinate (line) is on the visible area
	function y_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean;

	-- return true if the point is on the visible area
	function point_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean;

	-- make a coordinate and return it
	function make_coordinate (
			x, y:		in	natural
		) return coordinate;

	-- compute the next coordinate by incrementing the current coordinate
	-- and return the new coordinate
	function next_coordinate (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return coordinate;

	-- generate a horizontal sync pulse if we are in the hsync period
	function do_horizontal_sync (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return std_logic;

	-- generate a vertical sync pulse if we are in the vsync period
	function do_vertical_sync (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return std_logic;

end package vga_data;

package body vga_data is

	type timing_select is (horizontal, vertical);

	function timing_range (
			vga_res:	in	vga_timing;
			timing:		in	timing_select
		) return natural is
			variable ret_data: timing_data;
	begin
		if timing = horizontal then
			ret_data := vga_res.horizontal;
		else
			ret_data := vga_res.vertical;
		end if;

		return ret_data.active + ret_data.front_porch
				+ ret_data.sync_width + ret_data.back_porch;
	end function timing_range;

	function do_sync (
			point:		in	coordinate;
			vga_res:	in	vga_timing;
			timing:		in	timing_select
		) return std_logic is
			variable sync_data: timing_data;
			variable coord:		natural;
			variable ret:		std_logic;
	begin
		if timing = horizontal then
			sync_data := vga_res.horizontal;
			coord := point.x;
		else
			sync_data := vga_res.vertical;
			coord := point.y;
		end if;

		if coord >= (sync_data.active + sync_data.front_porch) and
				coord < (sync_data.active + sync_data.front_porch +
							sync_data.sync_width) then
			if vga_res.sync_polarity = active_high then
				ret := '1';
			else
				ret := '0';
			end if;
		else
			if vga_res.sync_polarity = active_high then
				ret := '0';
			else
				ret := '1';
			end if;
		end if;

		return ret;

	end function do_sync;

	function x_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean is
	begin
		return point.x < vga_res.horizontal.active;
	end function x_visible;

	function y_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean is
	begin
		-- TODO: implement
	end function y_visible;

	function point_visible (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return boolean is
	begin
		-- TODO: implement
	end function point_visible;

	function make_coordinate (
			x, y:		in natural
		) return coordinate is
			variable ret: coordinate;
	begin
		ret.x := x;
		ret.y := y;
		return ret;
	end function make_coordinate;

	function next_coordinate (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return coordinate is
			variable ret: coordinate;
	begin
		ret.x := point.x + 1;
		ret.y := point.y;

		-- TODO: add logic to increment y and reset y if needed

		if ret.x = timing_range(vga_res, horizontal) then
			ret.x := 0;
		end if;


		return ret;
	end function next_coordinate;

	function do_horizontal_sync (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return std_logic is
	begin
		return do_sync(point, vga_res, horizontal);
	end function do_horizontal_sync;

	function do_vertical_sync (
			point:		in	coordinate;
			vga_res:	in	vga_timing := vga_res_default
		) return std_logic is
	begin
		-- TODO: implement
	end function do_vertical_sync;

end package body vga_data;

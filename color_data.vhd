package color_data is

	subtype color_channel_type is natural range 0 to 15;

	type rgb_color is
	record
		red:	color_channel_type;
		green:	color_channel_type;
		blue:	color_channel_type;
	end record rgb_color;

	-- NOTE: on your toplevel you can define an output as
	-- 
	-- color: out rgb_color;
	--
	-- then on pin placement:
	--
	-- set_location_assignment PIN_XXXX -to color.red[0]
	-- set_location_assignment PIN_YYYY -to color.red[1]
	--
	-- and so on (use loops to simplify the work!)

	constant color_black: rgb_color :=
		( red =>  0, green =>  0, blue =>  0 );
	constant color_red: rgb_color :=
		( red => 15, green =>  0, blue =>  0 );
	constant color_green: rgb_color :=
		( red =>  0, green => 15, blue =>  0 );
	constant color_blue: rgb_color :=
		( red =>  0, green =>  0, blue => 15 );

	type color_table_type is array(natural range<>) of rbg_color;
	constant color_table_1: color_table_type := (
			0  => ( red =>  0, green =>  0, blue => 15 ),
			1  => ( red =>  1, green =>  1, blue => 14 ),
			2  => ( red =>  2, green =>  2, blue => 13 ),
			3  => ( red =>  3, green =>  3, blue => 12 ),
			4  => ( red =>  4, green =>  4, blue => 11 ),
			5  => ( red =>  5, green =>  5, blue => 10 ),
			6  => ( red =>  6, green =>  6, blue =>  9 ),
			7  => ( red =>  7, green =>  7, blue =>  8 ),
			8  => ( red =>  8, green =>  8, blue =>  7 ),
			9  => ( red =>  9, green =>  9, blue =>  6 ),
			10 => ( red => 10, green => 10, blue =>  5 ),
			11 => ( red => 11, green => 11, blue =>  4 ),
			12 => ( red => 12, green => 12, blue =>  3 ),
			13 => ( red => 13, green => 13, blue =>  2 ),
			14 => ( red => 14, green => 14, blue =>  1 ),
			15 => ( red => 15, green => 15, blue =>  0 )
		);

	constant color_table_2: color_table_type := (
			0  => ( red =>  0,  green =>  0,  blue => 15 ), 
			1  => ( red =>  0,  green =>  8,  blue => 15 ), 
			2  => ( red =>  0,  green => 15, blue => 15 ), 
			3  => ( red =>  0,  green => 15, blue =>  8 ),
			4  => ( red =>  0,  green => 15, blue =>  0 ), 
			5  => ( red =>  8,  green => 15, blue =>  0 ), 
			6  => ( red => 15, green => 15, blue =>  0 ), 
			7  => ( red => 15, green =>  8,  blue =>  0 ), 
			8  => ( red => 15, green =>  0,  blue =>  0 ), 
			9  => ( red => 15, green =>  0,  blue =>  8 ), 
			10 => ( red => 15, green =>  0,  blue => 15 ), 
			11 => ( red =>  8,  green =>  0,  blue => 15 ), 
			12 => ( red =>  4,  green =>  0,  blue => 15 ), 
			13 => ( red =>  0,  green =>  0,  blue => 15 ), 
			14 => ( red =>  0,  green =>  0,  blue =>  8 ), 
			15 => ( red =>  0,  green =>  0,  blue =>  4 )  
		);

	type color_palette_type is array(natural range<>) of color_table_type;
	constant color_palette_table: color_palette_type := (
			0 => color_table_1,
			1 => color_table_2,
			2 => (
				0  => ( red => 15, green =>  0, blue =>  0 ),
				1  => ( red => 14, green =>  1, blue =>  0 ),
				2  => ( red => 13, green =>  2, blue =>  0 ),
				3  => ( red => 12, green =>  3, blue =>  0 ),
				4  => ( red => 11, green =>  4, blue =>  0 ),
				5  => ( red => 10, green =>  5, blue =>  0 ),
				6  => ( red =>  9, green =>  6, blue =>  0 ),
				7  => ( red =>  8, green =>  7, blue =>  0 ),
				8  => ( red =>  7, green =>  8, blue =>  0 ),
				9  => ( red =>  6, green =>  9, blue =>  0 ),
				10 => ( red =>  5, green => 10, blue =>  0 ),
				11 => ( red =>  4, green => 11, blue =>  0 ),
				12 => ( red =>  3, green => 12, blue =>  0 ),
				13 => ( red =>  2, green => 13, blue =>  0 ),
				14 => ( red =>  1, green => 14, blue =>  0 ),
				15 => ( red =>  0, green => 15, blue =>  0 )
			)
		);

	subtype color_index_type is natural range color_table'range;
	subtype palette_index_type is natural range color_palette_table'range;

	function get_color (
			color_index: in color_index_type;
			color_palette: in color_palette_type
		) return rgb_color;

	function get_palette (
			palette_index: in palette_index_type
		) return color_palette_type;

end package color_data;


package body color_data is

	function get_color (
			color_index: in color_index_type;
			color_palette: in color_palette_type
		) return rgb_color
	is
	begin
		-- TODO: return a color from the provided color palette
		return color_palette(color_index.palette)(color_index.color);
	end function get_color;

	function get_palette (
			palette_index: in palette_index_type
		) return color_palette_type
	is
	begin
		-- TODO: return something from the color palette table
		return color_palette_table(palette_index);
	end function get_palette;

end package body color_data; 

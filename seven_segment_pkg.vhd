library ieee;
use ieee.std_logic_1164.all;

package seven_segment_pkg is
    type seven_segment_config is record
        a : std_logic;
        b : std_logic;
        c : std_logic;
        d : std_logic;
        e : std_logic;
        f : std_logic;
        g : std_logic;
    end record seven_segment_config;

    type seven_segment_array is array(natural range <>) of seven_segment_config;
    
	 type lamp_configuration is (
		common_anode,
		common_cathode
		);
		
		
    subtype hex_digit is natural range 0 to 15;
	 
	 type hex_digit_array is array(natural range <>) of hex_digit;
	 
	 
	 constant default_lamp_config : lamp_configuration := common_anode;
	 
	 constant seven_segment_table : seven_segment_array(0 to 15) := (
        (a=>'0', b=>'0', c=>'0', d=>'0', e=>'0', f=>'0', g=>'1'), -- 0
        (a=>'1', b=>'0', c=>'0', d=>'1', e=>'1', f=>'1', g=>'1'), -- 1
        (a=>'0', b=>'0', c=>'1', d=>'0', e=>'0', f=>'1', g=>'0'), -- 2
        (a=>'0', b=>'0', c=>'0', d=>'0', e=>'1', f=>'1', g=>'0'), -- 3
        (a=>'1', b=>'0', c=>'0', d=>'1', e=>'1', f=>'0', g=>'0'), -- 4
        (a=>'0', b=>'1', c=>'0', d=>'0', e=>'1', f=>'0', g=>'0'), -- 5
        (a=>'0', b=>'1', c=>'0', d=>'0', e=>'0', f=>'0', g=>'0'), -- 6
        (a=>'0', b=>'0', c=>'0', d=>'1', e=>'1', f=>'1', g=>'1'), -- 7
        (a=>'0', b=>'0', c=>'0', d=>'0', e=>'0', f=>'0', g=>'0'), -- 8
        (a=>'0', b=>'0', c=>'0', d=>'0', e=>'1', f=>'0', g=>'0'), -- 9
        (a=>'0', b=>'0', c=>'0', d=>'1', e=>'0', f=>'0', g=>'0'), -- A
        (a=>'1', b=>'1', c=>'0', d=>'0', e=>'0', f=>'0', g=>'0'), -- b
        (a=>'0', b=>'1', c=>'1', d=>'0', e=>'0', f=>'0', g=>'1'), -- C
        (a=>'1', b=>'0', c=>'0', d=>'0', e=>'0', f=>'1', g=>'0'), -- d
        (a=>'0', b=>'1', c=>'1', d=>'0', e=>'0', f=>'0', g=>'0'), -- E
        (a=>'0', b=>'1', c=>'1', d=>'1', e=>'0', f=>'0', g=>'0')  -- F
    );

    function get_hex_digit (
        digit : in hex_digit;
		  lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config;

    function lamps_off(
		lamp_mode : in lamp_configuration := default_lamp_config
	)return seven_segment_config;
	
end package seven_segment_pkg;

package body seven_segment_pkg is

    function get_hex_digit (
        digit : in hex_digit;
		  lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config is
			variable result : seven_segment_config;
    begin
        result := seven_segment_table(digit);
		  
		  if lamp_mode = common_cathode then
				result.a := not result.a;
				result.b := not result.b;
				result.c := not result.c;
				result.d := not result.d;
				result.e := not result.e;
				result.f := not result.f;
				result.g := not result.g;
			end if;
			
			return result;
    end function get_hex_digit;

    function lamps_off(
		lamp_mode : in lamp_configuration := default_lamp_config
	)return seven_segment_config is
		variable result : seven_segment_config;
    begin
        if lamp_mode = common_anode then
            result := (a=>'1', b=>'1', c=>'1', d=>'1', e=>'1', f=>'1', g=>'1');
        else
            result := (a=>'0', b=>'0', c=>'0', d=>'0', e=>'0', f=>'0', g=>'0');
        end if;

        return result;
    end function lamps_off;

end package body;
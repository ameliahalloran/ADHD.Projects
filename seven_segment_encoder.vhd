library ieee;
use ieee.std_logic_1164.all;
use work.seven_segment_pkg.all;

entity sevenseg_encoder is
    port (
        hex_in  : in hex_digit_array(0 to 5);
        seg_out : out seven_segment_array(0 to 5)
    );
end entity;

architecture rtl of sevenseg_encoder is
begin   
    gen_digits: for i in 0 to 5 generate
		seg_out(i) <= get_hex_digit(hex_in(i));
		end generate;
end architecture;


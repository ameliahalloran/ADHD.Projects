library ieee;
use ieee.std_logic_1164.all;
use work.seven_segment_pkg.all;

entity sevenseg_encoder is
    port (
        hex_in  : in hex_digit;
        seg_out : out seven_segment_config
    );
end entity;

architecture rtl of sevenseg_encoder is
begin   
    seg_out <= get_hex_digit(hex_in, default_lamp_config);
end architecture;


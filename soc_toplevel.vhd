library ieee;
use ieee.std_logic_1164.all;

entity soc_toplevel is
    port (
        CLOCK_50 : in std_logic;
        HEX0,HEX1,HEX2,HEX3,HEX4,HEX5 : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of soc_toplevel is

    component soc_calc is
        port (
            clk_clk        : in std_logic;
            reset_reset_n  : in std_logic;
            digits_export  : out std_logic_vector(41 downto 0)
        );
    end component;

    signal digits : std_logic_vector(41 downto 0);

begin

    u0: soc_calc
        port map (
            clk_clk       => CLOCK_50,
            reset_reset_n => '1',
            digits_export => digits
        );

    HEX0 <= digits(6 downto 0);
    HEX1 <= digits(13 downto 7);
    HEX2 <= digits(20 downto 14);
    HEX3 <= digits(27 downto 21);
    HEX4 <= digits(34 downto 28);
    HEX5 <= digits(41 downto 35);

end architecture;

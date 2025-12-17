library ieee;
use ieee.std_logic_1164.all;

entity toplevel_wrapper is
end;

architecture sim of toplevel_wrapper is

    signal clk       : std_logic := '0';
    signal reset_n   : std_logic := '1';

    signal address   : std_logic_vector(1 downto 0) := "00";
    signal read      : std_logic := '0';
    signal write     : std_logic := '0';
    signal readdata  : std_logic_vector(31 downto 0);
    signal writedata : std_logic_vector(31 downto 0) := (others => '0');

    signal lamps     : std_logic_vector(41 downto 0); -- 6 digits * 7 seg

begin

    clk <= not clk after 5 ns;

    uut: entity work.sevenseg_core
        generic map (
            lamp_mode_common_anode => true,
            decimal_support        => true,
            implementer            => 42,
            revision               => 1,
            num_digits             => 6
        )
        port map (
            clk       => clk,
            reset_n   => reset_n,
            address   => address,
            read      => read,
            readdata  => readdata,
            write     => write,
            writedata => writedata,
            lamps     => lamps
        );

end architecture;

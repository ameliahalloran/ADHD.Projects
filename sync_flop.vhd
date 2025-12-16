library ieee;
use ieee.std_logic_1164.all;

entity sync_flop is
	generic (
		WIDTH : natural := 1
		);
    port (
        clk     : in  std_logic;   -- destination clock
        reset 	: in  std_logic;
        din     : in  std_logic_vector(WIDTH-1 downto 0);   -- async input
        dout    : out std_logic_vector(WIDTH-1 downto 0)    -- synchronized output
    );
end entity sync_flop;

architecture rtl of sync_flop is
    signal q : std_logic_vector(WIDTH-1 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            q <= din;
        end if;
    end process;

    dout <= q;
end architecture rtl;
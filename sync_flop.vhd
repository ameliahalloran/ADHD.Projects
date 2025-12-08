library ieee;
use ieee.std_logic_1164.all;

entity sync_flop is
    port (
        clk     : in  std_logic;   -- destination clock
        reset 	: in  std_logic;
        din     : in  std_logic;   -- async input
        dout    : out std_logic    -- synchronized output
    );
end entity sync_flop;

architecture rtl of sync_flop is
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				dout <= '0';
			else
				dout <= din;
		end if;
	end process;
end architecture;
		
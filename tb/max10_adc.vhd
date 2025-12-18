library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----
-- port map:
--
-- pll_clk:	clock input (10 MHz)
-- chsel:	channel select
-- soc:		start of conversion
-- tsen:	0 - normal mode
--			1 - temperature sensing mode
-- dout:	data output
-- eoc:		end of conversion
-- clk_dft:	clock output from clock divider

entity max10_adc is
	port (
		pll_clk:	in	std_logic;
		chsel:		in	natural range 0 to 2**5 - 1;
		soc:		in	std_logic;
		tsen:		in	std_logic;
		dout:		out	natural range 0 to 2**12 - 1;
		eoc:		out	std_logic := '0';
		clk_dft:	out	std_logic
	);
end entity max10_adc;

architecture dummy of max10_adc is
	type state_type is ( idle, dummy_wait, done );
	signal state: state_type;
begin

	clk_dft <= pll_clk;
	dout <= 1234;

	drive_eoc: process(pll_clk) is
	begin
		if rising_edge(pll_clk) then
			eoc <= '0';
			case state is
				when idle =>
					if soc = '1' then
						state <= dummy_wait;
					end if;
				when dummy_wait =>
					state <= done after 200 ns;
				when done =>
					state <= idle;
					eoc <= '1';
			end case;
		end if;
	end process drive_eoc;

end architecture dummy;

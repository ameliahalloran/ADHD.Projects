library ieee;
use ieee.std_logic_1164.all;

use work.seven_segment_pkg.all;

entity tb_toplevel is
    generic (
		sim_cycles :	positive := 2000;
	    ADDR_WIDTH :    positive := 6;
        lamp_config:    lamp_configuration := common_anode
    );
end entity tb_toplevel;

architecture test of tb_toplevel is
	signal reset: std_logic := '0';
	signal clk_50mhz: std_logic := '0';
	signal clk_1mhz: std_logic := '0';

	signal done: boolean := false;
begin

	clk_50mhz <= not clk_50mhz after 1 ns when not done else '0';
	clk_1mhz <= not clk_1mhz after 5 ns when not done else '0';

	dut: entity work.ADS_Project3_TopLevel
		generic map (
			ADDR_WIDTH =>	ADDR_WIDTH,
			lamp_mode =>	lamp_config
		)
		port map (
			reset_n =>		reset,
			clk_10mhz =>	clk_1mhz,
			clk_50mhz =>	clk_50mhz,
			seg_out =>		open
		);

	stimulus: process is
	begin
		reset <= '0';
		wait until rising_edge(clk_1mhz);
		wait until rising_edge(clk_1mhz);

		reset <= '1';

		for i in 0 to sim_cycles - 1 loop
			wait until rising_edge(clk_1mhz);
		end loop;

		done <= true;
		wait;
	end process stimulus;

end architecture test;

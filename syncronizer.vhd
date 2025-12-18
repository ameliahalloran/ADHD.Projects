library ieee;
use ieee.std_logic_1164.all;

entity crossing_addr is
	generic (
		ADDR_WIDTH : positive := 4
		);
	port (
		data_in	: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		data_out	: out std_logic_vector(ADDR_WIDTH - 1 downto 0);
		clk_a		: in std_logic;
		reset		: in std_logic;
		clk_b		: in std_logic
		);
	generic (
		ADDR_WIDTH : positive := 4
		);
	port (
		data_in	: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		data_out	: out std_logic_vector(ADDR_WIDTH - 1 downto 0);
		clk_a		: in std_logic;
		reset		: in std_logic;
		clk_b		: in std_logic
		);
end entity crossing_addr;

architecture rtl of crossing_addr is
	signal ptr_gray  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out1 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out2 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out3 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal ptr_gray  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out1 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out2 : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal flip_out3 : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin
	
		u_bin2gray : entity work.bin_to_gray
			generic map (input_width => ADDR_WIDTH)
			port map (
				bin_in => data_in,
				gray_out => ptr_gray
				);
				
		--gray out becomes the input to the first flop, controlled by clock a
		
		u_flipflop1 : entity work.sync_flop 
			generic map (WIDTH => ADDR_WIDTH)
			port map(
				clk => clk_a,
				reset => reset,
				din => ptr_gray,
				dout => flip_out1
				);
				
		
		--output of the first flop , driven by clock b
		u_flipflop2 : entity work.sync_flop
			generic map (WIDTH => ADDR_WIDTH)
			port map(
				clk => clk_b,
				reset => reset,
				din => flip_out1,
				dout => flip_out2
				);
				
		--output of the second flop driven by clock b
		u_flipflop3 : entity work.sync_flop
			generic map (WIDTH => ADDR_WIDTH)
			port map (
				clk => clk_b,
				reset => reset,
				din => flip_out2,
				dout => flip_out3
				);
				
				
		u_gray2bin : entity work.gray_to_bin
			generic map (input_width => ADDR_WIDTH)
			port map (
				gray_in => flip_out3,
				bin_out => data_out
				);
				
	
		u_bin2gray : entity work.bin_to_gray
			generic map (input_width => ADDR_WIDTH)
			port map (
				bin_in => data_in,
				gray_out => ptr_gray
				);
				
		--gray out becomes the input to the first flop, controlled by clock a
		
		u_flipflop1 : entity work.sync_flop 
			generic map (WIDTH => ADDR_WIDTH)
			port map(
				clk => clk_a,
				reset => reset,
				din => ptr_gray,
				dout => flip_out1
				);
				
		
		--output of the first flop , driven by clock b
		u_flipflop2 : entity work.sync_flop
			generic map (WIDTH => ADDR_WIDTH)
			port map(
				clk => clk_b,
				reset => reset,
				din => flip_out1,
				dout => flip_out2
				);
				
		--output of the second flop driven by clock b
		u_flipflop3 : entity work.sync_flop
			generic map (WIDTH => ADDR_WIDTH)
			port map (
				clk => clk_b,
				reset => reset,
				din => flip_out2,
				dout => flip_out3
				);
				
				
		u_gray2bin : entity work.gray_to_bin
			generic map (input_width => ADDR_WIDTH)
			port map (
				gray_in => flip_out3,
				bin_out => data_out
				);
				
end architecture rtl;
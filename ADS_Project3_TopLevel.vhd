library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_pkg.all;

entity ADS_Project3_TopLevel is
    generic (
        lamp_mode  : lamp_configuration := default_lamp_config;
        ADDR_WIDTH : positive := 5
    );
    port (
        clk_10mhz : in  std_logic;
        clk_50mhz : in  std_logic;
        reset_n   : in  std_logic;
        seg_out   : out seven_segment_array(0 to 5)
    );
end entity ADS_Project3_TopLevel;

architecture rtl of ADS_Project3_TopLevel is

    signal adc_clk  : std_logic;
    signal clk_1mhz : std_logic;

    -- ADC → buffer
	 signal dout_sig : natural range 0 to 2**12 - 1;
    signal adc_data_1mhz : std_logic_vector(11 downto 0);
    signal wren          : std_logic;

	 -- ADC control
	 signal soc_sig, eoc_sig : std_logic;
    -- Ring buffer
    

    -- Addresses
    signal addr_write_1mhz  : unsigned(ADDR_WIDTH-1 downto 0);
    signal addr_read_1mhz   : unsigned(ADDR_WIDTH-1 downto 0);
    signal addr_write_50mhz : unsigned(ADDR_WIDTH-1 downto 0);
    signal addr_read_50mhz  : unsigned(ADDR_WIDTH-1 downto 0);

    signal addr_write_vec_1mhz  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal addr_read_vec_1mhz   : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal addr_write_vec_50mhz : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal addr_read_vec_50mhz  : std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal write_addr_nat_1mhz : natural range 0 to 2**ADDR_WIDTH - 1;
    signal read_addr_nat_50mhz : natural range 0 to 2**ADDR_WIDTH - 1;

    signal adv : std_logic;
	 
	 signal temp_data_50mhz, temp_data_1mhz: std_logic_vector(11 downto 0);
	 signal addr_write_nat_1mhz, addr_read_nat_50mhz: natural range 0 to 2**ADDR_WIDTH - 1;
	 -- signal wren: std_logic;

begin

    --------------------------------------------------------------------
    -- PLL
    --------------------------------------------------------------------
    pll_inst : entity work.pll
        port map (
            inclk0 => clk_10mhz,
            c0     => adc_clk
        );

    --------------------------------------------------------------------
    -- ADC controller (CORRECT PORT MAP)
    --------------------------------------------------------------------
	 adc: entity work.max10_adc
		port map (
		      pll_clk => adc_clk,
            chsel   => 0,
            soc     => soc_sig,
            tsen    => '1',
            dout    => dout_sig,
            eoc     => eoc_sig,
            clk_dft => clk_1mhz
		);
    adc_data_1mhz <= std_logic_vector(to_unsigned(dout_sig, 12));

    --------------------------------------------------------------------
    -- Producer FSM (UNCHANGED)
    --------------------------------------------------------------------
    producer : entity work.adc_fsm1
        generic map (addr_width => ADDR_WIDTH)
        port map (
            clock      => clk_1mhz,
            reset_n    => reset_n,
            soc        => soc_sig,          -- handled internally now
            eoc        => eoc_sig,
            addr_write => addr_write_1mhz,
            addr_read  => addr_read_1mhz,
            wren       => wren           -- adc_controller drives wren
        );
    addr_write_vec_1mhz <= std_logic_vector(addr_write_1mhz);
    write_addr_nat_1mhz <= to_integer(addr_write_1mhz);

    --------------------------------------------------------------------
    -- Consumer FSM
    --------------------------------------------------------------------
    consumer : entity work.adc_fsm50
        generic map (addr_width => ADDR_WIDTH)
        port map (
            clock      => clk_50mhz,
            reset_n    => reset_n,
            addr_write => addr_write_50mhz,
            addr_read  => addr_read_50mhz
        );
    addr_read_vec_50mhz <= std_logic_vector(addr_read_50mhz);
    read_addr_nat_50mhz <= to_integer(addr_read_50mhz);

    --------------------------------------------------------------------
    -- Dual-port RAM
    --------------------------------------------------------------------
    dp_buf : entity work.dp_ram
        generic map (
            DATA_WIDTH => 12,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk_a  => clk_1mhz,
            addr_a => write_addr_nat_1mhz,
            data_a => adc_data_1mhz,
            we_a => wren,
            q_a    => open,

            clk_b  => clk_50mhz,
            addr_b => read_addr_nat_50mhz,
            data_b => (others => '0'),
            we_b => '0',
            q_b    => temp_data_50mhz
        );
-- clock crossings for the pointers
	wrptr_cross: entity work.crossing_addr
		generic map (
			ADDR_WIDTH =>	ADDR_WIDTH
		)
		port map (
			data_in =>	addr_write_vec_1mhz,
			data_out =>	addr_write_vec_50mhz,
			clk_a =>	clk_1mhz,
			reset =>	reset_n,
			clk_b =>	clk_50mhz
		);
	addr_write_50mhz <= unsigned(addr_write_vec_50mhz);

	rdptr_cross: entity work.crossing_addr
		generic map (
			ADDR_WIDTH =>	ADDR_WIDTH
		)
		port map (
			data_in =>	addr_read_vec_50mhz,
			data_out =>	addr_read_vec_1mhz,
			clk_a =>	clk_50mhz,
			reset =>	reset_n,
			clk_b =>	clk_1mhz
		);
		addr_read_1mhz <= unsigned(addr_read_vec_1mhz);
		
--    fifo_inst : entity work.fifo_sync
--        generic map (
--            DATA_WIDTH => 12,
--            ADDR_WIDTH => 4
--        )
--        port map (
--            wr_clk   => clk_1mhz,
--            wr_reset => reset,
--            wr_en    => fifo_wr,
--            din      => adc_data_reg,
--
--            rd_clk   => clk_50mhz,
--            rd_reset => reset,
--            rd_en    => fifo_rd,
--            dout     => fifo_dout,
--
--            empty    => fifo_empty,
--            full     => fifo_full
--        );

    
--    process(clk_50mhz, reset_n)
--        variable adc_val : integer;
--        variable temp_i  : integer;
--    begin
--        if reset_n = '0' then
--            -- hex_digits <= (others => 0);
--            fifo_rd    <= '0';
--            temp_c     <= 0;
--
--        elsif rising_edge(clk_50mhz) then
--
--            fifo_rd <= '0';
--
--            if fifo_empty = '0' then
--                fifo_rd <= '1';
--
--                adc_val := to_integer(unsigned(fifo_dout));
--
--                -- MAX10 temperature conversion (10M50)
--                -- T(°C) = (ADC_code - 1536) / 4
--                temp_i := (adc_val - 1536) / 4;
--
--                if temp_i < 0 then
--                    temp_c <= 0;     -- clamp negative temperatures to 0
--                else
--                    temp_c <= temp_i;
--                end if;
--
--                -- Display Celsius value (integer)
----                hex_digits(0) <= 1;--temp_c mod 10;
----                hex_digits(1) <= 2;--(temp_c / 10) mod 10;
----                hex_digits(2) <= 3;--(temp_c / 100) mod 10;
----                hex_digits(3) <= 4;
----                hex_digits(4) <= 5;
----                hex_digits(5) <= 6;
--            end if;
--        end if;
--    end process;

	drive_outs: for i in 0 to 2 generate
	begin
		seg_out(i) <= get_hex_digit(to_integer(unsigned(temp_data_50mhz(4*i + 3 downto 4*i))), lamp_mode);
	end generate drive_outs;
	
	clear_outs: for i in 3 to 5 generate
	begin
		seg_out(i) <= lamps_off(lamp_mode);
	end generate clear_outs;
--    seg_out(0) <= get_hex_digit(0, lamp_mode);
--    seg_out(1) <= get_hex_digit(1, lamp_mode);
--    seg_out(2) <= get_hex_digit(2, lamp_mode);
--    seg_out(3) <= get_hex_digit(3, lamp_mode);
--    seg_out(4) <= get_hex_digit(4, lamp_mode);
--    seg_out(5) <= get_hex_digit(5, lamp_mode);

end architecture rtl;
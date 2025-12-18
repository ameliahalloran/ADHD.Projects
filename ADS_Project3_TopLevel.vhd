library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_pkg.all;

entity ADS_Project3_TopLevel is
	generic (
		lamp_mode: lamp_configuration := default_lamp_config;
		ADDR_WIDTH:	positive := 5
	);
    port (
        clk_10mhz : in  std_logic;  -- raw 10 MHz board input
        clk_50mhz : in  std_logic;  -- 50 MHz board input
        reset_n   : in  std_logic;
        seg_out   : out seven_segment_array(0 to 5)
    );
end entity ADS_Project3_TopLevel;

architecture rtl of ADS_Project3_TopLevel is

    signal adc_clk  : std_logic;
	signal clk_1mhz : std_logic;
	
    -- ADC control
    signal soc      : std_logic := '0';
    signal eoc      : std_logic;
    signal dout_int : natural range 0 to 2**12 - 1;
--    signal dout_vec : std_logic_vector(11 downto 0);

--    signal adc_data_reg : std_logic_vector(11 downto 0);
--    signal adc_ready    : std_logic := '0';

    -- FIFO signals
	signal temp_data_50mhz, temp_data_1mhz: std_logic_vector(11 downto 0);
	signal addr_write_nat_1mhz, addr_read_nat_50mhz: natural range 0 to 2**ADDR_WIDTH - 1;
	signal wren: std_logic;
--    signal fifo_dout  : std_logic_vector(11 downto 0);
--    signal fifo_wr    : std_logic;
--    signal fifo_rd    : std_logic;
--    signal fifo_empty : std_logic;
--    signal fifo_full  : std_logic;

	-- crossing signals
	signal addr_write_vec_1mhz, addr_write_vec_50mhz:	std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal addr_read_vec_50mhz, addr_read_vec_1mhz:		std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal addr_write_1mhz, addr_write_50mhz:			unsigned(ADDR_WIDTH - 1 downto 0);
	signal addr_read_50mhz, addr_read_1mhz:				unsigned(ADDR_WIDTH - 1 downto 0);

    -- Display
    -- signal hex_digits : hex_digit_array(0 to 5);

    --------------------------------------------------------------------
    -- Temperature
    --------------------------------------------------------------------
    signal temp_c : integer range 0 to 255 := 0;

begin
    pll_inst : entity work.pll
        port map (
            inclk0 => clk_10mhz,
            c0     => adc_clk
        );

    --------------------------------------------------------------------
    -- ADC controller
    --------------------------------------------------------------------
    adc_ctrl : entity work.adc_controller
        port map (
            pll_clk => adc_clk,
            chsel   => 0,
            soc     => soc,
            tsen    => '1',
            dout    => dout_int,
            eoc     => eoc,
            clk_dft => clk_1mhz	-- need this clock!
        );

    temp_data_1mhz <= std_logic_vector(to_unsigned(dout_int, 12));

	producer: entity work.adc_fsm
		generic map (
			addr_width =>	ADDR_WIDTH
		)
		port map (
			clock =>	clk_1mhz,
			reset_n =>	reset_n,
			soc =>		soc,
			eoc =>		eoc,
			addr_write =>	addr_write_1mhz,
			addr_read =>	addr_read_1mhz,
			wren =>		wren
		);
	addr_write_nat_1mhz <= to_integer(addr_write_1mhz);
	addr_write_vec_1mhz <= std_logic_vector(addr_write_1mhz);
	

--    process(adc_clk, reset_n)
--    begin
--        if reset_n = '0' then
--            state        <= idle;
--            soc          <= '0';
--            adc_ready    <= '0';
--            adc_data_reg <= (others => '0');
--
--        elsif rising_edge(adc_clk) then
--            case state is
--
--                when idle =>
--                    soc       <= '1';
--                    adc_ready <= '0';
--                    state     <= start_conv;
--
--                when start_conv =>
--                    soc   <= '0';
--                    state <= wait_eoc;
--
--                when wait_eoc =>
--                    if eoc = '1' then
--                        state <= latch_data;
--                    end if;
--
--                when latch_data =>
--                    adc_data_reg <= dout_vec;
--                    adc_ready    <= '1';
--                    state        <= idle;
--
--            end case;
--        end if;
--    end process;
--
--    fifo_wr <= adc_ready;


	---------------------------
	-- dp_ram as buffer
	---------------------------
	dp_buf: entity work.dp_ram
		generic map (
			DATA_WIDTH =>	12,	-- 12 bit ADC
			ADDR_WIDTH =>	ADDR_WIDTH
		)
		port map (
			-- port A for writes
			clk_a =>	clk_1mhz,
			addr_a =>	write_addr_nat_1mhz,
			data_a =>	temp_data_1mhz,
			wren_a =>	wren,
			q_a =>		open,
			-- port B for reads
			clk_b =>	clk_50mhz,
			addr_b =>	read_addr_nat_50mhz,
			data_b =>	( others => '0' ),
			wren_b =>	'0',
			q_b =>		temp_data_50mhz
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
--    seg_out(0) <= get_hex_digit(0, lamp_mode);
--    seg_out(1) <= get_hex_digit(1, lamp_mode);
--    seg_out(2) <= get_hex_digit(2, lamp_mode);
--    seg_out(3) <= get_hex_digit(3, lamp_mode);
--    seg_out(4) <= get_hex_digit(4, lamp_mode);
--    seg_out(5) <= get_hex_digit(5, lamp_mode);

end architecture rtl;

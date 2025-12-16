library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_pkg.all;

entity ADS_Project3_TopLevel is
    port (
        clk_10mhz   : in  std_logic;
        clk_50mhz   : in  std_logic;
        reset_n     : in  std_logic;
        seg_out     : out seven_segment_array(0 to 5)
    );
end entity ADS_Project3_TopLevel;

architecture rtl of ADS_Project3_TopLevel is

    signal reset : std_logic;
    signal adc_clk : std_logic;

    --------------------------------------------------------------------
    -- ADC signals
    --------------------------------------------------------------------
    signal soc        : std_logic := '0';
    signal eoc        : std_logic;
    signal dout_int   : natural range 0 to 4095;
    signal dout_vec   : std_logic_vector(11 downto 0);

    type state_type is (idle, start_conv, wait_eoc, latch_data);
    signal state : state_type := idle;

    signal adc_data_reg : std_logic_vector(11 downto 0);
    signal adc_ready    : std_logic := '0';

    --------------------------------------------------------------------
    -- FIFO signals
    --------------------------------------------------------------------
    signal fifo_dout  : std_logic_vector(11 downto 0);
    signal fifo_wr    : std_logic;
    signal fifo_rd    : std_logic;
    signal fifo_empty : std_logic;
    signal fifo_full  : std_logic;

    --------------------------------------------------------------------
    -- Display signals
    --------------------------------------------------------------------
    signal hex_digits : hex_digit_array(0 to 5);

begin

    reset <= not reset_n;

    --------------------------------------------------------------------
    -- PLL: derive ADC clock
    --------------------------------------------------------------------
    pll_inst : entity work.pll
        port map (
            inclk0 => clk_10mhz,
            c0     => adc_clk
        );

    --------------------------------------------------------------------
    -- ADC wrapper
    --------------------------------------------------------------------
    adc_inst : entity work.max10_adc
        port map (
            pll_clk => adc_clk,
            chsel   => 0,
            soc     => soc,
            tsen    => '1',
            dout    => dout_int,
            eoc     => eoc,
            clk_dft => open
        );

    dout_vec <= std_logic_vector(to_unsigned(dout_int, 12));

    --------------------------------------------------------------------
    -- ADC FSM
    --------------------------------------------------------------------
    process(adc_clk, reset)
    begin
        if reset = '1' then
            state        <= idle;
            soc          <= '0';
            adc_ready    <= '0';
            adc_data_reg <= (others => '0');

        elsif rising_edge(adc_clk) then
            case state is

                when idle =>
                    soc       <= '1';
                    adc_ready <= '0';
                    state     <= start_conv;

                when start_conv =>
                    soc   <= '0';
                    state <= wait_eoc;

                when wait_eoc =>
                    if eoc = '1' then
                        state <= latch_data;
                    end if;

                when latch_data =>
                    adc_data_reg <= dout_vec;
                    adc_ready    <= '1';
                    state        <= idle;

            end case;
        end if;
    end process;

    fifo_wr <= adc_ready;

    --------------------------------------------------------------------
    -- FIFO instance
    --------------------------------------------------------------------
    fifo_inst : entity work.fifo_sync
        generic map (
            DATA_WIDTH => 12,
            ADDR_WIDTH => 4
        )
        port map (
            wr_clk   => adc_clk,
            wr_reset => reset,
            wr_en    => fifo_wr,
            din      => adc_data_reg,

            rd_clk   => clk_50mhz,
            rd_reset => reset,
            rd_en    => fifo_rd,
            dout     => fifo_dout,

            empty    => fifo_empty,
            full     => fifo_full
        );

    --------------------------------------------------------------------
    -- Consumer domain (50 MHz)
    --------------------------------------------------------------------
    process(clk_50mhz, reset)
        variable value : integer;
    begin
        if reset = '1' then
            hex_digits <= (others => 0);
            fifo_rd    <= '0';

        elsif rising_edge(clk_50mhz) then

            fifo_rd <= '0';

            if fifo_empty = '0' then
                fifo_rd <= '1';

                value := to_integer(unsigned(fifo_dout));

                hex_digits(0) <= value mod 10;
                hex_digits(1) <= (value / 10) mod 10;
                hex_digits(2) <= (value / 100) mod 10;
                hex_digits(3) <= (value / 1000) mod 10;
                hex_digits(4) <= (value / 10000) mod 10;
                hex_digits(5) <= (value / 100000) mod 10;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Drive seven-segment displays
    --------------------------------------------------------------------
    seg_out(0) <= get_hex_digit(hex_digits(0));
    seg_out(1) <= get_hex_digit(hex_digits(1));
    seg_out(2) <= get_hex_digit(hex_digits(2));
    seg_out(3) <= get_hex_digit(hex_digits(3));
    seg_out(4) <= get_hex_digit(hex_digits(4));
    seg_out(5) <= get_hex_digit(hex_digits(5));

end architecture rtl;

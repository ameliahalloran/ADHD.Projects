library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_pkg.all;

entity ADS_Project3_TopLevel is
    generic (
        lamp_mode : lamp_configuration := default_lamp_config
    );
    port (
        clk_10mhz : in  std_logic;  -- raw 10 MHz board input
        clk_50mhz : in  std_logic;  -- 50 MHz board input
        reset_n   : in  std_logic;
        seg_out   : out seven_segment_array(0 to 5)
    );
end entity ADS_Project3_TopLevel;

architecture rtl of ADS_Project3_TopLevel is

    --------------------------------------------------------------------
    -- Reset
    --------------------------------------------------------------------
    signal reset : std_logic;

    --------------------------------------------------------------------
    -- Clock for ADC
    --------------------------------------------------------------------
    signal adc_clk : std_logic;

    --------------------------------------------------------------------
    -- Producer → FIFO signals
    --------------------------------------------------------------------
    signal fifo_din  : std_logic_vector(11 downto 0);
    signal fifo_wr   : std_logic;
    signal clk_dft   : std_logic;

    --------------------------------------------------------------------
    -- FIFO → Consumer signals
    --------------------------------------------------------------------
    signal fifo_dout      : std_logic_vector(11 downto 0);
    signal fifo_rd        : std_logic;
    signal fifo_empty     : std_logic;
    signal fifo_full      : std_logic;
    signal fifo_valid_reg : std_logic := '0';
    signal fifo_dout_reg  : std_logic_vector(11 downto 0);

    --------------------------------------------------------------------
    -- Temperature
    --------------------------------------------------------------------
    signal temp_c : integer range 0 to 255 := 0;

begin

    reset <= not reset_n;

    --------------------------------------------------------------------
    -- PLL to drive ADC safely
    --------------------------------------------------------------------
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
            pll_clk  => adc_clk,
            reset_n  => reset_n,
            tsen     => '1',
            fifo_din => fifo_din,
            fifo_wr  => fifo_wr,
            clk_dft  => clk_dft
        );

    --------------------------------------------------------------------
    -- CDC FIFO
    --------------------------------------------------------------------
    fifo_inst : entity work.fifo_sync
        generic map (
            DATA_WIDTH => 12,
            ADDR_WIDTH => 4
        )
        port map (
            wr_clk   => clk_dft,
            wr_reset => reset,
            wr_en    => fifo_wr,
            din      => fifo_din,

            rd_clk   => clk_50mhz,
            rd_reset => reset,
            rd_en    => fifo_rd,
            dout     => fifo_dout,

            empty    => fifo_empty,
            full     => fifo_full
        );

    --------------------------------------------------------------------
    -- FIFO consumer + temperature conversion (50 MHz)
    --------------------------------------------------------------------
    process(clk_50mhz, reset)
        variable adc_val  : integer;
        variable temp_i   : integer;
    begin
        if reset = '1' then
            fifo_rd        <= '0';
            fifo_dout_reg  <= (others => '0');
            fifo_valid_reg <= '0';
            temp_c         <= 0;

        elsif rising_edge(clk_50mhz) then
            fifo_rd <= '0';

            if fifo_empty = '0' then
                fifo_rd <= '1';
            end if;

            fifo_dout_reg  <= fifo_dout;
            fifo_valid_reg <= fifo_rd;

            if fifo_valid_reg = '1' then
                adc_val := to_integer(unsigned(fifo_dout_reg));
                temp_i  := (adc_val - 1536) / 4;  -- adjust scaling if needed

                if temp_i < 0 then
                    temp_c <= 0;
                else
                    temp_c <= temp_i;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Seven-segment display
    --------------------------------------------------------------------
    seg_out(0) <= get_hex_digit(temp_c mod 10, lamp_mode);
    seg_out(1) <= get_hex_digit((temp_c / 10) mod 10, lamp_mode);
    seg_out(2) <= get_hex_digit((temp_c / 100) mod 10, lamp_mode);
    seg_out(3) <= get_hex_digit(0, lamp_mode);
    seg_out(4) <= get_hex_digit(0, lamp_mode);
    seg_out(5) <= get_hex_digit(0, lamp_mode);

end architecture rtl;

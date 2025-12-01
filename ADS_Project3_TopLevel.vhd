library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seven_segment_pkg.all

entity top_level is
    port (
        clk_10mhz   : in  std_logic;                    -- 10 MHz input clock
        clk_50mhz   : in  std_logic;                    --50 MHz consumer clock
        reset_n     : in  std_logic;                    -- active-low reset
        temp_mode   : in  std_logic;                    -- '1' = temperature is sensing
        seg_out     : out seven_segment_config          -- seven segement a-g
    );
end entity top_level;

architecture rtl of top_level is

    -- PLL signals
    signal clk_1mhz   : std_logic;   
    signal pll_locked : std_logic;   

    -- ADC signals
    signal soc        : std_logic := '0';           
    signal eoc        : std_logic;                  
    signal dout_int   : integer range 0 to 2**12-1; 
    signal dout_vec   : std_logic_vector(11 downto 0);

    -- Control FSM states
    type state_type is (idle, start_conv, wait_eoc, latch_data);
    signal state : state_type := idle;

    -- Data crossing into consumer domain
    signal adc_data_reg : std_logic_vector(11 downto 0);
    signal adc_ready    : std_logic := '0';

    --Seven-seg input (lower 4 bits of ADC data)
    signal hex_digit    : std_logic_vector(3 downto 0);

begin

    pll_inst : entity work.pll
        port map (
            inclk0 => clk_10mhz,
            c0     => clk_1mhz,
            locked => pll_locked
        );

    adc_inst : entity work.max10_adc
        port map (
            pll_clk => clk_1mhz,     
            chsel   => 0,            
            soc     => soc,          
            tsen    => temp_mode,          
            dout    => dout_int,     
            eoc     => eoc,          
            clk_dft => open          
        );

    -- Convert integer ADC output to std_logic_vector for external use
    dout_vec <= std_logic_vector(to_unsigned(dout_int, 12));
    
    
    process(clk_1mhz, reset_n)
    begin
        if reset_n = '0' then
            state     <= idle;
            soc       <= '0';
            adc_ready <= (others => '0');
        elsif rising_edge(clk_1mhz) then
            case state is
                when idle =>
                    soc       <= '1';       -- request conversion
                    adc_ready <= '0';
                    state     <= start_conv;

                when start_conv =>
                    soc       <= '0';       -- pulse SOC for one cycle
                    state     <= wait_eoc;

                when wait_eoc =>
                    if eoc = '1' then       -- wait until conversion finishes
                        state <= latch_data;
                    end if;

                when latch_data =>
                    adc_ready <= '1';       -- flag: new data available
                    state     <= idle;      -- go back and start again
            end case;
        end if;
    end process;

    process(clk_50mhz, reset_n)
    begin
        if reset_n = '0' then
            hex_digit <= (others => '0');
        elsif rising_edge(clk_50mhz) then
            if adc_ready = '1' then
                hex_digit <= to_integer(unsigned(adc_data_reg(3 downto 0)));
            end if;
        end if;
    end process;

    seg_out <= get_hex_digit(hex_digit, default_lamp_config);
    
end architecture rtl;
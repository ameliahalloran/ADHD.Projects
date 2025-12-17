library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_fsm1 is 
    port(
        clk        : in  std_logic;  -- MUST be clk_dft
        reset_n    : in  std_logic;
        start      : in  std_logic;  -- tie to '1' for continuous conversions
        eoc        : in  std_logic;  -- end of conversion from ADC
        dout       : in  natural range 0 to 4095; -- ADC output
        soc        : out std_logic;  -- start of conversion (1 clk_dft pulse)
        data_valid : out std_logic;  -- 1 clk_dft pulse
        data_out1  : out natural range 0 to 4095
    );
end entity adc_fsm1;

architecture rtl of adc_fsm1 is

    type state_type is (IDLE, SOC_PULSE, WAIT_EOC, LATCH);
    signal state : state_type := IDLE;

    signal data_reg : natural range 0 to 4095 := 0;

begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state      <= IDLE;
            soc        <= '0';
            data_valid <= '0';
            data_reg   <= 0;

        elsif rising_edge(clk) then
            -- defaults every cycle
            soc        <= '0';
            data_valid <= '0';

            case state is

                when IDLE =>
                    if start = '1' then
                        soc   <= '1';          -- assert SOC for 1 cycle
                        state <= SOC_PULSE;
                    end if;

                when SOC_PULSE =>
                    -- SOC already deasserted by default
                    state <= WAIT_EOC;

                when WAIT_EOC =>
                    if eoc = '1' then
                        data_reg <= dout;      -- latch ADC data
                        state    <= LATCH;
                    end if;

                when LATCH =>
                    data_valid <= '1';         -- 1-cycle pulse
                    state      <= IDLE;

            end case;
        end if;
    end process;

    data_out1 <= data_reg;

end architecture rtl;

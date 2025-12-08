-- driven by the 1 Mhz clk
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_fsm1 is 
	port(
		clk       : in  std_logic;  -- 1 MHz ADC clock
      reset_n   : in  std_logic;
      start     : in  std_logic;  -- external trigger (could be '1' always)
      eoc       : in  std_logic;  -- end of conversion from ADC
      dout      : in  natural range 0 to 2**12 - 1; -- ADC output
      soc       : out std_logic;  -- start of conversion
      data_valid: out std_logic;  -- pulse when new data is ready
      data_out1  : out natural range 0 to 2**12 - 1  -- latched ADC value
	);
end entity adc_fsm1;

architecture rtl of adc_fsm1 is
	type state_type is (IDLE, START_CONV, WAIT_EOC, LATCH);
	signal state, next_state : state_type;
	signal data_reg : natural range 0 to 2**12 - 1;
begin
	process(clk, reset_n)
	begin
		if reset_n = '0'then
			state <= IDLE;
			data_reg <= 0;
		elsif rising_edge(clk) then
			state <= next_state;
			if state = LATCH then
				data_reg <= dout;
			end if;
		end if;
	end process;
	
	process(state, start, eoc)
    begin
        soc <= '0';
        data_valid <= '0';
        next_state <= state;

        case state is
            when IDLE =>
                if start = '1' then
                    soc <= '1';
                    next_state <= START_CONV;
                end if;

            when START_CONV =>
                soc <= '1';
                next_state <= WAIT_EOC;

            when WAIT_EOC =>
                if eoc = '1' then
                    next_state <= LATCH;
                end if;

            when LATCH =>
                data_valid <= '1';
                next_state <= IDLE;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    data_out1 <= data_reg;
end architecture rtl;
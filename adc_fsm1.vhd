library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_fsm1 is
	generic (
		addr_width:	positive := 5
	);
	port (
		clock:		in	std_logic;
		reset_n:	in	std_logic;
		
		-- adc signals
		soc:		out	std_logic;
		eoc:		in	std_logic;
		
		-- ring buffer signals
		addr_write:	out	unsigned(addr_width - 1 downto 0);
		addr_read:	in	unsigned(addr_width - 1 downto 0);
		wren:		out	std_logic
	);
end entity adc_fsm1;

architecture fsm of adc_fsm1 is
	type state_type is ( start_conv, wait_conv, wait_addr, store );
	signal state, next_state: state_type;
	
	signal current_addr, next_addr: unsigned(addr_width - 1 downto 0);
begin
	-- drive address output
	addr_write <= current_addr;

	-- compute next address at all times
	next_addr <= current_addr + 1;
	
	store_state: process(clock, reset_n) is
	begin
		if reset_n = '0' then
			state <= start_conv;
		elsif rising_edge(clock) then
			state <= next_state;
		end if;
	end process store_state;
	
	transition_fn: process(state, next_addr, addr_read, eoc) is
	begin
		next_state <= state;
		case state is
			when start_conv =>
				next_state <= wait_conv;
			when wait_conv =>
				if eoc = '1' then
					next_state <= wait_addr;
				end if;
			when wait_addr =>
				if next_addr /= addr_read then
					next_state <= store;
				end if;
			when store =>
				next_state <= start_conv;
		end case;
	end process transition_fn;
	
	output_fn: process(clock, reset_n) is
	begin
		if reset_n = '0' then
			current_addr <= (others => '0');
			wren <= '0';
			soc <= '0';
		elsif rising_edge(clock) then
			-- default values for signals
			soc <= '0';
			wren <= '0';
			
			case state is
				when start_conv =>
					soc <= '1';
				when wait_conv | wait_addr =>
					null;
				when store =>
					wren <= '1';
					current_addr <= next_addr;
			end case;
		end if;
	end process output_fn;

end architecture fsm;
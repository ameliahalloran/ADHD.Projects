library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_fsm50 is
    generic (
        addr_width : positive := 5
    );
    port (
        clock      : in  std_logic;   -- 50 MHz
        reset_n    : in  std_logic;

        -- ring buffer signals
        addr_write : in  unsigned(addr_width-1 downto 0);
        addr_read  : out unsigned(addr_width-1 downto 0);
        adv        : out std_logic
    );
end entity adc_fsm50;

architecture fsm50 of adc_fsm50 is

    type state_type is (wait_data, advance);
    signal state, next_state : state_type;

    signal current_addr, next_addr : unsigned(addr_width-1 downto 0);

begin

    -- compute next read address
    next_addr <= current_addr + 1;

    ------------------------------------------------------------------
    -- State register
    ------------------------------------------------------------------
    state_reg : process(clock, reset_n)
    begin
        if reset_n = '0' then
            state <= wait_data;
        elsif rising_edge(clock) then
            state <= next_state;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Next-state logic
    ------------------------------------------------------------------
    next_state_logic : process(state, next_addr, addr_write)
    begin
        next_state <= state;

        case state is
            when wait_data =>
                -- FIFO not empty
                if next_addr /= addr_write then
                    next_state <= advance;
                end if;

            when advance =>
                next_state <= wait_data;

        end case;
    end process;

    ------------------------------------------------------------------
    -- Output logic
    ------------------------------------------------------------------
    output_logic : process(clock, reset_n)
    begin
        if reset_n = '0' then
            current_addr <= (others => '0');
            adv          <= '0';
        elsif rising_edge(clock) then
            adv <= '0';  -- default

            case state is
                when wait_data =>
                    null;

                when advance =>
                    adv          <= '1';
                    current_addr <= next_addr;

            end case;
        end if;
    end process;

    addr_read <= current_addr;

end architecture fsm50;

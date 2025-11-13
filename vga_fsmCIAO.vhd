library ieee;
use ieee.std_logic_1164.all;

library vga;
use vga.vga_data.all;

entity vga_fsm is
    generic (
        vga_res : vga_timing := vga_res_default
    );
    port (
        vga_clock   : in  std_logic;
        reset       : in  std_logic;

        point       : out coordinate;
        point_valid : out boolean;

        h_sync      : out std_logic;
        v_sync      : out std_logic
    );
end entity vga_fsm;

architecture fsm of vga_fsm is
    -- internal signal for current position
    signal current_point : coordinate := make_coordinate(0, 0);

    -- raw sync signals
    signal h_sync_raw    : std_logic := '1';
    signal v_sync_raw    : std_logic := '1';
    signal h_sync_shift  : std_logic_vector(15 downto 0) := (others => '0');
    signal v_sync_shift  : std_logic_vector(15 downto 0) := (others => '0');
begin

    -- main process will advance through all pixel positions
    process(vga_clock, reset)
    begin
        if reset = '0' then  -- active-low reset
            current_point <= make_coordinate(0, 0);
            h_sync_shift  <= (others => '0');
            v_sync_shift  <= (others => '0');
        elsif rising_edge(vga_clock) then
            -- move to next coordinate every clock cycle
            current_point <= next_coordinate(current_point, vga_res);

            -- shift sync signals
            h_sync_shift <= h_sync_shift(14 downto 0) & h_sync_raw;
            v_sync_shift <= v_sync_shift(14 downto 0) & v_sync_raw;
        end if;
    end process;

    -- raw sync generation
    h_sync_raw <= do_horizontal_sync(current_point, vga_res);
    v_sync_raw <= do_vertical_sync(current_point, vga_res);

    -- output delayed syncs
    h_sync <= h_sync_shift(15);
    v_sync <= v_sync_shift(15);

    -- output current point
    point <= current_point;
    
    -- check if current point is in visible area
    point_valid <= point_visible(current_point, vga_res);

end architecture fsm;

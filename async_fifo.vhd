library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo is
    generic (
        DATA_WIDTH : positive := 12;  -- ADC sample width
        ADDR_WIDTH : positive := 4    -- FIFO depth = 2^ADDR_WIDTH
    );
    port (
        -- Producer (write side)
        wr_clk   : in  std_logic;
        wr_en    : in  std_logic;
        wr_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        full     : out std_logic;

        -- Consumer (read side)
        rd_clk   : in  std_logic;
        rd_en    : in  std_logic;
        rd_data  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty    : out std_logic;

        -- Reset
        reset_n  : in  std_logic
    );
end entity async_fifo;

architecture rtl of async_fifo is
    -- Memory
    type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_type;

    -- Binary pointers
    signal wr_ptr_bin, rd_ptr_bin : unsigned(ADDR_WIDTH downto 0) := (others => '0');
    signal wr_ptr_gray, rd_ptr_gray : std_logic_vector(ADDR_WIDTH downto 0);

    -- Synchronized pointers
    signal wr_ptr_gray_sync1, wr_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0);
    signal rd_ptr_gray_sync1, rd_ptr_gray_sync2 : std_logic_vector(ADDR_WIDTH downto 0);

    -- Converted back to binary
    signal wr_ptr_bin_sync, rd_ptr_bin_sync : unsigned(ADDR_WIDTH downto 0);

begin
    --------------------------------------------------------------------
    -- Write pointer logic (producer domain)
    --------------------------------------------------------------------
    process(wr_clk, reset_n)
    begin
        if reset_n = '0' then
            wr_ptr_bin <= (others => '0');
        elsif rising_edge(wr_clk) then
            if wr_en = '1' and full = '0' then
                ram(to_integer(wr_ptr_bin(ADDR_WIDTH-1 downto 0))) <= wr_data;
                wr_ptr_bin <= wr_ptr_bin + 1;
            end if;
        end if;
    end process;

    -- Convert to Gray
    bin2gray_wr: entity work.bin_to_gray
        generic map (input_width => ADDR_WIDTH+1)
        port map (
            bin_in  => std_logic_vector(wr_ptr_bin),
            gray_out => wr_ptr_gray
        );

    --------------------------------------------------------------------
    -- Read pointer logic (consumer domain)
    --------------------------------------------------------------------
    process(rd_clk, reset_n)
    begin
        if reset_n = '0' then
            rd_ptr_bin <= (others => '0');
            rd_data    <= (others => '0');
        elsif rising_edge(rd_clk) then
            if rd_en = '1' and empty = '0' then
                rd_data <= ram(to_integer(rd_ptr_bin(ADDR_WIDTH-1 downto 0)));
                rd_ptr_bin <= rd_ptr_bin + 1;
            end if;
        end if;
    end process;

    -- Convert to Gray
    bin2gray_rd: entity work.bin_to_gray
        generic map (input_width => ADDR_WIDTH+1)
        port map (
            bin_in  => std_logic_vector(rd_ptr_bin),
            gray_out => rd_ptr_gray
        );

    --------------------------------------------------------------------
    -- Synchronizers
    --------------------------------------------------------------------
    -- Sync read pointer into write domain
    process(wr_clk, reset_n)
    begin
        if reset_n = '0' then
            rd_ptr_gray_sync1 <= (others => '0');
            rd_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(wr_clk) then
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end if;
    end process;

    gray2bin_rd_sync: entity work.gray_to_bin
        generic map (input_width => ADDR_WIDTH+1)
        port map (
            gray_in => rd_ptr_gray_sync2,
            bin_out => std_logic_vector(rd_ptr_bin_sync)
        );

    -- Sync write pointer into read domain
    process(rd_clk, reset_n)
    begin
        if reset_n = '0' then
            wr_ptr_gray_sync1 <= (others => '0');
            wr_ptr_gray_sync2 <= (others => '0');
        elsif rising_edge(rd_clk) then
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end if;
    end process;

    gray2bin_wr_sync: entity work.gray_to_bin
        generic map (input_width => ADDR_WIDTH+1)
        port map (
            gray_in => wr_ptr_gray_sync2,
            bin_out => std_logic_vector(wr_ptr_bin_sync)
        );

    --------------------------------------------------------------------
    -- Status flags
    --------------------------------------------------------------------
    full  <= '1' when (wr_ptr_bin(ADDR_WIDTH downto 0) = (rd_ptr_bin_sync + 2**ADDR_WIDTH)) else '0';
    empty <= '1' when (rd_ptr_bin = wr_ptr_bin_sync) else '0';

end architecture rtl;

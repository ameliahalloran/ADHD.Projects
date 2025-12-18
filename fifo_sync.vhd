library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_sync is
    generic (
        DATA_WIDTH : natural := 12;
        ADDR_WIDTH : natural := 5
    );
    port (
        -- Write clock domain
        wr_clk     : in  std_logic;
        wr_reset_n : in  std_logic;
        wren       : in  std_logic;
        din        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        addr_write : out unsigned(ADDR_WIDTH-1 downto 0);
        addr_read_w: out unsigned(ADDR_WIDTH-1 downto 0);

        -- Read clock domain
        rd_clk     : in  std_logic;
        rd_reset_n : in  std_logic;
        adv        : in  std_logic;
        dout       : out std_logic_vector(DATA_WIDTH-1 downto 0);
        addr_read  : out unsigned(ADDR_WIDTH-1 downto 0);
        addr_write_r: out unsigned(ADDR_WIDTH-1 downto 0)
    );
end entity fifo_sync;

architecture rtl of fifo_sync is

    constant PTR_WIDTH : natural := ADDR_WIDTH + 1;
    constant DEPTH     : natural := 2**ADDR_WIDTH;

    type ram_type is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_type;

    -- Binary pointers
    signal wr_bin, rd_bin : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');

    -- Gray pointers
    signal wr_gray, rd_gray : std_logic_vector(PTR_WIDTH-1 downto 0);

    -- Synchronized Gray pointers
    signal wr_gray_rd1, wr_gray_rd2 : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rd_gray_wr1, rd_gray_wr2 : std_logic_vector(PTR_WIDTH-1 downto 0);

    -- Binary versions of synced pointers
    signal wr_bin_sync, rd_bin_sync : unsigned(PTR_WIDTH-1 downto 0);

    -- Binary → Gray
    function bin2gray(b : unsigned) return std_logic_vector is
    begin
        return std_logic_vector(b xor (b srl 1));
    end function;

    -- Gray → Binary
    function gray2bin(g : std_logic_vector) return unsigned is
        variable b : unsigned(g'range);
    begin
        b(b'high) := g(b'high);
        for i in b'high-1 downto 0 loop
            b(i) := b(i+1) xor g(i);
        end loop;
        return b;
    end function;

begin

    ------------------------------------------------------------------
    -- WRITE DOMAIN
    ------------------------------------------------------------------
    process(wr_clk, wr_reset_n)
    begin
        if wr_reset_n = '0' then
            wr_bin <= (others => '0');
        elsif rising_edge(wr_clk) then
            if wren = '1' then
                ram(to_integer(wr_bin(ADDR_WIDTH-1 downto 0))) <= din;
                wr_bin <= wr_bin + 1;
            end if;
        end if;
    end process;

    wr_gray <= bin2gray(wr_bin);

    ------------------------------------------------------------------
    -- READ DOMAIN
    ------------------------------------------------------------------
    process(rd_clk, rd_reset_n)
    begin
        if rd_reset_n = '0' then
            rd_bin <= (others => '0');
            dout   <= (others => '0');
        elsif rising_edge(rd_clk) then
            if adv = '1' then
                dout <= ram(to_integer(rd_bin(ADDR_WIDTH-1 downto 0)));
                rd_bin <= rd_bin + 1;
            end if;
        end if;
    end process;

    rd_gray <= bin2gray(rd_bin);

    ------------------------------------------------------------------
    -- Pointer Synchronizers
    ------------------------------------------------------------------
    process(rd_clk, rd_reset_n)
    begin
        if rd_reset_n = '0' then
            wr_gray_rd1 <= (others => '0');
            wr_gray_rd2 <= (others => '0');
        elsif rising_edge(rd_clk) then
            wr_gray_rd1 <= wr_gray;
            wr_gray_rd2 <= wr_gray_rd1;
        end if;
    end process;

    process(wr_clk, wr_reset_n)
    begin
        if wr_reset_n = '0' then
            rd_gray_wr1 <= (others => '0');
            rd_gray_wr2 <= (others => '0');
        elsif rising_edge(wr_clk) then
            rd_gray_wr1 <= rd_gray;
            rd_gray_wr2 <= rd_gray_wr1;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Export binary addresses for FSMs
    ------------------------------------------------------------------
    wr_bin_sync <= gray2bin(rd_gray_wr2);
    rd_bin_sync <= gray2bin(wr_gray_rd2);

    addr_write   <= wr_bin(ADDR_WIDTH-1 downto 0);
    addr_read    <= rd_bin(ADDR_WIDTH-1 downto 0);

    addr_read_w  <= wr_bin_sync(ADDR_WIDTH-1 downto 0);
    addr_write_r <= rd_bin_sync(ADDR_WIDTH-1 downto 0);

end architecture rtl;

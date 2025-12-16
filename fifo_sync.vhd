library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_sync is
    generic (
        DATA_WIDTH : natural := 12;
        ADDR_WIDTH : natural := 4
    );
    port (
        -- Write side
        wr_clk   : in  std_logic;
        wr_reset : in  std_logic;
        wr_en    : in  std_logic;
        din      : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Read side
        rd_clk   : in  std_logic;
        rd_reset : in  std_logic;
        rd_en    : in  std_logic;
        dout     : out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- NEW STATUS OUTPUTS
        empty    : out std_logic;
        full     : out std_logic
    );
end entity fifo_sync;

architecture rtl of fifo_sync is

    --------------------------------------------------------------------
    -- FIFO parameters
    --------------------------------------------------------------------
    constant PTR_WIDTH : natural := ADDR_WIDTH + 1;
    constant DEPTH     : natural := 2**ADDR_WIDTH;

    --------------------------------------------------------------------
    -- Memory
    --------------------------------------------------------------------
    type ram_type is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram : ram_type;

    --------------------------------------------------------------------
    -- Pointers (binary + gray)
    --------------------------------------------------------------------
    signal wr_ptr_bin  : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
    signal wr_ptr_gray : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

    signal rd_ptr_bin  : unsigned(PTR_WIDTH-1 downto 0) := (others => '0');
    signal rd_ptr_gray : std_logic_vector(PTR_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Crossed pointers (binary crossing)
    --------------------------------------------------------------------
    signal wr_ptr_bin_sync_to_rd : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rd_ptr_bin_sync_to_wr : std_logic_vector(PTR_WIDTH-1 downto 0);

    -- Convert synced binary pointers back to gray for comparisons
    signal wr_ptr_gray_sync_to_rd : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rd_ptr_gray_sync_to_wr : std_logic_vector(PTR_WIDTH-1 downto 0);

    --------------------------------------------------------------------
    -- Status flags
    --------------------------------------------------------------------
    signal full_flag  : std_logic := '0';
    signal empty_flag : std_logic := '1';

    --------------------------------------------------------------------
    -- Output register
    --------------------------------------------------------------------
    signal dout_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Binary <-> Gray functions
    --------------------------------------------------------------------
    function bin_to_gray_f(b : unsigned) return std_logic_vector is
        variable g : unsigned(b'range);
    begin
        g := (b(b'high) & (b(b'high downto 1) xor b(b'high-1 downto 0)));
        return std_logic_vector(g);
    end function;

    function gray_to_bin_f(g : std_logic_vector) return unsigned is
        variable b : unsigned(g'range);
        variable gv: unsigned(g'range);
    begin
        gv := unsigned(g);
        b(b'high) := gv(gv'high);
        for i in b'high-1 downto 0 loop
            b(i) := b(i+1) xor gv(i);
        end loop;
        return b;
    end function;

begin

    --------------------------------------------------------------------
    -- Cross-domain sync: WRITE pointer into READ domain
    --------------------------------------------------------------------
    wr_ptr_sync_inst : entity work.crossing_addr
        generic map (ADDR_WIDTH => ADDR_WIDTH)
        port map (
            data_in  => std_logic_vector(wr_ptr_bin),   -- FEED BINARY
            data_out => wr_ptr_bin_sync_to_rd,          -- GET BINARY BACK
            clk_a    => wr_clk,
            reset    => wr_reset,
            clk_b    => rd_clk
        );

    wr_ptr_gray_sync_to_rd <= bin_to_gray_f(unsigned(wr_ptr_bin_sync_to_rd));

    --------------------------------------------------------------------
    -- Cross-domain sync: READ pointer into WRITE domain
    --------------------------------------------------------------------
    rd_ptr_sync_inst : entity work.crossing_addr
        generic map (ADDR_WIDTH => ADDR_WIDTH)
        port map (
            data_in  => std_logic_vector(rd_ptr_bin),   -- FEED BINARY
            data_out => rd_ptr_bin_sync_to_wr,          -- GET BINARY BACK
            clk_a    => rd_clk,
            reset    => rd_reset,
            clk_b    => wr_clk
        );

    rd_ptr_gray_sync_to_wr <= bin_to_gray_f(unsigned(rd_ptr_bin_sync_to_wr));

    --------------------------------------------------------------------
    -- WRITE DOMAIN
    --------------------------------------------------------------------
    process(wr_clk, wr_reset)
        variable wr_addr : natural;
        variable wr_ptr_bin_next  : unsigned(PTR_WIDTH-1 downto 0);
        variable wr_ptr_gray_next : std_logic_vector(PTR_WIDTH-1 downto 0);
    begin
        if wr_reset = '1' then
            wr_ptr_bin  <= (others => '0');
            wr_ptr_gray <= (others => '0');
            full_flag   <= '0';

        elsif rising_edge(wr_clk) then

            wr_ptr_bin_next  := wr_ptr_bin;
            wr_ptr_gray_next := wr_ptr_gray;

            if (wr_en = '1') and (full_flag = '0') then
                wr_addr := to_integer(wr_ptr_bin(ADDR_WIDTH-1 downto 0));
                ram(wr_addr) <= din;

                wr_ptr_bin_next := wr_ptr_bin + 1;
                wr_ptr_gray_next := bin_to_gray_f(wr_ptr_bin_next);
            end if;

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

            -- FULL detection
            if (wr_ptr_gray_next(PTR_WIDTH-1 downto PTR_WIDTH-2) =
                    not rd_ptr_gray_sync_to_wr(PTR_WIDTH-1 downto PTR_WIDTH-2)) and
               (wr_ptr_gray_next(PTR_WIDTH-3 downto 0) =
                    rd_ptr_gray_sync_to_wr(PTR_WIDTH-3 downto 0)) then
                full_flag <= '1';
            else
                full_flag <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- READ DOMAIN
    --------------------------------------------------------------------
    process(rd_clk, rd_reset)
        variable rd_addr : natural;
        variable rd_ptr_bin_next  : unsigned(PTR_WIDTH-1 downto 0);
        variable rd_ptr_gray_next : std_logic_vector(PTR_WIDTH-1 downto 0);
    begin
        if rd_reset = '1' then
            rd_ptr_bin  <= (others => '0');
            rd_ptr_gray <= (others => '0');
            empty_flag  <= '1';
            dout_reg    <= (others => '0');

        elsif rising_edge(rd_clk) then

            rd_ptr_bin_next  := rd_ptr_bin;
            rd_ptr_gray_next := rd_ptr_gray;

            if (rd_en = '1') and (empty_flag = '0') then
                rd_addr := to_integer(rd_ptr_bin(ADDR_WIDTH-1 downto 0));
                dout_reg <= ram(rd_addr);

                rd_ptr_bin_next := rd_ptr_bin + 1;
                rd_ptr_gray_next := bin_to_gray_f(rd_ptr_bin_next);
            end if;

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

            -- EMPTY detection
            if wr_ptr_gray_sync_to_rd = rd_ptr_gray_next then
                empty_flag <= '1';
            else
                empty_flag <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    dout  <= dout_reg;
    empty <= empty_flag;
    full  <= full_flag;

end architecture rtl;

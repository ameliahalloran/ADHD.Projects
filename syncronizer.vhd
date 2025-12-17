library ieee;
use ieee.std_logic_1164.all;

entity crossing_addr is
    generic (
        ADDR_WIDTH : natural := 4
    );
    port (
        data_in  : in  std_logic_vector(ADDR_WIDTH downto 0); -- binary
        data_out : out std_logic_vector(ADDR_WIDTH downto 0); -- binary (safe)
        clk_a    : in  std_logic;
        reset    : in  std_logic;
        clk_b    : in  std_logic
    );
end entity crossing_addr;

architecture rtl of crossing_addr is

    signal ptr_gray  : std_logic_vector(ADDR_WIDTH downto 0);
    signal ff_a_out  : std_logic_vector(ADDR_WIDTH downto 0);
    signal ff_b1_out : std_logic_vector(ADDR_WIDTH downto 0);
    signal ff_b2_out : std_logic_vector(ADDR_WIDTH downto 0);

begin

    -- Binary → Gray (SOURCE DOMAIN)
    u_bin2gray : entity work.bin_to_gray
        generic map (input_width => ADDR_WIDTH + 1)
        port map (
            bin_in   => data_in,
            gray_out => ptr_gray
        );

    -- 1st flop (clk_a)
    u_ff_a : entity work.sync_flop
        generic map (WIDTH => ADDR_WIDTH + 1)
        port map (
            clk   => clk_a,
            reset => reset,
            din   => ptr_gray,
            dout  => ff_a_out
        );

    -- 2nd flop (clk_b)
    u_ff_b1 : entity work.sync_flop
        generic map (WIDTH => ADDR_WIDTH + 1)
        port map (
            clk   => clk_b,
            reset => reset,
            din   => ff_a_out,
            dout  => ff_b1_out
        );

    -- 3rd flop (clk_b)
    u_ff_b2 : entity work.sync_flop
        generic map (WIDTH => ADDR_WIDTH + 1)
        port map (
            clk   => clk_b,
            reset => reset,
            din   => ff_b1_out,
            dout  => ff_b2_out
        );

    -- Gray → Binary (DESTINATION DOMAIN)
    u_gray2bin : entity work.gray_to_bin
        generic map (input_width => ADDR_WIDTH + 1)
        port map (
            gray_in => ff_b2_out,
            bin_out => data_out
        );

end architecture rtl;

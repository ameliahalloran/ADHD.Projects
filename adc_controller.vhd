library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_controller is
    port (
        pll_clk  : in  std_logic;
        reset_n  : in  std_logic;
        tsen     : in  std_logic;
        fifo_din : out std_logic_vector(11 downto 0);
        fifo_wr  : out std_logic;
        clk_dft  : out std_logic
    );
end entity adc_controller;

architecture rtl of adc_controller is
    signal soc_sig, eoc_sig : std_logic;
    signal dout_sig         : natural range 0 to 4095;
    signal data_valid_sig   : std_logic;
    signal data_out_sig     : natural range 0 to 4095;
    signal clk_dft_sig      : std_logic;
begin

    adc_inst : entity work.max10_adc
        port map (
            pll_clk => pll_clk,
            chsel   => 17,
            soc     => soc_sig,
            tsen    => tsen,
            dout    => dout_sig,
            eoc     => eoc_sig,
            clk_dft => clk_dft_sig
        );

    clk_dft <= clk_dft_sig;

    fsm_inst : entity work.adc_fsm1
        port map (
            clock        => pll_clk,
            reset_n    => reset_n,
            --start      => '1',
            eoc        => eoc_sig,
            soc        => soc_sig,
				
            data_valid => data_valid_sig,
            data_out1  => data_out_sig
        );

    fifo_din <= std_logic_vector(to_unsigned(data_out_sig, 12));
    fifo_wr  <= data_valid_sig;

end architecture rtl;

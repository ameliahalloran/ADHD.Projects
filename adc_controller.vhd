library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_controller is
    port (
        pll_clk   : in  std_logic;  -- 10 MHz input clock
        reset_n   : in  std_logic;
        tsen      : in  std_logic;  -- temperature sensing mode
        fifo_din  : out natural range 0 to 2**12 - 1;
        fifo_wr   : out std_logic;  -- write enable to FIFO
        clk_dft   : out std_logic   -- derived ADC clock
    );
end entity adc_controller;

architecture rtl of adc_controller is
    signal soc_sig, eoc_sig : std_logic;
    signal dout_sig         : natural range 0 to 2**12 - 1;
    signal data_valid_sig   : std_logic;
    signal data_out_sig     : natural range 0 to 2**12 - 1;
	 signal clk_dft_sig		 : std_logic;
begin
    -- Instantiate ADC wrapper
    adc_inst: entity work.max10_adc
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
	 
    -- Instantiate FSM
    fsm_inst: entity work.adc_fsm1
        port map (
            clk       => pll_clk,
            reset_n   => reset_n,
            start     => '1',         -- always trigger conversions
            eoc       => eoc_sig,
            dout      => dout_sig,
            soc       => soc_sig,
            data_valid=> data_valid_sig,
            data_out1  => data_out_sig
        );

    -- Connect to FIFO
    fifo_din <= data_out_sig;
    fifo_wr  <= data_valid_sig;
end architecture rtl;

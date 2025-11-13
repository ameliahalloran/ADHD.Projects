library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

library work;
use work.color_data.all;

entity mandelbrot_pbm_tb is
end entity;

architecture tb of mandelbrot_pbm_tb is
    constant WIDTH  : integer := 64;
    constant HEIGHT : integer := 48;
    constant MAX_ITER : natural := 16;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal c_val     : ads_complex;
    signal c_valid   : boolean := false;
    signal iter_out  : natural range 0 to MAX_ITER := 0;
    signal iter_valid: boolean := false;

    signal color_out : rgb_color;
    signal color_valid : boolean := false;

    file pbm_file : text open write_mode is "out_mandelbrot_64x48.pbm";

    component mandelbrot_pipeline
        generic ( max_iterations : natural );
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            c_in       : in  ads_complex;
            c_valid    : in  boolean;
            iter_out   : out natural range 0 to max_iterations;
            iter_valid : out boolean
        );
    end component;

    component color_mapper
        generic ( max_iterations : natural );
        port (
            clock       : in  std_logic;
            reset       : in  std_logic;
            iter_count  : in  natural range 0 to max_iterations;
            iter_valid  : in  boolean;
            color_out   : out rgb_color;
            color_valid : out boolean;
            palette_sel : in  natural range 0 to 3
        );
    end component;

begin
    clk <= not clk after 10 ns;

    dut_pipeline: mandelbrot_pipeline
        generic map ( max_iterations => MAX_ITER )
        port map (
            clock      => clk,
            reset      => reset,
            c_in       => c_val,
            c_valid    => c_valid,
            iter_out   => iter_out,
            iter_valid => iter_valid
        );

    dut_color: color_mapper
        generic map ( max_iterations => MAX_ITER )
        port map (
            clock       => clk,
            reset       => reset,
            iter_count  => iter_out,
            iter_valid  => iter_valid,
            color_out   => color_out,
            color_valid => color_valid,
            palette_sel => 0
        );

    process
        variable L : line;
        variable x, y : integer;
        variable r_scaled : integer;
        variable tmp_c : ads_complex;
    begin
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        write(L, string'("P1"));
        writeline(pbm_file, L);
        write(L, string'(integer'image(WIDTH) & " " & integer'image(HEIGHT)));
        writeline(pbm_file, L);

        for y in 0 to HEIGHT - 1 loop
            for x in 0 to WIDTH - 1 loop
                tmp_c.re := to_ads_sfixed(-2.0 + 3.0 * real(x) / real(WIDTH));
                tmp_c.im := to_ads_sfixed(-1.5 + 3.0 * real(y) / real(HEIGHT));
                c_val <= tmp_c;
                c_valid <= true;
                wait for 20 ns;
                c_valid <= false;

                wait until iter_valid = true;
                r_scaled := color_out.red;

                if r_scaled > 7 then
                    write(L, string'("1 "));
                else
                    write(L, string'("0 "));
                end if;
            end loop;
            writeline(pbm_file, L);
        end loop;

        wait for 100 ns;
        report "Mandelbrot PBM image written to out_mandelbrot_64x48.pbm";
        wait;
    end process;
end architecture;

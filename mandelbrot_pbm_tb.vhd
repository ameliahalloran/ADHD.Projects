library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

library work;
use work.color_data.all;

entity complete_fractal_tb is
end entity;

architecture tb of complete_fractal_tb is
    constant WIDTH  : integer := 320;
    constant HEIGHT : integer := 240;
    constant MAX_ITER : natural := 16;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    
    signal julia_mode : std_logic := '0';
    signal julia_c    : ads_complex;

    signal seed_val   : ads_complex;
    signal seed_valid : boolean := false;
    signal iter_out   : natural range 0 to MAX_ITER := 0;
    signal iter_valid : boolean := false;

    signal color_out   : rgb_color;
    signal color_valid : boolean := false;

    component mandelbrot_pipeline
        generic ( max_iterations : natural );
        port (
            clock      : in  std_logic;
            reset      : in  std_logic;
            julia_mode : in  std_logic;
            julia_c    : in  ads_complex;
            seed_in    : in  ads_complex;
            seed_valid : in  boolean;
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
            julia_mode => julia_mode,
            julia_c    => julia_c,
            seed_in    => seed_val,
            seed_valid => seed_valid,
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
        variable tmp_seed : ads_complex;
        file out_file : text;
        
        -- Procedure to generate Mandelbrot set
        procedure generate_mandelbrot is
        begin
            report "=== Generating Mandelbrot set (320x240) ===";
            file_open(out_file, "mandelbrot_320x240.pbm", write_mode);
            
            -- Set mode
            julia_mode <= '0';
            wait for 100 ns;
            
            -- PBM header (P1 = ASCII black and white)
            write(L, string'("P1"));
            writeline(out_file, L);
            write(L, WIDTH);
            write(L, string'(" "));
            write(L, HEIGHT);
            writeline(out_file, L);
            
            -- Generate each pixel
            for y in 0 to HEIGHT - 1 loop
                for x in 0 to WIDTH - 1 loop
                    -- Map to Mandelbrot window: Re[-2.2, 1.0], Im[-1.2, 1.2]
                    tmp_seed.re := to_ads_sfixed(-2.2 + 3.2 * real(x) / real(WIDTH));
                    tmp_seed.im := to_ads_sfixed(1.2 - 2.4 * real(y) / real(HEIGHT));
                    
                    seed_val <= tmp_seed;
                    seed_valid <= true;
                    wait for 20 ns;
                    seed_valid <= false;
                    
                    -- Wait for pipeline result
                    wait until iter_valid = true;
                    wait for 20 ns;
                    
                    -- Write pixel: 0 = black (in set), 1 = white (escaped)
                    if iter_out = MAX_ITER then
                        write(L, string'("0 "));
                    else
                        write(L, string'("1 "));
                    end if;
                end loop;
                writeline(out_file, L);
                
                -- Progress indicator
                if y mod 24 = 0 then
                    report "  Progress: " & integer'image(y * 100 / HEIGHT) & "%";
                end if;
            end loop;
            
            file_close(out_file);
            report "=== Mandelbrot complete! ===";
        end procedure;
        
        -- Procedure to generate Julia set
        procedure generate_julia(
            filename: string; 
            c_re: real; 
            c_im: real;
            description: string
        ) is
        begin
            report "=== Generating " & description & " ===";
            file_open(out_file, filename, write_mode);
            
            -- Set Julia mode and constant
            julia_mode <= '1';
            julia_c <= ads_cmplx(to_ads_sfixed(c_re), to_ads_sfixed(c_im));
            wait for 100 ns;
            
            -- PBM header
            write(L, string'("P1"));
            writeline(out_file, L);
            write(L, WIDTH);
            write(L, string'(" "));
            write(L, HEIGHT);
            writeline(out_file, L);
            
            -- Generate each pixel
            for y in 0 to HEIGHT - 1 loop
                for x in 0 to WIDTH - 1 loop
                    -- Map to Julia window: Re[-2.0, 2.0], Im[-1.5, 1.5]
                    tmp_seed.re := to_ads_sfixed(-2.0 + 4.0 * real(x) / real(WIDTH));
                    tmp_seed.im := to_ads_sfixed(1.5 - 3.0 * real(y) / real(HEIGHT));
                    
                    seed_val <= tmp_seed;
                    seed_valid <= true;
                    wait for 20 ns;
                    seed_valid <= false;
                    
                    -- Wait for pipeline result
                    wait until iter_valid = true;
                    wait for 20 ns;
                    
                    -- Write pixel
                    if iter_out = MAX_ITER then
                        write(L, string'("0 "));
                    else
                        write(L, string'("1 "));
                    end if;
                end loop;
                writeline(out_file, L);
                
                -- Progress indicator
                if y mod 24 = 0 then
                    report "  Progress: " & integer'image(y * 100 / HEIGHT) & "%";
                end if;
            end loop;
            
            file_close(out_file);
            report "=== " & description & " complete! ===";
        end procedure;
        
    begin
        -- Reset
        wait for 100 ns;
        reset <= '0';
        wait for 200 ns;
        
        report "Starting Fractal Image Generation";
        report "Resolution: 320x240";
        report "Max Iterations: 16";
        
        -- 1. Generate Mandelbrot set
        generate_mandelbrot;
        wait for 1 us;
        
        -- 2. Generate Julia set #1: c = -0.6 + 0.5i 
        generate_julia(
            "julia1_320x240.pbm", 
            -0.6, 0.5,
            "Julia set #1 (c = -0.6 + 0.5i)"
        );
        wait for 1 us;
        
        -- 3. Generate Julia set #2: c = -0.8 + 0.2i
        generate_julia(
            "julia2_320x240.pbm", 
            -0.8, 0.2,
            "Julia set #2 (c = -0.8 + 0.2i)"
        );
        wait for 1 us;
        
        -- 4. Generate Julia set #3: c = -0.4 + 0.6i
        generate_julia(
            "julia3_320x240.pbm", 
            -0.4, 0.6,
            "Julia set #3 (c = -0.4 + 0.6i)"
        );
        wait for 1 us;

                              
        report "IMAGES GENERATED SUCCESSFULLY!";
        report "Files created:";
        report "  1. mandelbrot_320x240.pbm";
        report "  2. julia1_320x240.pbm (c = -0.6 + 0.5i)";
        report "  3. julia2_320x240.pbm (c = -0.8 + 0.2i)";
        report "  4. julia3_320x240.pbm (c = -0.4 + 0.6i)";

        wait;
    end process;

end architecture;

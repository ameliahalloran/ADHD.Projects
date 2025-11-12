library ieee;
use ieee.std_logic_1164.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

entity mandelbrot_stage is
    generic (
        stage_number: natural := 0;  -- Which stage in the pipeline (0 to N-1)
        max_iterations: natural := 16;  -- Total number of stages
        threshold: ads_sfixed := to_ads_sfixed(4.0)  -- Threshold for |z|² (use 4 since we check |z|² > 4 instead of |z| > 2)
    );
    port (
        clock:          in  std_logic;
        reset:          in  std_logic;
        
        -- Inputs from previous stage (or initial values for stage 0)
        z_in:           in  ads_complex;
        c_in:           in  ads_complex;
        escaped_in:     in  boolean;
        escape_iter_in: in  natural range 0 to max_iterations;
        
        -- Outputs to next stage
        z_out:          out ads_complex;
        c_out:          out ads_complex;
        escaped_out:    out boolean;
        escape_iter_out: out natural range 0 to max_iterations
    );
end entity mandelbrot_stage;

architecture rtl of mandelbrot_stage is
    -- Internal signals for registered values
    signal z_reg:           ads_complex;
    signal c_reg:           ads_complex;
    signal escaped_reg:     boolean;
    signal escape_iter_reg: natural range 0 to max_iterations;
    
begin
    process(clock, reset)
        --variable z_squared: ads_complex;
		  variable re_re, im_im, re_im: ads_sfixed;
        variable z_next: ads_complex;
        variable magnitude_sq: ads_sfixed;
        variable has_escaped: boolean;
    begin
        if reset = '0' then  -- Active-low reset
            z_reg <= complex_zero;
            c_reg <= complex_zero;
            escaped_reg <= false;
            escape_iter_reg <= max_iterations;
            
        elsif rising_edge(clock) then
            -- Register the c value (it passes through unchanged)
            c_reg <= c_in;
            
            -- If already escaped in previous stage, just pass through
            if escaped_in then
                z_reg <= z_in;  -- Don't compute, just pass through
                escaped_reg <= true;
                escape_iter_reg <= escape_iter_in;
            else
                -- Compute z² + c
                --z_squared := ads_square(z_in);
					 re_re := z_in.re * z_in.re;
					 im_im := z_in.im * z_in.im;
					 re_im := z_in.re * z_in.im;
					 z_next.re := re_re - im_im + c_in.re;
					 z_next.im := re_im + re_im + c_in.im;
                -- z_next := z_squared + c_in;
                z_reg <= z_next;
                
                -- Check if |z|² > threshold
                magnitude_sq := re_re + im_im;-- abs2(z_next);
                has_escaped := magnitude_sq > threshold;
                
                if has_escaped then
                    escaped_reg <= true;
                    escape_iter_reg <= stage_number;  -- Record which stage we escaped at
                else
                    escaped_reg <= false;
                    escape_iter_reg <= max_iterations;  -- Still iterating
                end if;
            end if;
        end if;
    end process;
    
    -- Output assignments
    z_out <= z_reg;
    c_out <= c_reg;
    escaped_out <= escaped_reg;
    escape_iter_out <= escape_iter_reg;
    
end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

library vga;
use vga.vga_data.all;

entity coordinate_mapper is
    generic (
        -- Mandelbrot viewing window
        mandel_re_min: real := -2.2;
        mandel_re_max: real := 1.0;
        mandel_im_min: real := -1.2;
        mandel_im_max: real := 1.2;
        
        -- Julia/Fatou viewing window (centered on origin)
        julia_re_min: real := -2.0;
        julia_re_max: real := 2.0;
        julia_im_min: real := -1.5;
        julia_im_max: real := 1.5;
        
        screen_width: natural := 640;
        screen_height: natural := 480
    );
    port (
        clock:      in  std_logic;
        reset:      in  std_logic;
        
        -- Mode selection
        julia_mode: in  std_logic;  -- '1' for Julia, '0' for Mandelbrot
        
        -- Screen coordinates
        point:      in  coordinate;
        point_valid: in boolean;
        
        -- Complex plane coordinates
        c_out:      out ads_complex;
        c_valid:    out boolean
    );
end entity coordinate_mapper;

architecture rtl of coordinate_mapper is
    signal c_reg: ads_complex;
    signal valid_reg: boolean;
    
begin
    process(clock, reset)
        variable x_norm: real;
        variable y_norm: real;
        variable re_val: real;
        variable im_val: real;
        variable re_min, re_max, im_min, im_max: real;
        variable re_range, im_range: real;
    begin
        if reset = '0' then
            c_reg <= complex_zero;
            valid_reg <= false;
            
        elsif rising_edge(clock) then
            if point_valid then
                -- Select viewing window based on mode
                if julia_mode = '1' then
                    re_min := julia_re_min;
                    re_max := julia_re_max;
                    im_min := julia_im_min;
                    im_max := julia_im_max;
                else
                    re_min := mandel_re_min;
                    re_max := mandel_re_max;
                    im_min := mandel_im_min;
                    im_max := mandel_im_max;
                end if;
                
                re_range := re_max - re_min;
                im_range := im_max - im_min;
                
                -- Normalize coordinates to [0, 1]
                x_norm := real(point.x) / real(screen_width);
                y_norm := real(point.y) / real(screen_height);
                
                -- Map to complex plane
                re_val := re_min + x_norm * re_range;
                im_val := im_max - y_norm * im_range;  -- Invert y-axis
                
                -- Convert to fixed-point
                c_reg.re <= to_ads_sfixed(re_val);
                c_reg.im <= to_ads_sfixed(im_val);
                valid_reg <= true;
            else
                valid_reg <= false;
            end if;
        end if;
    end process;
    
    c_out <= c_reg;
    c_valid <= valid_reg;
    
end architecture rtl;
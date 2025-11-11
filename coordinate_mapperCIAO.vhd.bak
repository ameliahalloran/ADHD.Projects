library ieee;
use ieee.std_logic_1164.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

library vga;
use vga.vga_data.all;

entity coordinate_mapper is
    generic (
        -- Viewing window for Mandelbrot set
        -- Default: Re(c) ∈ [-2.2, 1.0], Im(c) ∈ [-1.2, 1.2]
        re_min: real := -2.2;
        re_max: real := 1.0;
        im_min: real := -1.2;
        im_max: real := 1.2;
        
        -- Screen resolution
        screen_width: natural := 640;
        screen_height: natural := 480
    );
    port (
        clock:      in  std_logic;
        reset:      in  std_logic;
        
        -- Screen coordinates
        point:      in  coordinate;
        point_valid: in boolean;
        
        -- Complex plane coordinates
        c_out:      out ads_complex;
        c_valid:    out boolean
    );
end entity coordinate_mapper;

architecture rtl of coordinate_mapper is
    -- Precompute scaling factors
    constant re_range: real := re_max - re_min;  -- 3.2 for default
    constant im_range: real := im_max - im_min;  -- 2.4 for default
    
    -- Scaling: re = re_min + (x / width) * re_range
    --          im = im_max - (y / height) * im_range  (y inverted)
    
    signal c_reg: ads_complex;
    signal valid_reg: boolean;
    
begin
    process(clock, reset)
        variable x_norm: real;  -- Normalized x: 0.0 to 1.0
        variable y_norm: real;  -- Normalized y: 0.0 to 1.0
        variable re_val: real;
        variable im_val: real;
    begin
        if reset = '0' then
            c_reg <= complex_zero;
            valid_reg <= false;
            
        elsif rising_edge(clock) then
            if point_valid then
                -- Normalize coordinates to [0, 1]
                x_norm := real(point.x) / real(screen_width);
                y_norm := real(point.y) / real(screen_height);
                
                -- Map to complex plane
                -- Re(c) = re_min + x_norm * re_range
                re_val := re_min + x_norm * re_range;
                
                -- Im(c) = im_max - y_norm * im_range (invert y-axis)
                im_val := im_max - y_norm * im_range;
                
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
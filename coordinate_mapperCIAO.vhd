library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        clock:       in  std_logic;
        reset:       in  std_logic;
        
        -- Screen coordinates
        point:       in  coordinate;
        point_valid: in  boolean;
        
        -- Complex plane coordinates
        c_out:       out ads_complex;
        c_valid:     out boolean
    );
end entity coordinate_mapper;


architecture rtl of coordinate_mapper is
    -- Convert viewing window constants to fixed-point
    constant re_min_fx   : ads_sfixed := to_ads_sfixed(re_min);
    constant re_max_fx   : ads_sfixed := to_ads_sfixed(re_max);
    constant im_min_fx   : ads_sfixed := to_ads_sfixed(im_min);
    constant im_max_fx   : ads_sfixed := to_ads_sfixed(im_max);

    -- Precompute scaling factors
    constant re_range_fx : ads_sfixed := to_ads_sfixed(re_max - re_min);  -- 3.2 for default
    constant im_range_fx : ads_sfixed := to_ads_sfixed(im_max - im_min);  -- 2.4 for default

    -- Scaling: re = re_min + (x / width) * re_range
    --          im = im_max - (y / height) * im_range  (y inverted)

    signal c_reg: ads_complex;
    signal valid_reg: boolean;

begin
    process(clock, reset)
        -- Fixed-point equivalents
        variable x_fx, y_fx     : ads_sfixed;
        variable w_fx, h_fx     : ads_sfixed;
        variable x_norm, y_norm : ads_sfixed;
        variable re_val, im_val : ads_sfixed;
    begin
        if reset = '0' then
            c_reg <= complex_zero;
            valid_reg <= false;

        elsif rising_edge(clock) then
            if point_valid then
                -- Convert pixel coordinates and screen dimensions to fixed-point
                x_fx := to_ads_sfixed(point.x);
                y_fx := to_ads_sfixed(point.y);
                w_fx := to_ads_sfixed(screen_width);
                h_fx := to_ads_sfixed(screen_height);

                -- Normalize coordinates to [0, 1]
                x_norm := x_fx / w_fx;
                y_norm := y_fx / h_fx;

                -- Map to complex plane
                -- Re(c) = re_min + x_norm * re_range
                re_val := re_min_fx + (x_norm * re_range_fx);

                -- Im(c) = im_max - y_norm * im_range (invert y-axis)
                im_val := im_max_fx - (y_norm * im_range_fx);

                -- Assign to output complex
                c_reg.re <= re_val;
                c_reg.im <= im_val;
                valid_reg <= true;
            else
                valid_reg <= false;
            end if;
        end if;
    end process;

    c_out   <= c_reg;
    c_valid <= valid_reg;

end architecture rtl;

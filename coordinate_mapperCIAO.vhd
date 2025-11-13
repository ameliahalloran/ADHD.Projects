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
        -- Mandelbrot view window
        re_min: real := -2.2;
        re_max: real := 1.0;
        im_min: real := -1.2;
        im_max: real := 1.2;

        -- Julia view window
        julia_re_min: real := -1.5;
        julia_re_max: real := 1.5;
        julia_im_min: real := -1.5;
        julia_im_max: real := 1.5;

        -- Screen resolution
        screen_width:  natural := 640;
        screen_height: natural := 480
    );
    port (
        clock:       in  std_logic;
        reset:       in  std_logic;

        -- '0' = Mandelbrot window, '1' = Julia window
        julia_mode:  in  std_logic;

        -- Screen coordinates from VGA FSM
        point:       in  coordinate;
        point_valid: in  boolean;

        -- Mapped complex coordinate (used as c or z0 depending on mode)
        c_out:       out ads_complex;
        c_valid:     out boolean
    );
end entity coordinate_mapper;

architecture rtl of coordinate_mapper is

    signal re_min_fx, re_max_fx : ads_sfixed;
    signal im_min_fx, im_max_fx : ads_sfixed;
    signal re_range_fx, im_range_fx : ads_sfixed;

    signal c_reg     : ads_complex;
    signal valid_reg : boolean;

begin
    -- Select viewport based on mode
    process(julia_mode)
    begin
        if julia_mode = '1' then
            -- Julia window (centered around origin)
            re_min_fx <= to_ads_sfixed(julia_re_min);
            re_max_fx <= to_ads_sfixed(julia_re_max);
            im_min_fx <= to_ads_sfixed(julia_im_min);
            im_max_fx <= to_ads_sfixed(julia_im_max);
        else
            -- Mandelbrot window
            re_min_fx <= to_ads_sfixed(re_min);
            re_max_fx <= to_ads_sfixed(re_max);
            im_min_fx <= to_ads_sfixed(im_min);
            im_max_fx <= to_ads_sfixed(im_max);
        end if;
    end process;

    re_range_fx <= re_max_fx - re_min_fx;
    im_range_fx <= im_max_fx - im_min_fx;

    process(clock, reset)
        variable x_fx, y_fx     : ads_sfixed;
        variable w_fx, h_fx     : ads_sfixed;
        variable x_norm, y_norm : ads_sfixed;
        variable re_val, im_val : ads_sfixed;
    begin
        if reset = '0' then
            c_reg     <= complex_zero;
            valid_reg <= false;

        elsif rising_edge(clock) then
            if point_valid then
                -- Convert pixel coords to fixed point
                x_fx := to_ads_sfixed(point.x);
                y_fx := to_ads_sfixed(point.y);
                w_fx := to_ads_sfixed(screen_width);
                h_fx := to_ads_sfixed(screen_height);

                -- Normalize to [0,1]
                x_norm := x_fx / w_fx;
                y_norm := y_fx / h_fx;

                -- Map to complex plane
                re_val := re_min_fx + (x_norm * re_range_fx);
                -- Flip Y axis so top of screen is max imag
                im_val := im_max_fx - (y_norm * im_range_fx);

                c_reg     <= (re => re_val, im => im_val);
                valid_reg <= true;
            else
                valid_reg <= false;
            end if;
        end if;
    end process;

    c_out   <= c_reg;
    c_valid <= valid_reg;

end architecture rtl;
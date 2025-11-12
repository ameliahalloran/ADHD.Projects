--Top level entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

library vga;
use vga.vga_data.all;

library work;
use work.color_data.all;
use work.julia_constants.all;

entity ADSHDproj2CIAOv2 is
	generic (
		vga_res: vga_timing := vga_res_default
	);
    port (
        -- Clock and reset
        clk_50mhz:      in  std_logic;  -- 50 MHz board clock
        reset_n:        in  std_logic;  -- Active-low reset button
        
        -- VGA outputs
		  color_out:		out rgb_color;
        vga_hs:         out std_logic;
        vga_vs:         out std_logic;
        
        -- Control inputs
        sw:             in  std_logic_vector(9 downto 0)  -- Switches
    );
end entity ADSHDproj2CIAOv2;

architecture structural of ADSHDproj2CIAOv2 is
    -- Constants
    constant MAX_ITER: natural := 16;
    
    -- Component declarations
    component vga_fsm is
        generic (
            vga_res: vga_timing := vga_res_default
        );
        port (
            vga_clock:      in  std_logic;
            reset:          in  std_logic;
            point:          out coordinate;
            point_valid:    out boolean;
            h_sync:         out std_logic;
            v_sync:         out std_logic
        );
    end component;
    
    component coordinate_mapper is
        generic (
            re_min: real;
            re_max: real;
            im_min: real;
            im_max: real;
            screen_width: natural;
            screen_height: natural
        );
        port (
            clock:      in  std_logic;
            reset:      in  std_logic;
            point:      in  coordinate;
            point_valid: in boolean;
            c_out:      out ads_complex;
            c_valid:    out boolean
        );
    end component;
    
    component mandelbrot_pipeline is
        generic (
            max_iterations: natural
        );
        port (
            clock:      in  std_logic;
            reset:      in  std_logic;
            c_in:       in  ads_complex;
            c_valid:    in  boolean;
            iter_out:   out natural range 0 to max_iterations;
            iter_valid: out boolean
        );
    end component;
    
    component julia_pipeline is
        generic (
            max_iterations: natural
        );
        port (
            clock:      in  std_logic;
            reset:      in  std_logic;
            julia_c:    in  ads_complex;
            z_in:       in  ads_complex;
            z_valid:    in  boolean;
            iter_out:   out natural range 0 to max_iterations;
            iter_valid: out boolean
        );
    end component;
    
    component color_mapper is
        generic (
            max_iterations: natural
        );
        port (
            clock:          in  std_logic;
            reset:          in  std_logic;
            iter_count:     in  natural range 0 to max_iterations;
            iter_valid:     in  boolean;
            color_out:      out rgb_color;
            color_valid:    out boolean;
            palette_sel:    in  natural range 0 to 3
        );
    end component;
    
    -- Signals
    signal vga_clock: std_logic;
    signal pll_locked: std_logic;
    
    signal current_point: coordinate;
    signal point_is_valid: boolean;
    
    signal c_value: ads_complex;
    signal c_is_valid: boolean;
    
    signal iteration_count: natural range 0 to MAX_ITER;
    signal iter_is_valid: boolean;
    
    signal pixel_color: rgb_color;
    signal color_is_valid: boolean;
    
    signal fractal_select: std_logic;
    
    signal julia_seed: ads_complex;
    signal julia_valid: boolean;
    signal julia_iter: natural range 0 to MAX_ITER;
    signal julia_iter_valid: boolean;
    signal julia_c_value: ads_complex;
    signal selected_iter: natural range 0 to MAX_ITER;
    signal selected_valid: boolean;
    
    -- PLL component
    component pll is
        port (
            inclk0 : in  std_logic;
            c0     : out std_logic
        );
    end component;

begin
    -- Fractal selection from SW9
    fractal_select <= sw(9);
    
    -- ADD THIS: Select Julia constant from SW1-SW0
    julia_c_value <= get_julia_c(to_integer(unsigned(sw(1 downto 0))));
    
    -- PLL: Generate 25.175 MHz VGA clock from 50 MHz input
    pll_inst: pll
        port map (
            inclk0   => clk_50mhz,
            c0 => vga_clock
        );
    
    -- VGA signal generator
    vga_inst: vga_fsm
        generic map (
            vga_res => vga_res
        )
        port map (
            vga_clock   => vga_clock,
            reset       => reset_n,
            point       => current_point,
            point_valid => point_is_valid,
            h_sync      => vga_hs,
            v_sync      => vga_vs
        );
    
    -- Coordinate mapper (screen to complex plane) - MANDELBROT
    coord_map_inst: coordinate_mapper
        generic map (
            re_min => -2.2,
            re_max => 1.0,
            im_min => -1.2,
            im_max => 1.2,
            screen_width => vga_res.horizontal.active,
            screen_height => vga_res.vertical.active
        )
        port map (
            clock       => vga_clock,
            reset       => reset_n,
            point       => current_point,
            point_valid => point_is_valid,
            c_out       => c_value,
            c_valid     => c_is_valid
        );
    
    -- Coordinate mapper for JULIA (centered window)
    julia_coord_map: coordinate_mapper
        generic map (
            re_min => -2.0,
            re_max => 2.0,
            im_min => -1.5,
            im_max => 1.5,
            screen_width => vga_res.horizontal.active,
            screen_height => vga_res.vertical.active
        )
        port map (
            clock       => vga_clock,
            reset       => reset_n,
            point       => current_point,
            point_valid => point_is_valid,
            c_out       => julia_seed,
            c_valid     => julia_valid
        );
    
    -- Mandelbrot/Julia pipeline
    pipeline_inst: mandelbrot_pipeline
        generic map (
            max_iterations => MAX_ITER
        )
        port map (
            clock      => vga_clock,
            reset      => reset_n,
            c_in       => c_value,
            c_valid    => c_is_valid,
            iter_out   => iteration_count,
            iter_valid => iter_is_valid
        );
    
    -- Julia pipeline
    julia_pipe_inst: julia_pipeline
        generic map (
            max_iterations => MAX_ITER
        )
        port map (
            clock      => vga_clock,
            reset      => reset_n,
            julia_c    => julia_c_value,
            z_in       => julia_seed,
            z_valid    => julia_valid,
            iter_out   => julia_iter,
            iter_valid => julia_iter_valid
        );
    
    -- Mux to select between Mandelbrot and Julia outputs
    selected_iter <= julia_iter when fractal_select = '1' else iteration_count;
    selected_valid <= julia_iter_valid when fractal_select = '1' else iter_is_valid;
    
    -- Color mapper - CHANGE iter_count and iter_valid to use selected signals
    color_map_inst: color_mapper
        generic map (
            max_iterations => MAX_ITER
        )
        port map (
            clock       => vga_clock,
            reset       => reset_n,
            iter_count  => selected_iter,      -- CHANGED
            iter_valid  => selected_valid,     -- CHANGED
            color_out   => pixel_color,
            color_valid => color_is_valid,
            palette_sel => 0
        );
    
    -- Output RGB values
    -- When color is valid and in visible area, output the color
    -- Otherwise output black
    process(vga_clock, reset_n)
    begin
        if reset_n = '0' then
				color_out <= color_black;
        elsif rising_edge(vga_clock) then
            if color_is_valid then
					color_out <= pixel_color;
            else
                -- Output black during blanking intervals
					 color_out <= color_black;
            end if;
        end if;
    end process;
    
end architecture structural;
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
        clk_50mhz:      in  std_logic;
        reset_n:        in  std_logic;
        
        -- VGA outputs
        color_out:      out rgb_color;
        vga_hs:         out std_logic;
        vga_vs:         out std_logic;
        
        -- Control inputs
        sw:             in  std_logic_vector(9 downto 0)
    );
end entity ADSHDproj2CIAOv2;

architecture structural of ADSHDproj2CIAOv2 is
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
            julia_re_min: real;
            julia_re_max: real;
            julia_im_min: real;
            julia_im_max: real;
            screen_width: natural;
            screen_height: natural
        );
        port (
            clock:      in  std_logic;
            reset:      in  std_logic;
            julia_mode: in  std_logic;
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
            clock:          in  std_logic;
            reset:          in  std_logic;
            julia_mode:     in  std_logic;
            julia_c:        in  ads_complex;
            seed_in:        in  ads_complex;
            seed_valid:     in  boolean;
            iter_out:       out natural range 0 to max_iterations;
            iter_valid:     out boolean
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
    
    component pll is
        port (
            inclk0 : in  std_logic;
            c0     : out std_logic
        );
    end component;
    
    -- Signals
    signal vga_clock:       std_logic;
    signal current_point:   coordinate;
    signal point_is_valid:  boolean;
    signal seed_value:      ads_complex;
    signal seed_is_valid:   boolean;
    signal iteration_count: natural range 0 to MAX_ITER;
    signal iter_is_valid:   boolean;
    signal pixel_color:     rgb_color;
    signal color_is_valid:  boolean;
    
    -- Mode control
    signal julia_mode:      std_logic;
    signal julia_c_sel:     natural range 0 to 3;
    signal julia_c_value:   ads_complex;
    
begin
    -- Control signals from switches
    julia_mode <= sw(9);                              -- SW9: 0=Mandelbrot, 1=Julia/Fatou
    julia_c_sel <= to_integer(unsigned(sw(1 downto 0)));  -- SW1-SW0: Select Julia constant
    
    -- Select Julia constant based on switches
    julia_c_value <= get_julia_c(julia_c_sel);
    
    -- PLL: 25.175 MHz from 50 MHz
    pll_inst: pll
        port map (
            inclk0 => clk_50mhz,
            c0     => vga_clock
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
    
    -- Coordinate mapper with dual viewing windows
    coord_map_inst: coordinate_mapper
        generic map (
            -- Mandelbrot window
            re_min => -2.2,
            re_max => 1.0,
            im_min => -1.2,
            im_max => 1.2,
            -- Julia window (centered on origin)
            julia_re_min => -2.0,
            julia_re_max => 2.0,
            julia_im_min => -1.5,
            julia_im_max => 1.5,
            screen_width => vga_res.horizontal.active,
            screen_height => vga_res.vertical.active
        )
        port map (
            clock       => vga_clock,
            reset       => reset_n,
            julia_mode  => julia_mode,
            point       => current_point,
            point_valid => point_is_valid,
            c_out       => seed_value,
            c_valid     => seed_is_valid
        );
    
    -- Fractal pipeline (works for both Mandelbrot and Julia)
    pipeline_inst: mandelbrot_pipeline
        generic map (
            max_iterations => MAX_ITER
        )
        port map (
            clock      => vga_clock,
            reset      => reset_n,
            julia_mode => julia_mode,
            julia_c    => julia_c_value,
            seed_in    => seed_value,
            seed_valid => seed_is_valid,
            iter_out   => iteration_count,
            iter_valid => iter_is_valid
        );
    
    -- Color mapper
    color_map_inst: color_mapper
        generic map (
            max_iterations => MAX_ITER
        )
        port map (
            clock       => vga_clock,
            reset       => reset_n,
            iter_count  => iteration_count,
            iter_valid  => iter_is_valid,
            color_out   => pixel_color,
            color_valid => color_is_valid,
            palette_sel => 0
        );
    
    -- Output process
    process(vga_clock, reset_n)
    begin
        if reset_n = '0' then
            color_out <= color_black;
        elsif rising_edge(vga_clock) then
            if color_is_valid then
                color_out <= pixel_color;
            else
                color_out <= color_black;
            end if;
        end if;
    end process;
    
end architecture structural;

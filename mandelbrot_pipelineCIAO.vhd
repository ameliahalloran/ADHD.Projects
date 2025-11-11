library ieee;
use ieee.std_logic_1164.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;

entity mandelbrot_pipeline is
    generic (
        max_iterations: natural := 16  -- Number of pipeline stages
    );
    port (
        clock:          in  std_logic;
        reset:          in  std_logic;
        
        -- Input: seed value c for this pixel
        c_in:           in  ads_complex;
        c_valid:        in  boolean;  -- True when c_in is valid
        
        -- Output: iteration count for color mapping
        iter_out:       out natural range 0 to max_iterations;
        iter_valid:     out boolean  -- True when iter_out is valid
    );
end entity mandelbrot_pipeline;

architecture structural of mandelbrot_pipeline is
    -- Component declaration for pipeline stage
    component mandelbrot_stage is
        generic (
            stage_number: natural;
            max_iterations: natural;
            threshold: ads_sfixed
        );
        port (
            clock:          in  std_logic;
            reset:          in  std_logic;
            z_in:           in  ads_complex;
            c_in:           in  ads_complex;
            escaped_in:     in  boolean;
            escape_iter_in: in  natural range 0 to max_iterations;
            z_out:          out ads_complex;
            c_out:          out ads_complex;
            escaped_out:    out boolean;
            escape_iter_out: out natural range 0 to max_iterations
        );
    end component;
    
    -- Arrays to connect pipeline stages
    type complex_array is array(0 to max_iterations) of ads_complex;
    type boolean_array is array(0 to max_iterations) of boolean;
    type iter_array is array(0 to max_iterations) of natural range 0 to max_iterations;
    
    signal z_pipe:      complex_array;
    signal c_pipe:      complex_array;
    signal escaped_pipe: boolean_array;
    signal iter_pipe:   iter_array;
    
    -- Valid signal pipeline (delays c_valid to match pipeline depth)
    signal valid_pipe:  std_logic_vector(0 to max_iterations);
    
    constant threshold_value: ads_sfixed := to_ads_sfixed(4.0);
    
begin
    -- Input to first stage
    z_pipe(0) <= complex_zero;  -- Start with z = 0
    c_pipe(0) <= c_in;
    escaped_pipe(0) <= false;
    iter_pipe(0) <= max_iterations;
    valid_pipe(0) <= '1' when c_valid else '0';
    
    -- Generate pipeline stages
    gen_stages: for i in 0 to max_iterations-1 generate
        stage_inst: mandelbrot_stage
            generic map (
                stage_number => i,
                max_iterations => max_iterations,
                threshold => threshold_value
            )
            port map (
                clock => clock,
                reset => reset,
                z_in => z_pipe(i),
                c_in => c_pipe(i),
                escaped_in => escaped_pipe(i),
                escape_iter_in => iter_pipe(i),
                z_out => z_pipe(i+1),
                c_out => c_pipe(i+1),
                escaped_out => escaped_pipe(i+1),
                escape_iter_out => iter_pipe(i+1)
            );
        
        -- Pipeline the valid signal
        process(clock, reset)
        begin
            if reset = '0' then
                valid_pipe(i+1) <= '0';
            elsif rising_edge(clock) then
                valid_pipe(i+1) <= valid_pipe(i);
            end if;
        end process;
    end generate;
    
    -- Output assignments
    iter_out <= iter_pipe(max_iterations);
    iter_valid <= (valid_pipe(max_iterations) = '1');
    
end architecture structural;
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.color_data.all;

entity color_mapper is
    generic (
        max_iterations: natural := 16
    );
    port (
        clock:          in  std_logic;
        reset:          in  std_logic;
        
        -- Iteration count input
        iter_count:     in  natural range 0 to max_iterations;
        iter_valid:     in  boolean;
        
        -- Color output
        color_out:      out rgb_color;
        color_valid:    out boolean;
        
        -- Optional: palette selection
        palette_sel:    in  natural range 0 to 3 := 0
    );
end entity color_mapper;

architecture rtl of color_mapper is
    signal color_reg: rgb_color;
    signal valid_reg: boolean;
    
begin
    process(clock, reset)
        variable color_idx: natural;
    begin
        if reset = '0' then
            color_reg <= color_black;
            valid_reg <= false;
            
        elsif rising_edge(clock) then
            if iter_valid then
                -- If we reached max iterations, the point is in the set (black)
                if iter_count = max_iterations then
                    color_reg <= color_black;
                else
                    -- Map iteration count to color index (0 to 15)
                    -- Scale iter_count to fit color table range
                    color_idx := (iter_count * 15) / max_iterations;
                    
                    -- Select color from palette
                    case palette_sel is
                        when 0 =>
                            color_reg <= color_table_1(color_idx);
                        when 1 =>
                            color_reg <= color_table_2(color_idx);
                        when others =>
                            color_reg <= color_table_1(color_idx);
                    end case;
                end if;
                valid_reg <= true;
            else
                valid_reg <= false;
            end if;
        end if;
    end process;
    
    color_out <= color_reg;
    color_valid <= valid_reg;
    
end architecture rtl;

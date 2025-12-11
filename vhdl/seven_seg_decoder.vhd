library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_seg_decoder is
  generic (
    lamp_mode_common_anode : boolean := true;
    decimal_support        : boolean := true;
    implementer            : natural range 1 to 255 := 42;  -- Replace with your group number
    revision               : natural range 0 to 255 := 1;
    num_digits             : positive := 6  -- DE1-SoC has 6 seven-segment displays
  );
  port (
    -- Clock and Reset
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    
    -- Avalon MM Slave Interface
    address   : in  std_logic_vector(1 downto 0);
    read      : in  std_logic;
    readdata  : out std_logic_vector(31 downto 0);
    write     : in  std_logic;
    writedata : in  std_logic_vector(31 downto 0);
    
    -- Seven Segment Display Output
    lamps     : out std_logic_vector((7 * num_digits) - 1 downto 0)
  );
end entity seven_seg_decoder;

architecture rtl of seven_seg_decoder is
  
  -- Memory-Mapped Registers (Table 3)
  signal data_reg    : std_logic_vector(31 downto 0) := (others => '0');
  signal control_reg : std_logic_vector(31 downto 0) := (others => '0');
  signal features_reg: std_logic_vector(31 downto 0);
  constant magic_reg : std_logic_vector(31 downto 0) := x"41445335";  -- "ADS5" in hex
  
  -- Control register bit fields (Figure 2)
  alias lamps_on     : std_logic is control_reg(0);
  alias show_decimal : std_logic is control_reg(1);
  
  -- Binary Coded Decimal conversion function (provided in assignment)
  function to_bcd (
    data_value: in std_logic_vector(15 downto 0)
  ) return std_logic_vector is
    variable ret  : std_logic_vector(19 downto 0);
    variable temp : std_logic_vector(data_value'range);
  begin
    temp := data_value;
    ret := (others => '0');
    for i in data_value'range loop
      for j in 0 to ret'length/4 - 1 loop
        if unsigned(ret(4*j + 3 downto 4*j)) >= 5 then
          ret(4*j + 3 downto 4*j) :=
            std_logic_vector(
              unsigned(ret(4*j + 3 downto 4 * j)) + 3);
        end if;
      end loop;
      ret := ret(ret'high -1 downto 0) & temp(temp'high);
      temp := temp(temp'high - 1 downto 0) & '0';
    end loop;
    return ret;
  end function to_bcd;
  
  -- Seven segment decoder (converts 4-bit hex to 7-segment pattern)
  function hex_to_7seg(
    digit : std_logic_vector(3 downto 0);
    common_anode : boolean
  ) return std_logic_vector is
    variable segments : std_logic_vector(6 downto 0);
  begin
    -- Segment mapping: 6543210 = GFEDCBA
    --      A
    --     ---
    --  F |   | B
    --     -G-
    --  E |   | C
    --     ---
    --      D
    
    case digit is
      when x"0" => segments := "0111111";  -- 0
      when x"1" => segments := "0000110";  -- 1
      when x"2" => segments := "1011011";  -- 2
      when x"3" => segments := "1001111";  -- 3
      when x"4" => segments := "1100110";  -- 4
      when x"5" => segments := "1101101";  -- 5
      when x"6" => segments := "1111101";  -- 6
      when x"7" => segments := "0000111";  -- 7
      when x"8" => segments := "1111111";  -- 8
      when x"9" => segments := "1101111";  -- 9
      when x"A" => segments := "1110111";  -- A
      when x"B" => segments := "1111100";  -- b
      when x"C" => segments := "0111001";  -- C
      when x"D" => segments := "1011110";  -- d
      when x"E" => segments := "1111001";  -- E
      when x"F" => segments := "1110001";  -- F
      when others => segments := "0000000";
    end case;
    
    -- Invert for common anode
    if common_anode then
      segments := not segments;
    end if;
    
    return segments;
  end function hex_to_7seg;
  
begin
  
  -- Build the features register (Figure 1)
  features_reg(31 downto 24) <= std_logic_vector(to_unsigned(implementer, 8));
  features_reg(23 downto 16) <= std_logic_vector(to_unsigned(revision, 8));
  features_reg(15 downto 8)  <= std_logic_vector(to_unsigned(num_digits, 8));
  features_reg(7 downto 4)   <= (others => '0');  -- Reserved
  features_reg(3)            <= '1' when lamp_mode_common_anode else '0';
  features_reg(2 downto 1)   <= (others => '0');  -- Reserved
  features_reg(0)            <= '1' when decimal_support else '0';
  
  -- Avalon MM Slave Read Process
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        readdata <= (others => '0');
      elsif read = '1' then
        case address is
          when "00"   => readdata <= data_reg;      -- 0x0: data register
          when "01"   => readdata <= control_reg;   -- 0x4: control register
          when "10"   => readdata <= features_reg;  -- 0x8: features register
          when "11"   => readdata <= magic_reg;     -- 0xC: magic number
          when others => readdata <= (others => '0');
        end case;
      end if;
    end if;
  end process;
  
  -- Avalon MM Slave Write Process
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        data_reg <= (others => '0');
        control_reg <= (others => '0');
      elsif write = '1' then
        case address is
          when "00" =>  -- data register
            data_reg <= writedata;
          when "01" =>  -- control register (only bits 1:0 writable)
            control_reg(1 downto 0) <= writedata(1 downto 0);
            -- If decimal_support is false, ignore writes to bit 1
            if not decimal_support then
              control_reg(1) <= '0';
            end if;
          when others =>  -- features and magic are read-only
            null;
        end case;
      end if;
    end if;
  end process;
  
  -- Seven Segment Display Driver Process
  process(clk)
    variable bcd_value : std_logic_vector(19 downto 0);
    variable digit_val : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        lamps <= (others => '1') when lamp_mode_common_anode else (others => '0');
      else
        if lamps_on = '0' then
          -- Turn off all lamps
          lamps <= (others => '1') when lamp_mode_common_anode else (others => '0');
        else
          -- Display the value
          if decimal_support and show_decimal = '1' then
            -- Convert to BCD and display as decimal
            bcd_value := to_bcd(data_reg(15 downto 0));
            
            for i in 0 to num_digits - 1 loop
              if i < 5 then  -- BCD has 5 digits max
                digit_val := bcd_value(4*i + 3 downto 4*i);
                lamps(7*i + 6 downto 7*i) <= hex_to_7seg(digit_val, lamp_mode_common_anode);
              else
                -- Blank remaining displays
                lamps(7*i + 6 downto 7*i) <= (others => '1') when lamp_mode_common_anode 
                                              else (others => '0');
              end if;
            end loop;
          else
            -- Display as hexadecimal
            for i in 0 to num_digits - 1 loop
              if i < 8 then  -- 32-bit = 8 hex digits
                digit_val := data_reg(4*i + 3 downto 4*i);
                lamps(7*i + 6 downto 7*i) <= hex_to_7seg(digit_val, lamp_mode_common_anode);
              else
                lamps(7*i + 6 downto 7*i) <= (others => '1') when lamp_mode_common_anode 
                                              else (others => '0');
              end if;
            end loop;
          end if;
        end if;
      end if;
    end if;
  end process;
  
end architecture rtl;

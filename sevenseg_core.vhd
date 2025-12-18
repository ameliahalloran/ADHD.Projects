library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevenseg_core is
  generic (
    lamp_mode_common_anode : boolean := true;
    decimal_support        : boolean := true;
    implementer            : natural range 1 to 255 := 2;
    revision               : natural range 0 to 255 := 1;
    num_digits             : positive := 6
  );
  port (
    clk       : in  std_logic;
    reset_n   : in  std_logic;
    address   : in  std_logic_vector(1 downto 0);
    read      : in  std_logic;
    readdata  : out std_logic_vector(31 downto 0);
    write     : in  std_logic;
    writedata : in  std_logic_vector(31 downto 0);
    lamps     : out std_logic_vector((7 * num_digits) - 1 downto 0)
  );
end entity sevenseg_core;

architecture rtl of sevenseg_core is

  signal data_reg    : std_logic_vector(31 downto 0) := (others => '0');
  signal control_reg : std_logic_vector(31 downto 0) := (others => '0');
  constant magic_reg : std_logic_vector(31 downto 0) := x"41445335";

  function build_features return std_logic_vector is
    variable result : std_logic_vector(31 downto 0);
  begin
    result := (others => '0');
    result(31 downto 24) := std_logic_vector(to_unsigned(implementer, 8));
    result(23 downto 16) := std_logic_vector(to_unsigned(revision, 8));
    result(15 downto 8)  := std_logic_vector(to_unsigned(num_digits, 8));
    if lamp_mode_common_anode then
      result(3) := '1';
    end if;
    if decimal_support then
      result(0) := '1';
    end if;
    return result;
  end function;

  constant features_reg : std_logic_vector(31 downto 0) := build_features;

  function to_bcd(data_value: in std_logic_vector(15 downto 0))
    return std_logic_vector is
    variable ret  : std_logic_vector(19 downto 0);
    variable temp : std_logic_vector(data_value'range);
  begin
    temp := data_value;
    ret := (others => '0');
    for i in data_value'range loop
      for j in 0 to ret'length/4 - 1 loop
        if unsigned(ret(4*j + 3 downto 4*j)) >= 5 then
          ret(4*j + 3 downto 4*j) :=
            std_logic_vector(unsigned(ret(4*j + 3 downto 4*j)) + 3);
        end if;
      end loop;
      ret := ret(ret'high - 1 downto 0) & temp(temp'high);
      temp := temp(temp'high - 1 downto 0) & '0';
    end loop;
    return ret;
  end function to_bcd;

  function hex_to_7seg(digit : std_logic_vector(3 downto 0); common_anode : boolean)
    return std_logic_vector is
    variable segments : std_logic_vector(6 downto 0);
  begin
    -- Segment order: GFEDCBA (bits 6 downto 0)
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

    if common_anode then
      segments := not segments;
    end if;

    return segments;
  end function hex_to_7seg;

begin

  -- Register read (clocked)
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        readdata <= (others => '0');
      elsif read = '1' then
        case address is
          when "00"   => readdata <= data_reg;
          when "01"   => readdata <= control_reg;
          when "10"   => readdata <= features_reg;
          when "11"   => readdata <= magic_reg;
          when others => readdata <= (others => '0');
        end case;
      end if;
    end if;
  end process;

  -- Register write (clocked)
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        data_reg <= (others => '0');
        control_reg <= (others => '0');
      elsif write = '1' then
        case address is
          when "00" =>
            data_reg <= writedata;
          when "01" =>
            control_reg(0) <= writedata(0);
            if decimal_support then
              control_reg(1) <= writedata(1);
            end if;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

    -- Display driver 
  process(data_reg, control_reg)
    variable bcd_value     : std_logic_vector(19 downto 0);
    variable digit_val     : std_logic_vector(3 downto 0);
    variable temp_lamps    : std_logic_vector((7 * num_digits) - 1 downto 0);
    variable blank_pattern : std_logic_vector(6 downto 0);
  begin
    -- Blank pattern (all segments OFF)
    if lamp_mode_common_anode then
      blank_pattern := (others => '1'); -- active-low OFF
    else
      blank_pattern := (others => '0');
    end if;

    -- Default: blank all digits correctly (7 bits per digit)
    for i in 0 to num_digits - 1 loop
      temp_lamps(7*i + 6 downto 7*i) := blank_pattern;
    end loop;

    -- Lamps enabled?
    if control_reg(0) = '1' then

      if decimal_support and control_reg(1) = '1' then
        -- Decimal mode
        bcd_value := to_bcd(data_reg(15 downto 0));
        for i in 0 to num_digits - 1 loop
          if i < 5 then
            digit_val := bcd_value(4*i + 3 downto 4*i);
            temp_lamps(7*i + 6 downto 7*i) :=
              hex_to_7seg(digit_val, lamp_mode_common_anode);
          end if;
        end loop;

      else
        -- Hex mode
        for i in 0 to num_digits - 1 loop
          if i < 8 then
            digit_val := data_reg(4*i + 3 downto 4*i);
            temp_lamps(7*i + 6 downto 7*i) :=
              hex_to_7seg(digit_val, lamp_mode_common_anode);
          end if;
        end loop;

      end if;
    end if;

    lamps <= temp_lamps;
  end process;


end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seven_seg_decoder is
  generic (
    num_digits            : integer := 8;
    lamp_mode_common_anode : boolean := true;
    decimal_support       : boolean := true
  );
  port (
    clk         : in  std_logic;
    reset_n     : in  std_logic;
    writedata   : in  std_logic_vector(31 downto 0);
    lamps_on    : in  std_logic;
    show_decimal: in  std_logic;
    ctrl_addr   : in  std_logic_vector(1 downto 0);
    write_en    : in  std_logic;
    lamps       : out std_logic_vector((num_digits * 7) - 1 downto 0)
  );
end entity;

architecture rtl of seven_seg_decoder is

  signal data_reg    : std_logic_vector(31 downto 0) := (others => '0');
  signal control_reg : std_logic_vector(1 downto 0) := (others => '0');

  -----------------------------------------------------------------------
  -- Converts a 4-bit nibble to a 7-segment pattern
  -----------------------------------------------------------------------
  function hex_to_7seg(
    nibble : std_logic_vector(3 downto 0);
    anode  : boolean
  ) return std_logic_vector is
    variable seg : std_logic_vector(6 downto 0);
  begin
    case nibble is
      when "0000" => seg := "1000000"; -- 0
      when "0001" => seg := "1111001"; -- 1
      when "0010" => seg := "0100100"; -- 2
      when "0011" => seg := "0110000"; -- 3
      when "0100" => seg := "0011001"; -- 4
      when "0101" => seg := "0010010"; -- 5
      when "0110" => seg := "0000010"; -- 6
      when "0111" => seg := "1111000"; -- 7
      when "1000" => seg := "0000000"; -- 8
      when "1001" => seg := "0010000"; -- 9
      when "1010" => seg := "0001000"; -- A
      when "1011" => seg := "0000011"; -- b
      when "1100" => seg := "1000110"; -- C
      when "1101" => seg := "0100001"; -- d
      when "1110" => seg := "0000110"; -- E
      when "1111" => seg := "0001110"; -- F
      when others => seg := (others => '1');
    end case;

    if anode then
      return seg;
    else
      return not seg;
    end if;
  end function;

  -----------------------------------------------------------------------
  -- Convert 16-bit value to BCD (returns 20 bits = 5 digits)
  -----------------------------------------------------------------------
  function to_bcd(x : std_logic_vector(15 downto 0))
    return std_logic_vector is
    variable value : integer := to_integer(unsigned(x));
    variable result : std_logic_vector(19 downto 0);
  begin
    for i in 0 to 4 loop
      result(4*i + 3 downto 4*i) := std_logic_vector(to_unsigned(value mod 10, 4));
      value := value / 10;
    end loop;
    return result;
  end function;

begin

  -----------------------------------------------------------------------
  -- Register write logic (data_reg & control_reg)
  -----------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_n = '0' then
        data_reg    <= (others => '0');
        control_reg <= (others => '0');

      elsif write_en = '1' then
        case ctrl_addr is
          when "00" =>
            data_reg <= writedata;

          when "01" =>
            control_reg(1 downto 0) <= writedata(1 downto 0);
            if not decimal_support then
              control_reg(1) <= '0';
            end if;

          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------
  -- Seven segment output driver
  -----------------------------------------------------------------------
  process(clk)
    variable bcd_value : std_logic_vector(19 downto 0);
    variable digit_val : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then

      -------------------------------------------------------------------
      -- RESET
      -------------------------------------------------------------------
      if reset_n = '0' then
        if lamp_mode_common_anode then
          lamps <= (others => '1');
        else
          lamps <= (others => '0');
        end if;

      -------------------------------------------------------------------
      -- LAMPS OFF
      -------------------------------------------------------------------
      elsif lamps_on = '0' then
        if lamp_mode_common_anode then
          lamps <= (others => '1');
        else
          lamps <= (others => '0');
        end if;

      -------------------------------------------------------------------
      -- DISPLAY CONTENT
      -------------------------------------------------------------------
      else

        ---------------------------------------------------------------
        -- DECIMAL MODE
        ---------------------------------------------------------------
        if decimal_support and show_decimal = '1' then

          bcd_value := to_bcd(data_reg(15 downto 0));

          for i in 0 to num_digits - 1 loop
            if i < 5 then
              digit_val := bcd_value(4*i + 3 downto 4*i);
              lamps(7*i + 6 downto 7*i) <= hex_to_7seg(digit_val, lamp_mode_common_anode);
            else
              if lamp_mode_common_anode then
                lamps(7*i + 6 downto 7*i) <= (others => '1');
              else
                lamps(7*i + 6 downto 7*i) <= (others => '0');
              end if;
            end if;
          end loop;

        ---------------------------------------------------------------
        -- HEX MODE
        ---------------------------------------------------------------
        else
          for i in 0 to num_digits - 1 loop
            if i < 8 then
              digit_val := data_reg(4*i + 3 downto 4*i);
              lamps(7*i + 6 downto 7*i) <= hex_to_7seg(digit_val, lamp_mode_common_anode);
            else
              if lamp_mode_common_anode then
                lamps(7*i + 6 downto 7*i) <= (others => '1');
              else
                lamps(7*i + 6 downto 7*i) <= (others => '0');
              end if;
            end if;
          end loop;

        end if; -- decimal vs hex

      end if; -- lamps_on
    end if; -- rising_edge
  end process;

end architecture rtl;

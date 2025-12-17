library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevenseg_core is
    generic (
        lamp_mode_common_anode : boolean := true;
        decimal_support        : boolean := true;
        implementer            : natural := 42;
        revision               : natural := 1;
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

        lamps     : out std_logic_vector((num_digits*7)-1 downto 0)
    );
end entity;


architecture rtl of sevenseg_core is

    signal reg_data     : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_control  : std_logic_vector(31 downto 0) := (others => '0');

    constant MAGIC_VALUE : std_logic_vector(31 downto 0)
        := x"41445335";  -- ADS5

    signal features_reg : std_logic_vector(31 downto 0);

    function to_bcd(data_value: std_logic_vector(15 downto 0))
        return std_logic_vector is
        variable ret  : std_logic_vector(19 downto 0);
        variable temp : std_logic_vector(15 downto 0);
    begin
        temp := data_value;
        ret  := (others => '0');
        for i in data_value'range loop
            for j in 0 to 4 loop
                if unsigned(ret(4*j+3 downto 4*j)) >= 5 then
                    ret(4*j+3 downto 4*j) :=
                        std_logic_vector(unsigned(ret(4*j+3 downto 4*j)) + 3);
                end if;
            end loop;
            ret  := ret(18 downto 0) & temp(15);
            temp := temp(14 downto 0) & '0';
        end loop;
        return ret;
    end function;

    function segencode(digit: std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable s : std_logic_vector(6 downto 0);
    begin
        case digit is
            when x"0" => s := "1111110";
            when x"1" => s := "0110000";
            when x"2" => s := "1101101";
            when x"3" => s := "1111001";
            when x"4" => s := "0110011";
            when x"5" => s := "1011011";
            when x"6" => s := "1011111";
            when x"7" => s := "1110000";
            when x"8" => s := "1111111";
            when x"9" => s := "1111011";
            when x"A" => s := "1110111";
            when x"B" => s := "0011111";
            when x"C" => s := "1001110";
            when x"D" => s := "0111101";
            when x"E" => s := "1001111";
            when x"F" => s := "1000111";
            when others => s := (others => '0');
        end case;

        if lamp_mode_common_anode = false then
            s := not s;
        end if;

        return s;
    end function;

    signal digit_array : std_logic_vector((num_digits*7)-1 downto 0);

begin

    features_reg(31 downto 24) <= std_logic_vector(to_unsigned(implementer, 8));
    features_reg(23 downto 16) <= std_logic_vector(to_unsigned(revision, 8));
    features_reg(15 downto 8)  <= std_logic_vector(to_unsigned(num_digits, 8));
    features_reg(3)            <= '1' when lamp_mode_common_anode else '0';
    features_reg(2)            <= '0'; -- blanking not implemented
    features_reg(1)            <= '0'; -- signed not implemented
    features_reg(0)            <= '1' when decimal_support else '0';
    features_reg(7 downto 4)   <= (others => '0');
    features_reg(31 downto 0)  <= features_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                reg_data    <= (others => '0');
                reg_control <= (others => '0');
            else
                if write = '1' then
                    case address is
                        when "00" => reg_data <= writedata;
                        when "01" => reg_control <= writedata;
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    with address select
        readdata <= reg_data    when "00",
                    reg_control when "01",
                    features_reg when "10",
                    MAGIC_VALUE when "11",
                    (others => '0') when others;

    process(reg_data, reg_control)
        variable val16  : std_logic_vector(15 downto 0);
        variable bcd    : std_logic_vector(19 downto 0);
        variable segs   : std_logic_vector((num_digits*7)-1 downto 0);
    begin
        val16 := reg_data(15 downto 0);

        if reg_control(1) = '1' and decimal_support then
            bcd := to_bcd(val16);
            for i in 0 to num_digits-1 loop
                segs( (i*7)+6 downto (i*7) ) :=
                    segencode(bcd( (i*4)+3 downto (i*4) ));
            end loop;
        else
            for i in 0 to num_digits-1 loop
                segs( (i*7)+6 downto (i*7) ) :=
                    segencode( reg_data( (i*4)+3 downto (i*4) ));
            end loop;
        end if;

        digit_array <= segs;
    end process;

    lamps <= digit_array;

end architecture;

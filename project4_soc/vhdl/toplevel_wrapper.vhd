library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Top-level wrapper for Platform Designer AND for simulation
entity toplevel_wrapper is
  port (
    -- Clock & reset
    clk       : in  std_logic;
    reset_n   : in  std_logic;

    -- Avalon-MM slave interface (2-bit address space)
    address     : in  std_logic_vector(1 downto 0);
    write       : in  std_logic;
    writedata   : in  std_logic_vector(31 downto 0);
    read        : in  std_logic;
    readdata    : out std_logic_vector(31 downto 0);

    -- Physical LED outputs (7 segments × 6 digits = 42 bits)
    digits      : out std_logic_vector(41 downto 0)
  );
end entity;

architecture structure of toplevel_wrapper is

  -- Updated seven_seg_decoder declaration
  component seven_seg_decoder is
    generic (
      num_digits             : integer := 6;
      lamp_mode_common_anode : boolean := true;
      decimal_support        : boolean := true
    );
    port (
      clk         : in  std_logic;
      reset_n     : in  std_logic;

      -- Avalon-MM control signals
      ctrl_addr   : in  std_logic_vector(1 downto 0);   -- replaced address
      write_en    : in  std_logic;                      -- replaced write
      writedata   : in  std_logic_vector(31 downto 0);

      -- Optional control flags
      lamps_on    : in  std_logic := '1';
      show_decimal: in  std_logic := '0';

      -- Readback
      readdata    : out std_logic_vector(31 downto 0);

      -- Output lamps
      lamps       : out std_logic_vector(41 downto 0)
    );
  end component;

  signal lamps_s : std_logic_vector(41 downto 0);

begin

  -- Instantiate updated decoder
  DEC0 : seven_seg_decoder
    port map (
      clk         => clk,
      reset_n     => reset_n,

      ctrl_addr   => address,
      write_en    => write,
      writedata   => writedata,

      lamps_on    => '1',
      show_decimal=> '0',

      readdata    => readdata,
      lamps       => lamps_s
    );

  -- Provide output to system or testbench
  digits <= lamps_s;

end architecture;

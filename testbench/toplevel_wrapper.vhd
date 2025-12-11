library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wrapper entity for testing with cocotb
entity toplevel_wrapper is
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

    -- Output expected by testbench
    digits    : out std_logic_vector(41 downto 0)  -- 7 * 6 = 42 bits
  );
end entity toplevel_wrapper;

architecture structure of toplevel_wrapper is

  component seven_seg_decoder is
    generic (
      lamp_mode_common_anode : boolean := true;
      decimal_support        : boolean := true;
      implementer            : natural range 1 to 255 := 42;
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
      lamps     : out std_logic_vector(41 downto 0)
    );
  end component;

  signal lamps_s : std_logic_vector(41 downto 0);

begin

  U_DEC : seven_seg_decoder
    port map (
      clk       => clk,
      reset_n   => reset_n,
      address   => address,
      read      => read,
      readdata  => readdata,
      write     => write,
      writedata => writedata,
      lamps     => lamps_s
    );

  -- Adapt output name for testbench
  digits <= lamps_s;

end architecture structure;

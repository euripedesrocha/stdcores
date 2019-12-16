----------------------------------------------------------------------------------
-- SPI-AXI-Master  by Ricardo F Tafas Jr
----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
library stdblocks;
    use stdblocks.sync_lib.all;

entity SPI_AXI_TOP_TB is
end SPI_AXI_TOP_TB;

architecture simulation of SPI_AXI_TOP_TB is

  component spi_axi_top
    generic (
      spi_cpol      : std_logic;
      ID_WIDTH      : integer := 1;
      ID_VALUE      : integer := 0;
      ADDR_BYTE_NUM : integer := 4;
      DATA_BYTE_NUM : integer := 4
    );
    port (
      rst_i         : in  std_logic;
      mclk_i        : in  std_logic;
      mosi_i        : in  std_logic;
      miso_o        : out std_logic;
      spck_i        : in  std_logic;
      spcs_i        : in  std_logic;
      RSTIO_o      : out std_logic;
      DID_i        : in  std_logic_vector(DATA_BYTE_NUM*8-1 downto 0);
      UID_i        : in  std_logic_vector(DATA_BYTE_NUM*8-1 downto 0);
      serial_num_i : in  std_logic_vector(DATA_BYTE_NUM*8-1 downto 0);
      irq_i         : in  std_logic_vector(7 downto 0);
      M_AXI_AWID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      M_AXI_AWVALID : out std_logic;
      M_AXI_AWREADY : in  std_logic;
      M_AXI_AWADDR  : out std_logic_vector(8*ADDR_BYTE_NUM-1 downto 0);
      M_AXI_AWPROT  : out std_logic_vector(2 downto 0);
      M_AXI_WVALID  : out std_logic;
      M_AXI_WREADY  : in  std_logic;
      M_AXI_WDATA   : out std_logic_vector(8*DATA_BYTE_NUM-1 downto 0);
      M_AXI_WSTRB   : out std_logic_vector(DATA_BYTE_NUM-1 downto 0);
      M_AXI_WLAST   : out std_logic;
      M_AXI_BVALID  : in  std_logic;
      M_AXI_BREADY  : out std_logic;
      M_AXI_BRESP   : in  std_logic_vector(1 downto 0);
      M_AXI_BID     : in  std_logic_vector(ID_WIDTH-1 downto 0);
      M_AXI_ARVALID : out std_logic;
      M_AXI_ARREADY : in  std_logic;
      M_AXI_ARADDR  : out std_logic_vector(8*ADDR_BYTE_NUM-1 downto 0);
      M_AXI_ARPROT  : out std_logic_vector(2 downto 0);
      M_AXI_ARID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      M_AXI_RVALID  : in  std_logic;
      M_AXI_RREADY  : out std_logic;
      M_AXI_RDATA   : in  std_logic_vector(8*DATA_BYTE_NUM-1 downto 0);
      M_AXI_RRESP   : in  std_logic_vector(1 downto 0);
      M_AXI_RID     : in  std_logic_vector(ID_WIDTH-1 downto 0);
      M_AXI_RLAST   : in  std_logic
    );
  end component spi_axi_top;

  constant  spi_cpol      : std_logic := '1';
  constant  ID_WIDTH      : integer := 1;
  constant  ID_VALUE      : integer := 0;
  constant  ADDR_BYTE_NUM : integer := 4;
  constant  DATA_BYTE_NUM : integer := 4;
  signal    rst_i         : std_logic;
  signal    mclk_i        : std_logic := '0';
  signal    mosi_i        : std_logic;
  signal    miso_o        : std_logic;
  signal    spck_i        : std_logic;
  signal    spcs_i        : std_logic;
  signal    RSTIO_o       : std_logic;

  constant  DID_i         : std_logic_vector(DATA_BYTE_NUM*8-1 downto 0) := x"01234567";
  constant  UID_i         : std_logic_vector(DATA_BYTE_NUM*8-1 downto 0) := x"89ABCDEF";
  constant  serial_num_i  : std_logic_vector(DATA_BYTE_NUM*8-1 downto 0) := x"76543210";
  signal    irq_i         : std_logic_vector(7 downto 0);

  signal    M_AXI_AWID    : std_logic_vector(ID_WIDTH-1 downto 0);
  signal    M_AXI_AWVALID : std_logic;
  signal    M_AXI_AWREADY : std_logic;
  signal    M_AXI_AWADDR  : std_logic_vector(8*ADDR_BYTE_NUM-1 downto 0);
  signal    M_AXI_AWPROT  : std_logic_vector(2 downto 0);
  signal    M_AXI_WVALID  : std_logic;
  signal    M_AXI_WREADY  : std_logic;
  signal    M_AXI_WDATA   : std_logic_vector(8*DATA_BYTE_NUM-1 downto 0);
  signal    M_AXI_WSTRB   : std_logic_vector(DATA_BYTE_NUM-1 downto 0);
  signal    M_AXI_WLAST   : std_logic;
  signal    M_AXI_BVALID  : std_logic;
  signal    M_AXI_BREADY  : std_logic;
  signal    M_AXI_BRESP   : std_logic_vector(1 downto 0);
  signal    M_AXI_BID     : std_logic_vector(ID_WIDTH-1 downto 0);
  signal    M_AXI_ARVALID : std_logic;
  signal    M_AXI_ARREADY : std_logic;
  signal    M_AXI_ARADDR  : std_logic_vector(8*ADDR_BYTE_NUM-1 downto 0);
  signal    M_AXI_ARPROT  : std_logic_vector(2 downto 0);
  signal    M_AXI_ARID    : std_logic_vector(ID_WIDTH-1 downto 0);
  signal    M_AXI_RVALID  : std_logic;
  signal    M_AXI_RREADY  : std_logic;
  signal    M_AXI_RDATA   : std_logic_vector(8*DATA_BYTE_NUM-1 downto 0);
  signal    M_AXI_RRESP   : std_logic_vector(1 downto 0);
  signal    M_AXI_RID     : std_logic_vector(ID_WIDTH-1 downto 0);
  signal    M_AXI_RLAST   : std_logic;

  constant frequency_mhz   : real := 20.0000;
  constant spi_period      : time := ( 1.000 / frequency_mhz) * 1 us;
  constant spi_half_period : time := spi_period;

  type data_vector_t is array (NATURAL RANGE <>) of std_logic_vector(7 downto 0);
  signal RDSN_c        : data_vector_t(5 downto 0) := (x"C3", others => x"00");


  signal WRITE_c       : std_logic_vector(7 downto 0) := x"02";
  signal READ_c        : std_logic_vector(7 downto 0) := x"03";
  signal FAST_WRITE_c  : std_logic_vector(7 downto 0) := x"0A";
  signal FAST_READ_c   : std_logic_vector(7 downto 0) := x"0B";
  signal WRITE_BURST_c : std_logic_vector(7 downto 0) := x"42";
  signal READ_BURST_c  : std_logic_vector(7 downto 0) := x"4B";
  signal EDIO_c        : std_logic_vector(7 downto 0) := x"3B";
  signal EQIO_c        : std_logic_vector(7 downto 0) := x"38";
  signal RSTIO_c       : std_logic_vector(7 downto 0) := x"FF";
  signal RDMR_c        : std_logic_vector(7 downto 0) := x"05";
  signal WRMR_c        : std_logic_vector(7 downto 0) := x"01";
  signal RDID_c        : std_logic_vector(7 downto 0) := x"9F";
  signal RUID_c        : std_logic_vector(7 downto 0) := x"4C";
  signal WRSN_c        : std_logic_vector(7 downto 0) := x"C2";
  signal DPD_c         : std_logic_vector(7 downto 0) := x"BA";
  signal HBN_c         : std_logic_vector(7 downto 0) := x"B9";
  signal IRQR_c        : std_logic_vector(7 downto 0) := x"A4";
  signal STAT_c        : std_logic_vector(7 downto 0) := x"A5";

  signal spi_rxdata_s    : data_vector_t(1023 downto 0);
  signal spi_rxdata_en   : std_logic;


  procedure spi_bus (
    signal data_i  : in  data_vector_t;
    signal data_o  : out data_vector_t;
    signal spcs    : out std_logic;
    signal spck    : out std_logic;
    signal miso    : in  std_logic;
    signal mosi    : out std_logic
  ) is
  begin
    for k in data_i'range loop
      for j in 7 downto 0 loop
        spcs <= '0';
        spck <= '0';
        mosi <= data_i(k)(j);
        wait for spi_half_period;
        spck      <= '1';
        data_o(k)(j) <= miso;
        wait for spi_half_period;
      end loop;
    end loop;
    spcs <= '1';
    spck <= '0';
    mosi <= 'H';
  end procedure;

begin

  --clock e reset
  mclk_i <= not mclk_i after 10 ns;
  rst_i  <= '1', '0' after 20 ns;

  process
  begin
    spck_i <= '0';
    spcs_i <= '1';
    mosi_i <= 'H';
    wait until rst_i = '0';
    wait until mclk_i'event and mclk_i = '1';
    --testing commands
    spi_bus(RDSN_c,spi_rxdata_s,spcs_i,spck_i,miso_o,mosi_i);
    wait;
  end process;


  spi_axi_top_u : spi_axi_top
    generic map (
      spi_cpol      => spi_cpol,
      ID_WIDTH      => ID_WIDTH,
      ID_VALUE      => ID_VALUE,
      ADDR_BYTE_NUM => ADDR_BYTE_NUM,
      DATA_BYTE_NUM => DATA_BYTE_NUM
    )
    port map (
      rst_i         => rst_i,
      mclk_i        => mclk_i,
      mosi_i        => mosi_i,
      miso_o        => miso_o,
      spck_i        => spck_i,
      spcs_i        => spcs_i,
      irq_i         => irq_i,
      RSTIO_o      => RSTIO_o,
      DID_i        => DID_i,
      UID_i        => UID_i,
      serial_num_i => serial_num_i,
      M_AXI_AWID    => M_AXI_AWID,
      M_AXI_AWVALID => M_AXI_AWVALID,
      M_AXI_AWREADY => M_AXI_AWREADY,
      M_AXI_AWADDR  => M_AXI_AWADDR,
      M_AXI_AWPROT  => M_AXI_AWPROT,
      M_AXI_WVALID  => M_AXI_WVALID,
      M_AXI_WREADY  => M_AXI_WREADY,
      M_AXI_WDATA   => M_AXI_WDATA,
      M_AXI_WSTRB   => M_AXI_WSTRB,
      M_AXI_WLAST   => M_AXI_WLAST,
      M_AXI_BVALID  => M_AXI_BVALID,
      M_AXI_BREADY  => M_AXI_BREADY,
      M_AXI_BRESP   => M_AXI_BRESP,
      M_AXI_BID     => M_AXI_BID,
      M_AXI_ARVALID => M_AXI_ARVALID,
      M_AXI_ARREADY => M_AXI_ARREADY,
      M_AXI_ARADDR  => M_AXI_ARADDR,
      M_AXI_ARPROT  => M_AXI_ARPROT,
      M_AXI_ARID    => M_AXI_ARID,
      M_AXI_RVALID  => M_AXI_RVALID,
      M_AXI_RREADY  => M_AXI_RREADY,
      M_AXI_RDATA   => M_AXI_RDATA,
      M_AXI_RRESP   => M_AXI_RRESP,
      M_AXI_RID     => M_AXI_RID,
      M_AXI_RLAST   => M_AXI_RLAST
    );



end simulation;
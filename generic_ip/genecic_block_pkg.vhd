----------------------------------------------------------------------------------------------------------
-- Gneric AXI buffered machine.
-- This is open source code licensed under LGPL.
-- By using it on your system you agree with all LGPL conditions.
-- This code is provided AS IS, without any sort of warranty.
-- Author: Ricardo F Tafas Jr
-- 2019
---------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package genecic_block_pkg is

	constant REG_NUM	        : integer := 32;
	constant C_S_AXI_DATA_WIDTH	: integer := 32;

	constant BYTE_NUM           : integer := C_S_AXI_DATA_WIDTH/8;
	constant OPT_MEM_ADDR_BITS  : integer := integer(log2(real( REG_NUM)));
	constant ADDR_LSB           : integer := integer(log2(real(BYTE_NUM)));
	constant C_S_AXI_ADDR_WIDTH : integer := OPT_MEM_ADDR_BITS + ADDR_LSB + 1;

    type reg_t is array (2**OPT_MEM_ADDR_BITS-1 downto 0) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    --mapa de registros.
    --se estiver em '1' é RW.
    --se estiver em '0' é READ ONLY e NO FEEDBACK WRITE. NO FEEDBACK WRITE siginfica não ler o que escreveu.
    constant RW_MAP : reg_t := (
        1  => x"FFFF_FFFF",
        2  => x"FFFF_FFFF",
        3  => x"FFFF_FFFF",
        others => (others => '0')
    );

		component genecic_block_core is
	    generic (
	      ram_addr    : integer;
				pipe_num    : integer;
        data_size   : integer
	    );
	    port (
	      mclk_i      : in  std_logic;
	      arst_i      : in  std_logic;
	      tready_o    : out std_logic;
	      tdata_i     : in  std_logic_vector(127 downto 0);
	      tvalid_i    : in  std_logic;
	      tlast_i     : in  std_logic;
	      tuser_i     : in  std_logic_vector;
	      tdest_i     : in  std_logic_vector;
	      tvalid_o    : out std_logic;
	      tdata_o     : out std_logic_vector(127 downto 0);
	      tlast_o     : out std_logic;
	      tready_i    : in  std_logic;
	      tuser_o     : out std_logic_vector;
	      tdest_o     : out std_logic_vector;
	      packet_size : in  integer;
	      busy_o      : out std_logic
	    );
	  end component;

		component genecic_block_regs is
        port (
            oreg_o       : out reg_t;
            ireg_i       : in  reg_t;
            pulse_o      : out reg_t;
            capture_i    : in  reg_t;

            S_AXI_ACLK	    : in  std_logic;
            S_AXI_ARESETN	: in  std_logic;
            S_AXI_AWADDR	: in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_AWPROT	: in  std_logic_vector(2 downto 0);
            S_AXI_AWVALID	: in  std_logic;
            S_AXI_AWREADY	: out std_logic;
            S_AXI_WDATA	    : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_WSTRB	    : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
            S_AXI_WVALID	: in  std_logic;
            S_AXI_WREADY	: out std_logic;
            S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
            S_AXI_BVALID	: out std_logic;
            S_AXI_BREADY	: in  std_logic;
            S_AXI_ARADDR	: in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
            S_AXI_ARPROT	: in  std_logic_vector(2 downto 0);
            S_AXI_ARVALID	: in  std_logic;
            S_AXI_ARREADY	: out std_logic;
            S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
            S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
            S_AXI_RVALID	: out std_logic;
            S_AXI_RREADY	: in  std_logic
        );
    end component genecic_block_regs;

end package;

package body genecic_block_pkg is

end package body;

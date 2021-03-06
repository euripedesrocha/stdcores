----------------------------------------------------------------------------------------------------------
-- SPI-AXI-Controller Machine.
-- Ricardo Tafas
-- This is open source code licensed under LGPL.
-- By using it on your system you agree with all LGPL conditions.
-- This code is provided AS IS, without any sort of warranty.
-- Author: Ricardo F Tafas Jr
-- 2019
---------------------------------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library expert;
    use expert.std_logic_expert.all;
library stdblocks;
    use stdblocks.sync_lib.all;

entity spi_control_mq is
    generic (
      addr_word_size : integer := 4;
      data_word_size : integer := 4;
      serial_num_rw  : boolean := true
    );
    port (
      --general
      rst_i        : in  std_logic;
      mclk_i       : in  std_logic;
      --spi
      bus_write_o  : out std_logic;
      bus_read_o   : out std_logic;
      bus_done_i   : in  std_logic;
      bus_data_i   : in  std_logic_vector(data_word_size*8-1 downto 0);
      bus_data_o   : out std_logic_vector(data_word_size*8-1 downto 0);
      bus_addr_o   : out std_logic_vector(addr_word_size*8-1 downto 0);
      --SPI Interface signals
      spi_busy_i   : in  std_logic;
      spi_rxen_i   : in  std_logic;
      spi_txen_o   : out std_logic;
      spi_txdata_o : out std_logic_vector(7 downto 0);
      spi_rxdata_i : in  std_logic_vector(7 downto 0);
      --SPI main registers
      RSTIO_o      : out std_logic;
      DID_i        : in  std_logic_vector(data_word_size*8-1 downto 0);
      UID_i        : in  std_logic_vector(data_word_size*8-1 downto 0);
      serial_num_i : in  std_logic_vector(data_word_size*8-1 downto 0);
      irq_i        : in  std_logic_vector(7 downto 0);
      irq_mask_o   : out std_logic_vector(7 downto 0);
      irq_clear_o  : out std_logic_vector(7 downto 0)
    );
end spi_control_mq;

architecture behavioral of spi_control_mq is

  signal modereg_s   : std_logic_vector(7 downto 0) := (others=>'0');
  signal irq_mask_s  : std_logic_vector(7 downto 0) := (others=>'0');

  signal serialnum_s : std_logic_vector(8*data_word_size-1 downto 0) := (others=>'0');
  signal did_s       : std_logic_vector(8*data_word_size-1 downto 0) := (others=>'0');
  signal uid_c       : std_logic_vector(8*data_word_size-1 downto 0) := (others=>'0');

  constant buffer_size   : integer := data_word_size;--maximum(addr_word_size, data_word_size);
  constant WRITE_c       : std_logic_vector(7 downto 0) := x"02";
  constant READ_c        : std_logic_vector(7 downto 0) := x"03";
  constant FAST_WRITE_c  : std_logic_vector(7 downto 0) := x"0A";
  constant FAST_READ_c   : std_logic_vector(7 downto 0) := x"0B";
  constant WRITE_BURST_c : std_logic_vector(7 downto 0) := x"42";
  constant READ_BURST_c  : std_logic_vector(7 downto 0) := x"4B";
  constant EDIO_c        : std_logic_vector(7 downto 0) := x"3B";
  constant EQIO_c        : std_logic_vector(7 downto 0) := x"38";
  constant RSTIO_c       : std_logic_vector(7 downto 0) := x"FF";
  constant RDMR_c        : std_logic_vector(7 downto 0) := x"05";
  constant WRMR_c        : std_logic_vector(7 downto 0) := x"01";
  constant RDID_c        : std_logic_vector(7 downto 0) := x"9F";
  constant RUID_c        : std_logic_vector(7 downto 0) := x"4C";
  constant WRSN_c        : std_logic_vector(7 downto 0) := x"C2";
  constant RDSN_c        : std_logic_vector(7 downto 0) := x"C3";
  constant DPD_c         : std_logic_vector(7 downto 0) := x"BA";
  constant HBN_c         : std_logic_vector(7 downto 0) := x"B9";
  constant IRQRD_c       : std_logic_vector(7 downto 0) := x"A2";
  constant IRQWR_c       : std_logic_vector(7 downto 0) := x"A3";
  constant IRQMRD_c      : std_logic_vector(7 downto 0) := x"D2";
  constant IRQMWR_c      : std_logic_vector(7 downto 0) := x"D3";
  constant STAT_c        : std_logic_vector(7 downto 0) := x"A5";


  signal data_en : unsigned(7 downto 0) := "00000001";
  signal input_sr : std_logic_vector(7 downto 0);

  type command_t is (
    WRITE_cmd,
    READ_cmd,
    FAST_WRITE_cmd,
    FAST_READ_cmd,
    WRITE_BURST_cmd,
    READ_BURST_cmd,
    EDIO_cmd,
    EQIO_cmd,
    RSTIO_cmd,
    RDMR_cmd,
    WRMR_cmd,
    RDID_cmd,
    RUID_cmd,
    WRSN_cmd,
    RDSN_cmd,
    DPD_cmd,
    HBN_cmd,
    IRQR_cmd,
    STAT_cmd,
    NULL_cmd
  );

  type spi_control_t is (
    --command states
    addr_st,
    read_st,
    write_st,
    act_st,
    inc_addr_st,
    idle_st,
    ack_st,
    wait4spi_st,
    wait_command_st,
    wait_forever_st
  );
  signal spi_mq : spi_control_t := idle_st;

  signal addr_s : std_logic_vector(23 downto 0);


  function action_decode (command : std_logic_vector(7 downto 0) ) return std_logic_vector is
    variable tmp : std_logic_vector(7 downto 0);
  begin
    case command is
      when WRITE_c       =>
        tmp := WRITE_c;
      when READ_c        =>
        tmp := READ_c;
      when FAST_WRITE_c  =>
        tmp := WRITE_c;
      when FAST_READ_c   =>
        tmp := READ_c;
      when WRITE_BURST_c =>
        tmp := WRITE_c;
      when READ_BURST_c  =>
        tmp := READ_c;
      when others        =>
        tmp := command;
    end case;

    return tmp;
  end function;

  function next_state (
    command : std_logic_vector(7 downto 0);
    aux_cnt : integer;
    busy    : std_logic;
    state   : spi_control_t
  )
  return spi_control_t is
    variable tmp     : spi_control_t;
  begin
    if busy = '0' then
      return idle_st;
    end if;

    tmp := state;
    case state is
      when idle_st =>
        tmp := wait_command_st;

      when wait_command_st =>
        case command is
          when WRITE_c       =>
            tmp := addr_st;
          when READ_c        =>
            tmp := addr_st;
          when FAST_WRITE_c  =>
            tmp := addr_st;
          when FAST_READ_c   =>
            tmp := addr_st;
          when WRITE_BURST_c =>
            tmp := addr_st;
          when READ_BURST_c  =>
            tmp := addr_st;
          when WRMR_c        =>
            tmp := wait4spi_st;
          when WRSN_c        =>
            tmp := wait4spi_st;
          when IRQWR_c       =>
            tmp := wait4spi_st;
          when IRQMWR_c      =>
            tmp := wait4spi_st;

          when others        =>
            tmp := act_st;
        end case;

      when addr_st =>
        if aux_cnt = addr_word_size then
          case command is
            when WRITE_c       =>
              tmp := wait4spi_st;
            when FAST_WRITE_c  =>
              tmp := ack_st;
            when WRITE_BURST_c =>
              tmp := ack_st;
            when READ_c        =>
              tmp := act_st;
            when FAST_READ_c   =>
              tmp := ack_st;
            when READ_BURST_c  =>
              tmp := ack_st;
            when others        =>
              tmp := wait_forever_st;
          end case;
        end if;

      when ack_st =>
        case command is
          when FAST_WRITE_c  =>
            tmp := wait4spi_st;
          when WRITE_BURST_c =>
            tmp := wait4spi_st;
          when FAST_READ_c   =>
            tmp := read_st;
          when READ_BURST_c  =>
            tmp := read_st;
          when others        =>
            tmp := wait_forever_st;
        end case;

      when inc_addr_st =>
        case command is
          when WRITE_c       =>
            tmp := wait4spi_st;
          when FAST_WRITE_c  =>
            tmp := wait4spi_st;
          when READ_c        =>
            tmp := read_st;
          when FAST_READ_c   =>
            tmp := read_st;
          when others        =>
            tmp := wait_forever_st;
        end case;

      when wait4spi_st =>
        case command is
          when WRITE_c =>
            if aux_cnt = data_word_size then
              tmp := act_st;
            end if;
          when FAST_WRITE_c =>
            if aux_cnt = data_word_size then
              tmp := act_st;
            end if;
          when WRITE_BURST_c =>
            if aux_cnt = data_word_size then
              tmp := act_st;
            end if;
          when READ_c =>
            if aux_cnt = data_word_size-1 then
              tmp := inc_addr_st;
            end if;
          when FAST_READ_c =>
            if aux_cnt = data_word_size-1 then
              tmp := inc_addr_st;
            end if;
          when READ_BURST_c =>
            if aux_cnt = data_word_size-1 then
              tmp := read_st;
            end if;
          when RDSN_c =>
            if aux_cnt = data_word_size-1 then
              tmp := wait_forever_st;
            end if;
          when RUID_c =>
            if aux_cnt = data_word_size-1 then
              tmp := wait_forever_st;
            end if;
          when RDID_c =>
            if aux_cnt = data_word_size-1 then
              tmp := wait_forever_st;
            end if;
          when WRMR_c =>
            if aux_cnt = data_word_size then
              tmp := act_st;
            end if;
          when WRSN_c =>
            if aux_cnt = data_word_size then
              tmp := act_st;
            end if;
          when IRQWR_c =>
            tmp := act_st;
          when IRQMWR_c =>
            tmp := act_st;
          when others =>
            tmp := wait_forever_st;
        end case;

      when act_st =>
        case command is
          when WRITE_c =>
            tmp := inc_addr_st;
          when FAST_WRITE_c =>
            tmp := inc_addr_st;
          when WRITE_BURST_c =>
            tmp := wait4spi_st;
          when READ_c =>
            tmp := wait4spi_st;
          when FAST_READ_c =>
            tmp := wait4spi_st;
          when READ_BURST_c =>
            tmp := read_st;
          when RDSN_c =>
            tmp := wait4spi_st;
          when RUID_c =>
            tmp := wait4spi_st;
          when RDID_c =>
            tmp := wait4spi_st;
          when IRQRD_c =>
            tmp := wait4spi_st;
          when IRQMRD_c =>
            tmp := wait4spi_st;
          when others =>
            tmp := wait_forever_st;
        end case;

      when others =>
        tmp := wait_forever_st;

    end case;
    return tmp;
  end function;

  signal get_addr_s : boolean;

  signal buffer_s : std_logic_vector(8*buffer_size-1 downto 0);
  signal aux_cnt_s : integer;
  signal command_s         : std_logic_vector(7 downto 0);


begin

  spi_mq_p : process(mclk_i,rst_i)
    variable aux_cnt           : integer range 0 to 4 := 0;
    variable command_v         : std_logic_vector(7 downto 0);
    variable decoded_command_v : std_logic_vector(7 downto 0);
    variable temp_v            : std_logic_vector(7 downto 0);
    variable buffer_v          : std_logic_vector(8*buffer_size-1 downto 0);
    variable addr_v            : std_logic_vector(8*addr_word_size-1 downto 0);
  begin
    if rst_i = '1' then
      spi_mq       <= idle_st;
      command_v    := (others=>'0');
      addr_v       := (others=>'0');
      aux_cnt      := 0;
      spi_txen_o   <= '0';
      spi_txdata_o <= (others=>'1');
      buffer_v     := (others=>'0');
      RSTIO_o      <= '0';
      serialnum_s  <= (others=>'0');
      irq_mask_s   <= (others=>'0');
      irq_clear_o  <= (others=>'0');
      bus_read_o   <= '0';
      bus_write_o  <= '0';
      bus_addr_o   <= (others=>'0');
    elsif mclk_i = '1' and mclk_i'event then
      case spi_mq is
          when idle_st  =>
            if spi_busy_i = '0' then
              spi_mq       <= idle_st;
              command_v    := (others=>'0');
              addr_v       := (others=>'0');
              aux_cnt      := 0;
              spi_txen_o   <= '0';
              spi_txdata_o <= (others=>'1');
              buffer_v     := (others=>'0');
              RSTIO_o      <= '0';
              irq_clear_o  <= (others=>'0');
            else
              command_v    := (others=>'0');
              addr_v       := (others=>'0');
              aux_cnt      := 0;
              spi_txen_o   <= '1';
              spi_txdata_o <= (others=>'1');
              buffer_v     := (others=>'0');
              spi_mq    <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
            end if;

          when wait_command_st  =>
            spi_txen_o   <= '0';
            spi_txdata_o <= (others=>'1');
            if spi_rxen_i = '1' then
              command_v := spi_rxdata_i;
              spi_mq    <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
            end if;

          when addr_st =>
            if spi_rxen_i = '1' then
              aux_cnt := aux_cnt + 1;
              for j in 1 to 8 loop
                buffer_v := buffer_v(buffer_v'high-1 downto 0) & '1';
              end loop;
              buffer_v(7 downto 0) := spi_rxdata_i;
              spi_mq     <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
              addr_v     := buffer_v(addr_v'range);
              if aux_cnt = addr_word_size then
                aux_cnt := 0;
              end if;
            end if;

          when ack_st =>
            spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
            spi_txen_o   <= '1';
            spi_txdata_o <= x"AC";

          when wait4spi_st =>
            if spi_rxen_i = '1' then
              aux_cnt      := aux_cnt + 1;
              for j in 1 to 8 loop
                buffer_v := buffer_v(8*buffer_size-2 downto 0) & '1';
              end loop;
              buffer_v(7 downto 0) := spi_rxdata_i;
              spi_mq   <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
              spi_txen_o   <= '1';
              spi_txdata_o <= buffer_v(buffer_v'high downto buffer_v'high-7);
            else
              spi_txen_o <= '0';
            end if;

          when act_st =>
            temp_v := action_decode(command_v);
            case temp_v is

              when READ_c        =>
                bus_read_o <= '1';
                bus_addr_o <= addr_v;
                if bus_done_i = '1' then
                  bus_read_o <= '0';
                  spi_mq    <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
                  buffer_v(buffer_v'high downto buffer_v'length-bus_data_i'length) := bus_data_i;
                  spi_txen_o   <= '1';
                  spi_txdata_o <= buffer_v(buffer_v'high downto buffer_v'high-7);
                end if;

              when WRITE_c        =>
                bus_data_o  <= buffer_v(bus_data_o'range);
                bus_addr_o  <= addr_v;
                bus_write_o <= '1';
                if bus_done_i = '1' then
                  spi_mq      <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
                  bus_write_o <= '0';
                end if;

              when RSTIO_c       =>
                RSTIO_o     <= '1';
                spi_mq      <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when RDMR_c        =>
                spi_txen_o   <= '1';
                spi_txdata_o <= modereg_s;
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when WRMR_c        =>
                modereg_s <= buffer_v(7 downto 0);
                spi_mq   <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when RDID_c        =>
                spi_txen_o   <= '1';
                buffer_v     := did_i;
                spi_txdata_o <= buffer_v(buffer_v'high downto buffer_v'high-7);
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when RUID_c        =>
                spi_txen_o   <= '1';
                buffer_v     := uid_i;
                spi_txdata_o <= buffer_v(buffer_v'high downto buffer_v'high-7);
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when WRSN_c        =>
                if serial_num_rw then
                  serialnum_s <= buffer_v(serialnum_s'range);
                end if;
                spi_mq   <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when RDSN_c        =>
                if serial_num_rw then
                  buffer_v     := serialnum_s;
                else
                  buffer_v     := serial_num_i;
                end if;
                spi_txen_o   <= '1';
                spi_txdata_o <= buffer_v(buffer_v'high downto buffer_v'high-7);
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when DPD_c         =>
                spi_mq <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when HBN_c         =>
                spi_mq <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when IRQRD_c =>
                spi_txen_o   <= '1';
                spi_txdata_o <= irq_i;
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when IRQWR_c =>
                irq_clear_o <= buffer_v(7 downto 0);
                spi_mq      <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when IRQMRD_c =>
                spi_txen_o   <= '1';
                spi_txdata_o <= irq_mask_s;
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when IRQMWR_c =>
                irq_mask_s <= buffer_v(7 downto 0);
                spi_mq     <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

              when others        =>
                spi_txen_o   <=   '1';
                spi_txdata_o <= x"FF";
                spi_mq       <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);
                report "Invalid Command detected." severity warning;

            end case;

          when others   =>
            spi_txen_o   <=   '0';
            --spi_txdata_o <= x"FF";
            spi_mq  <= next_state(command_v, aux_cnt, spi_busy_i, spi_mq);

        end case;
      end if;
      --saídas
    buffer_s <= buffer_v;
    aux_cnt_s <= aux_cnt;
    command_s <= command_v;
  end process;

  --Algumas saídas.
  irq_mask_o <= irq_mask_s;

end behavioral;

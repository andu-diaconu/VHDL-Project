
-- UART RECEPTOR - primeste 8 biti de date, un bit de start si unul de stop. RX_DV(data value) va indica o receptie completa
-- g_CLKS_PER_BIT = (Frecventa i_Clk-ului)/(Frecventa UART-ului)
-- Exemplu: 100 MHz Clock, 115200 baud UART
-- (100000000)/(115200) = 868
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity UART_RX is
  generic (
    g_CLKS_PER_BIT : integer := 868     
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0)
    );
end UART_RX;


architecture RTL of UART_RX is

  type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                     s_RX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;

  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0; 
  signal r_RX_Byte   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_RX_DV     : std_logic := '0';
  
begin

  p_UART_RX : process (i_Clk)
  begin
    if rising_edge(i_Clk) then
        
      case r_SM_Main is

        when s_Idle =>
          r_RX_DV     <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;

          if i_RX_Serial = '0' then       -- S-a detectat un inceput de receptie(pe placuta)
            r_SM_Main <= s_RX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;

          
        -- Ne asiguram ca intr-adevar s-a trimis un bit de start
        when s_RX_Start_Bit =>
          if r_Clk_Count = g_CLKS_PER_BIT/2 then
            if i_RX_Serial = '0' then
              r_Clk_Count <= 0; 
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_SM_Main   <= s_Idle;
            end if;
          else
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Start_Bit;
          end if;

          
        -- Asteptam g_CLKS_PER_BIT-1 cicluri de ceas sa sectionam data
        when s_RX_Data_Bits =>
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Data_Bits;
          else
            r_Clk_Count            <= 0;
            r_RX_Byte(r_Bit_Index) <= i_RX_Serial;
            
            -- Check if we have sent out all bits
            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= s_RX_Data_Bits;
            else
              r_Bit_Index <= 0;
              r_SM_Main   <= s_RX_Stop_Bit;
            end if;
          end if;


        -- S-a receptionat bit-ul de stop
        when s_RX_Stop_Bit =>
          -- Asteptam g_CLKS_PER_BIT-1 cicluri de clk ca StopBit-ul sa se finiseze
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_RX_Stop_Bit;
          else
            r_RX_DV     <= '1';
            r_Clk_Count <= 0;
            r_SM_Main   <= s_Cleanup;
          end if;

                  
        -- Tot un singur clk si aici
        when s_Cleanup =>
          r_SM_Main <= s_Idle;
          r_RX_DV   <= '0';

            
        when others =>
          r_SM_Main <= s_Idle;

      end case;
    end if;
  end process p_UART_RX;

  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;
  
end RTL;

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Loopback_Top is
  port (
    -- Clock (100MHz)
    i_Clk         : in std_logic;
 
    -- UART Data
    i_UART_RX : in  std_logic;
    o_UART_TX : out std_logic;
     
	An   : out STD_LOGIC_VECTOR (7 downto 0); 
		 -- semnale pentru anozi
	Seg  : out STD_LOGIC_VECTOR (7 downto 0)
		 -- semnale pentru segmentele (catozii) cifrei active
    );
end entity UART_Loopback_Top;
 
architecture RTL of UART_Loopback_Top is
 
  signal w_RX_DV     : std_logic;
  signal w_RX_Byte   : std_logic_vector(7 downto 0);
  signal w_TX_Active : std_logic;
  signal w_TX_Serial : std_logic;
  signal data : std_logic_vector(31 downto 0);
begin
 
  UART_RX_Inst : entity work.UART_RX
    generic map (
      g_CLKS_PER_BIT => 868)            -- 100 MHz / 115 200
    port map (
      i_Clk       => i_Clk,
      i_RX_Serial => i_UART_RX,
      o_RX_DV     => w_RX_DV,
      o_RX_Byte   => w_RX_Byte);
 
 
  UART_TX_Inst : entity work.UART_TX
    generic map (
      g_CLKS_PER_BIT => 868)               -- 100 MHz / 115 200
    port map (
      i_Clk       => i_Clk,
      i_TX_DV     => w_RX_DV,
      i_TX_Byte   => w_RX_Byte,
      o_TX_Active => w_TX_Active,
      o_TX_Serial => w_TX_Serial,
      o_TX_Done   => open
      );
 
  o_UART_TX <= w_TX_Serial when w_TX_Active = '1' else '1';
  
   data <= "000000000000000000000000"&w_Rx_Byte;
   display:entity work.displ7seg
   port map(clk=>i_clk,
   data=>data,
   An=>An,
   Seg=>Seg);
   
end architecture RTL;
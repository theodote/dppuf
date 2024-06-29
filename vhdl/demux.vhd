----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.06.2024 12:38:41
-- Design Name: 
-- Module Name: demux - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity demux is
    Port ( demux_input : in STD_LOGIC_VECTOR (31 downto 0);
           outa : out STD_LOGIC_VECTOR (31 downto 0);
           outb : out STD_LOGIC_VECTOR (31 downto 0);
           outc : out STD_LOGIC_VECTOR (31 downto 0);
           outd : out STD_LOGIC_VECTOR (31 downto 0);
           selection : in STD_LOGIC_VECTOR (1 downto 0));
end demux;

architecture demux_arch of demux is

begin

with selection select outa <=
    demux_input when "00",
    (others => '0') when "01",
    (others => '0') when "10",
    (others => '0') when "11";
    
with selection select outb <=
    (others => '0') when "00",
    demux_input when "01",
    (others => '0') when "10",
    (others => '0') when "11";
    
with selection select outc <=
    (others => '0') when "00",
    (others => '0') when "01",
    demux_input when "10",
    (others => '0') when "11";
    
with selection select outd <=
    (others => '0') when "00",
    (others => '0') when "01",
    (others => '0') when "10",
    demux_input when "11";

end demux_arch;

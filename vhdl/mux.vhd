----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.06.2024 12:38:41
-- Design Name: 
-- Module Name: mux - Behavioral
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

entity mux is
    Port ( ina : in STD_LOGIC_VECTOR (31 downto 0);
           inb : in STD_LOGIC_VECTOR (31 downto 0);
           inc : in STD_LOGIC_VECTOR (31 downto 0);
           ind : in STD_LOGIC_VECTOR (31 downto 0);
           mux_output : out STD_LOGIC_VECTOR (31 downto 0);
           selection : in STD_LOGIC_VECTOR (1 downto 0));
end mux;

architecture mux_arch of mux is

begin

with selection select mux_output <=
    ina when "00",
    inb when "01",
    inc when "10",
    ind when "11";

end mux_arch;

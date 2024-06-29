library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity symmetric_ff is
    Port ( d0 : in STD_LOGIC;
           d1 : in STD_LOGIC;
           q_out : out STD_LOGIC;
           n_q_out : out STD_LOGIC);
attribute dont_touch : string;
attribute dont_touch of symmetric_ff : entity is "true|yes";
end symmetric_ff;

architecture symmetric_ff_arch of symmetric_ff is

signal delay1, delay2, delay3, e, n_s, n_r, q, n_q : std_logic;
attribute dont_touch of delay1 : signal is "true";
attribute dont_touch of delay2 : signal is "true";
attribute dont_touch of delay3 : signal is "true";
attribute dont_touch of e : signal is "true";

attribute ALLOW_COMBINATORIAL_LOOPS : string;
attribute ALLOW_COMBINATORIAL_LOOPS of q_out, n_q_out : signal is "true";

begin

-- maybe just a bit of delay needed?
delay1 <= d0 xnor d1;
delay2 <= not delay1;
delay3 <= not delay2;
e <= not delay3;

-- maybe delay not needed at all?
--e <= d0 xor d1;

n_s <= e nand d0;
n_r <= e nand d1;
q <= n_s nand n_q;
n_q <= q nand n_r;
q_out <= q;
n_q_out <= n_q;

end symmetric_ff_arch;
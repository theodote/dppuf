library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity delayer is
generic (
    stages : natural
);
port (
    input : in STD_LOGIC;
    output : out STD_LOGIC
);
attribute dont_touch : string;
--attribute dont_touch of delayer : entity is "true|yes";

type switch_t is array(boolean) of string;
constant switch : switch_t := (false => "false|no", true => "true|yes");
attribute dont_touch of delayer : entity is switch(stages /= 0);

end delayer;

architecture delayer_arch of delayer is
    signal flips : std_logic_vector (0 to 2*stages-1);
    attribute dont_touch of flips : signal is "true";
begin
    
    do_delay: if (stages > 0) generate
        flips(0) <= not input;
        flipping: for n in 1 to 2*stages-1 generate
            flips(n) <= not flips(n-1);
        end generate flipping;
        output <= flips(2*stages-1);
    end generate do_delay;
    
    dont_delay: if (stages = 0) generate
        output <= input;
    end generate dont_delay; 
    
    incorrect_parameter: if (stages < 0) generate
        output <= input;
    end generate incorrect_parameter; 

end delayer_arch;



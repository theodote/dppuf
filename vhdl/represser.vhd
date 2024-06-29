library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity represser is
generic (
    a_delay : natural := 0;
    b_delay : natural := 0;
    c_delay : natural := 0;
    d_delay : natural := 0;
    q_delay : natural := 0
);
port (
    a_in : in STD_LOGIC;
    b_in : in STD_LOGIC;
    c_in : in STD_LOGIC;
    d_in : in STD_LOGIC;
    q_out : out STD_LOGIC
);
end represser;

architecture represser_arch of represser is

attribute dont_touch : string;

    component delayer is
    generic (
        stages : natural
    );
    port (
        input : in std_logic;
        output : out std_logic
    );
    end component delayer;
    attribute dont_touch of delayer : component is "true";
    
    signal a, b, c, d, q : std_logic; 
    attribute dont_touch of a, b, c, d, q : signal is "true";

begin

    a_delayed : delayer generic map (stages => a_delay) port map (input => a_in, output => a);
    b_delayed : delayer generic map (stages => b_delay) port map (input => b_in, output => b);
    c_delayed : delayer generic map (stages => c_delay) port map (input => c_in, output => c);
    d_delayed : delayer generic map (stages => d_delay) port map (input => d_in, output => d);
    
    q <= not( (not (a and b)) and (not (a and c)) and (not (c and d)) );
    
    q_delayed : delayer generic map (stages => q_delay) port map (input => q, output => q_out);

end represser_arch;

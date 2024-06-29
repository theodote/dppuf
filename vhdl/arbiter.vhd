library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arbiter is
    Port ( racer0 : in STD_LOGIC;
           racer1 : in STD_LOGIC;
           winner : out STD_LOGIC);
attribute dont_touch : string;
attribute dont_touch of arbiter : entity is "true|yes";
end arbiter;

architecture arbiter_arch of arbiter is

    component delayer is
    generic (
        stages : natural
    );
    port (
        input : in std_logic;
        output : out std_logic);
    end component delayer;
    
    component symmetric_ff is
        Port ( d0 : in STD_LOGIC;
               d1 : in STD_LOGIC;
               q_out : out STD_LOGIC;
               n_q_out : out STD_LOGIC);
    end component symmetric_ff;
    
    signal racer0_delayed : std_logic;
    signal sample : std_logic;
    signal edge : std_logic;    -- 1 is rising, 0 is falling
    attribute dont_touch of racer0_delayed : signal is "true";
    attribute dont_touch of sample : signal is "true";
    attribute dont_touch of edge : signal is "true";
    
    attribute dont_touch of delayer : component is "true";
    attribute dont_touch of symmetric_ff : component is "true";

begin

delay_racer0 : delayer generic map (stages => 4) port map (input => racer0, output => racer0_delayed);

which_edge: symmetric_ff port map (d0 => racer0, d1 => racer0_delayed, q_out => open, n_q_out => edge);

sampling: symmetric_ff port map (d0 => racer0, d1 => racer1, q_out => open, n_q_out => sample);

winner <= edge xor sample;

end arbiter_arch;

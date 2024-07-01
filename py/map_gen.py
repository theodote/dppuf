from random import shuffle, sample, randint, choice
import pyperclip as pc
import argparse

AUTOMATED = True

arbiter_component = ""
arbiter_label = ""
if AUTOMATED:
    arbiter_component = "arbiter"
    arbiter_label = "each_arbiter"
else:
    arbiter_component = "true_arbiter"
    arbiter_label = "arbiter"

parser = argparse.ArgumentParser()
parser.add_argument('nth_dppuf')
parser.add_argument('one_to_one')
parser.add_argument('complementary_delays')
parser.add_argument('width')
parser.add_argument('boosters')
parser.add_argument('repressers')
parser.add_argument('response_buffers')
parser.add_argument('cycles_stable')
args = parser.parse_args()

truths = ("true", "True", "TRUE", "yes", "Yes", "YES", "y", "Y")
if args.one_to_one in truths:
    one_to_one = True
else:
    one_to_one = False
if args.complementary_delays in truths:
    complementary_delays = True
else:
    complementary_delays = False
nth_dppuf = int(args.nth_dppuf)
w = int(args.width)
b = int(args.boosters)
r = int(args.repressers)
response_buffers = int(args.response_buffers)
cycles_stable = int(args.cycles_stable)

vhdl = f"""library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dppuf{nth_dppuf} is
generic (
    w : integer := {w};
    b : integer := {b};
    r : integer := {r};
    response_buffers: integer := {response_buffers};
    cycles_stable : integer := {cycles_stable}
);
port (
    gclk : in STD_LOGIC;
    challenge : in STD_LOGIC_VECTOR (w-1 downto 0);
    fire : in STD_LOGIC;    -- ACTIVE HIGH
    response : out STD_LOGIC_VECTOR (w-1 downto 0);
    finished : out STD_LOGIC
);
end dppuf{nth_dppuf};

architecture dppuf{nth_dppuf}_arch of dppuf{nth_dppuf} is

    attribute dont_touch : string;

    component booster is
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
    end component booster;
    
    component represser is
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
    end component represser;
    
    component {arbiter_component} is
    port (
        racer0 : in STD_LOGIC;
        racer1 : in STD_LOGIC;
        winner: out std_logic
    );
    end component {arbiter_component};
    
    signal fire_buf : std_logic_vector(3 downto 0) := "0000";
    
    --(h/vertical)(01/path)(w/horizontal)
    type w_array is array (natural range <>) of STD_LOGIC_VECTOR (w-1 downto 0);
    type h_array is array (natural range <>) of w_array(1 downto 0);
    signal challenge_buf : w_array(1 downto 0);
    signal dupe_challenges : w_array(1 downto 0);
    signal ms_responses : w_array (response_buffers-1 downto 0);
    signal stages : h_array(b+r downto 0);  -- how many are left, top = max, bottom = 0
    attribute dont_touch of challenge_buf, dupe_challenges, ms_responses, stages : signal is "true";
    
    signal cycles: integer range 0 to cycles_stable := 0;  -- cycles counter
    
begin

    -- receive challenge, double it and give it to the next stage
    deterministic_fire : process (gclk, fire, fire_buf, challenge) begin
        if rising_edge(gclk) then
            fire_buf(3) <= fire;
            fire_buf(2) <= fire_buf(3);
            fire_buf(1) <= fire_buf(2);
            fire_buf(0) <= fire_buf(1);
            
            challenge_buf(1) <= challenge;
            if (challenge_buf(1) /= challenge) then
                challenge_buf(0) <= (others => '0');
            else
                challenge_buf(0) <= challenge_buf(1);
            end if;
            
            if (fire_buf(3) /= fire) and (fire = '1') then
                dupe_challenges(0) <= (0 => '0', others => '1');
                dupe_challenges(1) <= (0 => '0', others => '1');
            end if;
            if (fire_buf(2) /= fire_buf(3)) and (fire_buf(3) = '1') then
                dupe_challenges(0) <= challenge_buf(0);
                dupe_challenges(1) <= challenge_buf(0);
            end if;
            if (fire_buf(1) /= fire_buf(2)) and (fire_buf(2) = '1') then
                dupe_challenges(0) <= challenge_buf(0);
                dupe_challenges(1) <= challenge_buf(0);
            end if;
            if (fire_buf(0) /= fire_buf(1)) and (fire_buf(1) = '1') then
                dupe_challenges(0) <= challenge_buf(0);
                dupe_challenges(1) <= challenge_buf(0);
            end if;
        end if;
    end process deterministic_fire;
    stages(b+r) <= dupe_challenges;
    
    -- START BOILERPLATE LAYERS
"""

inputs = list(range(0, w))
shuffle(inputs)
for i in range(b+r-1, -1, -1):  # h levels
    n = [0,0]   # two counters: n[0] and n[1]
    for j in range(0, w):       # w gates with different inputs
        if (i == b+r-1):
            if (n[0] // w != 0):
                shuffle(inputs)
                n = [0,0]
        else:
            if one_to_one:
                shuffle(inputs)
            else:
                inputs = [randint(0, w-1) for i in range(w)]
            
        
        raw_delays = [choice((0, 1)) for n in range(0, 5)]
        for k in range(0, 2):   # 2 paths with identical gates
            instance = "\n"
            generic_map = "generic map (\n"
            port_map = "port map (\n"
            if complementary_delays:
                delays = [20 * (k ^ delay) for delay in raw_delays]
            else:
                delays = [5 * sample(range(0, 5), 1)[0] for n in range(0, 5)]     # different delays!
            
            if i > r - 1:
                instance += f"boost_{i}_{k}_{j} : booster "
            else:
                instance += f"repress_{i}_{k}_{j} : represser "
                
            generic_map += f"    a_delay => {delays[0]},\n"
            generic_map += f"    b_delay => {delays[1]},\n"
            generic_map += f"    c_delay => {delays[2]},\n"
            generic_map += f"    d_delay => {delays[3]},\n"
            generic_map += f"    q_delay => {delays[4]}\n) "
            
            port_map += f"    a_in => stages({i+1})({k})({inputs[n[k] % w]}),\n"; n[k] += 1
            port_map += f"    b_in => stages({i+1})({k})({inputs[n[k] % w]}),\n"; n[k] += 1
            port_map += f"    c_in => stages({i+1})({k})({inputs[n[k] % w]}),\n"; n[k] += 1
            port_map += f"    d_in => stages({i+1})({k})({inputs[n[k] % w]}),\n"; n[k] += 1
            port_map += f"    q_out => stages({i})({k})({j})\n);\n"
            
            instance += generic_map + port_map
            vhdl += instance

vhdl += f"""
    -- END LAYERS
    
    -- arbitrate
    arbitrate : for n in w-1 downto 0 generate
        {arbiter_label}: {arbiter_component} port map (
            racer0 => stages(0)(0)(n),
            racer1 => stages(0)(1)(n),
            winner => ms_responses(response_buffers - 1)(n)
        );
    end generate arbitrate;
    
    -- rinse metastability away
    cleanup : process (gclk) begin
        if rising_edge(gclk) then
            buffers : for i in 1 to (response_buffers - 1) loop  -- because sync?
                ms_responses(i-1) <= ms_responses(i);
            end loop buffers;
            
            -- finished when stable enough
            if (ms_responses(0) /= ms_responses(1)) then
                cycles <= 0;
                finished <= '0';
            elsif (cycles < cycles_stable) then
                cycles <= cycles + 1;
                finished <= '0';
            else
                response <= ms_responses(0);
                finished <= '1';
            end if;
        end if;
    end process cleanup; 

end dppuf{nth_dppuf}_arch;
"""
pc.copy(vhdl)
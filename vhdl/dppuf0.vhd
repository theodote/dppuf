library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dppuf0 is
generic (
    w : integer := 16;
    b : integer := 12;
    r : integer := 0;
    response_buffers: integer := 2;
    cycles_stable : integer := 2
);
port (
    gclk : in STD_LOGIC;
    challenge : in STD_LOGIC_VECTOR (w-1 downto 0);
    fire : in STD_LOGIC;    -- ACTIVE HIGH
    response : out STD_LOGIC_VECTOR (w-1 downto 0);
    finished : out STD_LOGIC
);
end dppuf0;

architecture dppuf0_arch of dppuf0 is

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
    
    component arbiter is
    port (
        racer0 : in STD_LOGIC;
        racer1 : in STD_LOGIC;
        winner: out std_logic
    );
    end component arbiter;
    
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

boost_11_0_0 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(12)(0)(9),
    b_in => stages(12)(0)(13),
    c_in => stages(12)(0)(15),
    d_in => stages(12)(0)(1),
    q_out => stages(11)(0)(0)
);

boost_11_1_0 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 10,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(12)(1)(9),
    b_in => stages(12)(1)(13),
    c_in => stages(12)(1)(15),
    d_in => stages(12)(1)(1),
    q_out => stages(11)(1)(0)
);

boost_11_0_1 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 15,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(12)(0)(8),
    b_in => stages(12)(0)(7),
    c_in => stages(12)(0)(3),
    d_in => stages(12)(0)(5),
    q_out => stages(11)(0)(1)
);

boost_11_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(12)(1)(8),
    b_in => stages(12)(1)(7),
    c_in => stages(12)(1)(3),
    d_in => stages(12)(1)(5),
    q_out => stages(11)(1)(1)
);

boost_11_0_2 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(12)(0)(10),
    b_in => stages(12)(0)(6),
    c_in => stages(12)(0)(2),
    d_in => stages(12)(0)(0),
    q_out => stages(11)(0)(2)
);

boost_11_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(12)(1)(10),
    b_in => stages(12)(1)(6),
    c_in => stages(12)(1)(2),
    d_in => stages(12)(1)(0),
    q_out => stages(11)(1)(2)
);

boost_11_0_3 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(12)(0)(12),
    b_in => stages(12)(0)(14),
    c_in => stages(12)(0)(11),
    d_in => stages(12)(0)(4),
    q_out => stages(11)(0)(3)
);

boost_11_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(12)(1)(12),
    b_in => stages(12)(1)(14),
    c_in => stages(12)(1)(11),
    d_in => stages(12)(1)(4),
    q_out => stages(11)(1)(3)
);

boost_11_0_4 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 10,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(12)(0)(6),
    b_in => stages(12)(0)(10),
    c_in => stages(12)(0)(8),
    d_in => stages(12)(0)(1),
    q_out => stages(11)(0)(4)
);

boost_11_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(12)(1)(6),
    b_in => stages(12)(1)(10),
    c_in => stages(12)(1)(8),
    d_in => stages(12)(1)(1),
    q_out => stages(11)(1)(4)
);

boost_11_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(12)(0)(3),
    b_in => stages(12)(0)(0),
    c_in => stages(12)(0)(2),
    d_in => stages(12)(0)(15),
    q_out => stages(11)(0)(5)
);

boost_11_1_5 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 5,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(12)(1)(3),
    b_in => stages(12)(1)(0),
    c_in => stages(12)(1)(2),
    d_in => stages(12)(1)(15),
    q_out => stages(11)(1)(5)
);

boost_11_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(12)(0)(11),
    b_in => stages(12)(0)(4),
    c_in => stages(12)(0)(7),
    d_in => stages(12)(0)(14),
    q_out => stages(11)(0)(6)
);

boost_11_1_6 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(12)(1)(11),
    b_in => stages(12)(1)(4),
    c_in => stages(12)(1)(7),
    d_in => stages(12)(1)(14),
    q_out => stages(11)(1)(6)
);

boost_11_0_7 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 15,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(12)(0)(9),
    b_in => stages(12)(0)(12),
    c_in => stages(12)(0)(13),
    d_in => stages(12)(0)(5),
    q_out => stages(11)(0)(7)
);

boost_11_1_7 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(12)(1)(9),
    b_in => stages(12)(1)(12),
    c_in => stages(12)(1)(13),
    d_in => stages(12)(1)(5),
    q_out => stages(11)(1)(7)
);

boost_11_0_8 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 15,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(12)(0)(1),
    b_in => stages(12)(0)(4),
    c_in => stages(12)(0)(3),
    d_in => stages(12)(0)(7),
    q_out => stages(11)(0)(8)
);

boost_11_1_8 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 0,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(12)(1)(1),
    b_in => stages(12)(1)(4),
    c_in => stages(12)(1)(3),
    d_in => stages(12)(1)(7),
    q_out => stages(11)(1)(8)
);

boost_11_0_9 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 15,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(12)(0)(13),
    b_in => stages(12)(0)(2),
    c_in => stages(12)(0)(5),
    d_in => stages(12)(0)(9),
    q_out => stages(11)(0)(9)
);

boost_11_1_9 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(12)(1)(13),
    b_in => stages(12)(1)(2),
    c_in => stages(12)(1)(5),
    d_in => stages(12)(1)(9),
    q_out => stages(11)(1)(9)
);

boost_11_0_10 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(12)(0)(11),
    b_in => stages(12)(0)(14),
    c_in => stages(12)(0)(15),
    d_in => stages(12)(0)(8),
    q_out => stages(11)(0)(10)
);

boost_11_1_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(12)(1)(11),
    b_in => stages(12)(1)(14),
    c_in => stages(12)(1)(15),
    d_in => stages(12)(1)(8),
    q_out => stages(11)(1)(10)
);

boost_11_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 5,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(12)(0)(12),
    b_in => stages(12)(0)(10),
    c_in => stages(12)(0)(6),
    d_in => stages(12)(0)(0),
    q_out => stages(11)(0)(11)
);

boost_11_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 10,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(12)(1)(12),
    b_in => stages(12)(1)(10),
    c_in => stages(12)(1)(6),
    d_in => stages(12)(1)(0),
    q_out => stages(11)(1)(11)
);

boost_11_0_12 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(12)(0)(10),
    b_in => stages(12)(0)(12),
    c_in => stages(12)(0)(3),
    d_in => stages(12)(0)(9),
    q_out => stages(11)(0)(12)
);

boost_11_1_12 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(12)(1)(10),
    b_in => stages(12)(1)(12),
    c_in => stages(12)(1)(3),
    d_in => stages(12)(1)(9),
    q_out => stages(11)(1)(12)
);

boost_11_0_13 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(12)(0)(8),
    b_in => stages(12)(0)(7),
    c_in => stages(12)(0)(5),
    d_in => stages(12)(0)(13),
    q_out => stages(11)(0)(13)
);

boost_11_1_13 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(12)(1)(8),
    b_in => stages(12)(1)(7),
    c_in => stages(12)(1)(5),
    d_in => stages(12)(1)(13),
    q_out => stages(11)(1)(13)
);

boost_11_0_14 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(12)(0)(14),
    b_in => stages(12)(0)(4),
    c_in => stages(12)(0)(1),
    d_in => stages(12)(0)(6),
    q_out => stages(11)(0)(14)
);

boost_11_1_14 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(12)(1)(14),
    b_in => stages(12)(1)(4),
    c_in => stages(12)(1)(1),
    d_in => stages(12)(1)(6),
    q_out => stages(11)(1)(14)
);

boost_11_0_15 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 10,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(12)(0)(2),
    b_in => stages(12)(0)(15),
    c_in => stages(12)(0)(11),
    d_in => stages(12)(0)(0),
    q_out => stages(11)(0)(15)
);

boost_11_1_15 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(12)(1)(2),
    b_in => stages(12)(1)(15),
    c_in => stages(12)(1)(11),
    d_in => stages(12)(1)(0),
    q_out => stages(11)(1)(15)
);

boost_10_0_0 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(11)(0)(8),
    b_in => stages(11)(0)(1),
    c_in => stages(11)(0)(6),
    d_in => stages(11)(0)(10),
    q_out => stages(10)(0)(0)
);

boost_10_1_0 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 15,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(11)(1)(8),
    b_in => stages(11)(1)(1),
    c_in => stages(11)(1)(6),
    d_in => stages(11)(1)(10),
    q_out => stages(10)(1)(0)
);

boost_10_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 5,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(11)(0)(10),
    b_in => stages(11)(0)(9),
    c_in => stages(11)(0)(14),
    d_in => stages(11)(0)(6),
    q_out => stages(10)(0)(1)
);

boost_10_1_1 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 10,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(11)(1)(10),
    b_in => stages(11)(1)(9),
    c_in => stages(11)(1)(14),
    d_in => stages(11)(1)(6),
    q_out => stages(10)(1)(1)
);

boost_10_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(11)(0)(13),
    b_in => stages(11)(0)(12),
    c_in => stages(11)(0)(9),
    d_in => stages(11)(0)(2),
    q_out => stages(10)(0)(2)
);

boost_10_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 0,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(11)(1)(13),
    b_in => stages(11)(1)(12),
    c_in => stages(11)(1)(9),
    d_in => stages(11)(1)(2),
    q_out => stages(10)(1)(2)
);

boost_10_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 10,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(11)(0)(7),
    b_in => stages(11)(0)(4),
    c_in => stages(11)(0)(7),
    d_in => stages(11)(0)(15),
    q_out => stages(10)(0)(3)
);

boost_10_1_3 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 15,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(11)(1)(7),
    b_in => stages(11)(1)(4),
    c_in => stages(11)(1)(7),
    d_in => stages(11)(1)(15),
    q_out => stages(10)(1)(3)
);

boost_10_0_4 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 15,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(11)(0)(6),
    b_in => stages(11)(0)(3),
    c_in => stages(11)(0)(6),
    d_in => stages(11)(0)(14),
    q_out => stages(10)(0)(4)
);

boost_10_1_4 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 0,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(11)(1)(6),
    b_in => stages(11)(1)(3),
    c_in => stages(11)(1)(6),
    d_in => stages(11)(1)(14),
    q_out => stages(10)(1)(4)
);

boost_10_0_5 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(11)(0)(10),
    b_in => stages(11)(0)(10),
    c_in => stages(11)(0)(0),
    d_in => stages(11)(0)(10),
    q_out => stages(10)(0)(5)
);

boost_10_1_5 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 10,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(11)(1)(10),
    b_in => stages(11)(1)(10),
    c_in => stages(11)(1)(0),
    d_in => stages(11)(1)(10),
    q_out => stages(10)(1)(5)
);

boost_10_0_6 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 5,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(11)(0)(12),
    b_in => stages(11)(0)(8),
    c_in => stages(11)(0)(4),
    d_in => stages(11)(0)(6),
    q_out => stages(10)(0)(6)
);

boost_10_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(11)(1)(12),
    b_in => stages(11)(1)(8),
    c_in => stages(11)(1)(4),
    d_in => stages(11)(1)(6),
    q_out => stages(10)(1)(6)
);

boost_10_0_7 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(11)(0)(8),
    b_in => stages(11)(0)(1),
    c_in => stages(11)(0)(0),
    d_in => stages(11)(0)(3),
    q_out => stages(10)(0)(7)
);

boost_10_1_7 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 5,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(11)(1)(8),
    b_in => stages(11)(1)(1),
    c_in => stages(11)(1)(0),
    d_in => stages(11)(1)(3),
    q_out => stages(10)(1)(7)
);

boost_10_0_8 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 20,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(11)(0)(0),
    b_in => stages(11)(0)(14),
    c_in => stages(11)(0)(12),
    d_in => stages(11)(0)(0),
    q_out => stages(10)(0)(8)
);

boost_10_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(11)(1)(0),
    b_in => stages(11)(1)(14),
    c_in => stages(11)(1)(12),
    d_in => stages(11)(1)(0),
    q_out => stages(10)(1)(8)
);

boost_10_0_9 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(11)(0)(10),
    b_in => stages(11)(0)(3),
    c_in => stages(11)(0)(3),
    d_in => stages(11)(0)(11),
    q_out => stages(10)(0)(9)
);

boost_10_1_9 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(11)(1)(10),
    b_in => stages(11)(1)(3),
    c_in => stages(11)(1)(3),
    d_in => stages(11)(1)(11),
    q_out => stages(10)(1)(9)
);

boost_10_0_10 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(11)(0)(15),
    b_in => stages(11)(0)(13),
    c_in => stages(11)(0)(2),
    d_in => stages(11)(0)(8),
    q_out => stages(10)(0)(10)
);

boost_10_1_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(11)(1)(15),
    b_in => stages(11)(1)(13),
    c_in => stages(11)(1)(2),
    d_in => stages(11)(1)(8),
    q_out => stages(10)(1)(10)
);

boost_10_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 0,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(11)(0)(11),
    b_in => stages(11)(0)(11),
    c_in => stages(11)(0)(13),
    d_in => stages(11)(0)(10),
    q_out => stages(10)(0)(11)
);

boost_10_1_11 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(11)(1)(11),
    b_in => stages(11)(1)(11),
    c_in => stages(11)(1)(13),
    d_in => stages(11)(1)(10),
    q_out => stages(10)(1)(11)
);

boost_10_0_12 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 20,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(11)(0)(6),
    b_in => stages(11)(0)(1),
    c_in => stages(11)(0)(7),
    d_in => stages(11)(0)(6),
    q_out => stages(10)(0)(12)
);

boost_10_1_12 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(11)(1)(6),
    b_in => stages(11)(1)(1),
    c_in => stages(11)(1)(7),
    d_in => stages(11)(1)(6),
    q_out => stages(10)(1)(12)
);

boost_10_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(11)(0)(1),
    b_in => stages(11)(0)(0),
    c_in => stages(11)(0)(15),
    d_in => stages(11)(0)(13),
    q_out => stages(10)(0)(13)
);

boost_10_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 20,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(11)(1)(1),
    b_in => stages(11)(1)(0),
    c_in => stages(11)(1)(15),
    d_in => stages(11)(1)(13),
    q_out => stages(10)(1)(13)
);

boost_10_0_14 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(11)(0)(3),
    b_in => stages(11)(0)(6),
    c_in => stages(11)(0)(13),
    d_in => stages(11)(0)(0),
    q_out => stages(10)(0)(14)
);

boost_10_1_14 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(11)(1)(3),
    b_in => stages(11)(1)(6),
    c_in => stages(11)(1)(13),
    d_in => stages(11)(1)(0),
    q_out => stages(10)(1)(14)
);

boost_10_0_15 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(11)(0)(8),
    b_in => stages(11)(0)(11),
    c_in => stages(11)(0)(9),
    d_in => stages(11)(0)(15),
    q_out => stages(10)(0)(15)
);

boost_10_1_15 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(11)(1)(8),
    b_in => stages(11)(1)(11),
    c_in => stages(11)(1)(9),
    d_in => stages(11)(1)(15),
    q_out => stages(10)(1)(15)
);

boost_9_0_0 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(10),
    b_in => stages(10)(0)(7),
    c_in => stages(10)(0)(15),
    d_in => stages(10)(0)(11),
    q_out => stages(9)(0)(0)
);

boost_9_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(10)(1)(10),
    b_in => stages(10)(1)(7),
    c_in => stages(10)(1)(15),
    d_in => stages(10)(1)(11),
    q_out => stages(9)(1)(0)
);

boost_9_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(10)(0)(4),
    b_in => stages(10)(0)(5),
    c_in => stages(10)(0)(3),
    d_in => stages(10)(0)(5),
    q_out => stages(9)(0)(1)
);

boost_9_1_1 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 5,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(10)(1)(4),
    b_in => stages(10)(1)(5),
    c_in => stages(10)(1)(3),
    d_in => stages(10)(1)(5),
    q_out => stages(9)(1)(1)
);

boost_9_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(2),
    b_in => stages(10)(0)(12),
    c_in => stages(10)(0)(5),
    d_in => stages(10)(0)(13),
    q_out => stages(9)(0)(2)
);

boost_9_1_2 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(10)(1)(2),
    b_in => stages(10)(1)(12),
    c_in => stages(10)(1)(5),
    d_in => stages(10)(1)(13),
    q_out => stages(9)(1)(2)
);

boost_9_0_3 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(4),
    b_in => stages(10)(0)(3),
    c_in => stages(10)(0)(10),
    d_in => stages(10)(0)(13),
    q_out => stages(9)(0)(3)
);

boost_9_1_3 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(10)(1)(4),
    b_in => stages(10)(1)(3),
    c_in => stages(10)(1)(10),
    d_in => stages(10)(1)(13),
    q_out => stages(9)(1)(3)
);

boost_9_0_4 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(10),
    b_in => stages(10)(0)(5),
    c_in => stages(10)(0)(8),
    d_in => stages(10)(0)(6),
    q_out => stages(9)(0)(4)
);

boost_9_1_4 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(10)(1)(10),
    b_in => stages(10)(1)(5),
    c_in => stages(10)(1)(8),
    d_in => stages(10)(1)(6),
    q_out => stages(9)(1)(4)
);

boost_9_0_5 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(12),
    b_in => stages(10)(0)(8),
    c_in => stages(10)(0)(11),
    d_in => stages(10)(0)(9),
    q_out => stages(9)(0)(5)
);

boost_9_1_5 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(10)(1)(12),
    b_in => stages(10)(1)(8),
    c_in => stages(10)(1)(11),
    d_in => stages(10)(1)(9),
    q_out => stages(9)(1)(5)
);

boost_9_0_6 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 5,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(10)(0)(10),
    b_in => stages(10)(0)(15),
    c_in => stages(10)(0)(5),
    d_in => stages(10)(0)(12),
    q_out => stages(9)(0)(6)
);

boost_9_1_6 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(10)(1)(10),
    b_in => stages(10)(1)(15),
    c_in => stages(10)(1)(5),
    d_in => stages(10)(1)(12),
    q_out => stages(9)(1)(6)
);

boost_9_0_7 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 15,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(10)(0)(15),
    b_in => stages(10)(0)(13),
    c_in => stages(10)(0)(5),
    d_in => stages(10)(0)(11),
    q_out => stages(9)(0)(7)
);

boost_9_1_7 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(10)(1)(15),
    b_in => stages(10)(1)(13),
    c_in => stages(10)(1)(5),
    d_in => stages(10)(1)(11),
    q_out => stages(9)(1)(7)
);

boost_9_0_8 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(1),
    b_in => stages(10)(0)(2),
    c_in => stages(10)(0)(8),
    d_in => stages(10)(0)(5),
    q_out => stages(9)(0)(8)
);

boost_9_1_8 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(10)(1)(1),
    b_in => stages(10)(1)(2),
    c_in => stages(10)(1)(8),
    d_in => stages(10)(1)(5),
    q_out => stages(9)(1)(8)
);

boost_9_0_9 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(10)(0)(13),
    b_in => stages(10)(0)(7),
    c_in => stages(10)(0)(7),
    d_in => stages(10)(0)(14),
    q_out => stages(9)(0)(9)
);

boost_9_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 0,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(10)(1)(13),
    b_in => stages(10)(1)(7),
    c_in => stages(10)(1)(7),
    d_in => stages(10)(1)(14),
    q_out => stages(9)(1)(9)
);

boost_9_0_10 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(10)(0)(0),
    b_in => stages(10)(0)(9),
    c_in => stages(10)(0)(12),
    d_in => stages(10)(0)(4),
    q_out => stages(9)(0)(10)
);

boost_9_1_10 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 5,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(10)(1)(0),
    b_in => stages(10)(1)(9),
    c_in => stages(10)(1)(12),
    d_in => stages(10)(1)(4),
    q_out => stages(9)(1)(10)
);

boost_9_0_11 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 15,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(10)(0)(4),
    b_in => stages(10)(0)(7),
    c_in => stages(10)(0)(9),
    d_in => stages(10)(0)(4),
    q_out => stages(9)(0)(11)
);

boost_9_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 15,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(10)(1)(4),
    b_in => stages(10)(1)(7),
    c_in => stages(10)(1)(9),
    d_in => stages(10)(1)(4),
    q_out => stages(9)(1)(11)
);

boost_9_0_12 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(10)(0)(7),
    b_in => stages(10)(0)(10),
    c_in => stages(10)(0)(10),
    d_in => stages(10)(0)(14),
    q_out => stages(9)(0)(12)
);

boost_9_1_12 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 10,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(10)(1)(7),
    b_in => stages(10)(1)(10),
    c_in => stages(10)(1)(10),
    d_in => stages(10)(1)(14),
    q_out => stages(9)(1)(12)
);

boost_9_0_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(10)(0)(2),
    b_in => stages(10)(0)(6),
    c_in => stages(10)(0)(14),
    d_in => stages(10)(0)(10),
    q_out => stages(9)(0)(13)
);

boost_9_1_13 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(10)(1)(2),
    b_in => stages(10)(1)(6),
    c_in => stages(10)(1)(14),
    d_in => stages(10)(1)(10),
    q_out => stages(9)(1)(13)
);

boost_9_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(10)(0)(5),
    b_in => stages(10)(0)(3),
    c_in => stages(10)(0)(15),
    d_in => stages(10)(0)(9),
    q_out => stages(9)(0)(14)
);

boost_9_1_14 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 10,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(10)(1)(5),
    b_in => stages(10)(1)(3),
    c_in => stages(10)(1)(15),
    d_in => stages(10)(1)(9),
    q_out => stages(9)(1)(14)
);

boost_9_0_15 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(10)(0)(0),
    b_in => stages(10)(0)(5),
    c_in => stages(10)(0)(14),
    d_in => stages(10)(0)(7),
    q_out => stages(9)(0)(15)
);

boost_9_1_15 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 10,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(10)(1)(0),
    b_in => stages(10)(1)(5),
    c_in => stages(10)(1)(14),
    d_in => stages(10)(1)(7),
    q_out => stages(9)(1)(15)
);

boost_8_0_0 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(9)(0)(15),
    b_in => stages(9)(0)(4),
    c_in => stages(9)(0)(10),
    d_in => stages(9)(0)(1),
    q_out => stages(8)(0)(0)
);

boost_8_1_0 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 15,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(9)(1)(15),
    b_in => stages(9)(1)(4),
    c_in => stages(9)(1)(10),
    d_in => stages(9)(1)(1),
    q_out => stages(8)(1)(0)
);

boost_8_0_1 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 15,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(7),
    b_in => stages(9)(0)(5),
    c_in => stages(9)(0)(3),
    d_in => stages(9)(0)(11),
    q_out => stages(8)(0)(1)
);

boost_8_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(9)(1)(7),
    b_in => stages(9)(1)(5),
    c_in => stages(9)(1)(3),
    d_in => stages(9)(1)(11),
    q_out => stages(8)(1)(1)
);

boost_8_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(9)(0)(8),
    b_in => stages(9)(0)(3),
    c_in => stages(9)(0)(14),
    d_in => stages(9)(0)(8),
    q_out => stages(8)(0)(2)
);

boost_8_1_2 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(9)(1)(8),
    b_in => stages(9)(1)(3),
    c_in => stages(9)(1)(14),
    d_in => stages(9)(1)(8),
    q_out => stages(8)(1)(2)
);

boost_8_0_3 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 15,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(9)(0)(13),
    b_in => stages(9)(0)(7),
    c_in => stages(9)(0)(8),
    d_in => stages(9)(0)(3),
    q_out => stages(8)(0)(3)
);

boost_8_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(9)(1)(13),
    b_in => stages(9)(1)(7),
    c_in => stages(9)(1)(8),
    d_in => stages(9)(1)(3),
    q_out => stages(8)(1)(3)
);

boost_8_0_4 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(3),
    b_in => stages(9)(0)(15),
    c_in => stages(9)(0)(3),
    d_in => stages(9)(0)(4),
    q_out => stages(8)(0)(4)
);

boost_8_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(9)(1)(3),
    b_in => stages(9)(1)(15),
    c_in => stages(9)(1)(3),
    d_in => stages(9)(1)(4),
    q_out => stages(8)(1)(4)
);

boost_8_0_5 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 0,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(9)(0)(10),
    b_in => stages(9)(0)(1),
    c_in => stages(9)(0)(11),
    d_in => stages(9)(0)(13),
    q_out => stages(8)(0)(5)
);

boost_8_1_5 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 5,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(9)(1)(10),
    b_in => stages(9)(1)(1),
    c_in => stages(9)(1)(11),
    d_in => stages(9)(1)(13),
    q_out => stages(8)(1)(5)
);

boost_8_0_6 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 10,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(9)(0)(2),
    b_in => stages(9)(0)(0),
    c_in => stages(9)(0)(7),
    d_in => stages(9)(0)(4),
    q_out => stages(8)(0)(6)
);

boost_8_1_6 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 5,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(9)(1)(2),
    b_in => stages(9)(1)(0),
    c_in => stages(9)(1)(7),
    d_in => stages(9)(1)(4),
    q_out => stages(8)(1)(6)
);

boost_8_0_7 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 5,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(13),
    b_in => stages(9)(0)(5),
    c_in => stages(9)(0)(4),
    d_in => stages(9)(0)(15),
    q_out => stages(8)(0)(7)
);

boost_8_1_7 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 5,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(9)(1)(13),
    b_in => stages(9)(1)(5),
    c_in => stages(9)(1)(4),
    d_in => stages(9)(1)(15),
    q_out => stages(8)(1)(7)
);

boost_8_0_8 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(9)(0)(12),
    b_in => stages(9)(0)(12),
    c_in => stages(9)(0)(6),
    d_in => stages(9)(0)(10),
    q_out => stages(8)(0)(8)
);

boost_8_1_8 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 0,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(9)(1)(12),
    b_in => stages(9)(1)(12),
    c_in => stages(9)(1)(6),
    d_in => stages(9)(1)(10),
    q_out => stages(8)(1)(8)
);

boost_8_0_9 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 20,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(9)(0)(6),
    b_in => stages(9)(0)(4),
    c_in => stages(9)(0)(7),
    d_in => stages(9)(0)(6),
    q_out => stages(8)(0)(9)
);

boost_8_1_9 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 10,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(9)(1)(6),
    b_in => stages(9)(1)(4),
    c_in => stages(9)(1)(7),
    d_in => stages(9)(1)(6),
    q_out => stages(8)(1)(9)
);

boost_8_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 5,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(9)(0)(9),
    b_in => stages(9)(0)(15),
    c_in => stages(9)(0)(5),
    d_in => stages(9)(0)(5),
    q_out => stages(8)(0)(10)
);

boost_8_1_10 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(9)(1)(9),
    b_in => stages(9)(1)(15),
    c_in => stages(9)(1)(5),
    d_in => stages(9)(1)(5),
    q_out => stages(8)(1)(10)
);

boost_8_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(9)(0)(11),
    b_in => stages(9)(0)(5),
    c_in => stages(9)(0)(3),
    d_in => stages(9)(0)(12),
    q_out => stages(8)(0)(11)
);

boost_8_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(9)(1)(11),
    b_in => stages(9)(1)(5),
    c_in => stages(9)(1)(3),
    d_in => stages(9)(1)(12),
    q_out => stages(8)(1)(11)
);

boost_8_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(9)(0)(14),
    b_in => stages(9)(0)(14),
    c_in => stages(9)(0)(13),
    d_in => stages(9)(0)(7),
    q_out => stages(8)(0)(12)
);

boost_8_1_12 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 10,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(9)(1)(14),
    b_in => stages(9)(1)(14),
    c_in => stages(9)(1)(13),
    d_in => stages(9)(1)(7),
    q_out => stages(8)(1)(12)
);

boost_8_0_13 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(11),
    b_in => stages(9)(0)(8),
    c_in => stages(9)(0)(6),
    d_in => stages(9)(0)(7),
    q_out => stages(8)(0)(13)
);

boost_8_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(9)(1)(11),
    b_in => stages(9)(1)(8),
    c_in => stages(9)(1)(6),
    d_in => stages(9)(1)(7),
    q_out => stages(8)(1)(13)
);

boost_8_0_14 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 15,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(13),
    b_in => stages(9)(0)(6),
    c_in => stages(9)(0)(8),
    d_in => stages(9)(0)(2),
    q_out => stages(8)(0)(14)
);

boost_8_1_14 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 10,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(9)(1)(13),
    b_in => stages(9)(1)(6),
    c_in => stages(9)(1)(8),
    d_in => stages(9)(1)(2),
    q_out => stages(8)(1)(14)
);

boost_8_0_15 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 20,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(9)(0)(3),
    b_in => stages(9)(0)(5),
    c_in => stages(9)(0)(6),
    d_in => stages(9)(0)(2),
    q_out => stages(8)(0)(15)
);

boost_8_1_15 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(9)(1)(3),
    b_in => stages(9)(1)(5),
    c_in => stages(9)(1)(6),
    d_in => stages(9)(1)(2),
    q_out => stages(8)(1)(15)
);

boost_7_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(8)(0)(9),
    b_in => stages(8)(0)(1),
    c_in => stages(8)(0)(14),
    d_in => stages(8)(0)(5),
    q_out => stages(7)(0)(0)
);

boost_7_1_0 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(8)(1)(9),
    b_in => stages(8)(1)(1),
    c_in => stages(8)(1)(14),
    d_in => stages(8)(1)(5),
    q_out => stages(7)(1)(0)
);

boost_7_0_1 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(8)(0)(3),
    b_in => stages(8)(0)(6),
    c_in => stages(8)(0)(2),
    d_in => stages(8)(0)(7),
    q_out => stages(7)(0)(1)
);

boost_7_1_1 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 5,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(3),
    b_in => stages(8)(1)(6),
    c_in => stages(8)(1)(2),
    d_in => stages(8)(1)(7),
    q_out => stages(7)(1)(1)
);

boost_7_0_2 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 15,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(8)(0)(6),
    b_in => stages(8)(0)(3),
    c_in => stages(8)(0)(8),
    d_in => stages(8)(0)(15),
    q_out => stages(7)(0)(2)
);

boost_7_1_2 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 20,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(8)(1)(6),
    b_in => stages(8)(1)(3),
    c_in => stages(8)(1)(8),
    d_in => stages(8)(1)(15),
    q_out => stages(7)(1)(2)
);

boost_7_0_3 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(8)(0)(10),
    b_in => stages(8)(0)(5),
    c_in => stages(8)(0)(10),
    d_in => stages(8)(0)(14),
    q_out => stages(7)(0)(3)
);

boost_7_1_3 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(8)(1)(10),
    b_in => stages(8)(1)(5),
    c_in => stages(8)(1)(10),
    d_in => stages(8)(1)(14),
    q_out => stages(7)(1)(3)
);

boost_7_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 10,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(8)(0)(14),
    b_in => stages(8)(0)(1),
    c_in => stages(8)(0)(3),
    d_in => stages(8)(0)(8),
    q_out => stages(7)(0)(4)
);

boost_7_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 10,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(14),
    b_in => stages(8)(1)(1),
    c_in => stages(8)(1)(3),
    d_in => stages(8)(1)(8),
    q_out => stages(7)(1)(4)
);

boost_7_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 10,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(8)(0)(1),
    b_in => stages(8)(0)(14),
    c_in => stages(8)(0)(13),
    d_in => stages(8)(0)(12),
    q_out => stages(7)(0)(5)
);

boost_7_1_5 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(1),
    b_in => stages(8)(1)(14),
    c_in => stages(8)(1)(13),
    d_in => stages(8)(1)(12),
    q_out => stages(7)(1)(5)
);

boost_7_0_6 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(8)(0)(13),
    b_in => stages(8)(0)(5),
    c_in => stages(8)(0)(13),
    d_in => stages(8)(0)(0),
    q_out => stages(7)(0)(6)
);

boost_7_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(8)(1)(13),
    b_in => stages(8)(1)(5),
    c_in => stages(8)(1)(13),
    d_in => stages(8)(1)(0),
    q_out => stages(7)(1)(6)
);

boost_7_0_7 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(8)(0)(8),
    b_in => stages(8)(0)(5),
    c_in => stages(8)(0)(13),
    d_in => stages(8)(0)(7),
    q_out => stages(7)(0)(7)
);

boost_7_1_7 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(8)(1)(8),
    b_in => stages(8)(1)(5),
    c_in => stages(8)(1)(13),
    d_in => stages(8)(1)(7),
    q_out => stages(7)(1)(7)
);

boost_7_0_8 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 15,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(8)(0)(5),
    b_in => stages(8)(0)(9),
    c_in => stages(8)(0)(10),
    d_in => stages(8)(0)(15),
    q_out => stages(7)(0)(8)
);

boost_7_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(5),
    b_in => stages(8)(1)(9),
    c_in => stages(8)(1)(10),
    d_in => stages(8)(1)(15),
    q_out => stages(7)(1)(8)
);

boost_7_0_9 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 15,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(8)(0)(2),
    b_in => stages(8)(0)(1),
    c_in => stages(8)(0)(5),
    d_in => stages(8)(0)(9),
    q_out => stages(7)(0)(9)
);

boost_7_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(8)(1)(2),
    b_in => stages(8)(1)(1),
    c_in => stages(8)(1)(5),
    d_in => stages(8)(1)(9),
    q_out => stages(7)(1)(9)
);

boost_7_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(8)(0)(15),
    b_in => stages(8)(0)(0),
    c_in => stages(8)(0)(13),
    d_in => stages(8)(0)(5),
    q_out => stages(7)(0)(10)
);

boost_7_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(8)(1)(15),
    b_in => stages(8)(1)(0),
    c_in => stages(8)(1)(13),
    d_in => stages(8)(1)(5),
    q_out => stages(7)(1)(10)
);

boost_7_0_11 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(8)(0)(13),
    b_in => stages(8)(0)(9),
    c_in => stages(8)(0)(0),
    d_in => stages(8)(0)(12),
    q_out => stages(7)(0)(11)
);

boost_7_1_11 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 5,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(13),
    b_in => stages(8)(1)(9),
    c_in => stages(8)(1)(0),
    d_in => stages(8)(1)(12),
    q_out => stages(7)(1)(11)
);

boost_7_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(8)(0)(8),
    b_in => stages(8)(0)(2),
    c_in => stages(8)(0)(5),
    d_in => stages(8)(0)(1),
    q_out => stages(7)(0)(12)
);

boost_7_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 15,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(8)(1)(8),
    b_in => stages(8)(1)(2),
    c_in => stages(8)(1)(5),
    d_in => stages(8)(1)(1),
    q_out => stages(7)(1)(12)
);

boost_7_0_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(8)(0)(3),
    b_in => stages(8)(0)(0),
    c_in => stages(8)(0)(14),
    d_in => stages(8)(0)(3),
    q_out => stages(7)(0)(13)
);

boost_7_1_13 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 0,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(8)(1)(3),
    b_in => stages(8)(1)(0),
    c_in => stages(8)(1)(14),
    d_in => stages(8)(1)(3),
    q_out => stages(7)(1)(13)
);

boost_7_0_14 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 10,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(8)(0)(11),
    b_in => stages(8)(0)(4),
    c_in => stages(8)(0)(1),
    d_in => stages(8)(0)(6),
    q_out => stages(7)(0)(14)
);

boost_7_1_14 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(8)(1)(11),
    b_in => stages(8)(1)(4),
    c_in => stages(8)(1)(1),
    d_in => stages(8)(1)(6),
    q_out => stages(7)(1)(14)
);

boost_7_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(8)(0)(1),
    b_in => stages(8)(0)(1),
    c_in => stages(8)(0)(6),
    d_in => stages(8)(0)(7),
    q_out => stages(7)(0)(15)
);

boost_7_1_15 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 10,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(8)(1)(1),
    b_in => stages(8)(1)(1),
    c_in => stages(8)(1)(6),
    d_in => stages(8)(1)(7),
    q_out => stages(7)(1)(15)
);

boost_6_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 5,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(10),
    b_in => stages(7)(0)(11),
    c_in => stages(7)(0)(7),
    d_in => stages(7)(0)(14),
    q_out => stages(6)(0)(0)
);

boost_6_1_0 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 5,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(10),
    b_in => stages(7)(1)(11),
    c_in => stages(7)(1)(7),
    d_in => stages(7)(1)(14),
    q_out => stages(6)(1)(0)
);

boost_6_0_1 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 15,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(7),
    d_in => stages(7)(0)(0),
    q_out => stages(6)(0)(1)
);

boost_6_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(7),
    d_in => stages(7)(1)(0),
    q_out => stages(6)(1)(1)
);

boost_6_0_2 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(2),
    c_in => stages(7)(0)(3),
    d_in => stages(7)(0)(1),
    q_out => stages(6)(0)(2)
);

boost_6_1_2 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 5,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(2),
    c_in => stages(7)(1)(3),
    d_in => stages(7)(1)(1),
    q_out => stages(6)(1)(2)
);

boost_6_0_3 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(8),
    b_in => stages(7)(0)(10),
    c_in => stages(7)(0)(6),
    d_in => stages(7)(0)(0),
    q_out => stages(6)(0)(3)
);

boost_6_1_3 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(8),
    b_in => stages(7)(1)(10),
    c_in => stages(7)(1)(6),
    d_in => stages(7)(1)(0),
    q_out => stages(6)(1)(3)
);

boost_6_0_4 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(7)(0)(6),
    b_in => stages(7)(0)(12),
    c_in => stages(7)(0)(13),
    d_in => stages(7)(0)(3),
    q_out => stages(6)(0)(4)
);

boost_6_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(7)(1)(6),
    b_in => stages(7)(1)(12),
    c_in => stages(7)(1)(13),
    d_in => stages(7)(1)(3),
    q_out => stages(6)(1)(4)
);

boost_6_0_5 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(6),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(15),
    d_in => stages(7)(0)(9),
    q_out => stages(6)(0)(5)
);

boost_6_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 15,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(7)(1)(6),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(15),
    d_in => stages(7)(1)(9),
    q_out => stages(6)(1)(5)
);

boost_6_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(14),
    b_in => stages(7)(0)(4),
    c_in => stages(7)(0)(0),
    d_in => stages(7)(0)(3),
    q_out => stages(6)(0)(6)
);

boost_6_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(14),
    b_in => stages(7)(1)(4),
    c_in => stages(7)(1)(0),
    d_in => stages(7)(1)(3),
    q_out => stages(6)(1)(6)
);

boost_6_0_7 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(2),
    b_in => stages(7)(0)(15),
    c_in => stages(7)(0)(1),
    d_in => stages(7)(0)(5),
    q_out => stages(6)(0)(7)
);

boost_6_1_7 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 10,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(2),
    b_in => stages(7)(1)(15),
    c_in => stages(7)(1)(1),
    d_in => stages(7)(1)(5),
    q_out => stages(6)(1)(7)
);

boost_6_0_8 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 10,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(6),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(1),
    d_in => stages(7)(0)(10),
    q_out => stages(6)(0)(8)
);

boost_6_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 15,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(7)(1)(6),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(1),
    d_in => stages(7)(1)(10),
    q_out => stages(6)(1)(8)
);

boost_6_0_9 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(10),
    b_in => stages(7)(0)(11),
    c_in => stages(7)(0)(12),
    d_in => stages(7)(0)(10),
    q_out => stages(6)(0)(9)
);

boost_6_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(7)(1)(10),
    b_in => stages(7)(1)(11),
    c_in => stages(7)(1)(12),
    d_in => stages(7)(1)(10),
    q_out => stages(6)(1)(9)
);

boost_6_0_10 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(14),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(14),
    d_in => stages(7)(0)(9),
    q_out => stages(6)(0)(10)
);

boost_6_1_10 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(7)(1)(14),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(14),
    d_in => stages(7)(1)(9),
    q_out => stages(6)(1)(10)
);

boost_6_0_11 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(7)(0)(8),
    b_in => stages(7)(0)(3),
    c_in => stages(7)(0)(12),
    d_in => stages(7)(0)(14),
    q_out => stages(6)(0)(11)
);

boost_6_1_11 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(8),
    b_in => stages(7)(1)(3),
    c_in => stages(7)(1)(12),
    d_in => stages(7)(1)(14),
    q_out => stages(6)(1)(11)
);

boost_6_0_12 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(8),
    b_in => stages(7)(0)(12),
    c_in => stages(7)(0)(5),
    d_in => stages(7)(0)(2),
    q_out => stages(6)(0)(12)
);

boost_6_1_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(8),
    b_in => stages(7)(1)(12),
    c_in => stages(7)(1)(5),
    d_in => stages(7)(1)(2),
    q_out => stages(6)(1)(12)
);

boost_6_0_13 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 5,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(7)(0)(12),
    b_in => stages(7)(0)(2),
    c_in => stages(7)(0)(4),
    d_in => stages(7)(0)(0),
    q_out => stages(6)(0)(13)
);

boost_6_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(7)(1)(12),
    b_in => stages(7)(1)(2),
    c_in => stages(7)(1)(4),
    d_in => stages(7)(1)(0),
    q_out => stages(6)(1)(13)
);

boost_6_0_14 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 15,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(6),
    b_in => stages(7)(0)(13),
    c_in => stages(7)(0)(5),
    d_in => stages(7)(0)(11),
    q_out => stages(6)(0)(14)
);

boost_6_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 15,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(7)(1)(6),
    b_in => stages(7)(1)(13),
    c_in => stages(7)(1)(5),
    d_in => stages(7)(1)(11),
    q_out => stages(6)(1)(14)
);

boost_6_0_15 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 15,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(8),
    d_in => stages(7)(0)(4),
    q_out => stages(6)(0)(15)
);

boost_6_1_15 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 10,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(8),
    d_in => stages(7)(1)(4),
    q_out => stages(6)(1)(15)
);

boost_5_0_0 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(1),
    b_in => stages(6)(0)(5),
    c_in => stages(6)(0)(9),
    d_in => stages(6)(0)(9),
    q_out => stages(5)(0)(0)
);

boost_5_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(6)(1)(1),
    b_in => stages(6)(1)(5),
    c_in => stages(6)(1)(9),
    d_in => stages(6)(1)(9),
    q_out => stages(5)(1)(0)
);

boost_5_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 5,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(6)(0)(13),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(9),
    d_in => stages(6)(0)(5),
    q_out => stages(5)(0)(1)
);

boost_5_1_1 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(13),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(9),
    d_in => stages(6)(1)(5),
    q_out => stages(5)(1)(1)
);

boost_5_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(6)(0)(13),
    b_in => stages(6)(0)(7),
    c_in => stages(6)(0)(7),
    d_in => stages(6)(0)(14),
    q_out => stages(5)(0)(2)
);

boost_5_1_2 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 5,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(6)(1)(13),
    b_in => stages(6)(1)(7),
    c_in => stages(6)(1)(7),
    d_in => stages(6)(1)(14),
    q_out => stages(5)(1)(2)
);

boost_5_0_3 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(6)(0)(7),
    b_in => stages(6)(0)(2),
    c_in => stages(6)(0)(7),
    d_in => stages(6)(0)(2),
    q_out => stages(5)(0)(3)
);

boost_5_1_3 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(7),
    b_in => stages(6)(1)(2),
    c_in => stages(6)(1)(7),
    d_in => stages(6)(1)(2),
    q_out => stages(5)(1)(3)
);

boost_5_0_4 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 5,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(8),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(7),
    d_in => stages(6)(0)(13),
    q_out => stages(5)(0)(4)
);

boost_5_1_4 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(8),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(7),
    d_in => stages(6)(1)(13),
    q_out => stages(5)(1)(4)
);

boost_5_0_5 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 5,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(5),
    b_in => stages(6)(0)(12),
    c_in => stages(6)(0)(4),
    d_in => stages(6)(0)(14),
    q_out => stages(5)(0)(5)
);

boost_5_1_5 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(6)(1)(5),
    b_in => stages(6)(1)(12),
    c_in => stages(6)(1)(4),
    d_in => stages(6)(1)(14),
    q_out => stages(5)(1)(5)
);

boost_5_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 5,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(7),
    b_in => stages(6)(0)(6),
    c_in => stages(6)(0)(2),
    d_in => stages(6)(0)(0),
    q_out => stages(5)(0)(6)
);

boost_5_1_6 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(7),
    b_in => stages(6)(1)(6),
    c_in => stages(6)(1)(2),
    d_in => stages(6)(1)(0),
    q_out => stages(5)(1)(6)
);

boost_5_0_7 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 10,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(5),
    b_in => stages(6)(0)(10),
    c_in => stages(6)(0)(9),
    d_in => stages(6)(0)(15),
    q_out => stages(5)(0)(7)
);

boost_5_1_7 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 0,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(6)(1)(5),
    b_in => stages(6)(1)(10),
    c_in => stages(6)(1)(9),
    d_in => stages(6)(1)(15),
    q_out => stages(5)(1)(7)
);

boost_5_0_8 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 0,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(3),
    b_in => stages(6)(0)(10),
    c_in => stages(6)(0)(4),
    d_in => stages(6)(0)(6),
    q_out => stages(5)(0)(8)
);

boost_5_1_8 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 15,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(6)(1)(3),
    b_in => stages(6)(1)(10),
    c_in => stages(6)(1)(4),
    d_in => stages(6)(1)(6),
    q_out => stages(5)(1)(8)
);

boost_5_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(6)(0)(3),
    b_in => stages(6)(0)(8),
    c_in => stages(6)(0)(14),
    d_in => stages(6)(0)(0),
    q_out => stages(5)(0)(9)
);

boost_5_1_9 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(6)(1)(3),
    b_in => stages(6)(1)(8),
    c_in => stages(6)(1)(14),
    d_in => stages(6)(1)(0),
    q_out => stages(5)(1)(9)
);

boost_5_0_10 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(15),
    b_in => stages(6)(0)(5),
    c_in => stages(6)(0)(5),
    d_in => stages(6)(0)(10),
    q_out => stages(5)(0)(10)
);

boost_5_1_10 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(15),
    b_in => stages(6)(1)(5),
    c_in => stages(6)(1)(5),
    d_in => stages(6)(1)(10),
    q_out => stages(5)(1)(10)
);

boost_5_0_11 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 20,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(2),
    b_in => stages(6)(0)(1),
    c_in => stages(6)(0)(0),
    d_in => stages(6)(0)(4),
    q_out => stages(5)(0)(11)
);

boost_5_1_11 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 5,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(2),
    b_in => stages(6)(1)(1),
    c_in => stages(6)(1)(0),
    d_in => stages(6)(1)(4),
    q_out => stages(5)(1)(11)
);

boost_5_0_12 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 10,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(6)(0)(11),
    b_in => stages(6)(0)(13),
    c_in => stages(6)(0)(3),
    d_in => stages(6)(0)(11),
    q_out => stages(5)(0)(12)
);

boost_5_1_12 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 10,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(6)(1)(11),
    b_in => stages(6)(1)(13),
    c_in => stages(6)(1)(3),
    d_in => stages(6)(1)(11),
    q_out => stages(5)(1)(12)
);

boost_5_0_13 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 5,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(5),
    b_in => stages(6)(0)(6),
    c_in => stages(6)(0)(0),
    d_in => stages(6)(0)(15),
    q_out => stages(5)(0)(13)
);

boost_5_1_13 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(5),
    b_in => stages(6)(1)(6),
    c_in => stages(6)(1)(0),
    d_in => stages(6)(1)(15),
    q_out => stages(5)(1)(13)
);

boost_5_0_14 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(6)(0)(3),
    b_in => stages(6)(0)(15),
    c_in => stages(6)(0)(8),
    d_in => stages(6)(0)(6),
    q_out => stages(5)(0)(14)
);

boost_5_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(3),
    b_in => stages(6)(1)(15),
    c_in => stages(6)(1)(8),
    d_in => stages(6)(1)(6),
    q_out => stages(5)(1)(14)
);

boost_5_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(6)(0)(10),
    b_in => stages(6)(0)(8),
    c_in => stages(6)(0)(0),
    d_in => stages(6)(0)(14),
    q_out => stages(5)(0)(15)
);

boost_5_1_15 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(6)(1)(10),
    b_in => stages(6)(1)(8),
    c_in => stages(6)(1)(0),
    d_in => stages(6)(1)(14),
    q_out => stages(5)(1)(15)
);

boost_4_0_0 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(13),
    b_in => stages(5)(0)(2),
    c_in => stages(5)(0)(0),
    d_in => stages(5)(0)(9),
    q_out => stages(4)(0)(0)
);

boost_4_1_0 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(5)(1)(13),
    b_in => stages(5)(1)(2),
    c_in => stages(5)(1)(0),
    d_in => stages(5)(1)(9),
    q_out => stages(4)(1)(0)
);

boost_4_0_1 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 10,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(5)(0)(9),
    b_in => stages(5)(0)(15),
    c_in => stages(5)(0)(15),
    d_in => stages(5)(0)(8),
    q_out => stages(4)(0)(1)
);

boost_4_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(9),
    b_in => stages(5)(1)(15),
    c_in => stages(5)(1)(15),
    d_in => stages(5)(1)(8),
    q_out => stages(4)(1)(1)
);

boost_4_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 15,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(2),
    b_in => stages(5)(0)(9),
    c_in => stages(5)(0)(0),
    d_in => stages(5)(0)(0),
    q_out => stages(4)(0)(2)
);

boost_4_1_2 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 0,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(5)(1)(2),
    b_in => stages(5)(1)(9),
    c_in => stages(5)(1)(0),
    d_in => stages(5)(1)(0),
    q_out => stages(4)(1)(2)
);

boost_4_0_3 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 15,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(5)(0)(7),
    b_in => stages(5)(0)(9),
    c_in => stages(5)(0)(7),
    d_in => stages(5)(0)(14),
    q_out => stages(4)(0)(3)
);

boost_4_1_3 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 0,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(5)(1)(7),
    b_in => stages(5)(1)(9),
    c_in => stages(5)(1)(7),
    d_in => stages(5)(1)(14),
    q_out => stages(4)(1)(3)
);

boost_4_0_4 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(5)(0)(14),
    b_in => stages(5)(0)(0),
    c_in => stages(5)(0)(10),
    d_in => stages(5)(0)(11),
    q_out => stages(4)(0)(4)
);

boost_4_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(14),
    b_in => stages(5)(1)(0),
    c_in => stages(5)(1)(10),
    d_in => stages(5)(1)(11),
    q_out => stages(4)(1)(4)
);

boost_4_0_5 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(5)(0)(3),
    b_in => stages(5)(0)(7),
    c_in => stages(5)(0)(0),
    d_in => stages(5)(0)(9),
    q_out => stages(4)(0)(5)
);

boost_4_1_5 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 5,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(3),
    b_in => stages(5)(1)(7),
    c_in => stages(5)(1)(0),
    d_in => stages(5)(1)(9),
    q_out => stages(4)(1)(5)
);

boost_4_0_6 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(5)(0)(12),
    b_in => stages(5)(0)(7),
    c_in => stages(5)(0)(10),
    d_in => stages(5)(0)(7),
    q_out => stages(4)(0)(6)
);

boost_4_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 15,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(12),
    b_in => stages(5)(1)(7),
    c_in => stages(5)(1)(10),
    d_in => stages(5)(1)(7),
    q_out => stages(4)(1)(6)
);

boost_4_0_7 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(5)(0)(9),
    b_in => stages(5)(0)(11),
    c_in => stages(5)(0)(14),
    d_in => stages(5)(0)(7),
    q_out => stages(4)(0)(7)
);

boost_4_1_7 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(9),
    b_in => stages(5)(1)(11),
    c_in => stages(5)(1)(14),
    d_in => stages(5)(1)(7),
    q_out => stages(4)(1)(7)
);

boost_4_0_8 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(5)(0)(7),
    b_in => stages(5)(0)(12),
    c_in => stages(5)(0)(11),
    d_in => stages(5)(0)(14),
    q_out => stages(4)(0)(8)
);

boost_4_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(7),
    b_in => stages(5)(1)(12),
    c_in => stages(5)(1)(11),
    d_in => stages(5)(1)(14),
    q_out => stages(4)(1)(8)
);

boost_4_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 5,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(10),
    b_in => stages(5)(0)(4),
    c_in => stages(5)(0)(3),
    d_in => stages(5)(0)(11),
    q_out => stages(4)(0)(9)
);

boost_4_1_9 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(10),
    b_in => stages(5)(1)(4),
    c_in => stages(5)(1)(3),
    d_in => stages(5)(1)(11),
    q_out => stages(4)(1)(9)
);

boost_4_0_10 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 5,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(5)(0)(14),
    b_in => stages(5)(0)(7),
    c_in => stages(5)(0)(13),
    d_in => stages(5)(0)(4),
    q_out => stages(4)(0)(10)
);

boost_4_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 10,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(14),
    b_in => stages(5)(1)(7),
    c_in => stages(5)(1)(13),
    d_in => stages(5)(1)(4),
    q_out => stages(4)(1)(10)
);

boost_4_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 15,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(14),
    b_in => stages(5)(0)(7),
    c_in => stages(5)(0)(14),
    d_in => stages(5)(0)(0),
    q_out => stages(4)(0)(11)
);

boost_4_1_11 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 20,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(14),
    b_in => stages(5)(1)(7),
    c_in => stages(5)(1)(14),
    d_in => stages(5)(1)(0),
    q_out => stages(4)(1)(11)
);

boost_4_0_12 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 5,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(7),
    b_in => stages(5)(0)(2),
    c_in => stages(5)(0)(15),
    d_in => stages(5)(0)(7),
    q_out => stages(4)(0)(12)
);

boost_4_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 20,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(5)(1)(7),
    b_in => stages(5)(1)(2),
    c_in => stages(5)(1)(15),
    d_in => stages(5)(1)(7),
    q_out => stages(4)(1)(12)
);

boost_4_0_13 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(5)(0)(3),
    b_in => stages(5)(0)(2),
    c_in => stages(5)(0)(13),
    d_in => stages(5)(0)(7),
    q_out => stages(4)(0)(13)
);

boost_4_1_13 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 0,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(5)(1)(3),
    b_in => stages(5)(1)(2),
    c_in => stages(5)(1)(13),
    d_in => stages(5)(1)(7),
    q_out => stages(4)(1)(13)
);

boost_4_0_14 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 20,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(5)(0)(14),
    b_in => stages(5)(0)(2),
    c_in => stages(5)(0)(7),
    d_in => stages(5)(0)(5),
    q_out => stages(4)(0)(14)
);

boost_4_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(5)(1)(14),
    b_in => stages(5)(1)(2),
    c_in => stages(5)(1)(7),
    d_in => stages(5)(1)(5),
    q_out => stages(4)(1)(14)
);

boost_4_0_15 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 20,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(11),
    b_in => stages(5)(0)(4),
    c_in => stages(5)(0)(1),
    d_in => stages(5)(0)(2),
    q_out => stages(4)(0)(15)
);

boost_4_1_15 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(5)(1)(11),
    b_in => stages(5)(1)(4),
    c_in => stages(5)(1)(1),
    d_in => stages(5)(1)(2),
    q_out => stages(4)(1)(15)
);

boost_3_0_0 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(2),
    b_in => stages(4)(0)(15),
    c_in => stages(4)(0)(9),
    d_in => stages(4)(0)(2),
    q_out => stages(3)(0)(0)
);

boost_3_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(2),
    b_in => stages(4)(1)(15),
    c_in => stages(4)(1)(9),
    d_in => stages(4)(1)(2),
    q_out => stages(3)(1)(0)
);

boost_3_0_1 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(8),
    b_in => stages(4)(0)(10),
    c_in => stages(4)(0)(8),
    d_in => stages(4)(0)(4),
    q_out => stages(3)(0)(1)
);

boost_3_1_1 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 20,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(4)(1)(8),
    b_in => stages(4)(1)(10),
    c_in => stages(4)(1)(8),
    d_in => stages(4)(1)(4),
    q_out => stages(3)(1)(1)
);

boost_3_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 15,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(4)(0)(2),
    b_in => stages(4)(0)(0),
    c_in => stages(4)(0)(14),
    d_in => stages(4)(0)(3),
    q_out => stages(3)(0)(2)
);

boost_3_1_2 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(4)(1)(2),
    b_in => stages(4)(1)(0),
    c_in => stages(4)(1)(14),
    d_in => stages(4)(1)(3),
    q_out => stages(3)(1)(2)
);

boost_3_0_3 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(13),
    b_in => stages(4)(0)(10),
    c_in => stages(4)(0)(0),
    d_in => stages(4)(0)(5),
    q_out => stages(3)(0)(3)
);

boost_3_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 10,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(4)(1)(13),
    b_in => stages(4)(1)(10),
    c_in => stages(4)(1)(0),
    d_in => stages(4)(1)(5),
    q_out => stages(3)(1)(3)
);

boost_3_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(5),
    b_in => stages(4)(0)(6),
    c_in => stages(4)(0)(5),
    d_in => stages(4)(0)(8),
    q_out => stages(3)(0)(4)
);

boost_3_1_4 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 5,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(5),
    b_in => stages(4)(1)(6),
    c_in => stages(4)(1)(5),
    d_in => stages(4)(1)(8),
    q_out => stages(3)(1)(4)
);

boost_3_0_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(4)(0)(4),
    b_in => stages(4)(0)(7),
    c_in => stages(4)(0)(7),
    d_in => stages(4)(0)(11),
    q_out => stages(3)(0)(5)
);

boost_3_1_5 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(4)(1)(4),
    b_in => stages(4)(1)(7),
    c_in => stages(4)(1)(7),
    d_in => stages(4)(1)(11),
    q_out => stages(3)(1)(5)
);

boost_3_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(2),
    b_in => stages(4)(0)(8),
    c_in => stages(4)(0)(14),
    d_in => stages(4)(0)(0),
    q_out => stages(3)(0)(6)
);

boost_3_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(4)(1)(2),
    b_in => stages(4)(1)(8),
    c_in => stages(4)(1)(14),
    d_in => stages(4)(1)(0),
    q_out => stages(3)(1)(6)
);

boost_3_0_7 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(10),
    b_in => stages(4)(0)(8),
    c_in => stages(4)(0)(12),
    d_in => stages(4)(0)(4),
    q_out => stages(3)(0)(7)
);

boost_3_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 10,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(4)(1)(10),
    b_in => stages(4)(1)(8),
    c_in => stages(4)(1)(12),
    d_in => stages(4)(1)(4),
    q_out => stages(3)(1)(7)
);

boost_3_0_8 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(4)(0)(8),
    b_in => stages(4)(0)(0),
    c_in => stages(4)(0)(4),
    d_in => stages(4)(0)(7),
    q_out => stages(3)(0)(8)
);

boost_3_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(8),
    b_in => stages(4)(1)(0),
    c_in => stages(4)(1)(4),
    d_in => stages(4)(1)(7),
    q_out => stages(3)(1)(8)
);

boost_3_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(10),
    b_in => stages(4)(0)(13),
    c_in => stages(4)(0)(6),
    d_in => stages(4)(0)(15),
    q_out => stages(3)(0)(9)
);

boost_3_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 10,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(10),
    b_in => stages(4)(1)(13),
    c_in => stages(4)(1)(6),
    d_in => stages(4)(1)(15),
    q_out => stages(3)(1)(9)
);

boost_3_0_10 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(3),
    b_in => stages(4)(0)(2),
    c_in => stages(4)(0)(8),
    d_in => stages(4)(0)(15),
    q_out => stages(3)(0)(10)
);

boost_3_1_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(3),
    b_in => stages(4)(1)(2),
    c_in => stages(4)(1)(8),
    d_in => stages(4)(1)(15),
    q_out => stages(3)(1)(10)
);

boost_3_0_11 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 5,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(4)(0)(15),
    b_in => stages(4)(0)(10),
    c_in => stages(4)(0)(4),
    d_in => stages(4)(0)(11),
    q_out => stages(3)(0)(11)
);

boost_3_1_11 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 15,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(15),
    b_in => stages(4)(1)(10),
    c_in => stages(4)(1)(4),
    d_in => stages(4)(1)(11),
    q_out => stages(3)(1)(11)
);

boost_3_0_12 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 20,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(4)(0)(1),
    b_in => stages(4)(0)(3),
    c_in => stages(4)(0)(9),
    d_in => stages(4)(0)(12),
    q_out => stages(3)(0)(12)
);

boost_3_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(4)(1)(1),
    b_in => stages(4)(1)(3),
    c_in => stages(4)(1)(9),
    d_in => stages(4)(1)(12),
    q_out => stages(3)(1)(12)
);

boost_3_0_13 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(4)(0)(2),
    b_in => stages(4)(0)(15),
    c_in => stages(4)(0)(9),
    d_in => stages(4)(0)(7),
    q_out => stages(3)(0)(13)
);

boost_3_1_13 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 20,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(2),
    b_in => stages(4)(1)(15),
    c_in => stages(4)(1)(9),
    d_in => stages(4)(1)(7),
    q_out => stages(3)(1)(13)
);

boost_3_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 15,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(0),
    b_in => stages(4)(0)(6),
    c_in => stages(4)(0)(9),
    d_in => stages(4)(0)(15),
    q_out => stages(3)(0)(14)
);

boost_3_1_14 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(0),
    b_in => stages(4)(1)(6),
    c_in => stages(4)(1)(9),
    d_in => stages(4)(1)(15),
    q_out => stages(3)(1)(14)
);

boost_3_0_15 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(4)(0)(9),
    b_in => stages(4)(0)(9),
    c_in => stages(4)(0)(4),
    d_in => stages(4)(0)(11),
    q_out => stages(3)(0)(15)
);

boost_3_1_15 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(9),
    b_in => stages(4)(1)(9),
    c_in => stages(4)(1)(4),
    d_in => stages(4)(1)(11),
    q_out => stages(3)(1)(15)
);

boost_2_0_0 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(3)(0)(15),
    b_in => stages(3)(0)(6),
    c_in => stages(3)(0)(10),
    d_in => stages(3)(0)(0),
    q_out => stages(2)(0)(0)
);

boost_2_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(3)(1)(15),
    b_in => stages(3)(1)(6),
    c_in => stages(3)(1)(10),
    d_in => stages(3)(1)(0),
    q_out => stages(2)(1)(0)
);

boost_2_0_1 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(3),
    b_in => stages(3)(0)(0),
    c_in => stages(3)(0)(2),
    d_in => stages(3)(0)(12),
    q_out => stages(2)(0)(1)
);

boost_2_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(3)(1)(3),
    b_in => stages(3)(1)(0),
    c_in => stages(3)(1)(2),
    d_in => stages(3)(1)(12),
    q_out => stages(2)(1)(1)
);

boost_2_0_2 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(3)(0)(14),
    b_in => stages(3)(0)(15),
    c_in => stages(3)(0)(4),
    d_in => stages(3)(0)(15),
    q_out => stages(2)(0)(2)
);

boost_2_1_2 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(14),
    b_in => stages(3)(1)(15),
    c_in => stages(3)(1)(4),
    d_in => stages(3)(1)(15),
    q_out => stages(2)(1)(2)
);

boost_2_0_3 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 5,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(3)(0)(1),
    b_in => stages(3)(0)(13),
    c_in => stages(3)(0)(8),
    d_in => stages(3)(0)(6),
    q_out => stages(2)(0)(3)
);

boost_2_1_3 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(1),
    b_in => stages(3)(1)(13),
    c_in => stages(3)(1)(8),
    d_in => stages(3)(1)(6),
    q_out => stages(2)(1)(3)
);

boost_2_0_4 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 15,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(12),
    b_in => stages(3)(0)(12),
    c_in => stages(3)(0)(8),
    d_in => stages(3)(0)(5),
    q_out => stages(2)(0)(4)
);

boost_2_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 0,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(12),
    b_in => stages(3)(1)(12),
    c_in => stages(3)(1)(8),
    d_in => stages(3)(1)(5),
    q_out => stages(2)(1)(4)
);

boost_2_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 5,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(3),
    b_in => stages(3)(0)(15),
    c_in => stages(3)(0)(5),
    d_in => stages(3)(0)(5),
    q_out => stages(2)(0)(5)
);

boost_2_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(3)(1)(3),
    b_in => stages(3)(1)(15),
    c_in => stages(3)(1)(5),
    d_in => stages(3)(1)(5),
    q_out => stages(2)(1)(5)
);

boost_2_0_6 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(4),
    b_in => stages(3)(0)(7),
    c_in => stages(3)(0)(5),
    d_in => stages(3)(0)(13),
    q_out => stages(2)(0)(6)
);

boost_2_1_6 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 0,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(4),
    b_in => stages(3)(1)(7),
    c_in => stages(3)(1)(5),
    d_in => stages(3)(1)(13),
    q_out => stages(2)(1)(6)
);

boost_2_0_7 : booster generic map (
    a_delay => 10,
    b_delay => 10,
    c_delay => 10,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(3)(0)(9),
    b_in => stages(3)(0)(4),
    c_in => stages(3)(0)(11),
    d_in => stages(3)(0)(15),
    q_out => stages(2)(0)(7)
);

boost_2_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 15,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(9),
    b_in => stages(3)(1)(4),
    c_in => stages(3)(1)(11),
    d_in => stages(3)(1)(15),
    q_out => stages(2)(1)(7)
);

boost_2_0_8 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(3)(0)(15),
    b_in => stages(3)(0)(4),
    c_in => stages(3)(0)(12),
    d_in => stages(3)(0)(8),
    q_out => stages(2)(0)(8)
);

boost_2_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(15),
    b_in => stages(3)(1)(4),
    c_in => stages(3)(1)(12),
    d_in => stages(3)(1)(8),
    q_out => stages(2)(1)(8)
);

boost_2_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(3)(0)(7),
    b_in => stages(3)(0)(13),
    c_in => stages(3)(0)(1),
    d_in => stages(3)(0)(6),
    q_out => stages(2)(0)(9)
);

boost_2_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 10,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(7),
    b_in => stages(3)(1)(13),
    c_in => stages(3)(1)(1),
    d_in => stages(3)(1)(6),
    q_out => stages(2)(1)(9)
);

boost_2_0_10 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(3)(0)(2),
    b_in => stages(3)(0)(3),
    c_in => stages(3)(0)(5),
    d_in => stages(3)(0)(9),
    q_out => stages(2)(0)(10)
);

boost_2_1_10 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 5,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(2),
    b_in => stages(3)(1)(3),
    c_in => stages(3)(1)(5),
    d_in => stages(3)(1)(9),
    q_out => stages(2)(1)(10)
);

boost_2_0_11 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 20,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(2),
    b_in => stages(3)(0)(9),
    c_in => stages(3)(0)(0),
    d_in => stages(3)(0)(1),
    q_out => stages(2)(0)(11)
);

boost_2_1_11 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 5,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(2),
    b_in => stages(3)(1)(9),
    c_in => stages(3)(1)(0),
    d_in => stages(3)(1)(1),
    q_out => stages(2)(1)(11)
);

boost_2_0_12 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(3)(0)(11),
    b_in => stages(3)(0)(0),
    c_in => stages(3)(0)(8),
    d_in => stages(3)(0)(7),
    q_out => stages(2)(0)(12)
);

boost_2_1_12 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 20,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(11),
    b_in => stages(3)(1)(0),
    c_in => stages(3)(1)(8),
    d_in => stages(3)(1)(7),
    q_out => stages(2)(1)(12)
);

boost_2_0_13 : booster generic map (
    a_delay => 15,
    b_delay => 20,
    c_delay => 15,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(9),
    b_in => stages(3)(0)(2),
    c_in => stages(3)(0)(14),
    d_in => stages(3)(0)(2),
    q_out => stages(2)(0)(13)
);

boost_2_1_13 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(9),
    b_in => stages(3)(1)(2),
    c_in => stages(3)(1)(14),
    d_in => stages(3)(1)(2),
    q_out => stages(2)(1)(13)
);

boost_2_0_14 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(13),
    b_in => stages(3)(0)(0),
    c_in => stages(3)(0)(15),
    d_in => stages(3)(0)(11),
    q_out => stages(2)(0)(14)
);

boost_2_1_14 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(3)(1)(13),
    b_in => stages(3)(1)(0),
    c_in => stages(3)(1)(15),
    d_in => stages(3)(1)(11),
    q_out => stages(2)(1)(14)
);

boost_2_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 5,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(3)(0)(7),
    b_in => stages(3)(0)(11),
    c_in => stages(3)(0)(1),
    d_in => stages(3)(0)(12),
    q_out => stages(2)(0)(15)
);

boost_2_1_15 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 15,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(3)(1)(7),
    b_in => stages(3)(1)(11),
    c_in => stages(3)(1)(1),
    d_in => stages(3)(1)(12),
    q_out => stages(2)(1)(15)
);

boost_1_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 15,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(10),
    b_in => stages(2)(0)(15),
    c_in => stages(2)(0)(12),
    d_in => stages(2)(0)(0),
    q_out => stages(1)(0)(0)
);

boost_1_1_0 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 15,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(10),
    b_in => stages(2)(1)(15),
    c_in => stages(2)(1)(12),
    d_in => stages(2)(1)(0),
    q_out => stages(1)(1)(0)
);

boost_1_0_1 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(12),
    b_in => stages(2)(0)(13),
    c_in => stages(2)(0)(1),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(1)
);

boost_1_1_1 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 5,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(12),
    b_in => stages(2)(1)(13),
    c_in => stages(2)(1)(1),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(1)
);

boost_1_0_2 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 15,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(9),
    b_in => stages(2)(0)(4),
    c_in => stages(2)(0)(9),
    d_in => stages(2)(0)(14),
    q_out => stages(1)(0)(2)
);

boost_1_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(2)(1)(9),
    b_in => stages(2)(1)(4),
    c_in => stages(2)(1)(9),
    d_in => stages(2)(1)(14),
    q_out => stages(1)(1)(2)
);

boost_1_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 20,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(4),
    b_in => stages(2)(0)(14),
    c_in => stages(2)(0)(11),
    d_in => stages(2)(0)(11),
    q_out => stages(1)(0)(3)
);

boost_1_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(2)(1)(4),
    b_in => stages(2)(1)(14),
    c_in => stages(2)(1)(11),
    d_in => stages(2)(1)(11),
    q_out => stages(1)(1)(3)
);

boost_1_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 20,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(7),
    b_in => stages(2)(0)(6),
    c_in => stages(2)(0)(4),
    d_in => stages(2)(0)(8),
    q_out => stages(1)(0)(4)
);

boost_1_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(1)(7),
    b_in => stages(2)(1)(6),
    c_in => stages(2)(1)(4),
    d_in => stages(2)(1)(8),
    q_out => stages(1)(1)(4)
);

boost_1_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 15,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(2)(0)(8),
    b_in => stages(2)(0)(3),
    c_in => stages(2)(0)(2),
    d_in => stages(2)(0)(2),
    q_out => stages(1)(0)(5)
);

boost_1_1_5 : booster generic map (
    a_delay => 10,
    b_delay => 0,
    c_delay => 15,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(2)(1)(8),
    b_in => stages(2)(1)(3),
    c_in => stages(2)(1)(2),
    d_in => stages(2)(1)(2),
    q_out => stages(1)(1)(5)
);

boost_1_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 5,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(14),
    b_in => stages(2)(0)(14),
    c_in => stages(2)(0)(10),
    d_in => stages(2)(0)(3),
    q_out => stages(1)(0)(6)
);

boost_1_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 15,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(2)(1)(14),
    b_in => stages(2)(1)(14),
    c_in => stages(2)(1)(10),
    d_in => stages(2)(1)(3),
    q_out => stages(1)(1)(6)
);

boost_1_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 10,
    c_delay => 10,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(11),
    b_in => stages(2)(0)(1),
    c_in => stages(2)(0)(7),
    d_in => stages(2)(0)(4),
    q_out => stages(1)(0)(7)
);

boost_1_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 5,
    c_delay => 0,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(2)(1)(11),
    b_in => stages(2)(1)(1),
    c_in => stages(2)(1)(7),
    d_in => stages(2)(1)(4),
    q_out => stages(1)(1)(7)
);

boost_1_0_8 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(6),
    b_in => stages(2)(0)(4),
    c_in => stages(2)(0)(5),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(8)
);

boost_1_1_8 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 0,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(2)(1)(6),
    b_in => stages(2)(1)(4),
    c_in => stages(2)(1)(5),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(8)
);

boost_1_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(2)(0)(11),
    b_in => stages(2)(0)(1),
    c_in => stages(2)(0)(2),
    d_in => stages(2)(0)(12),
    q_out => stages(1)(0)(9)
);

boost_1_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 20,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(2)(1)(11),
    b_in => stages(2)(1)(1),
    c_in => stages(2)(1)(2),
    d_in => stages(2)(1)(12),
    q_out => stages(1)(1)(9)
);

boost_1_0_10 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 0,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(11),
    b_in => stages(2)(0)(3),
    c_in => stages(2)(0)(3),
    d_in => stages(2)(0)(14),
    q_out => stages(1)(0)(10)
);

boost_1_1_10 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 10,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(2)(1)(11),
    b_in => stages(2)(1)(3),
    c_in => stages(2)(1)(3),
    d_in => stages(2)(1)(14),
    q_out => stages(1)(1)(10)
);

boost_1_0_11 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 20,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(9),
    b_in => stages(2)(0)(10),
    c_in => stages(2)(0)(11),
    d_in => stages(2)(0)(9),
    q_out => stages(1)(0)(11)
);

boost_1_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(2)(1)(9),
    b_in => stages(2)(1)(10),
    c_in => stages(2)(1)(11),
    d_in => stages(2)(1)(9),
    q_out => stages(1)(1)(11)
);

boost_1_0_12 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 15,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(15),
    b_in => stages(2)(0)(4),
    c_in => stages(2)(0)(3),
    d_in => stages(2)(0)(10),
    q_out => stages(1)(0)(12)
);

boost_1_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(1)(15),
    b_in => stages(2)(1)(4),
    c_in => stages(2)(1)(3),
    d_in => stages(2)(1)(10),
    q_out => stages(1)(1)(12)
);

boost_1_0_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(7),
    b_in => stages(2)(0)(14),
    c_in => stages(2)(0)(1),
    d_in => stages(2)(0)(4),
    q_out => stages(1)(0)(13)
);

boost_1_1_13 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(2)(1)(7),
    b_in => stages(2)(1)(14),
    c_in => stages(2)(1)(1),
    d_in => stages(2)(1)(4),
    q_out => stages(1)(1)(13)
);

boost_1_0_14 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 0,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(2)(0)(0),
    b_in => stages(2)(0)(2),
    c_in => stages(2)(0)(0),
    d_in => stages(2)(0)(3),
    q_out => stages(1)(0)(14)
);

boost_1_1_14 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 15,
    d_delay => 20,
    q_delay => 10
) port map (
    a_in => stages(2)(1)(0),
    b_in => stages(2)(1)(2),
    c_in => stages(2)(1)(0),
    d_in => stages(2)(1)(3),
    q_out => stages(1)(1)(14)
);

boost_1_0_15 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 5,
    d_delay => 5,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(8),
    b_in => stages(2)(0)(5),
    c_in => stages(2)(0)(2),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(15)
);

boost_1_1_15 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 5,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(8),
    b_in => stages(2)(1)(5),
    c_in => stages(2)(1)(2),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(15)
);

boost_0_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(3),
    b_in => stages(1)(0)(14),
    c_in => stages(1)(0)(1),
    d_in => stages(1)(0)(9),
    q_out => stages(0)(0)(0)
);

boost_0_1_0 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 5,
    d_delay => 10,
    q_delay => 10
) port map (
    a_in => stages(1)(1)(3),
    b_in => stages(1)(1)(14),
    c_in => stages(1)(1)(1),
    d_in => stages(1)(1)(9),
    q_out => stages(0)(1)(0)
);

boost_0_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 5,
    d_delay => 0,
    q_delay => 5
) port map (
    a_in => stages(1)(0)(4),
    b_in => stages(1)(0)(7),
    c_in => stages(1)(0)(7),
    d_in => stages(1)(0)(8),
    q_out => stages(0)(0)(1)
);

boost_0_1_1 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 15,
    d_delay => 10,
    q_delay => 15
) port map (
    a_in => stages(1)(1)(4),
    b_in => stages(1)(1)(7),
    c_in => stages(1)(1)(7),
    d_in => stages(1)(1)(8),
    q_out => stages(0)(1)(1)
);

boost_0_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 15
) port map (
    a_in => stages(1)(0)(10),
    b_in => stages(1)(0)(12),
    c_in => stages(1)(0)(3),
    d_in => stages(1)(0)(12),
    q_out => stages(0)(0)(2)
);

boost_0_1_2 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 15,
    d_delay => 15,
    q_delay => 15
) port map (
    a_in => stages(1)(1)(10),
    b_in => stages(1)(1)(12),
    c_in => stages(1)(1)(3),
    d_in => stages(1)(1)(12),
    q_out => stages(0)(1)(2)
);

boost_0_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 10,
    d_delay => 20,
    q_delay => 5
) port map (
    a_in => stages(1)(0)(9),
    b_in => stages(1)(0)(0),
    c_in => stages(1)(0)(10),
    d_in => stages(1)(0)(4),
    q_out => stages(0)(0)(3)
);

boost_0_1_3 : booster generic map (
    a_delay => 5,
    b_delay => 15,
    c_delay => 5,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(9),
    b_in => stages(1)(1)(0),
    c_in => stages(1)(1)(10),
    d_in => stages(1)(1)(4),
    q_out => stages(0)(1)(3)
);

boost_0_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 20,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(1)(0)(8),
    b_in => stages(1)(0)(9),
    c_in => stages(1)(0)(2),
    d_in => stages(1)(0)(12),
    q_out => stages(0)(0)(4)
);

boost_0_1_4 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 5,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(8),
    b_in => stages(1)(1)(9),
    c_in => stages(1)(1)(2),
    d_in => stages(1)(1)(12),
    q_out => stages(0)(1)(4)
);

boost_0_0_5 : booster generic map (
    a_delay => 10,
    b_delay => 15,
    c_delay => 0,
    d_delay => 5,
    q_delay => 15
) port map (
    a_in => stages(1)(0)(11),
    b_in => stages(1)(0)(6),
    c_in => stages(1)(0)(15),
    d_in => stages(1)(0)(0),
    q_out => stages(0)(0)(5)
);

boost_0_1_5 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 0,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(11),
    b_in => stages(1)(1)(6),
    c_in => stages(1)(1)(15),
    d_in => stages(1)(1)(0),
    q_out => stages(0)(1)(5)
);

boost_0_0_6 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 10,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(12),
    b_in => stages(1)(0)(13),
    c_in => stages(1)(0)(8),
    d_in => stages(1)(0)(6),
    q_out => stages(0)(0)(6)
);

boost_0_1_6 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(1)(1)(12),
    b_in => stages(1)(1)(13),
    c_in => stages(1)(1)(8),
    d_in => stages(1)(1)(6),
    q_out => stages(0)(1)(6)
);

boost_0_0_7 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(1)(0)(8),
    b_in => stages(1)(0)(11),
    c_in => stages(1)(0)(10),
    d_in => stages(1)(0)(3),
    q_out => stages(0)(0)(7)
);

boost_0_1_7 : booster generic map (
    a_delay => 5,
    b_delay => 5,
    c_delay => 5,
    d_delay => 5,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(8),
    b_in => stages(1)(1)(11),
    c_in => stages(1)(1)(10),
    d_in => stages(1)(1)(3),
    q_out => stages(0)(1)(7)
);

boost_0_0_8 : booster generic map (
    a_delay => 10,
    b_delay => 5,
    c_delay => 5,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(7),
    b_in => stages(1)(0)(9),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(5),
    q_out => stages(0)(0)(8)
);

boost_0_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 15,
    c_delay => 5,
    d_delay => 15,
    q_delay => 10
) port map (
    a_in => stages(1)(1)(7),
    b_in => stages(1)(1)(9),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(5),
    q_out => stages(0)(1)(8)
);

boost_0_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 5,
    c_delay => 0,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(15),
    b_in => stages(1)(0)(15),
    c_in => stages(1)(0)(3),
    d_in => stages(1)(0)(1),
    q_out => stages(0)(0)(9)
);

boost_0_1_9 : booster generic map (
    a_delay => 15,
    b_delay => 10,
    c_delay => 10,
    d_delay => 15,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(15),
    b_in => stages(1)(1)(15),
    c_in => stages(1)(1)(3),
    d_in => stages(1)(1)(1),
    q_out => stages(0)(1)(9)
);

boost_0_0_10 : booster generic map (
    a_delay => 15,
    b_delay => 15,
    c_delay => 20,
    d_delay => 10,
    q_delay => 5
) port map (
    a_in => stages(1)(0)(7),
    b_in => stages(1)(0)(8),
    c_in => stages(1)(0)(9),
    d_in => stages(1)(0)(3),
    q_out => stages(0)(0)(10)
);

boost_0_1_10 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 15,
    d_delay => 5,
    q_delay => 5
) port map (
    a_in => stages(1)(1)(7),
    b_in => stages(1)(1)(8),
    c_in => stages(1)(1)(9),
    d_in => stages(1)(1)(3),
    q_out => stages(0)(1)(10)
);

boost_0_0_11 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(7),
    b_in => stages(1)(0)(12),
    c_in => stages(1)(0)(13),
    d_in => stages(1)(0)(14),
    q_out => stages(0)(0)(11)
);

boost_0_1_11 : booster generic map (
    a_delay => 5,
    b_delay => 20,
    c_delay => 10,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(7),
    b_in => stages(1)(1)(12),
    c_in => stages(1)(1)(13),
    d_in => stages(1)(1)(14),
    q_out => stages(0)(1)(11)
);

boost_0_0_12 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 0,
    d_delay => 15,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(15),
    b_in => stages(1)(0)(15),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(3),
    q_out => stages(0)(0)(12)
);

boost_0_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 10,
    c_delay => 5,
    d_delay => 10,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(15),
    b_in => stages(1)(1)(15),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(3),
    q_out => stages(0)(1)(12)
);

boost_0_0_13 : booster generic map (
    a_delay => 5,
    b_delay => 10,
    c_delay => 15,
    d_delay => 10,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(9),
    b_in => stages(1)(0)(6),
    c_in => stages(1)(0)(11),
    d_in => stages(1)(0)(11),
    q_out => stages(0)(0)(13)
);

boost_0_1_13 : booster generic map (
    a_delay => 5,
    b_delay => 0,
    c_delay => 10,
    d_delay => 5,
    q_delay => 10
) port map (
    a_in => stages(1)(1)(9),
    b_in => stages(1)(1)(6),
    c_in => stages(1)(1)(11),
    d_in => stages(1)(1)(11),
    q_out => stages(0)(1)(13)
);

boost_0_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 15,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(0),
    b_in => stages(1)(0)(3),
    c_in => stages(1)(0)(14),
    d_in => stages(1)(0)(12),
    q_out => stages(0)(0)(14)
);

boost_0_1_14 : booster generic map (
    a_delay => 15,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 15
) port map (
    a_in => stages(1)(1)(0),
    b_in => stages(1)(1)(3),
    c_in => stages(1)(1)(14),
    d_in => stages(1)(1)(12),
    q_out => stages(0)(1)(14)
);

boost_0_0_15 : booster generic map (
    a_delay => 10,
    b_delay => 20,
    c_delay => 10,
    d_delay => 0,
    q_delay => 10
) port map (
    a_in => stages(1)(0)(13),
    b_in => stages(1)(0)(0),
    c_in => stages(1)(0)(10),
    d_in => stages(1)(0)(4),
    q_out => stages(0)(0)(15)
);

boost_0_1_15 : booster generic map (
    a_delay => 15,
    b_delay => 5,
    c_delay => 15,
    d_delay => 15,
    q_delay => 5
) port map (
    a_in => stages(1)(1)(13),
    b_in => stages(1)(1)(0),
    c_in => stages(1)(1)(10),
    d_in => stages(1)(1)(4),
    q_out => stages(0)(1)(15)
);

    -- END LAYERS
    
    -- arbitrate
    arbitrate : for n in w-1 downto 0 generate
        each_arbiter: arbiter port map (
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

end dppuf0_arch;

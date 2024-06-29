library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dppuf is
generic (
    w : integer := 16;
    b : integer := 6;
    r : integer := 1;
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
end dppuf;

architecture dppuf_arch of dppuf is

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
    deterministic_fire : process (gclk) begin
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

boost_6_0_0 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(6),
    b_in => stages(7)(0)(14),
    c_in => stages(7)(0)(7),
    d_in => stages(7)(0)(12),
    q_out => stages(6)(0)(0)
);

boost_6_1_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(6),
    b_in => stages(7)(1)(14),
    c_in => stages(7)(1)(7),
    d_in => stages(7)(1)(12),
    q_out => stages(6)(1)(0)
);

boost_6_0_1 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(0),
    b_in => stages(7)(0)(10),
    c_in => stages(7)(0)(8),
    d_in => stages(7)(0)(9),
    q_out => stages(6)(0)(1)
);

boost_6_1_1 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(0),
    b_in => stages(7)(1)(10),
    c_in => stages(7)(1)(8),
    d_in => stages(7)(1)(9),
    q_out => stages(6)(1)(1)
);

boost_6_0_2 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(3),
    b_in => stages(7)(0)(4),
    c_in => stages(7)(0)(13),
    d_in => stages(7)(0)(15),
    q_out => stages(6)(0)(2)
);

boost_6_1_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(3),
    b_in => stages(7)(1)(4),
    c_in => stages(7)(1)(13),
    d_in => stages(7)(1)(15),
    q_out => stages(6)(1)(2)
);

boost_6_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(11),
    c_in => stages(7)(0)(2),
    d_in => stages(7)(0)(1),
    q_out => stages(6)(0)(3)
);

boost_6_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(11),
    c_in => stages(7)(1)(2),
    d_in => stages(7)(1)(1),
    q_out => stages(6)(1)(3)
);

boost_6_0_4 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(15),
    b_in => stages(7)(0)(12),
    c_in => stages(7)(0)(7),
    d_in => stages(7)(0)(11),
    q_out => stages(6)(0)(4)
);

boost_6_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(15),
    b_in => stages(7)(1)(12),
    c_in => stages(7)(1)(7),
    d_in => stages(7)(1)(11),
    q_out => stages(6)(1)(4)
);

boost_6_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(0),
    b_in => stages(7)(0)(9),
    c_in => stages(7)(0)(8),
    d_in => stages(7)(0)(2),
    q_out => stages(6)(0)(5)
);

boost_6_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(0),
    b_in => stages(7)(1)(9),
    c_in => stages(7)(1)(8),
    d_in => stages(7)(1)(2),
    q_out => stages(6)(1)(5)
);

boost_6_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(1),
    c_in => stages(7)(0)(3),
    d_in => stages(7)(0)(10),
    q_out => stages(6)(0)(6)
);

boost_6_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(1),
    c_in => stages(7)(1)(3),
    d_in => stages(7)(1)(10),
    q_out => stages(6)(1)(6)
);

boost_6_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(14),
    b_in => stages(7)(0)(4),
    c_in => stages(7)(0)(6),
    d_in => stages(7)(0)(13),
    q_out => stages(6)(0)(7)
);

boost_6_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(14),
    b_in => stages(7)(1)(4),
    c_in => stages(7)(1)(6),
    d_in => stages(7)(1)(13),
    q_out => stages(6)(1)(7)
);

boost_6_0_8 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(11),
    b_in => stages(7)(0)(12),
    c_in => stages(7)(0)(10),
    d_in => stages(7)(0)(0),
    q_out => stages(6)(0)(8)
);

boost_6_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(11),
    b_in => stages(7)(1)(12),
    c_in => stages(7)(1)(10),
    d_in => stages(7)(1)(0),
    q_out => stages(6)(1)(8)
);

boost_6_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(1),
    b_in => stages(7)(0)(13),
    c_in => stages(7)(0)(8),
    d_in => stages(7)(0)(6),
    q_out => stages(6)(0)(9)
);

boost_6_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(1),
    b_in => stages(7)(1)(13),
    c_in => stages(7)(1)(8),
    d_in => stages(7)(1)(6),
    q_out => stages(6)(1)(9)
);

boost_6_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(2),
    c_in => stages(7)(0)(15),
    d_in => stages(7)(0)(3),
    q_out => stages(6)(0)(10)
);

boost_6_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(2),
    c_in => stages(7)(1)(15),
    d_in => stages(7)(1)(3),
    q_out => stages(6)(1)(10)
);

boost_6_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(0)(4),
    b_in => stages(7)(0)(14),
    c_in => stages(7)(0)(9),
    d_in => stages(7)(0)(7),
    q_out => stages(6)(0)(11)
);

boost_6_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(1)(4),
    b_in => stages(7)(1)(14),
    c_in => stages(7)(1)(9),
    d_in => stages(7)(1)(7),
    q_out => stages(6)(1)(11)
);

boost_6_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(10),
    b_in => stages(7)(0)(12),
    c_in => stages(7)(0)(15),
    d_in => stages(7)(0)(8),
    q_out => stages(6)(0)(12)
);

boost_6_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(10),
    b_in => stages(7)(1)(12),
    c_in => stages(7)(1)(15),
    d_in => stages(7)(1)(8),
    q_out => stages(6)(1)(12)
);

boost_6_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(5),
    b_in => stages(7)(0)(3),
    c_in => stages(7)(0)(9),
    d_in => stages(7)(0)(1),
    q_out => stages(6)(0)(13)
);

boost_6_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(5),
    b_in => stages(7)(1)(3),
    c_in => stages(7)(1)(9),
    d_in => stages(7)(1)(1),
    q_out => stages(6)(1)(13)
);

boost_6_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(4),
    b_in => stages(7)(0)(6),
    c_in => stages(7)(0)(11),
    d_in => stages(7)(0)(13),
    q_out => stages(6)(0)(14)
);

boost_6_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(4),
    b_in => stages(7)(1)(6),
    c_in => stages(7)(1)(11),
    d_in => stages(7)(1)(13),
    q_out => stages(6)(1)(14)
);

boost_6_0_15 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(7)(0)(7),
    b_in => stages(7)(0)(14),
    c_in => stages(7)(0)(2),
    d_in => stages(7)(0)(0),
    q_out => stages(6)(0)(15)
);

boost_6_1_15 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(7)(1)(7),
    b_in => stages(7)(1)(14),
    c_in => stages(7)(1)(2),
    d_in => stages(7)(1)(0),
    q_out => stages(6)(1)(15)
);

boost_5_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(5),
    b_in => stages(6)(0)(0),
    c_in => stages(6)(0)(10),
    d_in => stages(6)(0)(12),
    q_out => stages(5)(0)(0)
);

boost_5_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(5),
    b_in => stages(6)(1)(0),
    c_in => stages(6)(1)(10),
    d_in => stages(6)(1)(12),
    q_out => stages(5)(1)(0)
);

boost_5_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(3),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(14),
    d_in => stages(6)(0)(0),
    q_out => stages(5)(0)(1)
);

boost_5_1_1 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(3),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(14),
    d_in => stages(6)(1)(0),
    q_out => stages(5)(1)(1)
);

boost_5_0_2 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(6),
    b_in => stages(6)(0)(13),
    c_in => stages(6)(0)(11),
    d_in => stages(6)(0)(13),
    q_out => stages(5)(0)(2)
);

boost_5_1_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(6),
    b_in => stages(6)(1)(13),
    c_in => stages(6)(1)(11),
    d_in => stages(6)(1)(13),
    q_out => stages(5)(1)(2)
);

boost_5_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(8),
    b_in => stages(6)(0)(9),
    c_in => stages(6)(0)(1),
    d_in => stages(6)(0)(7),
    q_out => stages(5)(0)(3)
);

boost_5_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(8),
    b_in => stages(6)(1)(9),
    c_in => stages(6)(1)(1),
    d_in => stages(6)(1)(7),
    q_out => stages(5)(1)(3)
);

boost_5_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(15),
    b_in => stages(6)(0)(14),
    c_in => stages(6)(0)(1),
    d_in => stages(6)(0)(12),
    q_out => stages(5)(0)(4)
);

boost_5_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(15),
    b_in => stages(6)(1)(14),
    c_in => stages(6)(1)(1),
    d_in => stages(6)(1)(12),
    q_out => stages(5)(1)(4)
);

boost_5_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(5),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(3),
    d_in => stages(6)(0)(15),
    q_out => stages(5)(0)(5)
);

boost_5_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(5),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(3),
    d_in => stages(6)(1)(15),
    q_out => stages(5)(1)(5)
);

boost_5_0_6 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(7),
    b_in => stages(6)(0)(4),
    c_in => stages(6)(0)(8),
    d_in => stages(6)(0)(5),
    q_out => stages(5)(0)(6)
);

boost_5_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(7),
    b_in => stages(6)(1)(4),
    c_in => stages(6)(1)(8),
    d_in => stages(6)(1)(5),
    q_out => stages(5)(1)(6)
);

boost_5_0_7 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(7),
    b_in => stages(6)(0)(4),
    c_in => stages(6)(0)(13),
    d_in => stages(6)(0)(4),
    q_out => stages(5)(0)(7)
);

boost_5_1_7 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(7),
    b_in => stages(6)(1)(4),
    c_in => stages(6)(1)(13),
    d_in => stages(6)(1)(4),
    q_out => stages(5)(1)(7)
);

boost_5_0_8 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(12),
    b_in => stages(6)(0)(9),
    c_in => stages(6)(0)(7),
    d_in => stages(6)(0)(10),
    q_out => stages(5)(0)(8)
);

boost_5_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(12),
    b_in => stages(6)(1)(9),
    c_in => stages(6)(1)(7),
    d_in => stages(6)(1)(10),
    q_out => stages(5)(1)(8)
);

boost_5_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(8),
    b_in => stages(6)(0)(15),
    c_in => stages(6)(0)(15),
    d_in => stages(6)(0)(9),
    q_out => stages(5)(0)(9)
);

boost_5_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(8),
    b_in => stages(6)(1)(15),
    c_in => stages(6)(1)(15),
    d_in => stages(6)(1)(9),
    q_out => stages(5)(1)(9)
);

boost_5_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(0)(6),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(10),
    d_in => stages(6)(0)(14),
    q_out => stages(5)(0)(10)
);

boost_5_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(1)(6),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(10),
    d_in => stages(6)(1)(14),
    q_out => stages(5)(1)(10)
);

boost_5_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(6),
    b_in => stages(6)(0)(10),
    c_in => stages(6)(0)(10),
    d_in => stages(6)(0)(15),
    q_out => stages(5)(0)(11)
);

boost_5_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(6),
    b_in => stages(6)(1)(10),
    c_in => stages(6)(1)(10),
    d_in => stages(6)(1)(15),
    q_out => stages(5)(1)(11)
);

boost_5_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(13),
    b_in => stages(6)(0)(11),
    c_in => stages(6)(0)(4),
    d_in => stages(6)(0)(6),
    q_out => stages(5)(0)(12)
);

boost_5_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(13),
    b_in => stages(6)(1)(11),
    c_in => stages(6)(1)(4),
    d_in => stages(6)(1)(6),
    q_out => stages(5)(1)(12)
);

boost_5_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(9),
    b_in => stages(6)(0)(7),
    c_in => stages(6)(0)(0),
    d_in => stages(6)(0)(5),
    q_out => stages(5)(0)(13)
);

boost_5_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(9),
    b_in => stages(6)(1)(7),
    c_in => stages(6)(1)(0),
    d_in => stages(6)(1)(5),
    q_out => stages(5)(1)(13)
);

boost_5_0_14 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(14),
    b_in => stages(6)(0)(10),
    c_in => stages(6)(0)(9),
    d_in => stages(6)(0)(14),
    q_out => stages(5)(0)(14)
);

boost_5_1_14 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(14),
    b_in => stages(6)(1)(10),
    c_in => stages(6)(1)(9),
    d_in => stages(6)(1)(14),
    q_out => stages(5)(1)(14)
);

boost_5_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(6)(0)(7),
    b_in => stages(6)(0)(14),
    c_in => stages(6)(0)(4),
    d_in => stages(6)(0)(8),
    q_out => stages(5)(0)(15)
);

boost_5_1_15 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(6)(1)(7),
    b_in => stages(6)(1)(14),
    c_in => stages(6)(1)(4),
    d_in => stages(6)(1)(8),
    q_out => stages(5)(1)(15)
);

boost_4_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(12),
    b_in => stages(5)(0)(14),
    c_in => stages(5)(0)(5),
    d_in => stages(5)(0)(8),
    q_out => stages(4)(0)(0)
);

boost_4_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(12),
    b_in => stages(5)(1)(14),
    c_in => stages(5)(1)(5),
    d_in => stages(5)(1)(8),
    q_out => stages(4)(1)(0)
);

boost_4_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(11),
    b_in => stages(5)(0)(14),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(3),
    q_out => stages(4)(0)(1)
);

boost_4_1_1 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(11),
    b_in => stages(5)(1)(14),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(3),
    q_out => stages(4)(1)(1)
);

boost_4_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(12),
    b_in => stages(5)(0)(0),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(14),
    q_out => stages(4)(0)(2)
);

boost_4_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(12),
    b_in => stages(5)(1)(0),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(14),
    q_out => stages(4)(1)(2)
);

boost_4_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(3),
    b_in => stages(5)(0)(4),
    c_in => stages(5)(0)(0),
    d_in => stages(5)(0)(8),
    q_out => stages(4)(0)(3)
);

boost_4_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(3),
    b_in => stages(5)(1)(4),
    c_in => stages(5)(1)(0),
    d_in => stages(5)(1)(8),
    q_out => stages(4)(1)(3)
);

boost_4_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(15),
    b_in => stages(5)(0)(13),
    c_in => stages(5)(0)(1),
    d_in => stages(5)(0)(6),
    q_out => stages(4)(0)(4)
);

boost_4_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(15),
    b_in => stages(5)(1)(13),
    c_in => stages(5)(1)(1),
    d_in => stages(5)(1)(6),
    q_out => stages(4)(1)(4)
);

boost_4_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(2),
    b_in => stages(5)(0)(14),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(0),
    q_out => stages(4)(0)(5)
);

boost_4_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(2),
    b_in => stages(5)(1)(14),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(0),
    q_out => stages(4)(1)(5)
);

boost_4_0_6 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(8),
    b_in => stages(5)(0)(10),
    c_in => stages(5)(0)(3),
    d_in => stages(5)(0)(11),
    q_out => stages(4)(0)(6)
);

boost_4_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(8),
    b_in => stages(5)(1)(10),
    c_in => stages(5)(1)(3),
    d_in => stages(5)(1)(11),
    q_out => stages(4)(1)(6)
);

boost_4_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(2),
    b_in => stages(5)(0)(2),
    c_in => stages(5)(0)(8),
    d_in => stages(5)(0)(8),
    q_out => stages(4)(0)(7)
);

boost_4_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(2),
    b_in => stages(5)(1)(2),
    c_in => stages(5)(1)(8),
    d_in => stages(5)(1)(8),
    q_out => stages(4)(1)(7)
);

boost_4_0_8 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(14),
    b_in => stages(5)(0)(9),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(2),
    q_out => stages(4)(0)(8)
);

boost_4_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(14),
    b_in => stages(5)(1)(9),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(2),
    q_out => stages(4)(1)(8)
);

boost_4_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(8),
    b_in => stages(5)(0)(8),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(6),
    q_out => stages(4)(0)(9)
);

boost_4_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(8),
    b_in => stages(5)(1)(8),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(6),
    q_out => stages(4)(1)(9)
);

boost_4_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(6),
    b_in => stages(5)(0)(15),
    c_in => stages(5)(0)(5),
    d_in => stages(5)(0)(6),
    q_out => stages(4)(0)(10)
);

boost_4_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(6),
    b_in => stages(5)(1)(15),
    c_in => stages(5)(1)(5),
    d_in => stages(5)(1)(6),
    q_out => stages(4)(1)(10)
);

boost_4_0_11 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(9),
    b_in => stages(5)(0)(13),
    c_in => stages(5)(0)(14),
    d_in => stages(5)(0)(5),
    q_out => stages(4)(0)(11)
);

boost_4_1_11 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(9),
    b_in => stages(5)(1)(13),
    c_in => stages(5)(1)(14),
    d_in => stages(5)(1)(5),
    q_out => stages(4)(1)(11)
);

boost_4_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(2),
    b_in => stages(5)(0)(12),
    c_in => stages(5)(0)(15),
    d_in => stages(5)(0)(11),
    q_out => stages(4)(0)(12)
);

boost_4_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(2),
    b_in => stages(5)(1)(12),
    c_in => stages(5)(1)(15),
    d_in => stages(5)(1)(11),
    q_out => stages(4)(1)(12)
);

boost_4_0_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(7),
    b_in => stages(5)(0)(1),
    c_in => stages(5)(0)(11),
    d_in => stages(5)(0)(14),
    q_out => stages(4)(0)(13)
);

boost_4_1_13 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(7),
    b_in => stages(5)(1)(1),
    c_in => stages(5)(1)(11),
    d_in => stages(5)(1)(14),
    q_out => stages(4)(1)(13)
);

boost_4_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(0)(13),
    b_in => stages(5)(0)(5),
    c_in => stages(5)(0)(9),
    d_in => stages(5)(0)(13),
    q_out => stages(4)(0)(14)
);

boost_4_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(1)(13),
    b_in => stages(5)(1)(5),
    c_in => stages(5)(1)(9),
    d_in => stages(5)(1)(13),
    q_out => stages(4)(1)(14)
);

boost_4_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(5)(0)(5),
    b_in => stages(5)(0)(12),
    c_in => stages(5)(0)(2),
    d_in => stages(5)(0)(12),
    q_out => stages(4)(0)(15)
);

boost_4_1_15 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(5)(1)(5),
    b_in => stages(5)(1)(12),
    c_in => stages(5)(1)(2),
    d_in => stages(5)(1)(12),
    q_out => stages(4)(1)(15)
);

boost_3_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(6),
    b_in => stages(4)(0)(12),
    c_in => stages(4)(0)(14),
    d_in => stages(4)(0)(13),
    q_out => stages(3)(0)(0)
);

boost_3_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(6),
    b_in => stages(4)(1)(12),
    c_in => stages(4)(1)(14),
    d_in => stages(4)(1)(13),
    q_out => stages(3)(1)(0)
);

boost_3_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(0),
    b_in => stages(4)(0)(14),
    c_in => stages(4)(0)(5),
    d_in => stages(4)(0)(11),
    q_out => stages(3)(0)(1)
);

boost_3_1_1 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(0),
    b_in => stages(4)(1)(14),
    c_in => stages(4)(1)(5),
    d_in => stages(4)(1)(11),
    q_out => stages(3)(1)(1)
);

boost_3_0_2 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(13),
    b_in => stages(4)(0)(5),
    c_in => stages(4)(0)(9),
    d_in => stages(4)(0)(10),
    q_out => stages(3)(0)(2)
);

boost_3_1_2 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(13),
    b_in => stages(4)(1)(5),
    c_in => stages(4)(1)(9),
    d_in => stages(4)(1)(10),
    q_out => stages(3)(1)(2)
);

boost_3_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(5),
    b_in => stages(4)(0)(14),
    c_in => stages(4)(0)(0),
    d_in => stages(4)(0)(12),
    q_out => stages(3)(0)(3)
);

boost_3_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(5),
    b_in => stages(4)(1)(14),
    c_in => stages(4)(1)(0),
    d_in => stages(4)(1)(12),
    q_out => stages(3)(1)(3)
);

boost_3_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(11),
    b_in => stages(4)(0)(2),
    c_in => stages(4)(0)(13),
    d_in => stages(4)(0)(10),
    q_out => stages(3)(0)(4)
);

boost_3_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(11),
    b_in => stages(4)(1)(2),
    c_in => stages(4)(1)(13),
    d_in => stages(4)(1)(10),
    q_out => stages(3)(1)(4)
);

boost_3_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(10),
    b_in => stages(4)(0)(0),
    c_in => stages(4)(0)(3),
    d_in => stages(4)(0)(9),
    q_out => stages(3)(0)(5)
);

boost_3_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(10),
    b_in => stages(4)(1)(0),
    c_in => stages(4)(1)(3),
    d_in => stages(4)(1)(9),
    q_out => stages(3)(1)(5)
);

boost_3_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(5),
    b_in => stages(4)(0)(3),
    c_in => stages(4)(0)(6),
    d_in => stages(4)(0)(7),
    q_out => stages(3)(0)(6)
);

boost_3_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(5),
    b_in => stages(4)(1)(3),
    c_in => stages(4)(1)(6),
    d_in => stages(4)(1)(7),
    q_out => stages(3)(1)(6)
);

boost_3_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(8),
    b_in => stages(4)(0)(7),
    c_in => stages(4)(0)(11),
    d_in => stages(4)(0)(0),
    q_out => stages(3)(0)(7)
);

boost_3_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(8),
    b_in => stages(4)(1)(7),
    c_in => stages(4)(1)(11),
    d_in => stages(4)(1)(0),
    q_out => stages(3)(1)(7)
);

boost_3_0_8 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(1),
    b_in => stages(4)(0)(9),
    c_in => stages(4)(0)(2),
    d_in => stages(4)(0)(5),
    q_out => stages(3)(0)(8)
);

boost_3_1_8 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(1),
    b_in => stages(4)(1)(9),
    c_in => stages(4)(1)(2),
    d_in => stages(4)(1)(5),
    q_out => stages(3)(1)(8)
);

boost_3_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(8),
    b_in => stages(4)(0)(5),
    c_in => stages(4)(0)(3),
    d_in => stages(4)(0)(0),
    q_out => stages(3)(0)(9)
);

boost_3_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(8),
    b_in => stages(4)(1)(5),
    c_in => stages(4)(1)(3),
    d_in => stages(4)(1)(0),
    q_out => stages(3)(1)(9)
);

boost_3_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(1),
    b_in => stages(4)(0)(6),
    c_in => stages(4)(0)(13),
    d_in => stages(4)(0)(10),
    q_out => stages(3)(0)(10)
);

boost_3_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(1),
    b_in => stages(4)(1)(6),
    c_in => stages(4)(1)(13),
    d_in => stages(4)(1)(10),
    q_out => stages(3)(1)(10)
);

boost_3_0_11 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(7),
    b_in => stages(4)(0)(1),
    c_in => stages(4)(0)(11),
    d_in => stages(4)(0)(8),
    q_out => stages(3)(0)(11)
);

boost_3_1_11 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(7),
    b_in => stages(4)(1)(1),
    c_in => stages(4)(1)(11),
    d_in => stages(4)(1)(8),
    q_out => stages(3)(1)(11)
);

boost_3_0_12 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(0)(6),
    b_in => stages(4)(0)(5),
    c_in => stages(4)(0)(12),
    d_in => stages(4)(0)(7),
    q_out => stages(3)(0)(12)
);

boost_3_1_12 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(1)(6),
    b_in => stages(4)(1)(5),
    c_in => stages(4)(1)(12),
    d_in => stages(4)(1)(7),
    q_out => stages(3)(1)(12)
);

boost_3_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(9),
    b_in => stages(4)(0)(9),
    c_in => stages(4)(0)(5),
    d_in => stages(4)(0)(3),
    q_out => stages(3)(0)(13)
);

boost_3_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(9),
    b_in => stages(4)(1)(9),
    c_in => stages(4)(1)(5),
    d_in => stages(4)(1)(3),
    q_out => stages(3)(1)(13)
);

boost_3_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(11),
    b_in => stages(4)(0)(12),
    c_in => stages(4)(0)(3),
    d_in => stages(4)(0)(7),
    q_out => stages(3)(0)(14)
);

boost_3_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(11),
    b_in => stages(4)(1)(12),
    c_in => stages(4)(1)(3),
    d_in => stages(4)(1)(7),
    q_out => stages(3)(1)(14)
);

boost_3_0_15 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(4)(0)(2),
    b_in => stages(4)(0)(1),
    c_in => stages(4)(0)(1),
    d_in => stages(4)(0)(0),
    q_out => stages(3)(0)(15)
);

boost_3_1_15 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(4)(1)(2),
    b_in => stages(4)(1)(1),
    c_in => stages(4)(1)(1),
    d_in => stages(4)(1)(0),
    q_out => stages(3)(1)(15)
);

boost_2_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(10),
    b_in => stages(3)(0)(4),
    c_in => stages(3)(0)(0),
    d_in => stages(3)(0)(2),
    q_out => stages(2)(0)(0)
);

boost_2_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(10),
    b_in => stages(3)(1)(4),
    c_in => stages(3)(1)(0),
    d_in => stages(3)(1)(2),
    q_out => stages(2)(1)(0)
);

boost_2_0_1 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(8),
    b_in => stages(3)(0)(12),
    c_in => stages(3)(0)(7),
    d_in => stages(3)(0)(1),
    q_out => stages(2)(0)(1)
);

boost_2_1_1 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(8),
    b_in => stages(3)(1)(12),
    c_in => stages(3)(1)(7),
    d_in => stages(3)(1)(1),
    q_out => stages(2)(1)(1)
);

boost_2_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(12),
    b_in => stages(3)(0)(8),
    c_in => stages(3)(0)(1),
    d_in => stages(3)(0)(6),
    q_out => stages(2)(0)(2)
);

boost_2_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(12),
    b_in => stages(3)(1)(8),
    c_in => stages(3)(1)(1),
    d_in => stages(3)(1)(6),
    q_out => stages(2)(1)(2)
);

boost_2_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(10),
    b_in => stages(3)(0)(4),
    c_in => stages(3)(0)(3),
    d_in => stages(3)(0)(11),
    q_out => stages(2)(0)(3)
);

boost_2_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(10),
    b_in => stages(3)(1)(4),
    c_in => stages(3)(1)(3),
    d_in => stages(3)(1)(11),
    q_out => stages(2)(1)(3)
);

boost_2_0_4 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(6),
    b_in => stages(3)(0)(14),
    c_in => stages(3)(0)(9),
    d_in => stages(3)(0)(5),
    q_out => stages(2)(0)(4)
);

boost_2_1_4 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(6),
    b_in => stages(3)(1)(14),
    c_in => stages(3)(1)(9),
    d_in => stages(3)(1)(5),
    q_out => stages(2)(1)(4)
);

boost_2_0_5 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(6),
    b_in => stages(3)(0)(2),
    c_in => stages(3)(0)(15),
    d_in => stages(3)(0)(5),
    q_out => stages(2)(0)(5)
);

boost_2_1_5 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(6),
    b_in => stages(3)(1)(2),
    c_in => stages(3)(1)(15),
    d_in => stages(3)(1)(5),
    q_out => stages(2)(1)(5)
);

boost_2_0_6 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(4),
    b_in => stages(3)(0)(8),
    c_in => stages(3)(0)(14),
    d_in => stages(3)(0)(7),
    q_out => stages(2)(0)(6)
);

boost_2_1_6 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(4),
    b_in => stages(3)(1)(8),
    c_in => stages(3)(1)(14),
    d_in => stages(3)(1)(7),
    q_out => stages(2)(1)(6)
);

boost_2_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(10),
    b_in => stages(3)(0)(3),
    c_in => stages(3)(0)(0),
    d_in => stages(3)(0)(9),
    q_out => stages(2)(0)(7)
);

boost_2_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(10),
    b_in => stages(3)(1)(3),
    c_in => stages(3)(1)(0),
    d_in => stages(3)(1)(9),
    q_out => stages(2)(1)(7)
);

boost_2_0_8 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(13),
    b_in => stages(3)(0)(14),
    c_in => stages(3)(0)(13),
    d_in => stages(3)(0)(9),
    q_out => stages(2)(0)(8)
);

boost_2_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(13),
    b_in => stages(3)(1)(14),
    c_in => stages(3)(1)(13),
    d_in => stages(3)(1)(9),
    q_out => stages(2)(1)(8)
);

boost_2_0_9 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(2),
    b_in => stages(3)(0)(0),
    c_in => stages(3)(0)(13),
    d_in => stages(3)(0)(7),
    q_out => stages(2)(0)(9)
);

boost_2_1_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(2),
    b_in => stages(3)(1)(0),
    c_in => stages(3)(1)(13),
    d_in => stages(3)(1)(7),
    q_out => stages(2)(1)(9)
);

boost_2_0_10 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(14),
    b_in => stages(3)(0)(5),
    c_in => stages(3)(0)(10),
    d_in => stages(3)(0)(9),
    q_out => stages(2)(0)(10)
);

boost_2_1_10 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(14),
    b_in => stages(3)(1)(5),
    c_in => stages(3)(1)(10),
    d_in => stages(3)(1)(9),
    q_out => stages(2)(1)(10)
);

boost_2_0_11 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(12),
    b_in => stages(3)(0)(4),
    c_in => stages(3)(0)(8),
    d_in => stages(3)(0)(8),
    q_out => stages(2)(0)(11)
);

boost_2_1_11 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(12),
    b_in => stages(3)(1)(4),
    c_in => stages(3)(1)(8),
    d_in => stages(3)(1)(8),
    q_out => stages(2)(1)(11)
);

boost_2_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(13),
    b_in => stages(3)(0)(13),
    c_in => stages(3)(0)(5),
    d_in => stages(3)(0)(5),
    q_out => stages(2)(0)(12)
);

boost_2_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(13),
    b_in => stages(3)(1)(13),
    c_in => stages(3)(1)(5),
    d_in => stages(3)(1)(5),
    q_out => stages(2)(1)(12)
);

boost_2_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(0)(10),
    b_in => stages(3)(0)(7),
    c_in => stages(3)(0)(12),
    d_in => stages(3)(0)(12),
    q_out => stages(2)(0)(13)
);

boost_2_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(1)(10),
    b_in => stages(3)(1)(7),
    c_in => stages(3)(1)(12),
    d_in => stages(3)(1)(12),
    q_out => stages(2)(1)(13)
);

boost_2_0_14 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(5),
    b_in => stages(3)(0)(10),
    c_in => stages(3)(0)(5),
    d_in => stages(3)(0)(12),
    q_out => stages(2)(0)(14)
);

boost_2_1_14 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(5),
    b_in => stages(3)(1)(10),
    c_in => stages(3)(1)(5),
    d_in => stages(3)(1)(12),
    q_out => stages(2)(1)(14)
);

boost_2_0_15 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(3)(0)(11),
    b_in => stages(3)(0)(11),
    c_in => stages(3)(0)(13),
    d_in => stages(3)(0)(1),
    q_out => stages(2)(0)(15)
);

boost_2_1_15 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(3)(1)(11),
    b_in => stages(3)(1)(11),
    c_in => stages(3)(1)(13),
    d_in => stages(3)(1)(1),
    q_out => stages(2)(1)(15)
);

boost_1_0_0 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(7),
    b_in => stages(2)(0)(1),
    c_in => stages(2)(0)(0),
    d_in => stages(2)(0)(5),
    q_out => stages(1)(0)(0)
);

boost_1_1_0 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(7),
    b_in => stages(2)(1)(1),
    c_in => stages(2)(1)(0),
    d_in => stages(2)(1)(5),
    q_out => stages(1)(1)(0)
);

boost_1_0_1 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(6),
    b_in => stages(2)(0)(3),
    c_in => stages(2)(0)(9),
    d_in => stages(2)(0)(1),
    q_out => stages(1)(0)(1)
);

boost_1_1_1 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(6),
    b_in => stages(2)(1)(3),
    c_in => stages(2)(1)(9),
    d_in => stages(2)(1)(1),
    q_out => stages(1)(1)(1)
);

boost_1_0_2 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(8),
    b_in => stages(2)(0)(3),
    c_in => stages(2)(0)(1),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(2)
);

boost_1_1_2 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(8),
    b_in => stages(2)(1)(3),
    c_in => stages(2)(1)(1),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(2)
);

boost_1_0_3 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(0),
    b_in => stages(2)(0)(15),
    c_in => stages(2)(0)(0),
    d_in => stages(2)(0)(7),
    q_out => stages(1)(0)(3)
);

boost_1_1_3 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(0),
    b_in => stages(2)(1)(15),
    c_in => stages(2)(1)(0),
    d_in => stages(2)(1)(7),
    q_out => stages(1)(1)(3)
);

boost_1_0_4 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(4),
    b_in => stages(2)(0)(7),
    c_in => stages(2)(0)(14),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(4)
);

boost_1_1_4 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(4),
    b_in => stages(2)(1)(7),
    c_in => stages(2)(1)(14),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(4)
);

boost_1_0_5 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(7),
    b_in => stages(2)(0)(9),
    c_in => stages(2)(0)(3),
    d_in => stages(2)(0)(7),
    q_out => stages(1)(0)(5)
);

boost_1_1_5 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(7),
    b_in => stages(2)(1)(9),
    c_in => stages(2)(1)(3),
    d_in => stages(2)(1)(7),
    q_out => stages(1)(1)(5)
);

boost_1_0_6 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(2),
    b_in => stages(2)(0)(3),
    c_in => stages(2)(0)(8),
    d_in => stages(2)(0)(7),
    q_out => stages(1)(0)(6)
);

boost_1_1_6 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(2),
    b_in => stages(2)(1)(3),
    c_in => stages(2)(1)(8),
    d_in => stages(2)(1)(7),
    q_out => stages(1)(1)(6)
);

boost_1_0_7 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(11),
    b_in => stages(2)(0)(1),
    c_in => stages(2)(0)(4),
    d_in => stages(2)(0)(9),
    q_out => stages(1)(0)(7)
);

boost_1_1_7 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(11),
    b_in => stages(2)(1)(1),
    c_in => stages(2)(1)(4),
    d_in => stages(2)(1)(9),
    q_out => stages(1)(1)(7)
);

boost_1_0_8 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(4),
    b_in => stages(2)(0)(12),
    c_in => stages(2)(0)(7),
    d_in => stages(2)(0)(5),
    q_out => stages(1)(0)(8)
);

boost_1_1_8 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(4),
    b_in => stages(2)(1)(12),
    c_in => stages(2)(1)(7),
    d_in => stages(2)(1)(5),
    q_out => stages(1)(1)(8)
);

boost_1_0_9 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(8),
    b_in => stages(2)(0)(6),
    c_in => stages(2)(0)(7),
    d_in => stages(2)(0)(3),
    q_out => stages(1)(0)(9)
);

boost_1_1_9 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(8),
    b_in => stages(2)(1)(6),
    c_in => stages(2)(1)(7),
    d_in => stages(2)(1)(3),
    q_out => stages(1)(1)(9)
);

boost_1_0_10 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(0),
    b_in => stages(2)(0)(8),
    c_in => stages(2)(0)(13),
    d_in => stages(2)(0)(1),
    q_out => stages(1)(0)(10)
);

boost_1_1_10 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(0),
    b_in => stages(2)(1)(8),
    c_in => stages(2)(1)(13),
    d_in => stages(2)(1)(1),
    q_out => stages(1)(1)(10)
);

boost_1_0_11 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(14),
    b_in => stages(2)(0)(14),
    c_in => stages(2)(0)(11),
    d_in => stages(2)(0)(5),
    q_out => stages(1)(0)(11)
);

boost_1_1_11 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(14),
    b_in => stages(2)(1)(14),
    c_in => stages(2)(1)(11),
    d_in => stages(2)(1)(5),
    q_out => stages(1)(1)(11)
);

boost_1_0_12 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(1),
    b_in => stages(2)(0)(12),
    c_in => stages(2)(0)(15),
    d_in => stages(2)(0)(1),
    q_out => stages(1)(0)(12)
);

boost_1_1_12 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(1),
    b_in => stages(2)(1)(12),
    c_in => stages(2)(1)(15),
    d_in => stages(2)(1)(1),
    q_out => stages(1)(1)(12)
);

boost_1_0_13 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(15),
    b_in => stages(2)(0)(0),
    c_in => stages(2)(0)(8),
    d_in => stages(2)(0)(6),
    q_out => stages(1)(0)(13)
);

boost_1_1_13 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(15),
    b_in => stages(2)(1)(0),
    c_in => stages(2)(1)(8),
    d_in => stages(2)(1)(6),
    q_out => stages(1)(1)(13)
);

boost_1_0_14 : booster generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(2)(0)(7),
    b_in => stages(2)(0)(11),
    c_in => stages(2)(0)(0),
    d_in => stages(2)(0)(15),
    q_out => stages(1)(0)(14)
);

boost_1_1_14 : booster generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(2)(1)(7),
    b_in => stages(2)(1)(11),
    c_in => stages(2)(1)(0),
    d_in => stages(2)(1)(15),
    q_out => stages(1)(1)(14)
);

boost_1_0_15 : booster generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(2)(0)(11),
    b_in => stages(2)(0)(1),
    c_in => stages(2)(0)(1),
    d_in => stages(2)(0)(14),
    q_out => stages(1)(0)(15)
);

boost_1_1_15 : booster generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(2)(1)(11),
    b_in => stages(2)(1)(1),
    c_in => stages(2)(1)(1),
    d_in => stages(2)(1)(14),
    q_out => stages(1)(1)(15)
);

repress_0_0_0 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(8),
    b_in => stages(1)(0)(9),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(0),
    q_out => stages(0)(0)(0)
);

repress_0_1_0 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(8),
    b_in => stages(1)(1)(9),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(0),
    q_out => stages(0)(1)(0)
);

repress_0_0_1 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(2),
    b_in => stages(1)(0)(8),
    c_in => stages(1)(0)(6),
    d_in => stages(1)(0)(13),
    q_out => stages(0)(0)(1)
);

repress_0_1_1 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(2),
    b_in => stages(1)(1)(8),
    c_in => stages(1)(1)(6),
    d_in => stages(1)(1)(13),
    q_out => stages(0)(1)(1)
);

repress_0_0_2 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(9),
    b_in => stages(1)(0)(0),
    c_in => stages(1)(0)(1),
    d_in => stages(1)(0)(7),
    q_out => stages(0)(0)(2)
);

repress_0_1_2 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(9),
    b_in => stages(1)(1)(0),
    c_in => stages(1)(1)(1),
    d_in => stages(1)(1)(7),
    q_out => stages(0)(1)(2)
);

repress_0_0_3 : represser generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(13),
    b_in => stages(1)(0)(3),
    c_in => stages(1)(0)(13),
    d_in => stages(1)(0)(2),
    q_out => stages(0)(0)(3)
);

repress_0_1_3 : represser generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(13),
    b_in => stages(1)(1)(3),
    c_in => stages(1)(1)(13),
    d_in => stages(1)(1)(2),
    q_out => stages(0)(1)(3)
);

repress_0_0_4 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(0),
    b_in => stages(1)(0)(1),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(2),
    q_out => stages(0)(0)(4)
);

repress_0_1_4 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(0),
    b_in => stages(1)(1)(1),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(2),
    q_out => stages(0)(1)(4)
);

repress_0_0_5 : represser generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(11),
    b_in => stages(1)(0)(3),
    c_in => stages(1)(0)(7),
    d_in => stages(1)(0)(12),
    q_out => stages(0)(0)(5)
);

repress_0_1_5 : represser generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(11),
    b_in => stages(1)(1)(3),
    c_in => stages(1)(1)(7),
    d_in => stages(1)(1)(12),
    q_out => stages(0)(1)(5)
);

repress_0_0_6 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(2),
    b_in => stages(1)(0)(14),
    c_in => stages(1)(0)(2),
    d_in => stages(1)(0)(7),
    q_out => stages(0)(0)(6)
);

repress_0_1_6 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(2),
    b_in => stages(1)(1)(14),
    c_in => stages(1)(1)(2),
    d_in => stages(1)(1)(7),
    q_out => stages(0)(1)(6)
);

repress_0_0_7 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(12),
    b_in => stages(1)(0)(10),
    c_in => stages(1)(0)(4),
    d_in => stages(1)(0)(8),
    q_out => stages(0)(0)(7)
);

repress_0_1_7 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(12),
    b_in => stages(1)(1)(10),
    c_in => stages(1)(1)(4),
    d_in => stages(1)(1)(8),
    q_out => stages(0)(1)(7)
);

repress_0_0_8 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(7),
    b_in => stages(1)(0)(12),
    c_in => stages(1)(0)(8),
    d_in => stages(1)(0)(13),
    q_out => stages(0)(0)(8)
);

repress_0_1_8 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(7),
    b_in => stages(1)(1)(12),
    c_in => stages(1)(1)(8),
    d_in => stages(1)(1)(13),
    q_out => stages(0)(1)(8)
);

repress_0_0_9 : represser generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(3),
    b_in => stages(1)(0)(2),
    c_in => stages(1)(0)(5),
    d_in => stages(1)(0)(3),
    q_out => stages(0)(0)(9)
);

repress_0_1_9 : represser generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(3),
    b_in => stages(1)(1)(2),
    c_in => stages(1)(1)(5),
    d_in => stages(1)(1)(3),
    q_out => stages(0)(1)(9)
);

repress_0_0_10 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(11),
    b_in => stages(1)(0)(1),
    c_in => stages(1)(0)(11),
    d_in => stages(1)(0)(11),
    q_out => stages(0)(0)(10)
);

repress_0_1_10 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(11),
    b_in => stages(1)(1)(1),
    c_in => stages(1)(1)(11),
    d_in => stages(1)(1)(11),
    q_out => stages(0)(1)(10)
);

repress_0_0_11 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(0),
    b_in => stages(1)(0)(15),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(15),
    q_out => stages(0)(0)(11)
);

repress_0_1_11 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(0),
    b_in => stages(1)(1)(15),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(15),
    q_out => stages(0)(1)(11)
);

repress_0_0_12 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(1),
    b_in => stages(1)(0)(7),
    c_in => stages(1)(0)(12),
    d_in => stages(1)(0)(11),
    q_out => stages(0)(0)(12)
);

repress_0_1_12 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(1),
    b_in => stages(1)(1)(7),
    c_in => stages(1)(1)(12),
    d_in => stages(1)(1)(11),
    q_out => stages(0)(1)(12)
);

repress_0_0_13 : represser generic map (
    a_delay => 20,
    b_delay => 0,
    c_delay => 20,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(13),
    b_in => stages(1)(0)(13),
    c_in => stages(1)(0)(4),
    d_in => stages(1)(0)(3),
    q_out => stages(0)(0)(13)
);

repress_0_1_13 : represser generic map (
    a_delay => 0,
    b_delay => 20,
    c_delay => 0,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(13),
    b_in => stages(1)(1)(13),
    c_in => stages(1)(1)(4),
    d_in => stages(1)(1)(3),
    q_out => stages(0)(1)(13)
);

repress_0_0_14 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 20
) port map (
    a_in => stages(1)(0)(1),
    b_in => stages(1)(0)(11),
    c_in => stages(1)(0)(13),
    d_in => stages(1)(0)(1),
    q_out => stages(0)(0)(14)
);

repress_0_1_14 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 0
) port map (
    a_in => stages(1)(1)(1),
    b_in => stages(1)(1)(11),
    c_in => stages(1)(1)(13),
    d_in => stages(1)(1)(1),
    q_out => stages(0)(1)(14)
);

repress_0_0_15 : represser generic map (
    a_delay => 0,
    b_delay => 0,
    c_delay => 0,
    d_delay => 20,
    q_delay => 0
) port map (
    a_in => stages(1)(0)(1),
    b_in => stages(1)(0)(4),
    c_in => stages(1)(0)(13),
    d_in => stages(1)(0)(8),
    q_out => stages(0)(0)(15)
);

repress_0_1_15 : represser generic map (
    a_delay => 20,
    b_delay => 20,
    c_delay => 20,
    d_delay => 0,
    q_delay => 20
) port map (
    a_in => stages(1)(1)(1),
    b_in => stages(1)(1)(4),
    c_in => stages(1)(1)(13),
    d_in => stages(1)(1)(8),
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

end dppuf_arch;

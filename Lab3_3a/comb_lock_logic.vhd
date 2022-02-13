library ieee;
use ieee.std_logic_1164.all;

entity comb_lock_logic is
	port(clk, reset : in std_logic; -- clk is "fast enough". reset is active high.
	     x1 : in std_logic; -- x1 is left
	     x0 : in std_logic; -- x0 is right
	     u : out std_logic);
end comb_lock_logic;

architecture behav of comb_lock_logic is
signal x1s, x0s : std_logic;
signal q1_plus, q0_plus : std_logic;
signal q1, q0 : std_logic;
begin
--vippor
process(clk, reset) begin
    if reset = '1' then
        q1 <= '0';
        q0 <= '0';
    elsif rising_edge(clk) then
        q1 <= q1_plus;
        q0 <= q0_plus;
        x1s <= x1;
        x0s <= x0;
    end if;
end process;

q1_plus <= (q1 and x0s) or (q1 and q0 and x1s) or (q0 and (not x1s) and x0s);
q0_plus <= ((not q1) and (not x1s) and (not x0s)) or (q1 and x1s and x0s) or (q1 and q0 and x0s) or (q1 and q0 and x1s);

u <= q1 and q0;

end behav;

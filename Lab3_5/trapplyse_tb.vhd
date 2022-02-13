library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trapplyse_tb is
end entity;

architecture sim of trapplyse_tb is
	component trapplyse is
		port(clk, reset : in std_logic; -- clk is 1 Hz. reset is active high.
		     x1 : in std_logic;
		     x0 : in std_logic;
		     u : out std_logic;
		     tidkvar : out unsigned(3 downto 0));
	end component;
	-- DUT I/O:
	signal clk,reset : std_logic := '0';
	signal x1, x0 : std_logic;
	signal u : std_logic;
	signal tidkvar : unsigned(3 downto 0);
	
	-- test bench signals:
	signal done : boolean := false;
begin
	clk <= not clk after 500 ns when not done; -- 1 MHz
	
	-- NOTE: The input must be syncronized, and the timer is probably a Moore mashine -> Allow two clock cycles from input to output.
	process begin
		reset <= '1', '0' after 500 ns;
		x0 <= '0';
		x1 <= '0';
		wait for 1 us;
		wait until falling_edge(clk); assert u = '0' report "0. u should be 0 after reset.                         :-(" severity error;
		
		-- Simple test: Turn on and off a few times.
		report "### 10. Turn on/off a few times" severity note;
		x0 <= '1';
		wait until falling_edge(clk);
		wait until falling_edge(clk); assert u = '1' report "10. u should be 1 after x0.                           :-(" severity error;
		wait until falling_edge(clk); assert u = '1' report "11. u should be 1 after x0.                           :-(" severity error;
		wait until falling_edge(clk); assert u = '1' report "12. u should be 1 after x0.                           :-(" severity error;
		x1 <= '1';
		wait until falling_edge(clk);
		wait until falling_edge(clk); assert u = '0' report "13. u should be 0 after x0->x1                        :-(" severity error;
		wait until falling_edge(clk); assert u = '0' report "14. u should be 0 after x0->x1                        :-(" severity error;
		x0 <= '0';
		wait until falling_edge(clk);
		wait until falling_edge(clk); assert u = '1' report "15. u should be 1 after x0->x1->/x0                   :-(" severity error;
		wait until falling_edge(clk); assert u = '1' report "16. u should be 1 after x0->x1->/x0                   :-(" severity error;
		x1 <= '0';
		wait until falling_edge(clk);
		wait until falling_edge(clk); 
		wait until falling_edge(clk); assert u = '0' report "17. u should be 0 after x0->x1->/x0->/x1.             :-(" severity error;
		x0 <= '1'; x1 <= '1';
		wait until falling_edge(clk);
		wait until falling_edge(clk);
		wait until falling_edge(clk); assert u = '1' report "18. u should be 1 after x0x1.                         :-(" severity error;
		x0 <= '0'; x1 <= '0';
		wait until falling_edge(clk);
		wait until falling_edge(clk);
		wait until falling_edge(clk); assert u = '0' report "19. u should be 0 after x0x1->/x0/x1.                 :-(" severity error;
		
		-- Timeout test: Turn on and wait... turn on again after 18 cycles.
		report "### 20. Timeout test. Also check tidkvar" severity note;
		x0 <= '1';
		wait until falling_edge(clk); -- No expected result yet
		wait until falling_edge(clk); -- Expected 15
		wait until falling_edge(clk); -- Expected 14 (testing: 13..15)
		assert tidkvar >=13 report "21. tidkvar should be >= 13 after x0 + 3cc.            :-(" severity error;
		wait until falling_edge(clk); -- Expected 13 (tested: 12..14)
		wait until falling_edge(clk); -- Expected 12 (tested: 11..13)
		wait until falling_edge(clk); -- Expected 11 (tested: 10..12)
		wait until falling_edge(clk); -- Expected 10 (tested: 9..11)
		wait until falling_edge(clk); -- Expected 9 (tested: 8..10)
		wait until falling_edge(clk); -- Expected 8 (tested: 7..9)
		wait until falling_edge(clk); -- Expected 7 (tested: 6..8)
		wait until falling_edge(clk); -- Expected 6 (tested: 5..7)
		wait until falling_edge(clk); -- Expected 5 (tested: 4..6)
		assert tidkvar <= 7 report "22. tidkvar should be <= 7 after x1 + 12cc.           :-(" severity error;
		wait until falling_edge(clk); -- Expected 4 (tested: 3..5)
		wait until falling_edge(clk); -- Expected 3 (tested: 2..4)
		wait until falling_edge(clk); -- Expected 2 (tested: 1..3)
		wait until falling_edge(clk); -- Expected 1 (tested: 0..2)
		wait until falling_edge(clk); -- Expected 0 (tested: 0..1)
		wait until falling_edge(clk); -- Expected 0 (tested: 0..0)
		wait until falling_edge(clk); -- Expected 0
		assert u = '0' report "23. u should be 0 after x0->timeout.                      :-(" severity error;
		x0 <= '0';
		wait until falling_edge(clk);
		wait until falling_edge(clk);
		assert u = '1' report "24. u should be 1 after x0->timeout->/x0                  :-(" severity error;
		
		report "### TEST BENCH DONE. Did you get any error message?" severity note;
		done <= true;
		wait;
	end process;
	
	-- Design under test:
	DUT : trapplyse port map (
	  clk => clk,
	  reset => reset,
	  x1 => x1,
	  x0 => x0,
	  u => u,
	  tidkvar => tidkvar);
	  
end architecture;


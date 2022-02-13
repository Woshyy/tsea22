library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_tb is
end entity;

architecture sim of timer_tb is
	component timer is
		port(clk, reset : in std_logic; -- clk is 1 Hz. reset is active high.
		     startknapp : in std_logic; -- aktiv hög
		     alarm : out std_logic;
		     tidkvar : out unsigned(3 downto 0));
	end component;
	-- DUT I/O:
	signal clk,reset : std_logic := '0';
	signal startknapp : std_logic;
	signal alarm : std_logic;
	signal tidkvar : unsigned(3 downto 0);

	-- test bench signals:
	signal done : boolean := false;
begin
	clk <= not clk after 500 ns when not done; -- 1 MHz rather than 1 Hz. Each clock cycle is 1 us.

	process begin
		reset <= '1', '0' after 500 ns;
		startknapp <= '0';
		wait for 10 us;

		-- Test that it actually starts:
		report "### 10 Test that it starts at all." severity note;
		startknapp <= '1', '0' after 2 us;
		wait until rising_edge(clk); -- give it three clock cycles to start.
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		assert tidkvar > 0 report "10. tidkvar should be > 0 after some clock cycles.    :-(" severity failure; -- failure will stop the simulation.

		-- Reset and try again with a normal case, and try to restart in the middle.
		report "### 20 Test a normal case + try to restart in middle." severity note;
		reset <= '1', '0' after 500 ns;
		wait for 10 us;
		startknapp <= '1', '0' after 2 us; -- three clock cycles.
		wait until rising_edge(clk) and tidkvar > 0; -- now it should be 8
		assert tidkvar = 8 report "20. tidkvar should be 8 by now.                       :-(" severity error;
		wait until rising_edge(clk); -- 7
		wait until rising_edge(clk); -- 6
		wait until rising_edge(clk); -- 5
		wait until rising_edge(clk); -- 4
		startknapp <= '1', '0' after 2 us; -- Test that we do not restart because of this
		wait until rising_edge(clk); -- 3
		wait until rising_edge(clk); -- 2
		wait until rising_edge(clk); -- 1
		assert tidkvar = 1 report "21. tidkvar should be 1 by now.                       :-(" severity error;
		wait until rising_edge(clk); -- 0
		assert tidkvar = 0 report "22. tidkvar should be 0 by now.                      :-(" severity error;


		-- Test that we actually do a one-pulser of input.
		report "### 30 Test that input is one-pulsed'." severity note;
		wait for 1 us;
		startknapp <= '1';
		wait until rising_edge(clk) and tidkvar > 0; -- now it should be 8
		wait until rising_edge(clk); -- 7
		wait until rising_edge(clk); -- 6
		wait until rising_edge(clk); -- 5
		wait until rising_edge(clk); -- 4
		wait until rising_edge(clk); -- 3
		wait until rising_edge(clk); -- 2
		wait until rising_edge(clk); -- 1
		wait until rising_edge(clk); -- 0

		assert tidkvar = 0 report "31. tidkvar should be 0 by now.                       :-(" severity error; -- failure will stop the simulation.
		wait until rising_edge(clk); -- 0
		wait until rising_edge(clk); -- 0
		wait until rising_edge(clk); -- 0
		wait until rising_edge(clk); -- 0
		assert tidkvar = 0 report "32. tidkvar should stay at 0.                         :-(" severity error; -- failure will stop the simulation.
		startknapp <= '1' after 250 ns, '0' after 500 ns;
		assert tidkvar = 0 report "33. tidkvar should stay at 0.                         :-(" severity error; -- failure will stop the simulation.

		report "### TEST BENCH DONE. Did you get any error message?" severity note;
		done <= true;
		wait;
	end process;

	-- Denna process kollar att alarm = 1 <=> tidkvar = 0.
	process(clk) begin
		if rising_edge(clk) then
			if tidkvar=0 and alarm = '0' then
				report "Alarm = 0 and tidkvar = 0                             X-(" severity error;
			elsif tidkvar > 0 and alarm = '1' then
				report "Alarm = 1 and tidkvar > 0                             X-(" severity error;
			end if;
		end if;
	end process;

	-- Design under test:
	DUT : timer port map (
	  clk => clk,
	  reset => reset,
	  startknapp => startknapp,
	  alarm => alarm,
	  tidkvar => tidkvar);


end architecture;

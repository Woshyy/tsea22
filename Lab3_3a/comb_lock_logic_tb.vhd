library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comb_lock_logic_tb is
end entity;

architecture sim of comb_lock_logic_tb is
	component comb_lock_logic is
		port(clk, reset : in std_logic; -- clk is "fast enough". reset is active high.
		     x1 : in std_logic; -- x1 is left
		     x0 : in std_logic; -- x0 is right
		     u : out std_logic);
	end component;
	-- DUT I/O:
	signal clk,reset : std_logic := '0';
	signal x1, x0 : std_logic;
	signal u : std_logic;
	
	-- test bench signals:
	signal x : std_logic_vector(1 downto 0);
	signal done : boolean := false;
begin
	clk <= not clk after 100 ns when not done; -- 5 MHz

	x1 <= x(1);
	x0 <= x(0);
	
	process begin
		reset <= '1', '0' after 500 ns;
		x <= "00";
		wait for 1 us;
		
		-- Test to unlock normally:
		report "### Test to unlock normally" severity note;
		x <= "00"; wait for 1 us;	assert u = '0' report "1. u should be off after 00.                         :-(" severity error;
		x <= "01"; wait for 1 us;	assert u = '0' report "2. u should be off after 00->01.                     :-(" severity error;
		x <= "11"; wait for 1 us;	assert u = '1' report "3. u should be on after 00->01->11.                  :-(" severity error;
		
		-- test that it stays unlocked:
		report "### Test that it stays unlocked" severity note;
		x <= "10"; wait for 1 us;	assert u = '1' report "4. u should stay at on.                              :-(" severity error;
		x <= "11"; wait for 1 us;	assert u = '1' report "5. u should stay at on.                              :-(" severity error;
		x <= "01"; wait for 1 us;	assert u = '1' report "6. u should stay at on.                              :-(" severity error;
		
		-- test the error code:
		report "### Test to enter invalid code" severity note;
		x <= "00"; wait for 1 us;	assert u = '0' report "7. u should go back to off after 00.                 :-(" severity error;
		x <= "10"; wait for 1 us;	assert u = '0' report "8. u should be off after 00->10.                     :-(" severity error;
		x <= "11"; wait for 1 us;	assert u = '0' report "9. u should be off after 00->10->11.                 :-(" severity error;
		x <= "10"; wait for 1 us;	assert u = '0' report "10. u should stay at off.                            :-(" severity error;
		x <= "11"; wait for 1 us;	assert u = '0' report "11. u should stay at off.                            :-(" severity error;
		x <= "01"; wait for 1 us;	assert u = '0' report "12. u should stay at off.                            :-(" severity error;
		
		-- test that x=00 is really tested after reset:
		report "### Test that x=00 is tested after reset" severity note;
		reset <= '1', '0' after 500 ns;
		wait for 1 us;
		x <= "11"; wait for 1 us;	assert u = '0' report "13. u should be off after reset->01->11.             :-(" severity error;
		
		report "### TEST BENCH DONE. Did you get any error message?" severity note;
		done <= true;
		wait;
	end process;
	
	-- Design under test:
	DUT : comb_lock_logic port map (
	  clk => clk,
	  reset => reset,
	  x1 => x1,
	  x0 => x0,
	  u => u);
	  
end architecture;


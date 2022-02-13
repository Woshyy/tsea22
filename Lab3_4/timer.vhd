library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
	port(clk, reset : in std_logic; -- clk is 1 Hz. reset is active high.
	     startknapp : in std_logic; -- aktiv hög
	     alarm : out std_logic;
	     tidkvar : out unsigned(3 downto 0));
end entity;

architecture behav of timer is
	signal q_int : unsigned(3 downto 0);
	signal ce : std_logic;
	signal startknapp_enpuls : std_logic;

	begin
		-- Enpulsare
		process(clk, reset) begin
		  if reset = '1' then
				ce <= '0';
			elsif rising_edge(clk) then
				ce <= startknapp;
			end if;
	end process;

	startknapp_enpuls <= startknapp and not ce;

	process(clk, reset) begin
		if reset = '1' then
			q_int <= to_unsigned(8, 4);

		elsif rising_edge(clk) then
			if startknapp_enpuls = '1' and (q_int = 8 or q_int = 0) then
				q_int <= to_unsigned(7, 4);
			elsif q_int = 0 then
				 q_int <= to_unsigned(0, 4);
			elsif q_int = 8 then
				q_int <= to_unsigned(8, 4);
			else
				q_int <= q_int - 1;
			end if;
		end if;
	end process;

	tidkvar <= q_int;
	alarm <= '1' when q_int = 0 else '0';
end architecture;

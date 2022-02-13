library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comb_lock_prom is
	port(clk, reset : in std_logic; -- clk is "fast enough". reset is active high.
	     x1 : in std_logic; -- x1 is left
	     x0 : in std_logic; -- x0 is right
	     u : out std_logic); -- NOTE: INVERTED OUTPUT IN THIS TASK
end comb_lock_prom;

architecture behav of comb_lock_prom is
	type ROM_mem is array(0 to 15) of std_logic_vector(2 downto 0);
	constant ROM_content : ROM_mem := (0 => "010",
																		 1 => "000",
																		 2 => "000",
																		 3 => "000",
																		 4 => "010",
																		 5 => "100",
																		 6 => "000",
																		 7 => "000",
																		 8 => "000",
																		 9 => "100",
																		 10 => "000",
																		 11 => "110",
																		 12 => "001",
																		 13 => "111",
																		 14 => "111",
																		 15 => "111");
		signal q1, q1_plus : std_logic;
		signal q0, q0_plus : std_logic;
		signal x1s, x0s : std_logic;
		signal adress : std_logic_vector(3 downto 0);
		signal data : std_logic_vector(2 downto 0);

		begin
			process(clk, reset) begin
				if reset = '1' then
					q0 <= '0';
					q1 <= '0';
				elsif rising_edge(clk) then
					q0 <= q0_plus;
					q1 <= q1_plus;
					x1s <= x1;
					x0s <= x0;
				end if;
			end process;

			adress(0) <= x0s;
			adress(1) <= x1s;
			adress(2) <= q0;
			adress(3) <= q1;

			data <= ROM_content(to_integer(unsigned(adress)));

			q1_plus <= data(2);
			q0_plus <= data(1);
			u <= 	not data(0);
end architecture;

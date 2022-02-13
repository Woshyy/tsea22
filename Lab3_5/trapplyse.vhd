library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trapplyse is
	port(clk, reset : in std_logic; -- clk is 1 Hz. reset is active high.
	     x1 : in std_logic;
	     x0 : in std_logic;
	     u : out std_logic;
	     tidkvar : out unsigned(3 downto 0));
end entity;

architecture behav of trapplyse is
	signal clr, ce, clr_onepulsed, rco: std_logic;
	signal x1_last, x0_last : std_logic;
	signal counter : unsigned(3 downto 0);
begin

	process(clk, reset) begin
		if reset = '1' then
			ce <= '0';
		elsif rising_edge(clk) then
			if not (x1 = x1_last) or not(x0 = x0_last) then
				ce <= not ce;
			elsif rco <= '0' then
				ce <= '0';
			end if;
		end if;
	end process;
-- save the state of x1
	process(clk, reset) begin
		if reset = '1' then
			x1_last <= '0';
		elsif rising_edge(clk) then
			x1_last <= x1;
		end if;
	end process;
-- save the state of x0
	process(clk, reset) begin
		if reset = '1' then
			x0_last <= '0';
		elsif rising_edge(clk) then
			x0_last <= x0;
		end if;
	end process;
-- one pulse the clear signal
	process(clk, reset) begin
		if reset = '1' then
			clr <= '0';
		elsif rising_edge(clk) then
			clr <= ce;
		end if;
	end process;

	clr_onepulsed <= ce and not clr;

	process(clk, reset, clr_onepulsed) begin
		if reset = '1' then
			counter <= to_unsigned(0, 4);
			rco <= '1';

		elsif rising_edge(clk) then
			if clr_onepulsed = '1' then
			counter <= to_unsigned(15, 4);
			rco <= '1';
			elsif ce = '0' then
				counter <= to_unsigned(0, 4);
				rco <= '1';
			elsif ce = '1' then
					if counter = 0 then
						rco <= '0';
					else
						counter <= counter - 1;
					end if;


				end if;
			end if;
	end process;

	u <= ce;
	tidkvar <= counter;
end architecture;

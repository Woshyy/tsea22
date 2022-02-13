library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch_tb is
end entity;

architecture sim of stopwatch_tb is
	component stopwatch is
		port(clk, reset : in std_logic; -- clk is "fast enough". reset active high.
		     hundradelspuls : in std_logic;
		     muxfrekvens : in std_logic; -- tic for multiplexing the display.
		     start_stopp : in std_logic;
		     nollstallning : in std_logic; -- clear counters. Active high
		     visningslage : in std_logic; -- 1:show min/sec. 0: show sec/centisec
		     display : out unsigned(1 downto 0); -- 0=right most
		     digit : out std_logic_vector(0 to 7); -- 0=A, 1=B, ..., 6=G, 7=DP
		     raknar : out std_logic);
	end component;
	-- DUT I/O:
	signal clk,reset : std_logic := '0';
	signal hundradelspuls : std_logic := '0';
	signal muxfrekvens : std_logic := '0'; -- tic for multiplexing the display.
	signal start_stopp : std_logic;
	signal nollstallning : std_logic; -- reset counters. Active high
	signal visningslage : std_logic; -- 1:show min/sec. 0: show sec/centisec
	signal display : unsigned(1 downto 0);
	signal digit : std_logic_vector(0 to 7); -- 0=top, 6=middle, 7=DP
	signal raknar : std_logic;

	signal done : boolean := false;
	signal bcd : unsigned(3 downto 0); -- digit converted to unsigned.
	signal BCD3, BCD2, BCD1, BCD0, BCD30 : integer;
begin
	-- scale up time a factor 1000. Except the clock.
	clk <= not clk after 100 ns when not done; -- 5 MHz rather than 8 MHz
	reset <= '1', '0' after 2 us;
	hundradelspuls <= not hundradelspuls after 5 us when not done; -- 100 kHz rather than 100 Hz
	muxfrekvens <= not muxfrekvens after 300 ns when not done; -- 1.67 MHz. All screen updated within 2.4 us.

	process begin
		visningslage <= '0'; -- show ss:cs (cs = centiseconds = second)
		nollstallning <= '1', '0' after 50 us; -- clear
		start_stopp <= '0';
		report "Init with reset" severity note;
		wait for 100 us;
		assert BCD30 = 0000 report "1. BCD not 0 after clear               :-(" severity error;
		assert raknar = '0' report "2. raknar is not 0 as expected         :-(" severity error;

		-- @100 us: Run for 1.5 s
		start_stopp <= '1', '0' after 50 us;
		report "Starting" severity note;
		wait for 1500 us;
		assert BCD30 = 0150 report "3. BCD not 150 after 1.5 s             :-(" severity error;
		assert raknar = '1' report "4. raknar is not 1 as expected         :-(" severity error;

		-- @1600 us: clear again.
		nollstallning <= '1', '0' after 50 us;
		report "zero" severity note;
		wait for 73 ms; -- 73 sec => should show 13:00
		assert BCD30 = 1300 report "5. BCD not 13.00, 73 s after clear     :-(" severity error;
		assert raknar = '1' report "6. raknar is not 1 as expected         :-(" severity error;

		-- @74600 us: Stopping+start (pause for 1.5 sec)
		start_stopp <= '1', '0' after 50 us, '1' after 1500 us, '0' after 2300 us;
		report "Stop/start" severity note;
		wait for 10 ms; --73 s + 10 s - 1.5 s = 81.5 s
		assert BCD30 = 2150 report "7. BCD not 21.50                       :-(" severity error;

		-- @84600 us: Change mode
		visningslage <= '1'; -- show mm:ss
		report "Switch to mm:ss view" severity note;
		wait for 10 us; -- wait for screen to update. 81.50 s = 01:21.50
		assert BCD30 = 0121 report "8. BCD not 01:21                       :-(" severity error;

		report "Now simulate one hour in x1000 speed. Done at 3.69 sec. (have a look at bottom left corner)" severity note;

		wait for 1800 ms; -- half an hour.
		assert BCD30 = 3121 report "9. BCD not 31:21                       :-(" severity error;

		wait for 1800 ms; -- half an hour.
		assert BCD30 = 0121 report "10. BCD not 01:21 (+ 1h)               :-(" severity error;

		start_stopp <= '1', '0' after 50 us;
		report "After one hour: Stop." severity note;
		wait for 10 ms;

		done <= true;
		wait;
	end process;

	-- Design under test:
	DUT : stopwatch port map (
	  clk => clk,
	  reset => reset,
		hundradelspuls => hundradelspuls,
		muxfrekvens => muxfrekvens,
		start_stopp => start_stopp,
		nollstallning => nollstallning,
		visningslage => visningslage,
		display => display,
		digit => digit,
		raknar => raknar);

	-- Drivers (convert display+digit to an integer in range 0-9999):
	bcd <= "0000" when digit(0 to 6) = "1111110" else -- 0
	       "0001" when digit(0 to 6) = "0110000" else -- 1
	       "0010" when digit(0 to 6) = "1101101" else -- 2
	       "0011" when digit(0 to 6) = "1111001" else -- 3
	       "0100" when digit(0 to 6) = "0110011" else -- 4
	       "0101" when digit(0 to 6) = "1011011" else -- 5
	       "0110" when digit(0 to 6) = "1011111" else -- 6
	       "0110" when digit(0 to 6) = "0011111" else -- 6 without top segment
	       "0111" when digit(0 to 6) = "1110000" else -- 7
	       "0111" when digit(0 to 6) = "1110010" else -- 7 with segment F
	       "1000" when digit(0 to 6) = "1111111" else -- 8
	       "1001" when digit(0 to 6) = "1111011" else -- 9
	       "1001" when digit(0 to 6) = "1110011" else -- 9 without bottom segment
	       "0000" when digit(0 to 6) = "0000000" else -- blank (e.g. " 1:15" = "01:15")
	       "XXXX";
	process(clk) begin
		-- To test that the multiplexing is running, use the following form:
		--   BCD0 <= to_integer(bcd), -1 after 5 us;
		-- This means that BCD0 gets -1 after 5 us, unless updated again
		-- before that. It should be updated every 2.4 us.
		if display = 0 then BCD0 <= to_integer(bcd), -1 after 5 us; end if;
		if display = 1 then BCD1 <= to_integer(bcd), -1 after 5 us; end if;
		if display = 2 then BCD2 <= to_integer(bcd), -1 after 5 us; end if;
		if display = 3 then BCD3 <= to_integer(bcd), -1 after 5 us; end if;
	end process;
	BCD30 <= 1000*BCD3 + 100*BCD2 + 10*BCD1 + 1*BCD0;

	-- Verify the display rate (should be 600 ns):
	process
		variable last_time : time;
	begin
		wait until reset = '0'; -- wait until reset releases.
		wait for 2 us; -- wait a little longer to let things stabalize
		wait until display'event;
		last_time := now; -- current simulation time.
		while true loop
			wait until display'event;
			assert now - last_time = 600 ns
				report "display rate = " & time'image(display'last_event) & " /= 600 ns.        :-("
				severity error;
			last_time := now;
		end loop;
	end process;

	-- Verify that output is syncronized to clk (and reset)
	process(display, digit, raknar) begin
		-- this one runs as soon as there is a change in any output signals.
		-- (it also runs at start, which gives error. Filter this with an if statement)
		if now > 0 ns then
			assert (clk'last_event = 0 ns and clk = '1') or reset'event
				report "An output just changed async to rising_edge(clk) and reset     :-("
				severity error;
		end if;
	end process;

end architecture;

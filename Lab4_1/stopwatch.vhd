library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch is
	port(clk, reset : in std_logic; -- clk is "fast enough". reset is active high.
	     hundradelspuls : in std_logic;
	     muxfrekvens   : in std_logic; -- tic for multiplexing the display.
	     start_stopp : in std_logic;
	     nollstallning : in std_logic; -- restart from 00:00:00
	     visningslage : in std_logic; -- 1:show min/sec. 0: show sec/centisec
	     display : out unsigned(1 downto 0); -- 0=rightmost
	     digit : out std_logic_vector(0 to 7); -- 0=A, 1=B, ..., 6=G, 7=DP
	     raknar : out std_logic); -- Connected to a LED
end entity;

architecture rtl of stopwatch is
	signal ce, start_stopp_old, start_stopp_onepulse, hundradelspuls_gammal, hundradelspuls_enpuls, visningslage_s: std_logic;
	signal rco_100_0, rco_100_1 : std_logic;
	signal counter_100_0, counter_100_1 : unsigned(3 downto 0);
	signal rco_sec_0, rco_sec_1 : std_logic;
	signal counter_sec_0, counter_sec_1 : unsigned(3 downto 0);
	signal rco_min_0 : std_logic;
	signal counter_min_0, counter_min_1 : unsigned(3 downto 0);
	signal out0, out1, out2, out3, show: unsigned(3 downto 0);
	signal mux_counter : unsigned(1 downto 0);
	signal nollstallning_enpuls, old_nollstallning : std_logic;
	signal muxfrekvens_old, muxfrekvens_enpuls, muxfrekvens_older : std_logic;
begin
	-- Control of the start and stop
	process(clk, reset) begin
		if reset = '1' then
			start_stopp_old <= '0';
		elsif rising_edge(clk) then
			start_stopp_old <= start_stopp;
		end if;
	end process;

	start_stopp_onepulse <= start_stopp and not start_stopp_old;
	---------------------------------------------------------------

	--Control count enable
	process(clk, reset) begin
		if reset = '1' then
			ce <= '0';
		elsif rising_edge(clk) then
			if start_stopp_onepulse = '1' then
				ce <= not ce;
			end if;
		end if;
	end process;
	----------------------------------------------------------------

	-- For the lamp that show if it is counting
	raknar <= ce;
	----------------------------------------------------------------

	-- One pulse the hundredpuls
	process(clk) begin
		if rising_edge(clk) then
			hundradelspuls_gammal <= hundradelspuls;
		end if;
	end process;

	hundradelspuls_enpuls <= hundradelspuls and not hundradelspuls_gammal;
	-------------------------------------------------------------------

	--One pulse the Synchronous reset
	process(clk) begin
		if rising_edge(clk) then
			old_nollstallning <= nollstallning;
		end if;
	end process;

	nollstallning_enpuls <= nollstallning and not old_nollstallning;
	-------------------------------------------------------------------

	-- Counter hundredts of a second (0)
	process(clk, reset) begin
		if reset = '1' then
			counter_100_0 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_100_0 <= to_unsigned(0, 4);
			elsif counter_100_0 = 0 and rco_100_0 = '1' then
				rco_100_0 <= '0';
			elsif hundradelspuls_enpuls = '1' then
				if ce = '1' then
					if counter_100_0 = 9 then
						rco_100_0 <= '1';
						counter_100_0 <= to_unsigned(0, 4);
					else
						counter_100_0 <= counter_100_0 + 1;
						end if;
				end if;
			end if;
		end if;
	end process;
	--------------------------------------------------------------------

	-- Counter hundredts of a second (1)
	process(clk, reset) begin
		if reset = '1' then
			counter_100_1 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_100_1 <= to_unsigned(0, 4);
			elsif rco_100_0 = '1' then
				if counter_100_1 = 9 then
					rco_100_1 <= '1';
					counter_100_1 <= to_unsigned(0, 4);
				else
					counter_100_1 <= counter_100_1 + 1;
				end if;
			elsif counter_100_1 = 0 then
					rco_100_1 <= '0';
			end if;
		end if;
	end process;
	------------------------------------------------------------------

	--counter second (0)
	process(clk, reset) begin
		if reset = '1' then
			counter_sec_0 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_sec_0 <= to_unsigned(0, 4);
			elsif rco_100_1 = '1' then
				if counter_sec_0 = 9 then
					rco_sec_0 <= '1';
					counter_sec_0 <= to_unsigned(0, 4);
				else
					counter_sec_0 <= counter_sec_0 + 1;
				end if;
			elsif counter_sec_0 = 0 then
				rco_sec_0 <= '0';
			end if;
		end if;
	end process;
	--------------------------------------------------------------------

	--counter second (1)
	process(clk, reset) begin
		if reset = '1' then
			counter_sec_1 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_sec_1 <= to_unsigned(0, 4);
			elsif rco_sec_0 = '1' then
				if counter_sec_1 = 5 then
					rco_sec_1 <= '1';
					counter_sec_1 <= to_unsigned(0, 4);
				else
					counter_sec_1 <= counter_sec_1 + 1;
				end if;
			elsif counter_sec_1 = 0 then
				rco_sec_1 <= '0';
			end if;
		end if;
	end process;
	-------------------------------------------------------------------

	--counter minute (0)
	process(clk, reset) begin
		if reset = '1' then
			counter_min_0 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_min_0 <= to_unsigned(0, 4);
			elsif rco_sec_1 = '1' then
				if counter_min_0 = 9 then
					rco_min_0 <= '1';
					counter_min_0 <= to_unsigned(0, 4);
				else
					counter_min_0 <= counter_min_0 + 1;
				end if;
			elsif counter_min_0 = 0 then
				rco_min_0 <= '0';
			end if;
		end if;
	end process;
	-----------------------------------------------------------------------

	--counter minute (1)
	process(clk, reset) begin
		if reset = '1' then
			counter_min_1 <= to_unsigned(0, 4);
		elsif rising_edge(clk) then
			if nollstallning_enpuls = '1' then
				counter_min_1 <= to_unsigned(0, 4);
			elsif rco_min_0 = '1' then
				if counter_min_1 = 5 then
					counter_min_1 <= to_unsigned(0, 4);
				else
					counter_min_1 <= counter_min_1 + 1;
				end if;
			end if;
		end if;
	end process;
	-----------------------------------------------------------------------

	--Synchronize the display mode signal.
process(clk, visningslage) begin
	if rising_edge(clk) then
		visningslage_s <= visningslage;
	end if;
end process;
-------------------------------------------------------------------------

--Display mode
process(counter_100_0, counter_100_1,
				counter_sec_0, counter_sec_1,
				counter_min_0, counter_min_1,
				visningslage_s) begin
					case visningslage_s is
						when '1' => out3 <= counter_min_1;
												out2 <= counter_min_0;
												out1 <= counter_sec_1;
												out0 <= counter_sec_0;

						when '0' => out3 <= counter_sec_1;
												out2 <= counter_sec_0;
												out1 <= counter_100_1;
												out0 <= counter_100_0;

					when others => out3 <= to_unsigned(1, 4);
												 out2 <= to_unsigned(2, 4);
										 		 out1 <= to_unsigned(3, 4);
												 out0 <= to_unsigned(4, 4);
					end case;
				end process;
	----------------------------------------------------------



	--Onepulse the mux frequency
	process(clk, muxfrekvens, muxfrekvens_old) begin
		if rising_edge(clk) then
			muxfrekvens_old <= muxfrekvens;
			muxfrekvens_older <= muxfrekvens_old;
		end if;
	end process;

	muxfrekvens_enpuls <= muxfrekvens_old and not muxfrekvens_older;
	-------------------------------------------------------------

	--Choose a number between 0 to 3 and that is where we are going go Display
	--a number.
	process(clk, reset) begin
		if reset = '1' then
			mux_counter <= to_unsigned(0, 2);
		elsif rising_edge(clk) then
			if muxfrekvens_enpuls = '1' then
				if mux_counter = 3 then
					mux_counter <= to_unsigned(0, 2);
				else
					mux_counter <= mux_counter + 1;
				end if;
			end if;
		end if;
	end process;
	------------------------------------------------------------------------

	--Choose a number to display
	process(mux_counter, out0, out1, out2, out3) begin
		case mux_counter is
			when "00" => show <= out0;
			when "01" => show <= out1;
			when "10" => show <= out2;
			when "11" => show <= out3;
			when others => show <= to_unsigned(0, 4);
		end case;
	end process;
	----------------------------------------------------------

	--Process that number into signal for the displayer.
	process(show) begin
		case show is
			when "0000" => digit <= "11111100";
			when "0001" => digit <= "01100000";
			when "0010" => digit <= "11011010";
			when "0011" => digit <= "11110010";
			when "0100" => digit <= "01100110";
			when "0101" => digit <= "10110110";
			when "0110" => digit <= "10111110";
			when "0111" => digit <= "11100000";
			when "1000" => digit <= "11111110";
			when "1001" => digit <= "11110110";
			when others => digit <= "00000000";
		end case;
	end process;
	---------------------------------------------------------------

	display <= mux_counter;

end architecture;

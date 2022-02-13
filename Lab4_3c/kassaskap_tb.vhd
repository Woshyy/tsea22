-- Testbänk för kassaskåp, implementation a) och c).
--
-- Då flera viktiga ord i denna labb innehåller "å", så får utskrifterna helt enkelt bli på engelska.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kassaskap_tb is
end entity;

architecture sim of kassaskap_tb is
	component kassaskap is
		port(clk : in std_logic; -- hög frekvens
			   reset : in std_logic; -- aktivt hög
			   oppna_stang : in std_logic; -- 1=öppna, 0=stäng
			   spara : in std_logic; -- aktivt hög
			   oppen_stangd : out std_logic; -- 1=olåst, 0=låst
			   ny_kod_ok : out std_logic;
			   ratt_a, ratt_b : in std_logic;
			   siffra : out unsigned(3 downto 0));
	end component;

	signal clk : std_logic := '1'; -- hög frekvens
	signal reset : std_logic := '0'; -- aktivt hög
	signal oppna_stang : std_logic := '0'; -- 1=öppna, 0=stäng
	signal spara : std_logic := '0'; -- aktivt hög
	signal oppen_stangd : std_logic; -- 1=olåst, 0=låst
	signal ny_kod_ok : std_logic;
	signal ratt_ab : std_logic_vector(0 to 1) := "11";
	signal siffra : unsigned(3 downto 0);
	
	signal test_nummer : integer := 0; -- bara för att underlätta avläsandet i wave-forms
	signal clk_running : boolean := true;
begin
	
	-- Skapa klocka. Den är '1' i 500 ns, och '0' i 500 ns (totalt 1000 ns = 1 us):
	clk <= '0' after 500 ns when clk /= '0' else
	       '1' after 500 ns when clk_running;
	-- (den här sorterns konstruktion går naturligtvis inte att göra på CPLD:er,
	--  utan bara i simulering).
	
	process
		variable felraknare : integer := 0;
		-- Förenkla resultat-utskrifter med denna funktion:
		procedure rapportera(cond : in boolean; str : in string) is begin
			if cond then
				report str & " : PASS  " & string'(str'length to 53 => ' ') & ":-)" severity note;
			else
				report str & " : FAIL  " & string'(str'length to 53 => ' ') & "X-(" severity error;
				felraknare := felraknare + 1;
			end if;
		end procedure;
	begin
		-- Nollställ allt under några klockcykler.
		reset <= '1';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		reset <= '0';
		wait until rising_edge(clk);
		wait for 500 ns; -- en halv klockcykel.
		
		------------- Test0: Vanligt rattande ------------------
		test_nummer <= 0;
		report "-------------- Test0: Simple rotating -----------------------" severity note;
		-- Minns: Vi är en halv klockcykel ur fas nu.
		ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
		wait for 20 us;
		rapportera(siffra = 1, "Test0.0. Want: Siffra = 1 after right turn");
		
		ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
		wait for 20 us;
		rapportera(siffra = 0, "Test0.1. Want: Siffra = 0 after left turn");
		
		ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
		wait for 20 us;
		rapportera(siffra = 9, "Test0.2. Want: Siffra = 9 after left turn");
		
		ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
		wait for 20 us;
		rapportera(siffra = 0, "Test0.3. Want: Siffra = 0 after right turn");
		
		------------- Test1: +- någon klockcykel mellan A och B ------------------
		test_nummer <= 1;
		report "-------------- Test1: one clock cycle between A and B -------" severity note;
		ratt_ab <= "01", "00" after 5 us, "10" after 9.3 us, "11" after 9.7 us; -- skev+ höger
		wait for 20 us;
		rapportera(siffra = 1, "Test1.0. Want: Siffra = 1 after skew+ right turn");
		ratt_ab <= "01", "00" after 5 us, "01" after 9.3 us, "11" after 9.7 us; -- skev- höger
		wait for 20 us;
		rapportera(siffra = 2, "Test1.1. Want: Siffra = 2 after skew- right turn");
		
		ratt_ab <= "01" after 0.3 us, "00" after 0.7 us, "01" after 5 us, "11" after 10 us; -- skev- vänster
		wait for 20 us;
		rapportera(siffra = 1, "Test1.2. Want: Siffra = 1 after skew- left turn");
		ratt_ab <= "10" after 0.3 us, "00" after 0.7 us, "01" after 5 us, "11" after 10 us; -- skev+ vänster
		wait for 20 us;
		rapportera(siffra = 0, "Test1.3. Want: Siffra = 0 after skre+ left turn");
		
		------------- Test2: Stäng + öppna låset ---------------
		test_nummer <= 2;
		report "-------------- Test2: Close+open lock -----------------------" severity note;
		-- Nollställ rotationsräknaren genom "öppna+stäng"-manöver:
		oppna_stang <= '1';
		wait for 3 us; -- 3 klockcykler.
		rapportera(oppen_stangd = '0', "Test2.0. Want: Safe is locked after oppna_stang=1");
		oppna_stang <= '0';
		wait for 3 us; -- 3 klockcykler.
		rapportera(oppen_stangd = '0', "Test2.0. Want: Safe is locked after oppna_stang=0");
		-- Öppna (under antagande att initiala koden är 00):
		-- Vrid högerut från 0 till 0:
		for i in 1 to 10 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Vrid vänsterut från 0 till 0:
		for i in 1 to 10 loop
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		-- Vrid högerut från 0 till 0:
		for i in 1 to 10 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		oppna_stang <= '1';
		wait for 3 us; -- 3 klockcykler
		rapportera(oppen_stangd = '1', "Test2.1. Want: Safe is unlocked after oppna_stang=1");
		
		------------- Test3: Ändra kod till 42, lås.
		test_nummer <= 3;
		report "-------------- Test3: Change code to 42. Lock ---------------" severity note;
		-- snurra höger 14 pulser (för att testa hela varvet, och gå från 0 till 4):
		for i in 1 to 14 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		rapportera(siffra = 4, "Test 3.0. Want: Siffra = 4 after 14 right turns");
		-- snurra vänster 12 pulser (för att testa hela varvet, och gå från 4 till 2):
		for i in 1 to 12 loop
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		rapportera(siffra = 2, "Test 3.1. Want: Siffra = 2 after 12 left turns");
		-- snurra höger 8 pulser 2->0
		for i in 1 to 8 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		rapportera(ny_kod_OK = '0', "Test 3.2. Want: ny_kod_OK = '0' before ""spara""");
		-- Spara:
		spara <= '1', '0' after 7 us;
		wait for 20 us;
		rapportera(ny_kod_OK = '1', "Test 3.3. Want: ny_kod_OK = '1' after ""spara""");
		-- Snurra lite till, vilket inte ska påverka koden:
		ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger (2 -> 3)
		wait for 20 us;
		ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster (3 -> 2)
		wait for 20 us;
		-- Lås:
		oppna_stang <= '0';
		wait for 40 us;
		rapportera(siffra = 0, "Test 3.4. Want: Siffra = 0 after locking");
		rapportera(oppen_stangd = '0', "Test 3.5. Want: Oppen_stangd = 0 after locking");
		
		------------- Test4: Ratta in 42, glöm 0:an => misslyckas med att låsa upp, lås.
		test_nummer <= 4;
		report "-------------- Test4: Rotate to 42 -> no 0. Unlock ----------" severity note;
		-- Ratta 0->4:
		for i in 1 to 4 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		rapportera(siffra = 4, "Test 4.0. Want: Siffra = 4 after 4 right turns");
		-- Ratta 4->2:
		for i in 1 to 2 loop
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		rapportera(siffra = 2, "Test 4.1. Want: Siffra = 2 after 2 left turns");
		-- Lås upp:
		oppna_stang <= '1';
		wait for 20 us;
		rapportera(siffra = 2, "Test 4.2. Want: Siffra = still 2 after unlocking");
		rapportera(oppen_stangd = '0', "Test 4.3. Want: Oppen_stangd = 0 after unlocking");
		oppna_stang <= '0';
		wait for 20 us;
		
		------------- Test5: Ratta in 21, misslyckas med att låsa upp
		test_nummer <= 5;
		report "-------------- Test5: Try unlock with code 21 ---------------" severity note;
		-- Ratta höger 0->2:
		for i in 1 to 2 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		rapportera(siffra = 2, "Test 5.0. Want: Siffra = 2 after two right turns");
		-- Ratta vänster 2->1:
		ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
		wait for 20 us;
		-- Ratta höger 1->0:
		for i in 1 to 9 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Lås upp (ska misslyckas):
		oppna_stang <= '1';
		wait for 20 us;
		rapportera(oppen_stangd = '0', "Test 5.1. Want: oppen_stangd = 0 after using code 21");
		oppna_stang <= '0';
		
		------------- Test6: Ratta in 42, sen sluta på 9, misslyckas med att låsa upp
		test_nummer <= 6;
		report "-------------- Test6: Try unlock with code 42, then 9 -------" severity note;
		-- Ratta höger 0->4:
		for i in 1 to 4 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Ratta vänster 4->2:
		for i in 1 to 2 loop
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		-- Ratta höger 2->9:
		for i in 1 to 7 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Lås upp (ska misslyckas):
		oppna_stang <= '1';
		wait for 20 us;
		rapportera(oppen_stangd = '0', "Test 6.0. Want: oppen_stangd = 0 after using code 42(9)");
		oppna_stang <= '0';
		
		------------- Test7: Ratta in 424242, misslyckas med att låsa upp
		test_nummer <= 7;
		report "-------------- Test7: Try unlock with code 424242 -----------" severity note;
		for i in 1 to 4 loop -- ratta höger 0->4
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta vänster 4->2:
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta höger 2->4:
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta vänster 4->2:
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta höger 2->4:
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta vänster 4->2:
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		-- Ratta höger 2->0:
		for i in 1 to 8 loop
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Lås upp (ska misslyckas):
		oppna_stang <= '1';
		wait for 20 us;
		rapportera(oppen_stangd = '0', "Test 6.0. Want: oppen_stangd = 0 after using code 42(9)");
		oppna_stang <= '0';

		------------- Test8: Lås, ratta in 42, lyckas med att låsa upp
		test_nummer <= 8;
		report "-------------- Test8: Unlock with code 42 -------------------" severity note;
		for i in 1 to 4 loop -- ratta höger 0->4
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		for i in 1 to 2 loop -- Ratta vänster 4->2:
			ratt_ab <= "00", "01" after 5 us, "11" after 10 us; -- normal vänster
			wait for 20 us;
		end loop;
		for i in 1 to 8 loop -- Ratta höger 2->0
			ratt_ab <= "01", "00" after 5 us, "11" after 10 us; -- normal höger
			wait for 20 us;
		end loop;
		-- Lås upp (ska lyckas):
		oppna_stang <= '1';
		wait for 20 us;
		rapportera(oppen_stangd = '1', "Test 8.0. Want: oppen_stangd = 1 after using code 42");
		oppna_stang <= '0';
		
		------------- Summering.
		report "-------------- Summary --------------------------------------" severity note;
		rapportera(felraknare = 0, "SUMMARY: error counter = "&integer'image(felraknare) & ".");
		
		-- Stoppa simuleringen genom att stoppa klockan:
		clk_running <= false;
		wait;
	end process;

	-- Här "kopplar vi in" vårt kassaskåp.
	dut : kassaskap port map(clk, reset, oppna_stang, spara, oppen_stangd, ny_kod_ok, ratt_ab(0), ratt_ab(1), siffra);
	
end architecture;


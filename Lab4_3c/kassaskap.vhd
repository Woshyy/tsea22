library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kassaskap is
	port(clk : in std_logic; -- hög frekvens
	     reset : in std_logic; -- aktivt hög
	     oppna_stang : in std_logic; -- 1=öppna, 0=stäng
	     spara : in std_logic; -- aktivt hög
	     oppen_stangd : out std_logic; -- 1=olåst, 0=låst
	     ny_kod_ok : out std_logic;
	     ratt_a, ratt_b : in std_logic;
	     siffra : out unsigned(3 downto 0));
end entity;

architecture behav of kassaskap is
	-- OBS. För att testbänken ska fungera, så måste koden sättas till 00 vid reset.
begin
end architecture;


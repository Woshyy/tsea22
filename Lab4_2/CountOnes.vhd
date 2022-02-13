library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CountOnes is
  port(clk : in std_logic;
       reset : in std_logic;     -- active high
       startknapp : in std_logic;    -- active high
       cs1,cs2 : out std_logic; -- active low
       addr : out unsigned(3 downto 0); -- this is a number, and should be unsigned
       data : in std_logic_vector(3 downto 0); -- this is just a vector of bits
       LED : out std_logic;
       BCD2,BCD1,BCD0 : out unsigned(3 downto 0)); -- these are also numbers, BCD0 is least significant digit.
end entity;

architecture behav of CountOnes is
  signal ce, startknapp_onepuls, startknapp_old : std_logic;
  signal counter_address : unsigned(3 downto 0);
  signal rco_address : std_logic;
  signal amount_of_zero : unsigned(3 downto 0);
  signal counter_unit, counter_tenth, counter_hundred : unsigned(3 downto 0);
  signal rco_unit, rco_tenth : std_logic;
  signal counter_stop : unsigned(4 downto 0);
  signal zero, zero_old : std_logic;
begin
  process(clk) begin
    --One pulsing the startknapp
    if rising_edge(clk) then
      startknapp_old <= startknapp;
    end if;
  end process;

  startknapp_onepuls <= startknapp and not startknapp_old;
  ----------------------------------------------------------------

  --Setting count enable and counting to 31. when 31 turn off ce.
  process(clk, reset) begin
    if reset = '1' then
      counter_stop <= to_unsigned(0, 5);
      ce <= '0';
    elsif rising_edge(clk) then
      if startknapp_onepuls = '1' then
        counter_stop <= to_unsigned(0, 5);
        ce <= '1';
      elsif counter_stop = 31 then
        counter_stop <= to_unsigned(0, 5);
        ce <= '0';
      elsif ce = '1' then
        counter_stop <= counter_stop + 1;
      end if;
    end if;
  end process;
  -----------------------------------------------------------------

  --Sykron reset one pulse
  process(clk) begin
    if rising_edge(clk) then
      zero_old <= ce;
    end if;
  end process;

  zero <= ce and not zero_old;
  -----------------------------------------------------------------


  --Adress counter
  process(clk, reset) begin
    if reset = '1' then
      counter_address <= to_unsigned(0, 4);
      rco_address <= '0';
    elsif rising_edge(clk) and ce = '1' then
      if zero = '1' then
        rco_address <= '0';
        counter_address <= to_unsigned(0, 4);

      elsif counter_address = 15 then
        counter_address <= to_unsigned(0, 4);
        rco_address <= '1';

      else
        counter_address <= counter_address + 1;
      end if;
    end if;
  end process;
  ------------------------------------------------------------------

  --LED
  process(clk, reset) begin
    if reset = '1' then
      LED <= '0';
    elsif rising_edge(clk) then
      LED <= ce;
    end if;
  end process;
  ------------------------------------------------------------------

  --which one to take from
  cs1 <= rco_address;
  cs2 <= not rco_address;
  addr <= counter_address;
  ------------------------------------------------------------------

  --the prom translate how many zeros there are. Depending what we get back.
  process(data) begin
    case data is
      when "0000" => amount_of_zero <= to_unsigned(0, 4);
      when "0001" => amount_of_zero <= to_unsigned(1, 4);
      when "0010" => amount_of_zero <= to_unsigned(1, 4);
      when "0011" => amount_of_zero <= to_unsigned(2, 4);
      when "0100" => amount_of_zero <= to_unsigned(1, 4);
      when "0101" => amount_of_zero <= to_unsigned(2, 4);
      when "0110" => amount_of_zero <= to_unsigned(2, 4);
      when "0111" => amount_of_zero <= to_unsigned(3, 4);
      when "1000" => amount_of_zero <= to_unsigned(1, 4);
      when "1001" => amount_of_zero <= to_unsigned(2, 4);
      when "1010" => amount_of_zero <= to_unsigned(2, 4);
      when "1011" => amount_of_zero <= to_unsigned(3, 4);
      when "1100" => amount_of_zero <= to_unsigned(2, 4);
      when "1101" => amount_of_zero <= to_unsigned(3, 4);
      when "1110" => amount_of_zero <= to_unsigned(3, 4);
      when "1111" => amount_of_zero <= to_unsigned(4, 4);
      when others => amount_of_zero <= to_unsigned(0, 4);
    end case;
  end process;
  -------------------------------------------------------------------

  --counter unit
  process(clk, reset) begin
    if reset = '1' then
      counter_unit <= to_unsigned(0, 4);
    elsif rising_edge(clk) then
      if zero = '1' then
      counter_unit <= amount_of_zero;
      elsif ce = '1' then
        if (counter_unit + amount_of_zero) > 9 then
          counter_unit <= counter_unit + amount_of_zero - 10;
          rco_unit <= '1';
        else
          counter_unit <= counter_unit + amount_of_zero;
          rco_unit <= '0';
        end if;
      else
        rco_unit <= '0';
      end if;
    end if;
  end process;
  ------------------------------------------------------------------

  --counter tenth
  process(clk, reset) begin
    if reset = '1' then
      counter_tenth <= to_unsigned(0, 4);
      rco_tenth <= '0';
    elsif rising_edge(clk) then
      if zero = '1' then
        counter_tenth <= to_unsigned(0, 4);
      elsif rco_unit = '1' then
        if counter_tenth = 9 then
          counter_tenth <= to_unsigned(0, 4);
          rco_tenth <= '1';
        else
          counter_tenth <= counter_tenth + 1;
          rco_tenth <= '0';
        end if;
      else
        rco_tenth <= '0';
      end if;
    end if;
  end process;
  ------------------------------------------------------------------

  --counter hundred
  process(clk, reset) begin
    if reset = '1' then
      counter_hundred <= to_unsigned(0, 4);
    elsif rising_edge(clk) then
      if zero = '1' then
        counter_hundred <= to_unsigned(0, 4);
      elsif rco_tenth = '1' then
        if counter_hundred = 9 then
          counter_hundred <= to_unsigned(0, 4);
        else
          counter_hundred <= counter_hundred + 1;
        end if;
      end if;
    end if;
  end process;
  -------------------------------------------------------------------

  BCD0 <= counter_unit;
  BCD1 <= counter_tenth;
  BCD2 <= counter_hundred;
end architecture;

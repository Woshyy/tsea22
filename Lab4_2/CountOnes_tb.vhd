--------------------------------------------------
-- Name: CountOnes_tb
-- Version: 2.4
-- Description: Test bench for CountOnes

-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CountOnes_tb is
end entity;

architecture sim of CountOnes_tb is
  -- Declare the pins of the unit we are going to test:
  component CountOnes is
    port(clk, reset : in std_logic;
         startknapp : in std_logic;
         cs1,cs2 : out std_logic;
         addr : out unsigned(3 downto 0);
         data : in std_logic_vector(3 downto 0);
         LED : out std_logic;
         BCD2,BCD1,BCD0 : out unsigned(3 downto 0));
  end component;
  -- Declare the use I/O signals:
  signal clk, reset : std_logic := '1';
  signal startknapp : std_logic := '0';
  signal cs1,cs2 : std_logic;
  signal addr : unsigned(3 downto 0);
  signal data : std_logic_vector(3 downto 0);
  signal LED : std_logic;
  signal BCD2,BCD1,BCD0 : unsigned(3 downto 0);

  -- Declare some other signals we need:
  signal done : boolean := false;
  signal watchdog : integer := 0;
  type ROM_t is array (0 to 15) of std_logic_vector(7 downto 0); -- Both ROMs beside each others
  signal ROM : ROM_t := (others=>(others=>'0')); -- The ROMs starts with just zeros.
  signal expected_res : integer;
  signal bcd_int : integer;
begin
  -- Create clock and timeout signals
  clk <= not clk after 5 ms when not done; -- 10 ms. This is required in one of the tests.
  
  process(clk,reset) begin
    if reset = '1' then
      watchdog <= 0;
    elsif rising_edge(clk) then
      watchdog <= watchdog + 1;
      if startknapp = '1' then
        watchdog <= 0;
      end if;
      -- If watchdog too big: Report it, and the "severity failure" will kill the simulation.
      assert watchdog < 1024 report "1. LED did not turn off in 1024 clock cycles. Aborting." severity failure;
    end if;
  end process;
  
  -- Create stimuli, and check sanity
  process
--bcd_int    variable cnt : integer; -- This is replaced by bcd_int
  begin
    -- Test 0: Just zeros.
    reset <= '1', '0' after 12 ms;   -- First clear the system, and refine the ROM content.
    ROM <= (others=>(others=>'0')); -- Meaning: (all rows are: (all bits are: '0'))
    expected_res <= 0;              -- We expect the result to be all-zeros.
    wait until reset = '0';          -- Release the clear signal
    startknapp <= '1' after 12 ms, '0' after 55 ms; -- Define a wave form for the startknapp signal.
    wait for 55 ms;                 -- Then wait for a while
    wait until LED = '0';           -- Wait until the output is ready
    wait for 1 ns;                  -- ...and yet a short while (google the "VHDL delta cycle")
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
                                    -- cnt is now an integer version of the BCD digits
    if bcd_int = expected_res then      -- Print the result
      report "Test 0: OK (achieved = expected = "&integer'image(bcd_int)&").                               :-)" severity note;
    else
      report "2. Test 0: NOK (achieved = "&integer'image(bcd_int)&", expected="&integer'image(expected_res)&").                               :-(" severity error;
    end if;
    
    -- Test 1: Just ones.
    ROM <= (others=>(others=>'1'));
    expected_res <= 128;
    startknapp <= '1' after 12 ms, '0' after 55 ms;
    wait for 55 ms;
    wait until LED = '0';
    wait for 1 ns;
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    if bcd_int = expected_res then      -- Print the result
      report "Test 1: OK (achieved = expected = "&integer'image(bcd_int)&").                             :-)" severity note;
    else
      report "3. Test 1: NOK (achieved = "&integer'image(bcd_int)&", expected="&integer'image(expected_res)&").                           :-(" severity error;
    end if;
    
    -- Test 1b: Did the counter stop when done?
    expected_res <= bcd_int; -- since we expect it to be the same.
    wait until rising_edge(clk);
    wait until rising_edge(clk);
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    if bcd_int = expected_res then
      report "Test 1b: OK (counter stopped).                                       :-)" severity note;
    else
      report "4. Test 1b: NOK (counter changed when LED=0).                           :-(" severity error;
    end if;
    
    -- Test 2: Random data
    --   Note: b"ROM1_ROM2"
    ROM <= (0=>b"0010_0000", -- 1+0=1 = number of ones on this row
            1=>b"0000_0000", -- 0+0=0, 1 ackumulated
            2=>b"1100_0101", -- 2+2=4, 5
            3=>b"1001_0101", -- 2+2=4, 9
            4=>b"0010_0011", -- 1+2=3, 12
            5=>b"1111_1111", -- 4+4=8, 20
            6=>b"0101_0101", -- 2+2=4, 24
            7=>b"1010_1001", -- 2+2=4, 28
            8=>b"0001_0010", -- 1+1=2, 30
            9=>b"1011_0100", -- 3+1=4, 34
           10=>b"0110_0101", -- 2+2=4, 38
           11=>b"1101_0010", -- 3+1=4, 42
           12=>b"1010_0011", -- 2+2=4, 46
           13=>b"1111_0000", -- 4+0=4, 50
           14=>b"0010_0101", -- 1+2=3, 53
           15=>b"1011_0010");-- 3+1=4, 57
           --sum: 33 + 24 = 57
    expected_res <= 57;
    wait until rising_edge(clk);
    startknapp <= '1';
    wait until rising_edge(clk);
    startknapp <= '0';
    wait for 55 ms;
    wait until LED = '0';
    wait for 1 ns;
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    if bcd_int = expected_res then      -- Print the result
      report "Test 2: OK (achieved = expected = "&integer'image(bcd_int)&").                              :-)" severity note;
    else
      report "5. Test 2: NOK (achieved = "&integer'image(bcd_int)&", expected="&integer'image(expected_res)&").                             :-(" severity error;
    end if;

    -- Test 3: 99 ones
    ROM <= (0=>b"0110_1100", -- 2+2=4   4
            1=>b"0111_0110", -- 3+2=5   9
            2=>b"0000_0000", -- 0+0=0   9
            3=>b"1111_1111", -- 4+4=8  17
            4=>b"1111_1111", -- 4+4=8  25
            5=>b"1111_1111", -- 4+4=8  33
            6=>b"1111_1111", -- 4+4=8  41
            7=>b"1111_1111", -- 4+4=8  49
            8=>b"1111_1111", -- 4+4=8  57
            9=>b"0111_1110", -- 3+3=6  63
           10=>b"0111_1011", -- 3+3=6  69
           11=>b"1011_1111", -- 3+4=7  76
           12=>b"1101_1111", -- 3+4=7  83
           13=>b"1101_1011", -- 3+3=6  89
           14=>b"1011_1101", -- 3+3=6  95
           15=>b"0110_0110");-- 2+2=4  99
           --sum: 49 + 50 = 99
    expected_res <= 99;

    wait for 12 ms;
    wait until rising_edge(clk);
    startknapp <= '1';
    wait until rising_edge(clk);
    startknapp <= '0';
    wait for 55 ms;
    wait until LED = '0';
    wait for 1 ns;
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    if bcd_int = expected_res then      -- Print the result
      report "Test 3: OK (achieved = expected = "&integer'image(bcd_int)&").                              :-)" severity note;
    else
      report "6. Test 3: NOK (achieved = "&integer'image(bcd_int)&", expected="&integer'image(expected_res)&").                             :-(" severity error;
    end if;
    
    -- Test 4: Corner cases
    ROM <= (0=>"10011001",
            1 to 14=>"00000000",
            15=>"10011001");
    expected_res <= 8;
    
    wait for 12 ms;
    wait until rising_edge(clk);
    startknapp <= '1';
    wait until rising_edge(clk);
    startknapp <= '0';
    wait for 55 ms; -- 5 1/2 clock pulse
    wait until LED = '0';
    wait for 1 ns;
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    if bcd_int = expected_res then      -- Print the result
      report "Test 4: OK (achieved = expected = "&integer'image(bcd_int)&").                               :-)" severity note;
    else
      report "7. Test 4: NOK (achieved = "&integer'image(bcd_int)&", expected="&integer'image(expected_res)&").                               :-(" severity error;
    end if;
    
    -- Test 5: Here comes misc small tests. Only output when NOK.
    -- Remember: Clock period is 10 ms
    
    -- Test 5a: Synchronous input.
    -- Give a short startknapp pulse between two clock flanks. This should not start any counting.
    wait until rising_edge(clk);
    startknapp <= '1' after 3 ms, '0' after 7 ms; -- Define a pulse around three clock cycles.
    wait for 5 ms; -- In the middle of the startknapp pulse.
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    assert LED = '0' report "8. Test 5a1: NOK. LED turned on asynchronous                            :-(" severity error;
    assert bcd_int = expected_res report "9. Test 5a2: NOK. BCD changed asynchronous (or prev. test failed)       :-(" severity error;
    wait for 55 ms; -- by now it should have started, if it detected the startknapp pulse.
    assert LED = '0' report "10. Test 5a3: NOK. The startknapp must have been detected assynchronous :-(" severity error;
    
    -- Test 5b: Asynchronous reset.
    -- start a new count and pull the reset in the middle.
    wait until rising_edge(clk);
    ROM <= (others => "11111111"); -- Fill with ones, to give a quicker count
    startknapp <= '1' after 3 ms, '0' after 55 ms;
    wait for 100 ms; -- Wait a few clock cycles, to make sure the counting has reached the output
    wait until rising_edge(clk);
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    assert LED = '1' and bcd_int > 0 report "10. Unexpected: After several clock cycles, LED turned off and count is still zero. Cannot test the reset. :-(" severity error;
    reset <= '1' after 2 ms, '0' after 3 ms;   -- Asyncronous clear in the middle.
    wait for 4 ms;
--bcd_int    cnt := 100*to_integer(BCD2) + 10*to_integer(BCD1) + to_integer(BCD0);
    assert LED = '0' and bcd_int = 0 report  "11. Test 5b: NOK. rstn is not asynchronous. LED or bcd_int not cleared.     :-(" severity error;
    
    -- Finalize:
    report "Testbench done. Did you get any errors?" severity note;
    done <= true; -- stop the clock using this signal
    wait; -- wait forever (otherwise the process will start over again)
  end process;
  
  -- Emulate the ROM:
  assert not(cs1 = '0' and cs2 = '0') report "12. NOK: Trying to address both memories in the same time               :-(" severity error;
  data <= ROM(to_integer(addr))(7 downto 4) when cs1 = '0' and cs2 = '1' else
          ROM(to_integer(addr))(3 downto 0) when cs1 = '1' and cs2 = '0' else
          "XXXX";
  
  -- Instantiate the design under test (DUT):
  DUT : CountOnes port map(
    clk => clk, -- The "port-signal => local-signal" means "connected to".
    reset => reset, -- The "=>" does NOT indicate data direction.
    startknapp => startknapp,
    cs1 => cs1,
    cs2 => cs2,
    addr => addr,
    data => data,
    LED => LED,
    BCD2 => BCD2,
    BCD1 => BCD1,
    BCD0 => BCD0);
  
  -- Convert and combine BCD to the type integer:
  bcd_int <=
    -1 when Is_X(std_logic_vector(BCD2&BCD1&BCD0)) else -- "metavalue detected" => -1
    -2 when BCD2>9 or BCD1>9 or BCD0>9 else -- "not decimal values" => -2
    100*to_integer(BCD2) + 10*to_integer(BCD1) + 1*to_integer(BCD0);
  
end architecture;


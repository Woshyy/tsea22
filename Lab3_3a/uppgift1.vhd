----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:15:07 02/17/2021
-- Design Name:
-- Module Name:    uppgift1 - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uppgift1 is
    Port ( x1 : in  STD_LOGIC;
           x0 : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           u : out  STD_LOGIC);
end uppgift1;

architecture Behavioral of uppgift1 is

  --signal q1_plus: std_logic;
  signal q1 : std_logic;
--  signal q0_plus: std_logic;
  signal q0 : std_logic;

  begin
    --Vippor q1 och q0
    --process(clk, reset) begin
      --if reset = '1' then
        --q1 <= '0';
        --q0 <= '0';
      --elsif rising_edge(clk) then
        --q1 <= q1_plus;
        --q0 <= q0_plus;
      --end if;
    --end process;

    --Tillståndsuppdatering
    --q1_plus <= (q1 and x0) or (q1 and q2 and x1) or (q0 and (not x1) and x0);

    --q0_plus <= ((not q1) and (not x1) and (not x0)) or (q1 and x1 and x0) or (q1 and q0 and x0) or (q1 and q0 and x1);

    --utsignaler
    u <= x1 and x0;

end Behavioral;

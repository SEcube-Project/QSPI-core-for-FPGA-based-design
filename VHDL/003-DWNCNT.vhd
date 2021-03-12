/**
  ******************************************************************************
  * File Name          : 003-DWNCNT.vhd
  * Description        : Component of the QSPI IP core 
  ******************************************************************************
  *
  * Copyright � 2016-present Blu5 Group <https://www.blu5group.com>
  *
  * This library is free software; you can redistribute it and/or
  * modify it under the terms of the GNU Lesser General Public
  * License as published by the Free Software Foundation; either
  * version 3 of the License, or (at your option) any later version.
  *
  * This library is distributed in the hope that it will be useful,
  * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  * Lesser General Public License for more details.
  *
  * You should have received a copy of the GNU Lesser General Public
  * License along with this library; if not, see <https://www.gnu.org/licenses/>.
  *
  ******************************************************************************
  */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DWN_COUNTER63 is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		ld            : in  std_logic;
		en            : in  std_logic;
		stop          : out std_logic
	);
end entity DWN_COUNTER63;

architecture BEHAVIORAL of DWN_COUNTER63 is

	--signal temp : std_logic_vector(15 downto 0);

begin

	count_p : process(clk, rst)
		variable tmp: std_logic_vector(5 downto 0);
	begin
		if (rst = '1') then
			tmp := "111110";
			stop <= '0';
		elsif (clk = '1' and clk'event) then
			if (ld = '1') then
				tmp := "111110";
				stop <= '0';
			elsif (en = '1') then
				if (unsigned(tmp) - 1 = "000000") then
					stop <= '1';
				else
					tmp := std_logic_vector(unsigned(tmp) - 1);
					stop <= '0';
				end if;
			end if;
		end if;

	end process count_p;

end architecture BEHAVIORAL;

/**
  ******************************************************************************
  * File Name          : 004-ADDRESS_GENERATOR.vhd
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
use WORK.CONSTANTS.all;

entity ADDRESS_GENERATOR is
	port(
		clk     : in  std_logic;
		rst     : in  std_logic;
		clr     : in  std_logic;
		ld      : in  std_logic;
		incr    : in  std_logic;
		address : out std_logic_vector(ADD_WIDTH - 1 downto 0)
	);
end entity ADDRESS_GENERATOR;

architecture RTL of ADDRESS_GENERATOR is

	signal currentAddress, nextAddress : std_logic_vector(ADD_WIDTH - 1 downto 0) := "000001";

begin

	address <= currentAddress;

	address_reg : process(clk, rst)
	begin
		if (rst = '1') then
			currentAddress <= "000001";
		elsif (clk'event and clk = '1') then
			if (clr = '1') then
				currentAddress <= "000001";
			elsif (ld = '1') then
				currentAddress <= nextAddress;
			end if;
		end if;
	end process;

	incr_p : process(currentAddress, incr)
	begin
		if (incr = '1') then
			if (unsigned(currentAddress) = 63) then
				nextAddress <= "000001";
			else
				nextAddress <= std_logic_vector(unsigned(currentAddress) + 1);
			end if;
		end if;
	end process;

end architecture RTL;

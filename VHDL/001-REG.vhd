/**
  ******************************************************************************
  * File Name          : 001-REG.vhd
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
use work.CONSTANTS.all;
entity generic_reg is
	generic (n: integer := 8);
	port(
		clk : in std_logic;
		rst : in std_logic;
		clr: in std_logic;
		ld: in std_logic;
		data_in : in std_logic_vector(n-1 downto 0);
		data_out : out std_logic_vector(n - 1 downto 0)
	);
end entity generic_reg;

architecture RTL of generic_reg is

signal currentValue : std_logic_vector(n - 1 downto 0);

begin

	reg_p : process(clk, rst)
	begin
		if (rst = '1') then
			currentValue <= (others => '0');
		elsif (clk'event and clk = '1') then
			if (clr = '1') then
				currentValue <= (others => '0');
			elsif (ld = '1') then
				currentValue <= data_in;
			end if;
		end if;
	end process reg_p;

	data_out <= currentValue;
end architecture RTL;

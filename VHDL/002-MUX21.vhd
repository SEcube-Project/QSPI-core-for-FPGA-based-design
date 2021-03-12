/**
  ******************************************************************************
  * File Name          : 002-MUX21.vhd
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
use work.CONSTANTS.all;

entity MUX21_GEN is
	GENERIC (n: integer);
	port(A : in std_logic_vector(n - 1 downto 0);
		 B : in std_logic_vector(n - 1 downto 0);
		 SEL : in std_logic;
		 O : out std_logic_vector(n - 1 downto 0)
		 );
end entity MUX21_GEN;

architecture behavioral of MUX21_GEN is

begin

	with SEL select O <=
		A when '0',
		B when '1',
		(others => '0') when others;

end architecture behavioral;
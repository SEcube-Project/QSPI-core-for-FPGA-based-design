/**
  ******************************************************************************
  * File Name          : IP_BLINKER.vhd
  * Description        : LED-blinker IP core for the IP Manager architecture  
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.CONSTANTS.all;

entity IP_BLINKER is
	port(
			clock                   : in std_logic;
			reset 				    : in std_logic;
			data_in 				: in std_logic_vector(DATA_WIDTH-1 downto 0);
			opcode 					: in std_logic_vector(OPCODE_SIZE-1 downto 0);
			enable 					: in std_logic;
			ack 					: in std_logic;
			interrupt_polling		: in std_logic;
			data_out 				: out std_logic_vector(DATA_WIDTH-1 downto 0);
			buffer_enable 			: out std_logic;
			address 				: out std_logic_vector(ADD_WIDTH-1 downto 0);
			rw 						: out std_logic;
			interrupt  				: out std_logic;
			error 					: out std_logic;
			write_completed			: in std_logic;
			read_completed			: in std_logic;
			-- DEBUG
			leds					: out std_logic_vector(7 downto 0)
		);	

end IP_BLINKER;

architecture BEHAVIORAL of IP_BLINKER is
	
	type statetype is    (OFF, 
						 WAIT_OPERAND, 
						 READ_OPERAND,
						 SHOW,
						 CLOSE
						 );
						 
	signal ip_state : statetype;
	signal operand : std_logic_vector(7 downto 0);
	 
begin
	
	process(clock)
	begin
		if(reset = '1') then
			ip_state <= OFF;
			leds  <= (others => '1');
		elsif(rising_edge(clock)) then
			case ip_state is
				when OFF =>
					data_out <= (others => '0');
					buffer_enable <= '0';
					address <= (others => '0');
					rw <= '0';
					interrupt <= '0';
					error <= '0';	
					if(enable = '1') then
						ip_state <= WAIT_OPERAND;
					else
						ip_state <= OFF;
					end if;
				when WAIT_OPERAND =>
					if(write_completed = '1') then 
						buffer_enable <= '1';
						address <= std_logic_vector(to_unsigned(1, ADD_WIDTH));
						data_out <= (others => '0');
						rw <= '0';
						interrupt <= '0';
						error <= '0';
						ip_state <= READ_OPERAND;
					else
						ip_state <= WAIT_OPERAND;
					end if;
				when READ_OPERAND =>
					operand <= data_in(7 downto 0);
					data_out <= (others => '0');
					buffer_enable <= '0';
					address <= (others => '0');
					rw <= '0';
					interrupt <= '0';
					error <= '0';
					ip_state <= SHOW;
				when SHOW =>
					leds <= not(operand);
					ip_state <= CLOSE;
				when CLOSE =>
					if (enable = '0') then
						ip_state <= OFF;
					else
						ip_state <= CLOSE;
					end if;
				when others => null;
			end case;
		end if;
	end process; 
	
end BEHAVIORAL;
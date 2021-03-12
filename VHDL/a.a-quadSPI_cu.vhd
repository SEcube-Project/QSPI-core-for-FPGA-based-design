/**
  ******************************************************************************
  * File Name          : a.a-quadSPI_cu.vhd
  * Description        : Control unit of the QSPI IP core 
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

entity quadSPI_cu_v2 is
	port(
		-- Interface FPGA-CPU
		clock             : in  std_logic;
		reset             : in  std_logic;
		enable            : in  std_logic;
		ack               : in  std_logic;
		interrupt_polling : in  std_logic;
		buffer_enable     : out std_logic;
		opcode            : in  std_logic_vector(OPCODE_SIZE - 1 downto 0);
		rw                : out std_logic;
		interrupt         : out std_logic;
		error             : out std_logic;
		write_completed   : in  std_logic; -- cpu completed write
		read_completed    : in  std_logic; -- cpu completed read
		-- Control unit - Data Path connections
		round_ld          : out std_logic;
		spill             : out std_logic;
		fill              : out std_logic;
		fill_en           : out std_logic;
		tx                : out std_logic;
		rx                : out std_logic;
		suspend           : out std_logic;
		round_en          : out std_logic;
		nibbles_ld        : out std_logic;
		conf_ld           : out std_logic;
		conf2_ld          : out std_logic;
		conf_clr          : out std_logic;
		addr_ld           : out std_logic;
		addr_clr          : out std_logic;
		addr_sel          : out std_logic;
		addr_incr         : out std_logic;
		data_out_sel      : out std_logic;
		round_end         : in  std_logic;
		idle              : in  std_logic
	);
end entity quadSPI_cu_v2;

architecture RTL of quadSPI_cu_v2 is

	type state_type is (OFF,
	                    IPCORE_CONF0,
	                    IPCORE_CONF1,
	                    IPCORE_CONF2,
	                    IPCORE_CONF3,
	                    COMMUNICATION_CONF0,
	                    COMMUNICATION_CONF1,
	                    SEND0,
	                    SEND1,
	                    SEND2,
	                    SEND3,
	                    SEND4,
	                    SEND5,
	                    SEND6,
	                    RECEIVE0,
	                    RECEIVE1,
	                    RECEIVE2,
	                    RECEIVE3,
	                    RECEIVE4,
	                    RECEIVE5,
	                    RECEIVE6,
	                    RECEIVE7,
	                    RECEIVE8,
	                    RECEIVE9,
	                    RECEIVE10,
	                    END_POLLING,
	                    WAIT_ACK,
	                    WAIT_ACK_REC,
	                    DONE
	                   );

	-- FSM state register
	signal state : state_type;

	-- Mode: 0 for polling - 1 for interrupt
	signal communication_mode : std_logic;

	-- Type: 0 for transmission - 1 for receiving
	signal direction : std_logic;

begin

	comb_p : process(clock, reset)
	begin
		if (reset = '1') then
			conf_clr <= '1';
			addr_clr <= '1';
			state    <= OFF;
		elsif (rising_edge(clock)) then
			case state is
				when OFF =>
					addr_clr      <= '0';
					conf_clr      <= '0';
					buffer_enable <= '0';
					rw            <= '0';
					round_ld      <= '0';
					spill         <= '0';
					fill          <= '0';
					tx            <= '0';
					rx            <= '0';
					suspend       <= '0';
					round_en      <= '0';
					nibbles_ld    <= '0';
					conf_ld       <= '0';
					conf2_ld      <= '0';
					addr_ld       <= '0';
					addr_incr     <= '0';
					addr_sel      <= '0';
					interrupt     <= '0';
					error         <= '0';
					fill_en       <= '0';
					data_out_sel  <= '0';
					-- Wait for the enable signal  => check opcode
					if (enable = '1') then
						communication_mode <= interrupt_polling;
						mode_selection : case opcode is
							when "000000" =>
								state <= IPCORE_CONF0;
							when "000010" =>
								direction <= '0';
								state     <= COMMUNICATION_CONF0;
							when "000011" =>
								direction <= '1';
								state     <= COMMUNICATION_CONF0;
							when others => null;
						end case;
					else
						state <= OFF;
					end if;
				when IPCORE_CONF0 =>
					if (write_completed = '1') then
						state    <= IPCORE_CONF1;
						-- Select the address 0x01 ( it will contain the parameters ) 
						addr_sel <= '0';
					else
						state <= IPCORE_CONF0;
					end if;
				when IPCORE_CONF1 =>
					-- Enable and read from the buffer
					buffer_enable <= '1';
					rw            <= '0';
					state         <= IPCORE_CONF2;
				when IPCORE_CONF2 =>
					-- Store the data in the register
					conf_ld <= '1';
					addr_incr <= '1';
					addr_ld  <= '1';
					state   <= IPCORE_CONF3;
				when IPCORE_CONF3 =>
					conf_ld  <= '0';
					addr_incr <= '0';
					addr_ld  <= '0';
					-- Store the second part of the divisor
					if (write_completed = '1') then
						-- Select the address 0x01 ( it will contain the parameters ) 
						conf2_ld <= '1';
						state <= DONE;
					else
						state <= IPCORE_CONF3;
					end if;
				when COMMUNICATION_CONF0 =>
					-- Wait for the first word to be written
					if (write_completed = '1') then
						state    <= COMMUNICATION_CONF1;
						-- Load address 0x01
						addr_sel <= '0';
					--addr_ld  <= '1';
					else
						state <= COMMUNICATION_CONF0;
					end if;
				when COMMUNICATION_CONF1 =>
					nibbles_ld    <= '1';
					addr_ld       <= '0';
					-- Enable and read address 0x01 from the buffer ( It contains the # nibbles to transmit/receive ) 
					buffer_enable <= '1';
					rw            <= '0';
					if (direction = '0') then
						state <= SEND0;
					else
						state <= RECEIVE0;
					end if;
				when SEND0 =>
					nibbles_ld <= '0';
					-- Start the filling
					fill       <= '1';
					state      <= SEND1;
				when SEND1 =>
					fill       <= '0';
					nibbles_ld <= '0';
					-- Increase the address
					addr_incr  <= '1';
					addr_sel   <= '0';
					state      <= SEND2;
				when SEND2 =>
					addr_ld <= '0';
					fill_en <= '0';
					-- If the fill operation has not terminated
					if (idle = '0') then
						-- If the word has been written, read it from the data buffer
						if (write_completed = '1') then
							buffer_enable <= '1';
							rw            <= '0';
							state         <= SEND3;
						else
							state <= SEND2;
						end if;
					else
						tx        <= '1';
						addr_incr <= '0';
						state     <= SEND5;
					end if;
				when SEND3 =>
					-- Store the word inside the ram
					fill_en <= '1';
					state   <= SEND4;
				when SEND4 =>
					buffer_enable <= '0';
					fill_en       <= '0';
					-- Increase the address
					addr_ld       <= '1';
					state         <= SEND2;
				when SEND5 =>
					tx    <= '0';
					-- Starts the transmission
					state <= SEND6;
				when SEND6 =>
					if (idle = '1') then
						if (communication_mode = '0') then
							-- Write in the data buffer the unlock code
							buffer_enable <= '1';
							rw            <= '1';
							addr_sel      <= '1';
							data_out_sel  <= '0';
							state         <= END_POLLING;
						else
							interrupt <= '1';
							state     <= WAIT_ACK;
						end if;
					else
						state <= SEND6;
					end if;
				when END_POLLING =>
					state <= DONE;
				when WAIT_ACK =>
					if (ack = '1' and enable = '1') then
						interrupt <= '0';
						state     <= DONE;
					else
						state <= WAIT_ACK;
					end if;
				when WAIT_ACK_REC =>
					if (ack = '1' and enable = '1') then
						interrupt <= '0';
						spill     <= '1';
						state     <= RECEIVE5;
					else
						state <= WAIT_ACK_REC;
					end if;
				when RECEIVE0 =>
					buffer_enable <= '0';
					nibbles_ld <= '0';
					state      <= RECEIVE1;
				when RECEIVE1 =>
					-- Starts receiving the words
					rx    <= '1';
					state <= RECEIVE2;
				when RECEIVE2 =>
					rx    <= '0';
					state <= RECEIVE3;
				when RECEIVE3 =>
					-- If all the data has been received from the slave
					if (idle = '1') then
						if (communication_mode = '0') then
							-- Write in the data buffer the unlock code
							buffer_enable <= '1';
							rw            <= '1';
							addr_sel      <= '1';
							data_out_sel  <= '0';
							state <= RECEIVE4;
						else
							interrupt <= '1';
							state     <= WAIT_ACK_REC;
						end if;
					else
						state <= RECEIVE3;
					end if;
				when RECEIVE4 =>
					spill         <= '1';
					state         <= RECEIVE5;
				when RECEIVE5 =>
					buffer_enable <= '0';
					rw            <= '0';
					data_out_sel <= '1';
					spill        <= '0';
					suspend      <= '0';
					state        <= RECEIVE6;
				when RECEIVE6 =>
					round_ld      <= '1';
					state         <= RECEIVE7;
				when RECEIVE7 =>
					round_ld      <= '0';
					-- Generate address starting from 1 to 63
					addr_sel      <= '0';
					-- Write in the buffer
					buffer_enable <= '1';
					rw            <= '1';
					-- Decrease the counter
					round_en      <= '1';
					-- If the data buffer is full, suspend the spilling
					if (idle = '1') then
						buffer_enable <= '0';
						addr_incr     <= '0';
						state         <= DONE;
					elsif (round_end = '1') then
						suspend       <= '1';
						round_ld      <= '1'; -- Reset the counter to 63
						addr_ld       <= '0';
						addr_incr     <= '0';
						buffer_enable <= '0';
						state         <= RECEIVE8;
					elsif (idle = '0') then
						addr_ld   <= '1';
						addr_incr <= '1';
						state     <= RECEIVE7;
					end if;
				when RECEIVE8 =>
					-- Wait until the CPU has read all the data buffer, that is when the signal
					-- read_completed has arrived 63 times
					round_ld <= '0';
					round_en <= read_completed;
					state    <= RECEIVE9;
				when RECEIVE9 =>
					-- If the counter reaches 0, the data buffer has been read
					if (round_end = '1') then
						state    <= RECEIVE10;
						round_ld <= '1';
						suspend  <= '0';
					else
						round_en <= read_completed;
						state    <= RECEIVE9;
					end if;
				when RECEIVE10 =>
					round_ld      <= '0';
					-- Wait for the counter to reset, and then go back and continue to fill the buffer
					addr_ld       <= '1';
					addr_incr     <= '1';
					buffer_enable <= '1';
					round_en      <= '1';
					state         <= RECEIVE7;
				when DONE =>
					addr_ld       <= '0';
					addr_incr <= '0';
					addr_clr      <= '1';
					conf_ld       <= '0';
					conf2_ld       <= '0';
					buffer_enable <= '0';
					rw            <= '0';
					if (enable = '0') then
						state <= OFF;
					else
						state <= DONE;
					end if;
			end case;
		end if;
	end process comb_p;
end architecture RTL;

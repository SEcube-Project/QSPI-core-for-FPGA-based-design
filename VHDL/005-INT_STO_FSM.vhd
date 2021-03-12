/**
  ******************************************************************************
  * File Name          : 005-INT_STO_FSM.vhd
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

entity INT_STO_FSM is
	port(
		clk         : in    std_logic;
		rst         : in    std_logic;
		spill       : in    std_logic;
		fill        : in    std_logic;
		fill_en     : in    std_logic;
		tx          : in    std_logic;
		rx          : in    std_logic;
		suspend     : in    std_logic;
		cpol        : in    std_logic;
		cpha        : in    std_logic;
		clk_divisor : in    std_logic_vector(23 downto 0);
		data_in     : in    std_logic_vector(15 downto 0);
		tot_bits    : in    std_logic_vector(15 downto 0);
		idle        : out   std_logic;
		data_out    : out   std_logic_vector(15 downto 0);
		spi_clk     : out   std_logic;
		CS			: out	std_logic;
		sdio        : inout std_logic_vector(3 downto 0)
	);
end entity INT_STO_FSM;

architecture RTL of INT_STO_FSM is

	type state_type is (state0, state_spill, state_fill, state_tx, state_tx_0, state_tx_1, state_rx, state_rx_1, state_wait, state_wait1, state_resume);
	signal state : state_type;

	component INT_RAM is
		port(
			Clock   : in  std_logic;
			ClockEn : in  std_logic;
			Reset   : in  std_logic;
			WE      : in  std_logic;
			Address : in  std_logic_vector(9 downto 0);
			Data    : in  std_logic_vector(15 downto 0);
			Q       : out std_logic_vector(15 downto 0));
	end component;

	signal clk_en, mem_we            : std_logic;
	signal address                   : std_logic_vector(9 downto 0);
	signal data_to_mem, data_out_mem : std_logic_vector(15 downto 0);
	signal spi_clk_internal          : std_logic;

begin

	data_out <= data_out_mem;
	spi_clk  <= spi_clk_internal;

	RAM : INT_RAM
		port map(clk, CLK_EN, RST, mem_we, address, data_to_mem, data_out_mem);

	process(clk, rst)
		variable current_word  : unsigned(9 downto 0)          := (others => '0');
		variable bit           : unsigned(3 downto 0)          := "0011";
		variable current_bit   : unsigned(15 downto 0)         := (others => '0');
		variable received_word : std_logic_vector(15 downto 0) := (others => '0');
		variable clk_cnt       : unsigned(23 downto 0)          := (others => '0');
		variable flag          : std_logic;
		variable cp_ol_ha      : std_logic_vector(1 downto 0);
		variable clk_div       : unsigned(23 downto 0);
		variable tx_mode       : std_logic;
	begin
		if (rst = '1') then
			-- reset the system
			clk_cnt          := "000000000000000000000001";
			spi_clk_internal <= '0';
			flag             := '0';
			state <= state0;
		elsif (clk'event and clk = '1') then
			cp_ol_ha := cpol & cpha;
			clk_div  := unsigned(clk_divisor);
			case state is
			when state0 =>
					CS <= '1';
					if (cpol = '0') then
						spi_clk_internal <= '0';
					elsif (cpol = '1') then
						spi_clk_internal <= '1';
					else
						spi_clk_internal <= 'Z';
					end if;
					flag         := '0';
					mem_we       <= '0';
					clk_en       <= '1';
					bit          := "0011";
					current_bit  := unsigned(tot_bits);
					current_word := (others => '0');
					sdio         <= "ZZZZ";
					if (spill = '1') then
						idle  <= '0';
						state <= state_spill;
					elsif (fill = '1') then
						idle  <= '0';
						state <= state_fill;
					elsif (tx = '1') then
						idle  <= '0';
						state <= state_tx_0;
					elsif (rx = '1') then
						idle  <= '0';
						CS <= '0';
						case cp_ol_ha is
							when "00" =>
								tx_mode := '1';
								flag    := '1';
							when "01" =>
								tx_mode := '1';
								flag    := '0';
							when "10" =>
								tx_mode := '0';
								flag    := '0';
							when "11" =>
								tx_mode := '0';
								flag    := '1';
							when others =>
								null;
						end case;
						state <= state_rx;
					else
						idle  <= '1';
						state <= state0;
					end if;
				when state_spill =>
					if (to_integer(signed(current_bit)) - 4 < 0) then
						idle  <= '1';
						state <= state0;
					elsif (suspend = '1') then
						state <= state_wait;
					-- The output of the memory in a clock cycle refers to the address of the previous clock cycle
					elsif (to_integer(signed(current_bit)) > 0) then
						address      <= std_logic_vector(current_word);
						state        <= state_spill;
						current_word := current_word + 1;
						current_bit  := current_bit - 16;
						state        <= state_spill;
					end if;

				when state_wait =>
					state <= state_wait1;
				when state_wait1 =>
					if (suspend = '1') then
						state <= state_resume;
					else
						state <= state_wait1;
					end if;
				when state_resume =>
					address      <= std_logic_vector(current_word);
					current_word := current_word + 1;
					current_bit  := current_bit - 16;
					state        <= state_spill;
				when state_fill =>
					if (fill_en = '1') then
						mem_we      <= '1';
						data_to_mem <= data_in;
						if (to_integer(signed(current_bit)) > 0) then
							address      <= std_logic_vector(current_word);
							state        <= state_fill;
							current_word := current_word + 1;
							current_bit := current_bit - 16;
						else
							mem_we <= '0';
							idle  <= '1';
							state <= state0;
						end if;
					end if;
				when state_tx_0 =>
					-- Read from the RAM, and set the address to 0, so that from the next c.c, data will be valid
					mem_we  <= '0';
					address <= std_logic_vector(current_word);
					state   <= state_tx_1;
				when state_tx_1 =>
					case cp_ol_ha is
						when "00" =>
							tx_mode := '1';
							flag    := '0';
						when "01" =>
							tx_mode := '1';
							flag    := '1';
						when "10" =>
							tx_mode := '1';
							flag    := '0';
						when "11" =>
							tx_mode := '0';
							flag    := '0';
						when others =>
							null;
					end case;
					state <= state_tx;
					CS <= '0';
				when state_tx =>
					if (clk_cnt = clk_div) then
						clk_cnt          := "000000000000000000000001";
						if (to_integer(signed(current_bit)) >= 0) then
							state            <= state_tx;
							spi_clk_internal <= not spi_clk_internal;
							if (flag = tx_mode) then
								address     <= std_logic_vector(current_word);
								if (bit = 11) then
									current_word := current_word + 1;
								end if;
								current_bit := current_bit - 4;
								sdio        <= data_out_mem(to_integer(bit) downto to_integer(bit) - 3);
								bit         := bit + 4;
								flag        := not (tx_mode);
							else
								flag := tx_mode;
							end if;
						else
							flag  := tx_mode;
							sdio  <= "ZZZZ";
							if (cpol = '0') then
								spi_clk_internal <= '0';
							elsif (cpol = '1') then
								spi_clk_internal <= '1';
							else
								spi_clk_internal <= 'Z';
							end if;
							idle  <= '1';
							state <= state0;
							CS <= '1';
						end if;
					else
						clk_cnt := clk_cnt + 1;
						state   <= state_tx;
					end if;
				when state_rx =>
					mem_we <= '0';
					if (clk_cnt = clk_div) then
						clk_cnt          := "000000000000000000000001";
						spi_clk_internal <= not spi_clk_internal;
						if (flag = tx_mode) then
							flag                                                      := not (tx_mode);
							address                                                   <= std_logic_vector(current_word);
							received_word(to_integer(bit) downto to_integer(bit) - 3) := sdio;
							if (current_bit - 4 > 0) then
								state       <= state_rx;
								current_bit := current_bit - 4;
							else
								mem_we      <= '1';
								data_to_mem <= received_word;
								state       <= state_rx_1;
							end if;
							if (bit = 15) then
								mem_we        <= '1';
								current_word  := current_word + 1;
								data_to_mem   <= received_word;
								received_word := (others => '0');
							end if;
							bit                                                       := bit + 4;
						else
							flag := tx_mode;
						end if;
					else
						clk_cnt := clk_cnt + 1;
						state   <= state_rx;
					end if;
				when state_rx_1 =>
					if (clk_cnt = clk_div) then
						if (cpol = '0') then
							spi_clk_internal <= '0';
						elsif (cpol = '1') then
							spi_clk_internal <= '1';
						else
							spi_clk_internal <= 'Z';
						end if;
						idle  <= '1';
						state <= state0;
						CS <= '1';
					else
						clk_cnt := clk_cnt + 1;
						state   <= state_rx_1;
					end if;
			end case;
		end if;

	end process;

end architecture RTL;

/**
  ******************************************************************************
  * File Name          : a-quadSPI.vhd
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

entity QSPI_FSMD is
	port(
		-- Interface FPGA-CPU
		clock             : in    std_logic;
		reset             : in    std_logic;
		data_in           : in    std_logic_vector(DATA_WIDTH - 1 downto 0);
		opcode            : in    std_logic_vector(OPCODE_SIZE - 1 downto 0);
		enable            : in    std_logic;
		ack               : in    std_logic;
		interrupt_polling : in    std_logic;
		data_out          : out   std_logic_vector(DATA_WIDTH - 1 downto 0); -- data going to the ip manager
		buffer_enable     : out   std_logic;
		address           : out   std_logic_vector(ADD_WIDTH - 1 downto 0);
		rw                : out   std_logic;
		interrupt         : out   std_logic;
		error             : out   std_logic;
		write_completed   : in    std_logic; -- cpu completed write
		read_completed    : in    std_logic; -- cpu completed read
		-- Interface to the slave device. Output of the SPI-Master
		SCLK              : out   std_logic;
		SDIO              : inout std_logic_vector(3 downto 0);
		CS                : out   std_logic
	);
end entity QSPI_FSMD;

architecture RTL of QSPI_FSMD is

	component quadSPI_cu_v2
		port(
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
			write_completed   : in  std_logic;
			read_completed    : in  std_logic;
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
	end component quadSPI_cu_v2;

	component quadSPI_dp_v2
		port(
			clk          : in    std_logic;
			rst          : in    std_logic;
			round_ld     : in    std_logic;
			spill        : in    std_logic;
			fill         : in    std_logic;
			fill_en      : in    std_logic;
			tx           : in    std_logic;
			rx           : in    std_logic;
			round_en     : in    std_logic;
			nibbles_ld   : in    std_logic;
			conf_ld      : in    std_logic;
			conf2_ld     : in    std_logic;
			conf_clr     : in    std_logic;
			addr_ld      : in    std_logic;
			addr_clr     : in    std_logic;
			addr_sel     : in    std_logic;
			addr_incr    : in    std_logic;
			data_out_sel : in    std_logic;
			data_in      : in    std_logic_vector(DATA_WIDTH - 1 downto 0);
			round_end    : out   std_logic;
			address      : out   std_logic_vector(ADD_WIDTH - 1 downto 0);
			data_out     : out   std_logic_vector(DATA_WIDTH - 1 downto 0);
			idle         : out   std_logic;
			spi_clk      : out   std_logic;
			CS           : out   std_logic;
			sdio         : inout std_logic_vector(3 downto 0)
		);
	end component quadSPI_dp_v2;

	signal round_ld     : std_logic;
	signal spill        : std_logic;
	signal fill         : std_logic;
	signal fill_en      : std_logic;
	signal tx           : std_logic;
	signal rx           : std_logic;
	signal suspend      : std_logic;
	signal round_en     : std_logic;
	signal nibbles_ld   : std_logic;
	signal conf_ld      : std_logic;
	signal conf_clr     : std_logic;
	signal addr_ld      : std_logic;
	signal addr_clr     : std_logic;
	signal addr_sel     : std_logic;
	signal addr_incr    : std_logic;
	signal data_out_sel : std_logic;
	signal round_end    : std_logic;
	signal idle         : std_logic;
	signal conf2_ld     : std_logic;

begin

	CU : quadSPI_cu_v2
		port map(
			clock             => clock,
			reset             => reset,
			enable            => enable,
			ack               => ack,
			interrupt_polling => interrupt_polling,
			buffer_enable     => buffer_enable,
			opcode            => opcode,
			rw                => rw,
			interrupt         => interrupt,
			error             => error,
			write_completed   => write_completed,
			read_completed    => read_completed,
			round_ld          => round_ld,
			spill             => spill,
			fill              => fill,
			fill_en           => fill_en,
			tx                => tx,
			rx                => rx,
			suspend           => suspend,
			round_en          => round_en,
			nibbles_ld        => nibbles_ld,
			conf_ld           => conf_ld,
			conf2_ld          => conf2_ld,
			conf_clr          => conf_clr,
			addr_ld           => addr_ld,
			addr_clr          => addr_clr,
			addr_sel          => addr_sel,
			addr_incr         => addr_incr,
			data_out_sel      => data_out_sel,
			round_end         => round_end,
			idle              => idle
		);

	DP : quadSPI_dp_v2
		port map(
			clk          => clock,
			rst          => reset,
			round_ld     => round_ld,
			spill        => spill,
			fill         => fill,
			fill_en      => fill_en,
			tx           => tx,
			rx           => rx,
			round_en     => round_en,
			nibbles_ld   => nibbles_ld,
			conf_ld      => conf_ld,
			conf2_ld     => conf2_ld,
			conf_clr     => conf_clr,
			addr_ld      => addr_ld,
			addr_clr     => addr_clr,
			addr_sel     => addr_sel,
			addr_incr    => addr_incr,
			data_out_sel => data_out_sel,
			data_in      => data_in,
			round_end    => round_end,
			address      => address,
			data_out     => data_out,
			idle         => idle,
			spi_clk      => sclk,
			CS           => CS,
			sdio         => sdio
		);

end architecture RTL;

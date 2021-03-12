/**
  ******************************************************************************
  * File Name          : a.b-quadSPI_dp.vhd
  * Description        : Datapath of the QSPI IP core 
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

entity quadSPI_dp_v2 is
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
end entity quadSPI_dp_v2;

architecture RTL of quadSPI_dp_v2 is

	component generic_reg
		generic(n : integer);
		port(
			clk      : in  std_logic;
			rst      : in  std_logic;
			clr      : in  std_logic;
			ld       : in  std_logic;
			data_in  : in  std_logic_vector(n - 1 downto 0);
			data_out : out std_logic_vector(n - 1 downto 0)
		);
	end component generic_reg;

	component MUX21_GEN
		GENERIC(n : integer);
		port(A   : in  std_logic_vector(n - 1 downto 0);
		     B   : in  std_logic_vector(n - 1 downto 0);
		     SEL : in  std_logic;
		     O   : out std_logic_vector(n - 1 downto 0)
		    );
	end component MUX21_GEN;

	component DWN_COUNTER63
		port(
			clk  : in  std_logic;
			rst  : in  std_logic;
			ld   : in  std_logic;
			en   : in  std_logic;
			stop : out std_logic
		);
	end component DWN_COUNTER63;

	component INT_STO_FSM
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
			CS          : out   std_logic;
			sdio        : inout std_logic_vector(3 downto 0)
		);
	end component INT_STO_FSM;

	component ADDRESS_GENERATOR
		port(
			clk     : in  std_logic;
			rst     : in  std_logic;
			clr     : in  std_logic;
			ld      : in  std_logic;
			incr    : in  std_logic;
			address : out std_logic_vector(ADD_WIDTH - 1 downto 0)
		);
	end component ADDRESS_GENERATOR;

	signal parameters       : std_logic_vector(25 downto 0);
	signal data_out_storage : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal tot_bits         : std_logic_vector(15 downto 0);
	signal currentAddress   : std_logic_vector(ADD_WIDTH - 1 DOWNTO 0);
	signal nibbles          : std_logic_vector(15 downto 0);
	signal tot_word         : std_logic_vector(15 downto 0);
	signal suspend_int      : std_logic;
begin

	-- 2 KB transfer maximum:
	-- 4096 nibbles = 4096 * 4 = 16384 bits
	tot_bits  <= '0' & nibbles(12 downto 0) & "00";
	tot_word  <= "00000" & nibbles(12 downto 2);
	round_end <= suspend_int;

	INT_STO : INT_STO_FSM
		port map(
			clk         => clk,
			rst         => rst,
			spill       => spill,
			fill        => fill,
			fill_en     => fill_en,
			tx          => tx,
			rx          => rx,
			suspend     => suspend_int,
			cpol        => parameters(1),
			cpha        => parameters(0),
			clk_divisor => parameters(25 downto 2),
			data_in     => data_in,
			tot_bits    => tot_bits(15 downto 0),
			idle        => idle,
			data_out    => data_out_storage,
			spi_clk     => spi_clk,
			CS          => CS,
			sdio        => sdio
		);

	round_terminated : DWN_COUNTER63
		port map(
			clk  => clk,
			rst  => rst,
			ld   => ROUND_LD,
			en   => ROUND_EN,
			stop => suspend_int
		);

	CONF_REG : generic_reg
		generic map(
			n => 16
		)
		port map(
			clk      => clk,
			rst      => rst,
			clr      => conf_clr,
			ld       => conf_ld,
			data_in  => data_in,
			data_out => parameters(15 downto 0)
		);

	CONF_REG2 : generic_reg
		generic map(n => 10)
		port map(
			clk      => clk,
			rst      => rst,
			clr      => conf_clr,
			ld       => conf2_ld,
			data_in  => data_in(9 downto 0),
			data_out => parameters(25 downto 16)
		);

	ADDRESS_MUX : MUX21_GEN
		generic map(ADD_WIDTH)
		port map(
			a   => currentAddress,
			b   => "111111",
			sel => addr_sel,
			o   => address
		);

	ADDR_GEN : ADDRESS_GENERATOR
		port map(
			clk     => clk,
			rst     => rst,
			clr     => addr_clr,
			ld      => addr_ld,
			incr    => addr_incr,
			address => currentAddress
		);

	DATA_TO_BUFF_MUX : MUX21_GEN
		generic map(DATA_WIDTH)
		port map(
			a   => (others => '1'),
			b   => data_out_storage,
			sel => data_out_sel,
			o   => data_out
		);

	NIBBLES_REG : generic_reg
		generic map(
			n => 16
		)
		port map(
			clk      => clk,
			rst      => rst,
			clr      => '0',
			ld       => nibbles_ld,
			data_in  => data_in,
			data_out => nibbles
		);

end architecture RTL;

/**
  ******************************************************************************
  * File Name          : TOP_ENTITY.vhd
  * Description        : Top entity of the QSPI IP core 
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

--IMPORTANT: The number of IPs must be written in the file CONSTANTS.vhd. The IPs core must be then connected at the end of this file
entity TOP_ENTITY is
	generic(
		ADDSET : integer := 2;
		DATAST : integer := 2
	);
	port(
		cpu_fpga_bus_a   : in    std_logic_vector(ADD_WIDTH - 1 downto 0);
		cpu_fpga_bus_d   : inout std_logic_vector(DATA_WIDTH - 1 downto 0);
		cpu_fpga_bus_noe : in    std_logic;
		cpu_fpga_bus_nwe : in    std_logic;
		cpu_fpga_bus_ne1 : in    std_logic;
		cpu_fpga_clk     : in    std_logic;
		cpu_fpga_int_n   : out   std_logic;
		cpu_fpga_rst     : in    std_logic;
		-- DEBUG
		fpga_gpio_leds   : out std_logic_vector(7 downto 0);
		SCLK             : out   std_logic;
		CS               : out   std_logic;
		SDIO             : inout std_logic_vector(3 downto 0)
	);
end entity TOP_ENTITY;

architecture STRUCTURAL of TOP_ENTITY is
	
	--Signals between the buffer and the ip manager
	signal row_0                  : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal ipm_to_buf_data        : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal buf_to_ipm_data        : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal ipm_addr               : std_logic_vector(ADD_WIDTH - 1 downto 0);
	signal ipm_rw                 : std_logic;
	signal ipm_buf_enable         : std_logic;
	signal cpu_read_completed     : std_logic;
	signal cpu_write_completed    : std_logic;
	--Signals between the IP manager and the various IP cores
	signal ip_to_ipm_data         : data_array;
	signal ipm_to_ip_data         : data_array;
	signal addr_ip                : addr_array;
	signal opcode_ip              : opcode_array;
	signal int_pol_ip             : std_logic_vector(NUM_IPS - 1 downto 0);
	signal rw_ip                  : std_logic_vector(NUM_IPS - 1 downto 0);
	signal buf_enable_ip          : std_logic_vector(NUM_IPS - 1 downto 0);
	signal enable_ip              : std_logic_vector(NUM_IPS - 1 downto 0);
	signal ack_ip                 : std_logic_vector(NUM_IPS - 1 downto 0);
	signal interrupt_ip           : std_logic_vector(NUM_IPS - 1 downto 0);
	signal error_ip               : std_logic_vector(NUM_IPS - 1 downto 0);
	signal cpu_read_completed_ip  : std_logic_vector(NUM_IPS - 1 downto 0);
	signal cpu_write_completed_ip : std_logic_vector(NUM_IPS - 1 downto 0);
	
	-- debug
	signal chip_select: std_logic;
	signal spi_clk: std_logic;

begin

	
	CS <= chip_select;
	SCLK <= spi_clk;
	
	data_buff : entity work.DATA_BUFFER
		generic map(
			ADDSET => ADDSET,
			DATAST => DATAST
		)
		port map(
			clock               => cpu_fpga_clk,
			reset               => cpu_fpga_rst,
			row_0               => row_0,
			cpu_data            => cpu_fpga_bus_d,
			cpu_addr            => cpu_fpga_bus_a,
			cpu_noe             => cpu_fpga_bus_noe,
			cpu_nwe             => cpu_fpga_bus_nwe,
			cpu_ne1             => cpu_fpga_bus_ne1,
			ipm_data_in         => ipm_to_buf_data,
			ipm_data_out        => buf_to_ipm_data,
			ipm_addr            => ipm_addr,
			ipm_rw              => ipm_rw,
			ipm_enable          => ipm_buf_enable,
			cpu_read_completed  => cpu_read_completed,
			cpu_write_completed => cpu_write_completed
		);

	ip_man : entity work.IP_MANAGER
		port map(
			clock                  => cpu_fpga_clk,
			reset                  => cpu_fpga_rst,
			interrupt              => cpu_fpga_int_n,
			ne1                    => cpu_fpga_bus_ne1,
			buf_data_out           => ipm_to_buf_data,
			buf_data_in            => buf_to_ipm_data,
			buf_addr               => ipm_addr,
			buf_rw                 => ipm_rw,
			buf_enable             => ipm_buf_enable,
			row_0                  => row_0,
			cpu_read_completed     => cpu_read_completed,
			cpu_write_completed    => cpu_write_completed,
			addr_ip                => addr_ip,
			data_in_ip             => ip_to_ipm_data,
			data_out_ip            => ipm_to_ip_data,
			opcode_ip              => opcode_ip,
			int_pol_ip             => int_pol_ip,
			rw_ip                  => rw_ip,
			buf_enable_ip          => buf_enable_ip,
			enable_ip              => enable_ip,
			ack_ip                 => ack_ip,
			interrupt_ip           => interrupt_ip,
			error_ip               => error_ip,
			cpu_read_completed_ip  => cpu_read_completed_ip,
			cpu_write_completed_ip => cpu_write_completed_ip
		);


	QSPI_CORE : entity work.QSPI_FSMD
		port map(
			clock             => cpu_fpga_clk,
			reset             => cpu_fpga_rst,
			data_in           => ipm_to_ip_data(0),
			opcode            => opcode_ip(0),
			enable            => enable_ip(0),
			ack               => ack_ip(0),
			interrupt_polling => int_pol_ip(0),
			data_out          => ip_to_ipm_data(0),
			buffer_enable     => buf_enable_ip(0),
			address           => addr_ip(0),
			rw                => rw_ip(0),
			interrupt         => interrupt_ip(0),
			error             => error_ip(0),
			write_completed   => cpu_write_completed_ip(0),
			read_completed    => cpu_read_completed_ip(0),
			SCLK              => spi_clk,
			SDIO              => SDIO,
			CS                => chip_select
		);
		
	LED_BLINKER: entity work.IP_BLINKER
		port map(
			clock             => cpu_fpga_clk,
			reset             => cpu_fpga_rst,
			data_in           => ipm_to_ip_data(1),
			opcode            => opcode_ip(1),
			enable            => enable_ip(1),
			ack               => ack_ip(1),
			interrupt_polling => int_pol_ip(1),
			data_out          => ip_to_ipm_data(1),
			buffer_enable     => buf_enable_ip(1),
			address           => addr_ip(1),
			rw                => rw_ip(1),
			interrupt         => interrupt_ip(1),
			error             => error_ip(1),
			write_completed   => cpu_write_completed_ip(1),
			read_completed    => cpu_read_completed_ip(1),
			leds              => fpga_gpio_leds
		);

end architecture;

/**
  ******************************************************************************
  * File Name          : qspi_fpga.h
  * Description        : High-level driver for communication between CPU and 
                         QSPI IP core in the IP-Manager-based environment
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

#include <stdio.h>

// Configuration
int FPGA_QSPI_CONF(uint32_t baud_rate, uint8_t clk_polarity, uint8_t clk_phase);
// Send
int FPGA_QSPI_SEND_8bI(uint16_t n_nibbles, uint8_t* data, int interruptMode);
int FPGA_QSPI_SEND_16bI(uint16_t n_nibbles, uint16_t* data, int interruptMode);
int FPGA_QSPI_SEND_32bI(uint16_t n_nibbles, uint32_t* data, int interruptMode);
// Receive
int FPGA_QSPI_RECEIVE_16bI(uint16_t n_nibbles, uint16_t* data, int interruptMode);

int handle_IR();

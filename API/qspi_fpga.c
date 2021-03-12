/**
  ******************************************************************************
  * File Name          : qspi_fpga.c
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

#include "qspi_fpga.h"
#include "fpgaipm.h"

// Variables needed to handle interrupt mode
uint8_t tx = 0;
uint16_t n_nibbles_g;
uint16_t* data_received;

int FPGA_QSPI_CONF(uint32_t baud_rate, uint8_t clk_polarity, uint8_t clk_phase) {
    uint16_t config_data=0x0000;
    uint16_t config_data_2=0x0000;
    config_data|= clk_phase;
    config_data|=(clk_polarity<<1);
    config_data|=(baud_rate<<2);
    config_data_2 |= (baud_rate>>14);
    FPGA_IPM_open(0x01,0x00,0,0);
    FPGA_IPM_write(0x01,0x01,&config_data);
    FPGA_IPM_write(0x01,0x02,&config_data_2);
    FPGA_IPM_close(0x01);
    return 1; //return true (1) on success
}

int FPGA_QSPI_SEND_8bI(uint16_t n_nibbles, uint8_t* data, int interruptMode) {

    FPGA_IPM_DATA unlock_code = 0x0000;
    uint16_t temp_data=0x0000;

    // Compute the number of words
    int n_words = ((n_nibbles*4)+(15))/(16);

    FPGA_IPM_ADDRESS buff_address=0x01;

    // Open transaction in polling/interrupt mode
    FPGA_IPM_open(0x01,0x02,interruptMode,0);

    // Write number of nibbles at address 1 of data buffer
    FPGA_IPM_write(0x01,0x01,&n_nibbles);

    // Write the words to transmit
    for(int i=0;i<(int)n_words;i++) {
        // If the end of data buffer has been reached, start from the begin
        if(buff_address==63) {
            buff_address=0x01;
        }
        temp_data=*data;
        temp_data=temp_data<<8;
        temp_data|=*(data+1);
        FPGA_IPM_write(0x01,buff_address,&temp_data);
        buff_address++;
        data+=2;
    }

    // If polling mode lock the CPU and wait for core unlocking
    if (!interruptMode) {
        FPGA_IPM_write(0x01, 63, &unlock_code);
        while(unlock_code != 0xFFFF) {
            FPGA_IPM_read(0x1, 63, &unlock_code);
        }
    } else {
        tx = 1;
    }

    return FPGA_IPM_close(0x01);
}

int FPGA_QSPI_SEND_16bI(uint16_t n_nibbles, uint16_t* data, int interruptMode) {

    FPGA_IPM_DATA unlock_code = 0x0000;

    // Compute the number of words shifting the number of nibbles by 2 positions
    int n_words = ((n_nibbles*4)+(15))/(16);

    FPGA_IPM_ADDRESS buff_address=0x01;

    // Open transaction in polling/interrupt mode
    FPGA_IPM_open(0x01,0x02,interruptMode,0);

    // Write number of nibbles at address 1 of data buffer
    FPGA_IPM_write(0x01,0x01,&n_nibbles);

    // Write the words to transmit
    for(int i=0;i<(int)n_words;i++) {
        // If the end of data buffer has been reached, start from the begin
        if(buff_address==63) {
            buff_address=0x01;
        }
        FPGA_IPM_write(0x01,buff_address,data);
        buff_address++;
        data++;
    }

    // If polling mode lock the CPU and wait for core unlocking
    if (!interruptMode) {
        FPGA_IPM_write(0x01, 63, &unlock_code);
        while(unlock_code != 0xFFFF) {
            FPGA_IPM_read(0x1, 63, &unlock_code);
        }
    } else {
        tx = 1;
    }

    return FPGA_IPM_close(0x01);
}

int FPGA_QSPI_SEND_32bI(uint16_t n_nibbles, uint32_t* data, int interruptMode) {

    FPGA_IPM_DATA unlock_code = 0x0000;
    uint16_t temp_data=0x0000;

    // Compute the number of words shifting the number of nibbles by 2 positions
    int n_words = ((n_nibbles*4)+(15))/(16);

    FPGA_IPM_ADDRESS buff_address=0x01;

    // Open transaction in polling/interrupt mode
    FPGA_IPM_open(0x01,0x02,interruptMode,0);

    // Write number of nibbles at address 1 of data buffer
    FPGA_IPM_write(0x01,0x01,&n_nibbles);

    // Write the words to transmit
    for(int i=0;i<(int)n_words;i++) {
        // If the end of data buffer has been reached, start from the begin
        if(buff_address==63) {
            buff_address=0x01;
        }
        temp_data=(uint16_t)*data;
        FPGA_IPM_write(0x01,buff_address,&temp_data);
        buff_address++;
        temp_data=(uint16_t)((*data)>>16);
        FPGA_IPM_write(0x01,buff_address,&temp_data);
        buff_address++;
        data+=1;
    }

    // If polling mode lock the CPU and wait for core unlocking
    if (!interruptMode) {
        FPGA_IPM_write(0x01, 63, &unlock_code);
        while(unlock_code != 0xFFFF) {
            FPGA_IPM_read(0x1, 63, &unlock_code);
        }
    } else {
        tx = 1;
    }
    return FPGA_IPM_close(0x01);
}


FPGA_IPM_BOOLEAN FPGA_QSPI_RECEIVE_16bI(uint16_t n_nibbles, uint16_t* data, FPGA_IPM_BOOLEAN interruptMode ) {

    FPGA_IPM_DATA unlock_code = 0x0000;
    int n_words = ((n_nibbles*4)+(15))/(16);
    n_nibbles_g = n_nibbles;
    data_received = data;
    FPGA_IPM_ADDRESS buff_address=0x01;

    FPGA_IPM_open(0x01,0x03,interruptMode,0);
    FPGA_IPM_write(0x01,0x01,&n_nibbles);

    if (!interruptMode) {
        // lock the CPU and wait for core unlocking
        FPGA_IPM_write(0x01, 63, &unlock_code);
        while(unlock_code != 0xFFFF) {
            FPGA_IPM_read(0x1, 63, &unlock_code);
        }
        // Once the core has unlocked the cpu, it means that reception is finished. Now the core will start writing the result on
        // the data buffer (max 63 words per time), so we have to wait until it finishes
        HAL_Delay(5000);
        // Now we can read the received data on the data buffer
        for(int i=0;i<(int)n_words;i++) {
            if(buff_address==0x3F) {
                FPGA_IPM_read(0x01,buff_address,data);
                // If we have read all the data buffer but there are still words to read,
                // wait again until the core has written other words on the buffer
                HAL_Delay(5000);
                // Now start reading from the beginning
                buff_address=0x01;
                data++;
            }
            FPGA_IPM_read(0x01,buff_address,data);
            buff_address++;
            data++;
        }
    }
    return FPGA_IPM_close(0x01);
}

int handle_IR() {

	// Open the ack transaction
	FPGA_IPM_open(0x01,0,1,1);

    // If it is an interrupt for the end of the reception, read the words
    if (tx == 0) {
    	FPGA_IPM_ADDRESS buff_address=0x01;
    	uint16_t n_words = ((n_nibbles_g*4)+(15))/(16);

        // Now we can read the received data on the data buffer
        for(int i=0;i<(int)n_words;i++) {
            if(buff_address==0x3F) {
                FPGA_IPM_read(0x01,buff_address,data_received);
                // Now start reading from the beginning
                buff_address=0x01;
                data_received++;
            }
            FPGA_IPM_read(0x01,buff_address,data_received);
            buff_address++;
            data_received++;
        }
    }
    // At the end of the reading, or if it was an interrupt for the transmission, close the transaction
    tx = 0;

    FPGA_IPM_close(0x01);
    return 1;
}

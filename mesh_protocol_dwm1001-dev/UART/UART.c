/* Copyright (c) 2022-23 California Institute of Technology (Caltech).
 * U.S. Government sponsorship acknowledged.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - Neither the name of Caltech nor its operating division,
 *   the Jet Propulsion Laboratory, nor the names of its contributors may be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Open Source License Approved by Caltech/JPL
 *
 * APACHE LICENSE, VERSION 2.0
 * - Text version: https://www.apache.org/licenses/LICENSE-2.0.txt
 * - SPDX short identifier: Apache-2.0
 * - OSI Approved License: https://opensource.org/licenses/Apache-2.0
 */

/*!
* @brief Component name:	UART
*
* Simple two-wire UART application level driver.
* Provides buffered UART interface, compatible with
* a redirected STDIO for printf and getc.
*
* @file UART.c
*/

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include "app_uart.h"
#include "app_error.h"
#include "nrf_delay.h"
#include "nrf.h"
#include "nrf_uart.h"
#include "UART.h"
#include "bsp.h"
#include "boards.h"

#define NO_PARITY	false

// UART circular buffers - Tx and Rx size
#define UART_TX_BUF_SIZE 512
#define UART_RX_BUF_SIZE 32

// UART initialisation structure
const app_uart_comm_params_t comm_params =
{
	RX_PIN_NUM,
  TX_PIN_NUM,
	RTS_PIN_NUM,
  CTS_PIN_NUM,
  APP_UART_FLOW_CONTROL_DISABLED,
  NO_PARITY,
  NRF_UART_BAUDRATE_115200
};

// local functions
static void vHandleUartInternalErrors (uint32_t u32Error);
static void vUartErrorHandle					(app_uart_evt_t * p_event);

/**
 * @brief Public interface, initialise the FIFO UART.
 */
bool boUART_Init(void)
{
	// Initialis the nrf UART driver returning state
	uint32_t err_code;

  APP_UART_FIFO_INIT
		(	&comm_params,
			UART_RX_BUF_SIZE,
      UART_TX_BUF_SIZE,
      vUartErrorHandle,
      APP_IRQ_PRIORITY_LOWEST,
      err_code
		);

	return (err_code == NRF_SUCCESS) ? true : false;
}

bool boUART_getc(uint8_t *u8ch)
{
	bool boSuccess = false;
	
	if (app_uart_get(u8ch) == NRF_SUCCESS)
		boSuccess = true;
	
	return boSuccess;
}

static void vUartErrorHandle(app_uart_evt_t * p_event)
{
    if (p_event->evt_type == APP_UART_COMMUNICATION_ERROR)
    {
        vHandleUartInternalErrors(p_event->evt_type);
    }
    else if (p_event->evt_type == APP_UART_FIFO_ERROR)
    {
        vHandleUartInternalErrors(p_event->evt_type);
    }
}

static void vHandleUartInternalErrors (uint32_t u32Error)
{
	// notify app of error - LED ?
}


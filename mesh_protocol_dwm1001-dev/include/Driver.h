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

/** @file Driver.h
*   @brief Simulation Driver that takes messages from the protocol that should be sent and writes them to a specific address
*
*/  

#ifndef DRIVER_H
#define DRIVER_H

#include <string.h>
#include <inttypes.h>
#include "Node.h"
#include "ProtocolClock.h"

#include "deca_regs.h"

#include "TimeKeeping.h" // debugging

typedef struct DriverStruct * Driver;

typedef struct DriverStruct{
  bool * txFinishedFlag;
  bool * isReceiving;

  uint16_t tx_antenna_delay;
  uint16_t rx_antenna_delay;

  // only for simulation
  /** address where sent messages are written to by this driver */
  Message * msgOutAddress;
  
  /** flag read by MatlabWrapper to determine whether message has been sent and needs to send to MATLAB */
  bool sentMessage; 

  int64_t lastTxStartTime;
} DriverStruct;

/** Constructor 
* @param txFinishedFlag is a pointer to the address that signals if sending is finished; may be changed externally
* @param isReceiving is a pointer to the address that signals if the node is currently receiving a transmission; may be changed externally
*/
Driver Driver_Create(bool *txFinishedFlag, bool *isReceiving);

/** Return if sending is finished
* @param node is the Node struct of the node that should perform this action
* return If sending is finished
*/
bool Driver_SendingFinished(Node node);

/** Transmit a ping
* @param node is the Node struct of the node that should perform this action
* @param msg is the Message struct that contains the information of the ping
*/
void Driver_TransmitPing(Node node, Message msg);

/** Transmit a poll
* @param node is the Node struct of the node that should perform this action
* @param msg is the Message struct that contains the information of the poll
*/
void Driver_TransmitPoll(Node node, Message msg);

/** Transmit a response
* @param node is the Node struct of the node that should perform this action
* @param msg is the Message struct that contains the information of the response
*/
void Driver_TransmitResponse(Node node, Message msg);

/** Transmit a final
* @param node is the Node struct of the node that should perform this action
* @param msg is the Message struct that contains the information of the final
*/
void Driver_TransmitFinal(Node node, Message msg);

/** Transmit a result
* @param node is the Node struct of the node that should perform this action
* @param msg is the Message struct that contains the information of the result
*/
void Driver_TransmitResult(Node node, Message msg);

/** Set the address where this driver writes sent messages to so external code can read them (instead of actually sending them via UWB, as this is a simulation driver)
* @param node is the Node struct of the node that should perform this action
* @param msgOutAddress is the address of the message that the driver should write messages to
*/
void Driver_SetOutMsgAddress(Node node, Message *msgOutAddress);

/** Return if driver is currently receiving a transmission
* @param node is the Node struct of the node that should perform this action
* return If driver is currently receiving an incoming transmission
*/
bool Driver_IsReceiving(Node node);

/** Return if driver has sent a message
* @param node is the Node struct of the node that should perform this action
* return If driver has sent a message
*/
bool Driver_GetMessageSentFlag(Node node);

/** Set the message sent flag
* @param node is the Node struct of the node that should perform this action
* @param value is the value the flag should be set to
*/
void Driver_SetMessageSentFlag(Node node, bool value);

#endif

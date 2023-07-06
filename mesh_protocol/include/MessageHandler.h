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

/** @file MessageHandler.h
*   @brief Handles incoming and outgoing messages
*
*   Creates messages from the current state of the node as a whole (e.g. slot maps) and calls the driver that actually sends the messages;
*   also handles incoming messages (calls functions to update the slot maps, join network etc.)
*/  

#ifndef MESSAGE_HANDLER_H
#define MESSAGE_HANDLER_H

#include "Node.h"
#include "TimeKeeping.h"
#include "NetworkManager.h"
#include "SlotMap.h"
#include "ProtocolClock.h"
#include "Neighborhood.h"
#include "Scheduler.h"

#ifdef SIMULATION
#include "mex.h"
#endif

typedef struct MessageHandlerStruct * MessageHandler;

typedef struct MessageHandlerStruct {
  
} MessageHandlerStruct;

/** Constructor */
MessageHandler MessageHandler_Create();

/** Handles pings when node is unconnected
* @param node is the Node struct of this node
* @param msg is the message of the ping
*/
void MessageHandler_HandlePingUnconnected(Node node, Message msg);

/** Handles pings when node is connected
* @param node is the Node struct of this node
* @param msg is the message of the ping
*/
void MessageHandler_HandlePingConnected(Node node, Message msg);

/** Send an initial ping (ping to create a new network when no network is around)
* @param node is the Node struct of this node
*
* creates a network first and then uses MessageHandler_SendPing
*/
void MessageHandler_SendInitialPing(Node node);

/** Send ping
* @param node is the Node struct of this node
*
* creates a ping message and transmits it via the driver
*/
void MessageHandler_SendPing(Node node);

/** Send poll
* @param node is the Node struct of this node
*
* creates a poll message and transmits it via the driver
*/
void MessageHandler_SendRangingPollMessage(Node node);

/** Send response
* @param node is the Node struct of this node
*
* creates a response message and transmits it via the driver
*/
void MessageHandler_SendRangingResponseMessage(Node node, Message pollMsgIn);

/** Send final
* @param node is the Node struct of this node
*
* creates a final message and transmits it via the driver
*/
void MessageHandler_SendRangingFinalMessage(Node node, Message responseMsgIn);

/** Send result
* @param node is the Node struct of this node
*
* creates a result message and transmits it via the driver
*/
void MessageHandler_SendRangingResultMessage(Node node, Message finalMsgIn);

#endif

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

#include "../include/Driver.h"

// simulation driver!

Driver Driver_Create(bool *txFinishedFlag, bool *isReceiving) {
  // allocate memory for the Driver struct
  Driver self = calloc(1, sizeof(DriverStruct));

  // set pointers for values that need to be changed from outside (by the simulation environment)
  self->txFinishedFlag = txFinishedFlag;
  self->isReceiving = isReceiving;

  self->sentMessage = false;

  return self;
};

bool Driver_SendingFinished(Node node) {
  return *node->driver->txFinishedFlag;
};

void Driver_TransmitPing(Node node, Message msg) {
#ifdef SIMULATION
  mexPrintf("%" PRId64 ": Node %" PRIu8 " sent ping in slot %" PRIu8 "\n", ProtocolClock_GetLocalTime(node->clock), node->id, TimeKeeping_CalculateCurrentSlotNum(node));
#endif 

  /** This simulation driver "transmits" messages by sending them to MATLAB.
  *   This is done by writing the message to a specific address in memory that is later read by the MatlabWrapper. 
  *   The message that was created by the MessageHandler is copied here so that the MessageHandler can free the memory 
  *   as it would do when a real driver had sent the message over UWB; that way, the implementation details of the driver
  *   can be hidden from the MessageHandler.
  */
  
  Message newMsg = Message_Create(PING);
  memcpy(newMsg, msg, sizeof(MessageStruct));

  *node->driver->msgOutAddress = newMsg;
  node->driver->sentMessage = true;
};

void Driver_TransmitPoll(Node node, Message msg) {
#ifdef SIMULATION
  mexPrintf("%" PRId64 ": Node %" PRIu8 " sent poll to %" PRIu8 "\n", ProtocolClock_GetLocalTime(node->clock), node->id, msg->recipientId);
#endif

  /** See description in Driver_TransmitPing */

  Message newMsg = Message_Create(POLL);
  memcpy(newMsg, msg, sizeof(MessageStruct));

  *node->driver->msgOutAddress = newMsg;
  node->driver->sentMessage = true;
};

void Driver_TransmitResponse(Node node, Message msg) {
#ifdef SIMULATION
  mexPrintf("%" PRId64 ": Node %" PRIu8 " sent response to %" PRIu8 "\n", ProtocolClock_GetLocalTime(node->clock), node->id, msg->recipientId);
#endif

  /** See description in Driver_TransmitPing */

  Message newMsg = Message_Create(RESPONSE);
  memcpy(newMsg, msg, sizeof(MessageStruct));

  *node->driver->msgOutAddress = newMsg;
  node->driver->sentMessage = true;
};

void Driver_TransmitFinal(Node node, Message msg) {
#ifdef SIMULATION
  mexPrintf("%" PRId64 ": Node %" PRIu8 " sent final to %" PRIu8 "\n", ProtocolClock_GetLocalTime(node->clock), node->id, msg->recipientId);
#endif

  /** See description in Driver_TransmitPing */

  Message newMsg = Message_Create(FINAL);
  memcpy(newMsg, msg, sizeof(MessageStruct));

  *node->driver->msgOutAddress = newMsg;
  node->driver->sentMessage = true;
};

void Driver_TransmitResult(Node node, Message msg) {
#ifdef SIMULATION
  mexPrintf("%" PRId64 ": Node %" PRIu8 " sent result to %" PRIu8 "\n", ProtocolClock_GetLocalTime(node->clock), node->id, msg->recipientId);
#endif

  /** See description in Driver_TransmitPing */

  Message newMsg = Message_Create(RESULT);
  memcpy(newMsg, msg, sizeof(MessageStruct));

  *node->driver->msgOutAddress = newMsg;
  node->driver->sentMessage = true;
};

void Driver_SetOutMsgAddress(Node node, Message *msgOutAddress) {
  /** The address that is used to deliver the message back to MATLAB in simulation */
  node->driver->msgOutAddress = msgOutAddress;
};

bool Driver_IsReceiving(Node node) {
  return *node->driver->isReceiving;
};

bool Driver_GetMessageSentFlag(Node node) {
  return node->driver->sentMessage;
};

void Driver_SetMessageSentFlag(Node node, bool value) {
  node->driver->sentMessage = value;
};

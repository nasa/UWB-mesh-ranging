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

/** @file RangingManager.h
*   @brief Maintains information about the last ranging message
*
*/  

#ifndef RANGING_MANAGER_H
#define RANGING_MANAGER_H

#include <string.h>
#include "Node.h"
#include "ProtocolClock.h"
#include "Config.h"
#include "Message.h"
#include "TimeKeeping.h"

#ifdef SIMULATION
#include "mex.h"
#endif

typedef struct RangingManagerStruct * RangingManager;

/** 
* lastRangingMsgOutTime: local time of the node at which it sent the last ranging message
* lastRangingMsgInTime: local time of the node at which it received the last ranging message
* lastIncomingRangingMsg: last incoming ranging message this node received
*
* ranging messages are POLL, RESPONSE, FINAL and RESULT
*/
typedef struct RangingManagerStruct {
  int64_t lastRangingMsgOutTime;
  int64_t lastRangingMsgInTime;
  Message lastIncomingRangingMsg;
} RangingManagerStruct;

/** Constructor */
RangingManager RangingManager_Create();

/** Determine if ranging has timed out
* @param node is the Node struct of the node that should perform this action
* return true if the other node took to long to respond to the last ranging message of the node; false if the timeout is not yet reached
*/
bool RangingManager_HasRangingTimedOut(Node node);

/** Save a ranging message as the last incoming ranging message
* @param node is the Node struct of the node that should perform this action
* @param msg is the message to be saved as lastIncomingRangingMsg 
*/ 
void RangingManager_RecordRangingMsgIn(Node node, Message msg);

/** Save the time when this node sent the last ranging message
* @param node is the Node struct of the node that should perform this action
*/
void RangingManager_RecordRangingMsgOut(Node node);

/** Determine if the node is allowed to respond to a ranging message
* @param node is the Node struct of the node that should perform this action
* return true if the defined WAITTIME has passed since the reception of the last incoming ranging message; false otherwise
*
* The implementation is dependent on the kind of ranging the driver does. The driver should be responsible for the timing of the ranging messages, 
* these higher level functions are used to ensure the state machine is in the correct state
*/
bool RangingManager_IsWaitTimeOver(Node node);

/** Get the last incoming ranging message
* @param node is the Node struct of the node that should perform this action
* return the last incoming ranging message
*/
Message RangingManager_GetLastIncomingRangingMsg(Node node);

#endif

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

/** @file StateMachine.h
*   @brief Handles the state transitions of the node based on guard conditions, incoming messages and scheduled pings
*/  

#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include "Node.h"
#include "Scheduler.h"
#include "StateActions.h"
#include "GuardConditions.h"
#include "Driver.h"
#include "RangingManager.h"

#include "Message.h" // TESTING ONLY

#ifdef SIMULATION
#include "mex.h"
#endif

enum States {
  OFF = 0, 
  LISTENING_UNCONNECTED = 1, 
  LISTENING_CONNECTED = 2, 
  SENDING_UNCONNECTED = 3, 
  SENDING_CONNECTED = 4, 
  RANGING_POLL = 5, 
  RANGING_LISTEN = 6, 
  RANGING_WAIT = 7, 
  RANGING_RESPONSE = 8, 
  RANGING_FINAL = 9, 
  RANGING_RESULT = 10,
  IDLE = 11
};

enum Events {
  TURN_ON, INCOMING_MSG, TIME_TIC
};

typedef struct StateMachineStruct * StateMachine;
typedef enum States States;
typedef enum Events Events;

typedef struct StateMachineStruct{
  States state;
} StateMachineStruct;

/** Constructor */
StateMachine StateMachine_Create();

/** Get the current state of the node
* @param node is the Node struct of the node that should perform this action
*/
States StateMachine_GetState(Node node);

/** Run the state machine one time
* @param node is the Node struct of the node that should perform this action
* @param event is the event that triggered the state machine (TURN_ON, INCOMING_MSG, TIME_TIC)
* @param msg is the message in case event is INCOMING_MSG; should be NULL otherwise
*/
void StateMachine_Run(Node node, Events event, Message msg);

#endif

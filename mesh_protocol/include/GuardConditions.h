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

/** @file GuardConditions.h
*   @brief Contains functions to check if a particular state transition is currently allowed
*
*/ 

#ifndef GUARD_CONDITIONS_H
#define GUARD_CONDITIONS_H

#include "Node.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"
#include "SlotMap.h"
#include "NetworkManager.h"
#include "Scheduler.h"
#include "Driver.h"
#include "Config.h"

typedef struct GuardConditionsStruct * GuardConditions;

typedef struct GuardConditionsStruct {

} GuardConditionsStruct;

/** Constructor */
GuardConditions GuardConditions_Create();

void GuardConditions_Destroy(GuardConditions self);

/** Determine whether transition from LISTENING UNCONNECTED to SENDING UNCONNECTED is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_ListeningUncToSendingUncAllowed(Node node);

/** Determine whether transition from SENDING UNCONNECTED to LISTENING CONNECTED  is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_SendingUncToListeningConAllowed(Node node);

/** Determine whether transition from LISTENING CONNECTED to SENDING CONNECTED is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_ListeningConToSendingConAllowed(Node node);

/** Determine whether transition from LISTENING CONNECTED to LISTENING UNCONNECTED is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_ListeningConToListeningUncAllowed(Node node);

/** Determine whether transition from SENDING CONNECTED to LISTENING CONNECTED is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_SendingConToListeningConAllowed(Node node);

/** Determine whether sending a POLL message is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_RangingPollAllowed(Node node);

/** Determine whether going to IDLE (duty cycle) is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_IdleingAllowed(Node node);

/** Determine whether returning out of IDLE is allowed on receiving a message
* @param node is the Node struct of this node
* @param msg is the incoming message
* return Whether transition is allowed
*/
bool GuardConditions_IdleToListeningConAllowedIncomingMsg(Node node, Message msg);

/** Determine whether returning out of IDLE is allowed
* @param node is the Node struct of this node
* return Whether transition is allowed
*/
bool GuardConditions_IdleToListeningConAllowed(Node node);

#endif

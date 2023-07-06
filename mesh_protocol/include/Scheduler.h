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

/** @file Scheduler.h
*   @brief Keeps track of the next schedule and knows how to schedule a new ping or cancel it
*
*/  

#ifndef SCHEDULER_H
#define SCHEDULER_H

#include "Node.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"
#include "RandomNumbers.h"
#include "StateMachine.h"
#include "SlotMap.h"

#ifdef SIMULATION
#include "mex.h"
#endif

typedef struct SchedulerStruct * Scheduler;

/**
* timeNextSchedule: local time of the next scheduled ping of this node
*/
typedef struct SchedulerStruct {
  int64_t timeNextSchedule;
} SchedulerStruct;

/** Constructor */
Scheduler Scheduler_Create();

/** Destructor, frees memory of a Scheduler struct
* @param self is the Scheduler struct that should be deallocated
*/
void Scheduler_Destroy(Scheduler self);

/** Determine if a ping is scheduled at the current time
* @param node is the Node struct of the node that should perform this action
*/
bool Scheduler_PingScheduledToNow(Node node);

/** Get the local time at which the next ping is scheduled
* @param node is the Node struct of the node that should perform this action
* return local time at which the next ping is scheduled in time tics
*/
int64_t Scheduler_GetTimeOfNextSchedule(Node node);

/** Schedule a ping at a specific time
* @param node is the Node struct of the node that should perform this action
* @param time is the local time of this node at which the ping should be sent
* return true if the ping was scheduled at the time; false if the ping was not scheduled
*/
bool Scheduler_SchedulePingAtTime(Node node, int64_t time);

/** Cancel the currently scheduled ping
* @param node is the Node struct of the node that should perform this action
*/
void Scheduler_CancelScheduledPing(Node node);

/** Check if a ping is already scheduled
* @param node is the Node struct of the node that should perform this action
* return true if ping is already scheduled for this node; false if no ping is scheduled for this node
*/
bool Scheduler_NothingScheduledYet(Node node);

/** Get the slot in which the next scheduled ping will be sent
* @param node is the Node struct of the node that should perform this action
* return number of slot of the next scheduled ping
*/
int8_t Scheduler_GetSlotOfNextSchedule(Node node);

/** Schedule the next ping automatically
* @param node is the Node struct of the node that should perform this action
* 
* This function automatically determines the time the next ping should be sent:
* - If the node is currently unconnected, it schedules an initial ping to create a network
* - If the node is connected but does not have enough slots, the function either schedules a new reservation 
*   to a reservable slot or the next ping to a slot this node already reserved (depending on which slot is next)
* The function also respects guard periods and may include random delays to make collisions more unlikely
*/
void Scheduler_ScheduleNextPing(Node node);

#endif

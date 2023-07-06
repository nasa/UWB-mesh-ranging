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

/** @file TimeKeeping.h
*   @brief Handles and calculates time-related values
*/  

#ifndef TIME_KEEPING_H
#define TIME_KEEPING_H

#include <math.h>
#include "Node.h"
#include "Config.h"
#include "ProtocolClock.h"
#include "NetworkManager.h"

#ifdef SIMULATION
#include "mex.h"
#endif

typedef struct TimeKeepingStruct * TimeKeeping;

/** 
* frameStartTime: start time of the frame when this node joined the network (used as a base)
* frameStartSet: signals if a value for frameStartTime was set
* lastResetAt: local time the TimeKeeping was last reset (to restart values like initial waiting time)
* lastIdledTime: local time this node last idled
*/
typedef struct TimeKeepingStruct {
  int64_t frameStartTime;
  bool frameStartSet;
  int64_t lastResetAt;
  int64_t lastIdledTime;
} TimeKeepingStruct;

/** Constructor */
TimeKeeping TimeKeeping_Create();

/** Set frame start time
* @param node is the Node struct of the node that should perform this action
* @param startTime is the frame start time that should be set
*/
void TimeKeeping_SetFrameStartTime(Node node, int64_t startTime);

/** Set frame start time to the time when the last preamble was received
* @param node is the Node struct of the node that should perform this action
* @param msg is the message to whose preamble the frame start should be set
*
* Time of last preamble means the time when the last message arrived at the antenna (timestamp of message)
*/
void TimeKeeping_SetFrameStartTimeForLastPreamble(Node node, Message msg);

/** Determine if initial wait time is over
* @param node is the Node struct of the node that should perform this action
* return true if the initial wait time is over; false if not
*
* Initial wait time is the time a node has to listen for pings of other networks before it can 
* start a network by sending a ping
*/
bool TimeKeeping_InitialWaitTimeOver(Node node);

/** Reset the TimeKeeping reference time
* @param node is the Node struct of the node that should perform this action
*
* This does not actually reset a time but saves the current time as a reference; this means 
* intial wait time will be calculated from the current time, so the node has to wait again before starting a network
*/
void TimeKeeping_ResetTime(Node node);

/** Calcute in which slot this node was or will be for any given time
* @param node is the Node struct of the node that should perform this action
* @param time is the time for which the slot should be calculated
* return calculated slot
*/
uint8_t TimeKeeping_CalculateOwnSlotAtTime(Node node, int64_t time);

/** Calculate the number of the slot the node is currently in
* @param node is the Node struct of the node that should perform this action
* return the number of the current slot
*/
uint8_t TimeKeeping_CalculateCurrentSlotNum(Node node);

/** Calculate the number of the frame the node is currently in
* @param node is the Node struct of the node that should perform this action
* return the number of the current frame
*/
uint64_t TimeKeeping_CalculateCurrentFrameNum(Node node);

/** Calculate the time a certain slot next begins
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the slot whose next beginning should be calculated
* return the local time of the next beginning of the queried slot
*/
int64_t TimeKeeping_CalculateNextStartOfSlot(Node node, uint8_t slotNum);

/** Calculate the network age of a node whose ping message was received in time tics
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message of the node
* return network age of the node who sent the message
*
* Ping messages contain the current network age of the sending node; however, as pings take 
* time until they are transmitted, this time has to be accounted for (which is what this function does)
*/
int64_t TimeKeeping_CalculateNetworkAgeFromMsg(Node node, Message msg);

/** Calculate the time since the last frame start of this node in time tics
* @param node is the Node struct of the node that should perform this action
* return time since the current frame began
*/
int64_t TimeKeeping_CalculateTimeSinceFrameStart(Node node);

/** Calculate how much time remains until current slot ends in time tics
* @param node is the Node struct of the node that should perform this action
* return time that remains in current slot
*/
int64_t TimeKeeping_GetTimeRemainingInCurrentSlot(Node node);

/** Calculates the local time of the node at which the collisions happened
* @param node is the Node struct of the node that should perform this action
* @param msg is the Ping Message containing the collision times
* @param buffer is the array to which the calculated times should be written; must be as big as the number of collisionTimes in msg
*   if the message does not contain collision times, this is set to NULL
*
* ping message contains times when the sending node received a collision ("how long ago they happened from the time the message was sent")
* this function adds the time it took to transmit the message to that time
*/
void TimeKeeping_CalculateCollisionTimes(Node node, Message msg, int32_t *buffer);

/** Set the time when the node idled last to the current time
* @param node is the Node struct of the node that should perform this action
*/
void TimeKeeping_SetLastTimeIdled(Node node);

/** Get the time the node idled last 
* @param node is the Node struct of the node that should perform this action
* return time the node idled last
*
* As the node sets this time when he wakes up from idleing, this returns the time the idleing ended, not the time when it began
*/
int64_t TimeKeeping_GetLastTimeIdled(Node node);

/** Check if the node should wake up now from idleing when in auto duty cycle
* @param node is the Node struct of the node that should perform this action
* return true if node should wake up; false otherwise
*/
bool TimeKeeping_IsAutoCycleWakeupTime(Node node);

#endif

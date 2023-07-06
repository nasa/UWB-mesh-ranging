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

/** @file Config.h
*   @brief Config structure used throughout the program to access different configuration values
*
*/  

#ifndef CONFIG_H
#define CONFIG_H

#include "Node.h"

typedef struct ConfigStruct * Config;

typedef struct ConfigStruct {

  /** length of one frame in time tics (the unit that the clock uses) 
  * frameLength equals slotLength times the number of slots per frame
  */
  int32_t frameLength;

  /** length of one slot in time tics (the unit that the clock uses) */
  int32_t slotLength;

  /** number of slots every node should try to reserve */
  int8_t slotGoal;

  /** time limit for the initial ping in time tics (the unit that the clock uses)
  * When there is no network, nodes will schedule an initial ping to create one at a random time; 
  * this value is the upper limit for the random value. Increasing it reduces the chance of collisions for the first ping, 
  * but might increase the time it takes until a network is established.
  */
  uint32_t initialPingUpperLimit;

  /** time nodes wait for networks after wakeup in time tics (the unit that the clock uses)
  * Before scheduling the initial ping, nodes will wait this time and listen for other networks that they can join
  */
  uint32_t initialWaitTime;

  /** length of the period that cannot be used for sending at the beginning and end of each slot in time tics (the unit that the clock uses)
  * This period makes sure that small errors in the time synchronization do not lead to nodes sending in slots that are not their own.
  * Must be lower than guard period length to ensure that nodes in the same network are always in the same slot before messages are sent.
  */
  uint16_t guardPeriodLength; 

  /** time tolerance for network ages to still be considered the same in time tics (the unit that the clock uses)
  * Two networks are the same when their IDs and ages match; due to small errors in synchronization, the age may not match perfectly so this value
  * determined how much the ages may differ
  */
  int64_t networkAgeToleranceSameNetwork;

  /** timeout for ranging in time tics (the unit that the clock uses)
  * A node will wait this time for an answer on its ranging request before it cancels it and trys again.
  * Default value: a value that is longer than any node will need to answer a ranging message
  */
  int32_t rangingTimeOut;

  /** time a node waits before answering a ranging request in time tics (the unit that the clock uses)*/
  int32_t rangingWaitTime;

  /** time after a node will remove a slot from its slot map if it has not been receiving messages in the slot, in time tics (the unit that the clock uses)
  * If a node does not receive pings from another node that has a slot in its slot map, it will set the slot to free after this time
  * Default value: 1 frameLength + 1 slotLength (needs to be more than one frame due to random delays in pings)
  */
  int32_t slotExpirationTimeOut;

  /** time after which a node considers its own slot as expired if it does not get acknowledgements from its neighbors in time tics (the unit that the clock uses)
  * A node stops using its own slot after this time if its neighbors do not acknowledge it in their frames anymore (could be due to 
  * collisions or other problems).
  * Default value: 2 frameLength + 1 slotLength
  */
  int32_t ownSlotExpirationTimeOut;

  /** time after which a node considers a neighbor as gone in time tics (the unit that the clock uses)
  * A node will delete a former neighbor from its internal neighborhood representation if it does not get pings from it for this time.
  * Default value: 1.5 frameLength
  */
  int32_t absentNeighborTimeOut;

  /** time for which a node waits after ranging with a neighbor until it ranges with this neighbor again 
  * To make repeating collisions between ranging and pings from foreign networks less likely, one could use a value that is a bit bigger than one frame.
  */
  int64_t rangingRefreshTime;

  /** time after which occupied slots in internal slot maps (one or multi hop) can be overwritten as "OCCUPIED by another node"
  * Default value: 2 frameLength
  */
  int32_t occupiedTimeout;

  /** time after which occupied slots in internal multi hop slot maps (two or three hop) can be overwritten by "FREE" 
  * Default value: 1 frameLength + 1 slotLength
  */
  int32_t occupiedToFreeTimeoutMultiHop;

  /** time after which an OCCUPIED slots in internal multi hop slot maps (two or three hop) can be overwritten as COLLIDING
  * Default value: 1 frameLength
  */
  int32_t collidingTimeoutMultiHop;

  /** time after which a COLLIDING slots in internal one hop slot map can be overwritten as "OCCUPIED by another node"
  * Default value: 1 slotLength
  */
  int32_t collidingTimeout;

  /** number of frames nodes will sleep on autoDutyCycle */
  int16_t sleepFrames;

  /** number of frames to stay awake */
  int16_t wakeFrames;

} ConfigStruct;

Config Config_Create();

#endif

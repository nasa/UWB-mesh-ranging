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

#include "../include/Scheduler.h"

static uint64_t getRandomDelay(Node node);
static uint64_t getRegularRandomDelay(Node node);

Scheduler Scheduler_Create() {
  Scheduler self = calloc(1, sizeof(SchedulerStruct));
  // no schedule after init
  self->timeNextSchedule = -1;

  return self;
};

void Scheduler_Destroy(Scheduler self) {
  free(self);
};

bool Scheduler_PingScheduledToNow(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  return node->scheduler->timeNextSchedule == localTime;
};

int64_t Scheduler_GetTimeOfNextSchedule(Node node) {
  return node->scheduler->timeNextSchedule;
};

bool Scheduler_SchedulePingAtTime(Node node, int64_t time) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock); 

  // if the time to schedule is in the past, do not schedule
  if (time < localTime) {
    return false;
  };

  node->scheduler->timeNextSchedule = time;
  
#if DEBUG_VERBOSE
  printf("Node %d scheduled ping to %d \n", node->id, time);
#endif

  #ifdef SIMULATION
  mexPrintf("Node %" PRIu8 " scheduled ping to %" PRId64 "\n", node->id, time);
  #endif
  return true;
};

void Scheduler_CancelScheduledPing(Node node) {
  node->scheduler->timeNextSchedule = -1;
};

bool Scheduler_NothingScheduledYet(Node node) {
  return node->scheduler->timeNextSchedule == -1;
};

int8_t Scheduler_GetSlotOfNextSchedule(Node node) {
  uint64_t timeNextSchedule = Scheduler_GetTimeOfNextSchedule(node);
  return TimeKeeping_CalculateOwnSlotAtTime(node, timeNextSchedule);
}

void Scheduler_ScheduleNextPing(Node node) {
  States state = StateMachine_GetState(node);
  int64_t scheduleTime = 0;
  // depending on the state, the time when the next ping should be scheduled is determined differently
  switch(state) {
    case LISTENING_UNCONNECTED: ;
      // not connected, so an initial ping must be sent
      // schedule initial ping randomly
      int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
      // ping should be scheduled at some point between the next time tic and the upper limit to send an initial ping
      int64_t lowerBound = localTime + 1;
      int64_t upperBound = lowerBound + node->config->initialPingUpperLimit;
      scheduleTime = RandomNumbers_GetRandomIntBetween(node, lowerBound, upperBound);

      #ifdef SIMULATION
      mexPrintf("Node %" PRIu8 " scheduled initial ping to %" PRId64 "\n", node->id, scheduleTime);
      #endif
      break;
    case LISTENING_CONNECTED: ;
      // when node is connected, the time of the next ping depends on whether it is a new reservation
      // or a regular ping in an already reserved slot

      int8_t scheduleSlotNum = 0;
      bool goalMet = SlotMap_SlotReservationGoalMet(node);

      uint64_t delay = 0;

      if(!goalMet) {
        // schedule new reservation
        // get a reservable slot
        scheduleSlotNum = SlotMap_GetReservableSlot(node);
        // get a random delay to later add to the beginning of the slot that should be reserved; 
        // this reduces the likelihood of a collision if multiple nodes try to reserve the same slot at the same time
        delay = getRandomDelay(node);
      } else {
        // schedule ping to next own slot
        uint8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);
        scheduleSlotNum = SlotMap_CalculateNextOwnOrPendingSlotNum(node, currentSlot);
        // add a small delay so if two nodes reserved the same slot without having common neighbors, they have a chance 
        // of recognizing this (without delay they would always send at the same time and could never "see" each other)
        delay = getRegularRandomDelay(node);
        #ifdef SIMULATION
        mexPrintf("Node %" PRIu8 " schedules to own slot %" PRIu8 "\n", node->id, scheduleSlotNum);
        #endif
      }

      if (scheduleSlotNum == -1) {// no reservable slots
        return;
      };

      #ifdef SIMULATION
      if (scheduleSlotNum == -1)
        mexPrintf("No reservable slot");
      #endif

      // schedule to the start of the slot + the random delay
      scheduleTime = TimeKeeping_CalculateNextStartOfSlot(node, scheduleSlotNum);
      scheduleTime += node->config->guardPeriodLength + delay;
      break;
  };

  // actually set the schedule
  Scheduler_SchedulePingAtTime(node, scheduleTime);
};

static uint64_t getRandomDelay(Node node) {
  /** The idea of the delay is to schedule new reservations not always to the beginning of
  *   a slot, but anywhere within the slot. This way, if two nodes try to reserve the same slot,
  *   there is a chance that one of them will have scheduled the transmission earlier than the other,
  *   so that the second node receives the reservation and then cancels its own. This way, one node
  *   gets a slot, whereas when both would send at the same time, both reservations would fail.
  *   The delay cannot be any number but only a multiple (between minDelayFactor and maxDelayFactor) of the PING_SIZE, 
  *   to make sure the second node has enough time to receive the transmission and cancel its ping. 
  */
  // minimum delay is zero (means to send right at the beginning of a slot after the guard period)
  uint32_t minDelayFactor = 0;
  // if max delay is chosen, the node will schedule to the last possible moment in the slot at which it can transmit the
  // whole ping without violating the guard period at the end of the slot
  uint32_t maxDelayFactor = floor(node->config->slotLength - 2 * node->config->guardPeriodLength - PING_SIZE)/PING_SIZE;
  uint32_t delayFactor = RandomNumbers_GetRandomIntBetween(node, minDelayFactor, maxDelayFactor);
  
  return delayFactor * PING_SIZE;
};

static uint64_t getRegularRandomDelay(Node node) {
  /** The main idea of the regular delay is not to reduce collisions but to make it possible for two nodes
  *   that are in range of each other, but have no common neighbors, to discover each other. If both nodes by chance 
  *   always transmit simultaneously, they would never be aware of each other. This is not very likely to happen, but
  *   by adding a small random delay this problem can be mitigated.
  *   If the slot length is chosen to be not much longer than is necessary to range all neighbors, this delay could 
  *   possibly be made even smaller.
  */

  // minimum delay is zero
  uint32_t minDelayFactor = 0;
  // max delay is quarter of random delay for reservation (this is a judgment call; change if necessary)
  uint32_t maxDelayFactor = round((floor(node->config->slotLength - 2 * node->config->guardPeriodLength - PING_SIZE)/PING_SIZE)/4);
  uint32_t delayFactor = RandomNumbers_GetRandomIntBetween(node, minDelayFactor, maxDelayFactor);
  
  return delayFactor * PING_SIZE;
};

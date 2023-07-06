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

#include "../include/TimeKeeping.h"

static int64_t calculateTimeSinceLastPreamble(Node node, Message msg);
static int64_t calculateTimeInSlot(Node node);

TimeKeeping TimeKeeping_Create() {
  TimeKeeping self = calloc(1, sizeof(TimeKeepingStruct));
  self->frameStartSet = false;
  self->lastResetAt = 0;
  self->lastIdledTime = 0;
  return self;
};

void TimeKeeping_SetFrameStartTime(Node node, int64_t startTime) {
  node->timeKeeping->frameStartTime = startTime;
  node->timeKeeping->frameStartSet = true;
};

void TimeKeeping_SetFrameStartTimeForLastPreamble(Node node, Message msg) {
  // frame start time of the sending node is the timestamp of the message (when it arrived at this node)
  // minus the time since frame start of the sending node; this neglects ToF which should not be relevant 
  // as is is several orders of magnitude shorter than one slot usually is (ns ToF vs. ms slot length)
  node->timeKeeping->frameStartTime = msg->timestamp - msg->timeSinceFrameStart;
  node->timeKeeping->frameStartSet = true;
};

bool TimeKeeping_InitialWaitTimeOver(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // earliest time a ping may be sent is the start time of the node (0) + the wait time; 
  // the wait time may start over when the node disconnects from a network, so the last
  // time that happened must be added
  int32_t earliestPingTime = node->config->initialWaitTime + node->timeKeeping->lastResetAt;
  if (localTime >= earliestPingTime) {
    return true;
  };
  return false;
};

void TimeKeeping_ResetTime(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  node->timeKeeping->lastResetAt = localTime;
};

uint8_t TimeKeeping_CalculateOwnSlotAtTime(Node node, int64_t time) {
  // calculate for a given time in which slot the node was or will be then
  int32_t frameLength = node->config->frameLength;
  int32_t slotLength = node->config->slotLength;

  // timeSinceFirstFrameStart is the time that passed from the first frame start of this node
  // in the network till the time that is queried
  int64_t timeSinceFirstFrameStart = time - node->timeKeeping->frameStartTime;
  // time that passed since the beginning of the current frame (value from 0 to frameLength) 
  int64_t timeInFrame = timeSinceFirstFrameStart % frameLength; 

  double slotAtQueriedTime = floor((timeInFrame + slotLength)/slotLength);
  return (uint16_t) slotAtQueriedTime;
};

uint8_t TimeKeeping_CalculateCurrentSlotNum(Node node) {
  if (!node->timeKeeping->frameStartSet) {
    // if frameStartTime not set, it is slot 1
    return 1;
  };
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  return TimeKeeping_CalculateOwnSlotAtTime(node, localTime);
};

uint64_t TimeKeeping_CalculateCurrentFrameNum(Node node) {
  if (!node->timeKeeping->frameStartSet) {
    // if frameStartTime not set, it is frame 0
    return 0;
  };

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // get the number of frames that have passed already and add 1 to get the current frame num
  uint64_t currentFrameNum = floor((localTime - node->timeKeeping->frameStartTime) / (node->config->frameLength)) + 1;
  return currentFrameNum;
};

int64_t TimeKeeping_CalculateNextStartOfSlot(Node node, uint8_t slotNum) {
  int64_t nextStartTime = -1;
  if (node->timeKeeping->frameStartSet) {
    int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
    uint64_t currentFrameNum = TimeKeeping_CalculateCurrentFrameNum(node);
    
    int32_t slotLength = node->config->slotLength;
    int32_t slotsPerFrame = node->config->frameLength / slotLength;

    // start time of the queried slot num in the current frame:
    nextStartTime = node->timeKeeping->frameStartTime + ((currentFrameNum - 1) * slotLength * slotsPerFrame) + ((slotNum - 1) * slotLength);

    // if starttime lies in the past, it means the slot start is already over, so add one frame to get the correct time
    if (nextStartTime <= localTime) {
      nextStartTime += node->config->frameLength;
    };
  };
  return nextStartTime;
};

int64_t TimeKeeping_CalculateNetworkAgeFromMsg(Node node, Message msg) {
  // current age of the network of a message is the network age in the message 
  // + the time it took to transmit the message + the time that has passed since it was received, neglecting ToF
  int64_t timeSinceLastPreamble = calculateTimeSinceLastPreamble(node, msg); // time it took to transmit the message + time that passed since message was received
  return (msg->networkAge + timeSinceLastPreamble);
};

int64_t TimeKeeping_CalculateTimeSinceFrameStart(Node node) {
  if(!node->timeKeeping->frameStartSet) {
    return 0;
  };
  uint8_t currentSlotNum = TimeKeeping_CalculateCurrentSlotNum(node);
  int64_t timeInSlot = calculateTimeInSlot(node);

  // time since the start of the current frame is the number of slot multiplied by the slot length 
  // + the time that has passed since the beginning of the current slot
  int64_t timeSinceFrameStart = node->config->slotLength * (currentSlotNum - 1) + timeInSlot;

  return timeSinceFrameStart;
};

int64_t TimeKeeping_GetTimeRemainingInCurrentSlot(Node node) {
  // calculate the time that has passed since the beginning of the slot
  int64_t timeInSlot = calculateTimeInSlot(node);
  // remaing time is slot length minus the time that has already passed
  return (node->config->slotLength - timeInSlot);
};

void TimeKeeping_CalculateCollisionTimes(Node node, Message msg, int32_t *buffer) {
  // collision times are contained in the message ("time that passed since the collision was 
  // received by the other node", but the time it took to transmit the message has also to be accounted for)
  for (int i = 0; i < msg->numCollisions; ++i) {
    if (msg->collisionTimes[i] == -1) {
      buffer = NULL;
    };
    int64_t timeSinceMessageArrived = calculateTimeSinceLastPreamble(node, msg);
    buffer[i] = timeSinceMessageArrived - msg->collisionTimes[i];
  };
};

void TimeKeeping_SetLastTimeIdled(Node node) {
  node->timeKeeping->lastIdledTime = ProtocolClock_GetLocalTime(node->clock);
};

int64_t TimeKeeping_GetLastTimeIdled(Node node) {
  return node->timeKeeping->lastIdledTime;
};

bool TimeKeeping_IsAutoCycleWakeupTime(Node node) {
  // sleeptime is defined as a multiple of frames; sleepFrames is the number of frames to sleep
  int64_t sleeptime = (node->config->frameLength * node->config->sleepFrames);
  int64_t networkAge = NetworkManager_CalculateNetworkAge(node);

  // nodes should wake up when the current network age is an even multiple of the sleeptime; 
  // as the network age is the same among the nodes, this makes then wake up at the same time
  return (networkAge % sleeptime == 0);
};

static int64_t calculateTimeSinceLastPreamble(Node node, Message msg) {
  // calculate the time that passed since the last message arrived at the antenna (preamble)
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  return (localTime - msg->timestamp);
};

static int64_t calculateTimeInSlot(Node node) {
 // calculate the time that has passed since the beginning of the current slot 
 int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
 return ((localTime - node->timeKeeping->frameStartTime) % node->config->slotLength);
};

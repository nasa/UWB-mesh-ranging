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

#include "../include/RangingManager.h"

RangingManager RangingManager_Create() {
  RangingManager self = calloc(1, sizeof(RangingManagerStruct));
  self->lastRangingMsgOutTime = 0;
  self->lastRangingMsgInTime = 0;
  return self;
};

bool RangingManager_HasRangingTimedOut(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  int64_t lastRangingMsgOutTime = node->rangingManager->lastRangingMsgOutTime;

  // ranging timed out if the other node did not answer to the last ranging message for a certain time
  if (localTime > (lastRangingMsgOutTime + node->config->rangingTimeOut)) {
    #ifdef SIMULATION
    mexPrintf("Node %" PRIu8 " ranging timed out \n", node->id);
    #endif
    return true;
  };

  // it also timed out if the slot ended in which the ranging started 
  uint8_t startSlot = TimeKeeping_CalculateOwnSlotAtTime(node, lastRangingMsgOutTime);
  uint8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);
  if (startSlot != currentSlot) {
    return true;
  };

  return false;
};

void RangingManager_RecordRangingMsgIn(Node node, Message msg) {
  node->rangingManager->lastRangingMsgInTime = msg->timestamp;  
};

void RangingManager_RecordRangingMsgOut(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  node->rangingManager->lastRangingMsgOutTime = localTime;
};

bool RangingManager_IsWaitTimeOver(Node node) {
  return true;
};

Message RangingManager_GetLastIncomingRangingMsg(Node node) {
  return node->rangingManager->lastIncomingRangingMsg;
};

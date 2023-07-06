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

#include "../include/GuardConditions.h"

GuardConditions GuardConditions_Create() {
  GuardConditions self = calloc(1, sizeof(GuardConditionsStruct));
  return self;
};

void GuardConditions_Destroy(GuardConditions self) {
  free(self);
};

bool GuardConditions_ListeningUncToSendingUncAllowed(Node node) {
  /** Guard condition for transition from unconnected listening to unconnected sending (sending the initial ping to start a network)
  *   Makes sure this node does not send when it is not supposed to (e.g. in another node's slot) or when
  *   it is currently receiving a transmission
  */
  bool clearToSend = SlotMap_ClearToSend(node);
  bool isReceiving = Driver_IsReceiving(node);

  if (clearToSend && !isReceiving) {
    return true;
  };
  return false;
};

bool GuardConditions_SendingUncToListeningConAllowed(Node node) {
  /** Transition from unconnected sending to connected listening is always allowed */
  return true;
};

bool GuardConditions_ListeningConToSendingConAllowed(Node node) {
  /** Guard condition for transition from connected listening to connected sending (in own slot or to reserve a new slot)
  *   Makes sure this node does not send when it is not supposed to (e.g. in another node's slot), when it is
  *   currently receiving a transmission or when the network status has changed to unconnected in the meantime
  */

  bool clearToSend = SlotMap_ClearToSend(node);
  bool isReceiving = Driver_IsReceiving(node);
  NetworkStatus status = NetworkManager_GetNetworkStatus(node);
  if (clearToSend && !isReceiving && status == CONNECTED) {
    return true;
  };
  return false;
};

bool GuardConditions_ListeningConToListeningUncAllowed(Node node) {
  /** Guard condition for transition from connected listening to unconnected listening */
  // if the network status has changed to unconnected, it is allowed to transition
  if (NetworkManager_GetNetworkStatus(node) == NOT_CONNECTED) {
    return true;
  };

  int8_t ownSlotBuffer[MAX_NUM_OWN_SLOTS];
  int8_t pendingSlotBuffer[MAX_NUM_PENDING_SLOTS];
  int8_t numOwn = SlotMap_GetOwnSlots(node, &ownSlotBuffer[0], MAX_NUM_OWN_SLOTS);
  int8_t numPending = SlotMap_GetPendingSlots(node, &pendingSlotBuffer[0], MAX_NUM_PENDING_SLOTS);

  bool otherNodeHasReservedASlot = false;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->oneHopSlotsStatus[i] == OCCUPIED)
     otherNodeHasReservedASlot = true;
  };

  /** It is also allowed to transition to unconnected if this slot does not have own or pending slots (no slot acknowledged)
  *   AND if the current network was started by this node AND if no other node has reserved a slot; this likely means that no 
  *   other node has received the initial ping of this node that was supposed to start a new network (because it collided or because 
  *   no other node was in range)
  */
  if (!((numOwn > 0)  || (numPending > 0)) && node->networkManager->currentNetworkStartedByThisNode && !otherNodeHasReservedASlot)
    return true;

  return false;
};

bool GuardConditions_SendingConToListeningConAllowed(Node node) {
  /** Transition from connected sending to connected listening is always allowed */
  return true;
};

bool GuardConditions_RangingPollAllowed(Node node) {
  /** Guard condition for transition from connected listening to sending a poll message */

  uint8_t currentSlotNum = TimeKeeping_CalculateCurrentSlotNum(node);
  bool isOwnSlot = SlotMap_IsOwnSlot(node, currentSlotNum);

  // if it is not this node's slot it cannot send a poll message
  if (!isOwnSlot) {
    return false;
  };

  // get the neighbor that should be done ranging with next
  int8_t nextNeighbor = Neighborhood_GetNextRangingNeighbor(node);
  if (nextNeighbor == -1) {
    // if this node has no neighbors at all or no neighbors that ranging is due with, sending another poll is not allowed
    return false;
  };
    
  int64_t remainingTime = TimeKeeping_GetTimeRemainingInCurrentSlot(node);
  int64_t nextScheduledTime = Scheduler_GetTimeOfNextSchedule(node);
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // only do ranging if no ping is scheduled in this slot (i.e. has already been sent)
  if (nextScheduledTime > (localTime + remainingTime)) {
    // check if remaining time in this slot is enough to do ranging
    // just assume ranging takes as long as the time out
    int64_t rangingDuration = node->config->rangingTimeOut;

    // make sure the node will not violate the guard period
    if (remainingTime > (rangingDuration + node->config->guardPeriodLength))
      return true;
  };

  return false;
};

bool GuardConditions_IdleingAllowed(Node node) {
  /** Guard condition for transition to idle */

  // no idleing when number of sleep frames was set to smaller than one
  if (node->config->sleepFrames < 1) {
    return false;
  };

  int8_t currentSlotNum = TimeKeeping_CalculateCurrentSlotNum(node);
  // only start idleing at the beginning of a frame, i.e. in the first slot
  if (currentSlotNum != 1) {
    return false;
  };

  int8_t ownSlots[MAX_NUM_OWN_SLOTS];
  int8_t numOwnSlots = SlotMap_GetOwnSlots(node, &ownSlots[0], MAX_NUM_OWN_SLOTS);
  // don't idle when slot goal not met (i.e. this node has not reserved enough nodes yet)
  if (numOwnSlots != node->config->slotGoal) {
    return false;
  };

  int64_t lastTimeIdled = TimeKeeping_GetLastTimeIdled(node);
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // only idle if last idleing was more than two frames ago
  int8_t minNumFrames = 2;
  if (localTime - lastTimeIdled < minNumFrames * node->config->frameLength) {
    return false;
  };  

  // don't idle if a new neighbor joined within the last frame, unless it is already present in the slot maps 
  // (i.e. it was already in the network and likely only changed its position)
  int64_t lastJoinedTime = Neighborhood_GetTimeWhenNewestNeighborJoined(node);
  int8_t newestNeighborId = Neighborhood_GetNewestNeighbor(node);

  if (localTime - lastJoinedTime <= node->config->frameLength) {
    int8_t oneHopSlotIds[NUM_SLOTS]; 
    SlotMap_GetOneHopSlotMapIds(node, &oneHopSlotIds[0], NUM_SLOTS);
    int8_t twoHopSlotIds[NUM_SLOTS]; 
    SlotMap_GetTwoHopSlotMapIds(node, &twoHopSlotIds[0], NUM_SLOTS);
    int8_t threeHopSlotIds[NUM_SLOTS]; 
    SlotMap_GetThreeHopSlotMapIds(node, &threeHopSlotIds[0], NUM_SLOTS);

    bool notInOneHopSlotMap = (Util_Int8tArrayFindElement(&oneHopSlotIds[0], newestNeighborId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the ID was not found in this node's oneHopSlotMap
    bool notInTwoHopSlotMap = (Util_Int8tArrayFindElement(&twoHopSlotIds[0], newestNeighborId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the ID was not found in this node's twoHopSlotMap
    bool notInThreeHopSlotMap = (Util_Int8tArrayFindElement(&threeHopSlotIds[0], newestNeighborId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the ID was not found in this node's threeHopSlotMap
    
    bool neighborIsNew = (notInOneHopSlotMap && notInTwoHopSlotMap && notInThreeHopSlotMap);
    if (neighborIsNew) {
      return false;
    };
  };

  // don't idle if there were reservations in the last frame (to make sure these are acknowledged at least once before idleing)
  int64_t lastReservationTime = SlotMap_GetLastReservationTime(node);
  if (localTime - lastReservationTime <= node->config->frameLength) {
    return false;
  };

  // if all conditions were met, idleing is allowed
  return true;
};

bool GuardConditions_IdleToListeningConAllowedIncomingMsg(Node node, Message msg) {
  /** Guard condition for waking up from idle when a message is received */

  // wake up when the message is a collision
  if (msg->type == COLLISION) {
    return true;
  };

  // check if ping is from a different network
  bool isForeignPing = NetworkManager_IsPingFromForeignNetwork(node, msg);

  // check if sending node already has a slot in this network
  int8_t oneHopSlotIds[NUM_SLOTS]; 
  SlotMap_GetOneHopSlotMapIds(node, &oneHopSlotIds[0], NUM_SLOTS);
  int8_t twoHopSlotIds[NUM_SLOTS]; 
  SlotMap_GetTwoHopSlotMapIds(node, &twoHopSlotIds[0], NUM_SLOTS);
  int8_t threeHopSlotIds[NUM_SLOTS]; 
  SlotMap_GetThreeHopSlotMapIds(node, &threeHopSlotIds[0], NUM_SLOTS);

  bool notInOneHopSlotMap = (Util_Int8tArrayFindElement(&oneHopSlotIds[0], msg->senderId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the senderId was not found in this node's oneHopSlotMap
  bool notInTwoHopSlotMap = (Util_Int8tArrayFindElement(&twoHopSlotIds[0], msg->senderId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the senderId was not found in this node's twoHopSlotMap
  bool notInThreeHopSlotMap = (Util_Int8tArrayFindElement(&threeHopSlotIds[0], msg->senderId, NUM_SLOTS) == -1); // if FindArrayElement returns -1, it means that the senderId was not found in this node's threeHopSlotMap

  bool sendingNodeDoesNotHaveSlot = (notInOneHopSlotMap && notInTwoHopSlotMap && notInThreeHopSlotMap);

  int8_t ownSlots[MAX_NUM_OWN_SLOTS];
  int8_t numOwnSlots = SlotMap_GetOwnSlots(node, &ownSlots[0], MAX_NUM_OWN_SLOTS);

  // node should stop idleing if either:
  // - it received a ping from a foreign network
  // - the sending node does not have a slot yet (therefore its pings need to be acknowledged)
  // - it received a collision (handled at the top of this function)
  // - it has no own slots anymore

  if (isForeignPing || sendingNodeDoesNotHaveSlot || (numOwnSlots == 0)) {
    return true;
  };

  return false;
};

bool GuardConditions_IdleToListeningConAllowed(Node node) {
  /** Guard condition for waking up from idle */

  // wake up if it is the regular time to wake up
  bool isWakeupTime = TimeKeeping_IsAutoCycleWakeupTime(node);
  if (isWakeupTime) {
    return true;
  };
  return false;
};

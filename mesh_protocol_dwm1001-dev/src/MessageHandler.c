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

#include "../include/MessageHandler.h"

static void joinNetwork(Node node, Message msg);
static void updateSlots(Node node, Message msg);
static bool createPingMessage(Node node, Message msg);
static bool createRangingPollMessage(Node node, Message msg);
static bool createRangingResponseMessage(Node node, Message msg, Message pollMsgIn);
static bool createRangingFinalMessage(Node node, Message msg, Message responseMsgIn);
static bool createRangingResultMessage(Node node, Message msg, Message finalMsgIn);
static void correctOwnTime(Node node, Message msg);

MessageHandler MessageHandler_Create() {
  MessageHandler self = calloc(1, sizeof(MessageHandlerStruct));

  return self;
};

void MessageHandler_HandlePingUnconnected(Node node, Message msg) {
  // this node does not have a network (unconnected), so it joins the network of the node whose ping it received
  joinNetwork(node, msg);
  // cancel any scheduled pings cause they are not valid in the new network
  Scheduler_CancelScheduledPing(node);
  // update slot map with the information in the message
  updateSlots(node, msg);

  // add sending node as a neighbor
  Neighborhood_AddOrUpdateOneHopNeighbor(node, msg->senderId);
};  

void MessageHandler_HandlePingConnected(Node node, Message msg) {
  // add or update "last time seen" of the neighbor who sent the message
  Neighborhood_AddOrUpdateOneHopNeighbor(node, msg->senderId);
  
  // check if the sending node is in a different network
  bool isForeignPing = NetworkManager_IsPingFromForeignNetwork(node, msg);

  if (isForeignPing) {
    // if the ping is from a different network, check which network precedes
    // the nodes from the not preceding network must join the preceding network when they receive a ping from it
    bool foreignNetPrecedes = NetworkManager_IsForeignNetworkPreceding(node, msg);
    if (foreignNetPrecedes) {
      // switch to the other network

      // join the other network
      joinNetwork(node, msg);
      // cancel any scheduled pings cause they are not valid in the new network
      Scheduler_CancelScheduledPing(node);
      // update slot maps with information from the ping
      updateSlots(node, msg);

    } else if (NetworkManager_DoNetworksHaveSameAge(node, msg)) {
      // networks have different ID but same age (this should be extremely unlikely to happen in reality)
      // cancel ping and leave the network, so the node goes back to unconnected listening
      Scheduler_CancelScheduledPing(node);
      NetworkManager_SetNetworkStatus(node, NOT_CONNECTED);
      NetworkManager_SetNetworkId(node, 0);

    } else {
      // own network precedes
      // do nothing
    };
  } else {
    // ping is not from foreign network
    
    // correct own time based on message
    correctOwnTime(node, msg);

    // update slots
    updateSlots(node, msg);
  };
}; 

void MessageHandler_SendInitialPing(Node node) {
  // sending an initial ping means a network must be created, the frame start time must be set and the ping has to be sent
  // all receiving nodes will do this when they receive the ping
  NetworkManager_CreateNetwork(node);
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  TimeKeeping_SetFrameStartTime(node, localTime);

  MessageHandler_SendPing(node);
};

void MessageHandler_SendPing(Node node) {
  // first create an empty ping message struct
  Message msg;
  struct MessageStruct message;
  msg = &message;
  msg->type = PING;

  // fill the message with the necessary information
  createPingMessage(node, msg);

  // transmit message via driver
  Driver_TransmitPing(node, msg);

  int8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);
  bool isOwn = SlotMap_IsOwnSlot(node, currentSlot);
  bool isPending = SlotMap_IsPendingSlot(node, currentSlot);

  // if the current slot is not already pending or own, add it to pending (it was a new reservation attempt)
  if (!isOwn && !isPending) {
    int8_t neighbors[MAX_NUM_NODES - 1];

    // get the neighbors of the node at this particular time, cause these neighbors need to acknowledge the ping 
    // Note: currently only the number of neighbors that ack'ed is checked, not which neighbors exactly (simpler implementation)
    int8_t numNeighbors = Neighborhood_GetOneHopNeighbors(node, &neighbors[0], (MAX_NUM_NODES - 1));
    SlotMap_AddPendingSlot(node, currentSlot, &neighbors[0], numNeighbors);
  };

};

void MessageHandler_SendRangingPollMessage(Node node) {
  Message msg;
  struct MessageStruct message;
  msg = &message;
  msg->type = POLL;

  createRangingPollMessage(node, msg);

  Driver_TransmitPoll(node, msg);
};

void MessageHandler_SendRangingResponseMessage(Node node, Message pollMsgIn) {
  Driver_TransmitResponse(node, pollMsgIn);
};

void MessageHandler_SendRangingFinalMessage(Node node, Message responseMsgIn) {
  Driver_TransmitFinal(node, responseMsgIn);
};

void MessageHandler_SendRangingResultMessage(Node node, Message finalMsgIn) {
  Driver_TransmitResult(node, finalMsgIn); 
};


static void joinNetwork(Node node, Message msg) {
  // set the network status and ID
  NetworkManager_SetNetworkStatus(node, CONNECTED);
  NetworkManager_SetNetworkId(node, msg->networkId);
  int64_t networkAge = TimeKeeping_CalculateNetworkAgeFromMsg(node, msg);

  // save the age of the network at the time when this node joined
  NetworkManager_SaveNetworkAgeAtJoining(node, networkAge);
  
  // save the local time of this node at the time it joined the network
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  NetworkManager_SaveLocalTimeAtJoining(node, localTime);

  // set the frame start to the time when the message arrived at the antenna (when the preamble was received)
  TimeKeeping_SetFrameStartTimeForLastPreamble(node, msg);

  // release possible own and pending slots when joining a new network, because these are not valid anymore
  int8_t ownSlotsBuffer[NUM_SLOTS];
  int8_t numOwn = SlotMap_GetOwnSlots(node, &ownSlotsBuffer[0], NUM_SLOTS);
  for (int i = 0; i < numOwn; ++i) {
    SlotMap_ReleaseOwnSlot(node, ownSlotsBuffer[i]);
  };

  int8_t pendingSlotsBuffer[NUM_SLOTS];
  int8_t numPending = SlotMap_GetPendingSlots(node, &pendingSlotsBuffer[0], NUM_SLOTS);
  for (int i = 0; i < numPending; ++i) {
    SlotMap_ReleasePendingSlot(node, pendingSlotsBuffer[i]);
  };

#if DEBUG_VERBOSE
  printf("%d: Node %d joined network %d \n", (int) localTime, node->id, msg->networkId);
#endif
};

static void updateSlots(Node node, Message msg) {
  // first update the acknowledgements of pending slots (if the sender of the message acknowledged a pending slot of this node)
  SlotMap_UpdatePendingSlotAcks(node, msg);
  
  // add pending slots that were acknowledged by all required nodes to own slots
  int8_t acknowledgedPendingSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numAcked = SlotMap_GetAcknowledgedPendingSlots(node, &acknowledgedPendingSlots[0], MAX_NUM_PENDING_SLOTS);
  for(int i = 0; i < numAcked; ++i) {
    SlotMap_ChangePendingToOwn(node, acknowledgedPendingSlots[i]);
  };
  
  // check if own slots were reported as colliding by the sending node
  int8_t collidingOwnSlots[MAX_NUM_OWN_SLOTS];
  int8_t numCollidingOwn = SlotMap_CheckOwnSlotsForCollisions(node, msg, &collidingOwnSlots[0], MAX_NUM_OWN_SLOTS);

  // release colliding own slots
  for (int i = 0; i < numCollidingOwn; ++i) {
    SlotMap_ReleaseOwnSlot(node, collidingOwnSlots[i]);
  };

  // check if pending slots were reported as colliding by the sending node
  int8_t collidingPendingSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numCollidingPending = SlotMap_CheckPendingSlotsForCollisions(node, msg, &collidingPendingSlots[0], MAX_NUM_PENDING_SLOTS);
  // release colliding pending slots
  for (int i = 0; i < numCollidingPending; ++i) {
    SlotMap_ReleasePendingSlot(node, collidingPendingSlots[i]);
  };

  // update the internal slot maps of this nodes with the information in the message
  uint8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);
  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);
  
  SlotMap_UpdateTwoHopSlotMap(node, msg);
  SlotMap_UpdateThreeHopSlotMap(node, msg);

  // cancel the next schedule if the corresponding slot was released 
  int8_t nextScheduledSlot = Scheduler_GetSlotOfNextSchedule(node);
  int16_t idxCollidingOwn = Util_Int8tArrayFindElement(&collidingOwnSlots[0], nextScheduledSlot, numCollidingOwn);
  int16_t idxCollidingPending = Util_Int8tArrayFindElement(&collidingPendingSlots[0], nextScheduledSlot, numCollidingPending);

  bool nextScheduledIsCollidingOwn = false;
  bool nextScheduledIsCollidingPending = false;

  if (idxCollidingOwn != -1)
    nextScheduledIsCollidingOwn = true;
  if (idxCollidingPending != -1)
    nextScheduledIsCollidingPending = true;

  if (nextScheduledIsCollidingOwn || nextScheduledIsCollidingPending) {
    Scheduler_CancelScheduledPing(node);
  };
};

static bool createPingMessage(Node node, Message msg) {
  msg->type = PING;
  msg->senderId = node->id;

  // add one hop and two hop slot maps to the message so receiving nodes 
  // get information about their two and three hop neighbors
  SlotMap_GetOneHopSlotMapStatus(node, &msg->oneHopSlotStatus[0], NUM_SLOTS);
  SlotMap_GetOneHopSlotMapIds(node, &msg->oneHopSlotIds[0], NUM_SLOTS);

  SlotMap_GetTwoHopSlotMapStatus(node, &msg->twoHopSlotStatus[0], NUM_SLOTS);
  SlotMap_GetTwoHopSlotMapIds(node, &msg->twoHopSlotIds[0], NUM_SLOTS);

  // add the time since the start of the current frame to the message so receiving nodes can synchronize
  // to the network
  msg->timeSinceFrameStart = TimeKeeping_CalculateTimeSinceFrameStart(node);

  // add network ID and age to the message so receiving nodes know if it is a foreign network or the same
  msg->networkId = NetworkManager_GetNetworkId(node);
  msg->networkAge = NetworkManager_CalculateNetworkAge(node);
};

static bool createRangingPollMessage(Node node, Message msg) {
  msg->type = POLL;
  msg->senderId = node->id;
  msg->recipientId = Neighborhood_GetNextRangingNeighbor(node);
  return true;
};

static bool createRangingResponseMessage(Node node, Message msg, Message pollMsgIn) {
  msg->type = RESPONSE;
  msg->senderId = node->id;
  msg->recipientId = pollMsgIn->senderId;
  return true;
};

static bool createRangingFinalMessage(Node node, Message msg, Message responseMsgIn) {
  msg->type = FINAL;
  msg->senderId = node->id;
  msg->recipientId = responseMsgIn->senderId;
  return true;
};

static bool createRangingResultMessage(Node node, Message msg, Message finalMsgIn) {
  msg->type = RESULT;
  msg->senderId = node->id;
  msg->recipientId = finalMsgIn->senderId;
  return true;
};

static void correctOwnTime(Node node, Message msg) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  int64_t timeSinceLastPreamble = (localTime - msg->timestamp);

  // time since frame start at the time when the message arrived at the antenna (when preamble was received)
  int64_t timeSinceFrameStart = TimeKeeping_CalculateTimeSinceFrameStart(node) - timeSinceLastPreamble;

  // if both nodes are in different frames (i.e. one is at the end of frame x and the other is at the beginning of frame x+1), this must be accounted for
  int64_t candidate1 = 0;
  if (msg->timeSinceFrameStart > timeSinceFrameStart) {
    candidate1 = (msg->timeSinceFrameStart - node->config->frameLength) - timeSinceFrameStart; // this node is a frame ahead
  } else if (msg->timeSinceFrameStart < timeSinceFrameStart) {
    candidate1 = (msg->timeSinceFrameStart + node->config->frameLength) - timeSinceFrameStart;  // the sending node is a frame ahead
  };

  int64_t candidate2 = msg->timeSinceFrameStart - timeSinceFrameStart; // both nodes (this and the other) are in the same frame
  // choose the smaller absolute value as the correction value (smaller one is the correct one, the larger one is the one where both nodes are in different frames)
  int64_t correctionValue = (abs(candidate1) < abs(candidate2)) ? candidate1 : candidate2;

  // do not correct by the full difference but only by a fraction at a time
  correctionValue = round(correctionValue/8);

  ProtocolClock_CorrectTime(node->clock, correctionValue);
};


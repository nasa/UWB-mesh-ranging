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

#include "../include/SlotMap.h"

static bool isAcknowledged(Node node, int8_t queriedPendingSlot);
static bool oneHopSlotIsExpired(Node node, int8_t currentSlot, int64_t timeout);
static void updateMultiHopSlotMap(Node node, Message msg, int *multiHopSlotMapStatus, int8_t *multiHopSlotMapIds, int64_t *multiHopSlotMapLastUpdate);
static bool slotReportedColliding(Message msg, int8_t slotNum);
static bool slotReportedOccupiedByOtherNode(Node node, Message msg, int8_t slotNum);
static void removeExpiredSlotsFromSlotMap(Node node, int *slotMapStatus, int8_t *slotMapIds, int64_t *slotMapLastUpdated);
static int8_t findFreeSlotsInThreeHopNeighborhood(Node node, int8_t *freeSlots);
static int8_t findFreeForThisNodeSlotsInThreeHopNeighborhood(Node node, int8_t *freeSlots);
static int8_t findCollidingSlotsInThreeHopNeighborhood(Node node, int8_t *collidingSlots);
static int8_t getNextSlotFromSelection(Node node, int8_t *selection, int8_t size);

SlotMap SlotMap_Create() {
  SlotMap self = calloc(1, sizeof(SlotMapStruct));
  self->numPendingSlots = 0;
  self->numOwnSlots = 0;
  self->lastReservationTime = 0;

  // initialize all slot maps
  for(int i = 0; i < NUM_SLOTS; ++i) {
    self->oneHopSlotsStatus[i] = FREE;
    self->oneHopSlotsIds[i] = 0;
    self->oneHopSlotsLastUpdated[i] = 0;

    self->twoHopSlotsStatus[i] = FREE;
    self->twoHopSlotsIds[i] = 0;
    self->twoHopSlotsLastUpdated[i] = 0;

    self->threeHopSlotsStatus[i] = FREE;
    self->threeHopSlotsIds[i] = 0;
    self->threeHopSlotsLastUpdated[i] = 0;
  };

  // initialize all pending slots to -1, to signal there are none
  for(int i = 0; i < MAX_NUM_PENDING_SLOTS; ++i) {
    self->pendingSlots[i] = -1;
    self->localTimePendingSlotAdded[i] = -1;

    // initialize all "neighbors when pending slot was added" to -1
    for(int j = 0; j < (MAX_NUM_NODES - 1); ++j) {
      self->pendingSlotsNeighbors[i][j] = -1;
      self->pendingSlotAcknowledgedBy[i][j] = -1;
    };
  };

  return self;
};

void SlotMap_UpdateOneHopSlotMap(Node node, Message msg, int8_t currentSlot) {
  /** One hop slot map contains all slot reservations this node receives directly;
  *   currentSlot is the slot that will be upated in the one hop slot map by this function,
  *   because it is the slot in which this message was received
  */

  // convert slot num to index by subtracting 1
  int8_t currentSlotIndex = currentSlot - 1; 
  // current status of the slot in one hop slot map
  int currentStatus = node->slotMap->oneHopSlotsStatus[currentSlotIndex]; 

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  switch(msg->type) {
    case PING: ;
      // current ID that reserved the slot in one hop slot map
      int8_t currentId = node->slotMap->oneHopSlotsIds[currentSlotIndex];
      // ID of node that sent the new ping
      int8_t newId = msg->senderId;

      switch(currentStatus) {
        case FREE:
          // if the slot is currently FREE, it is immediately overwritten with
          // the new values
          node->slotMap->oneHopSlotsStatus[currentSlotIndex] = OCCUPIED;
          node->slotMap->oneHopSlotsIds[currentSlotIndex] = newId;
          node->slotMap->oneHopSlotsLastUpdated[currentSlotIndex] = localTime;
          break;

        case OCCUPIED: ;
          if (newId == currentId) {
            // if the slot is already occupied by the node that sent this ping,
            // we only have to update the time
            node->slotMap->oneHopSlotsLastUpdated[currentSlotIndex] = localTime;
          } else {
            // if the slot is currently occupied by a different node, it is only overwritten
            // when the slot is expired (the node that currently reserved the slot did not use 
            // it for a while), otherwise, the current node will keep the slot
            if(oneHopSlotIsExpired(node, currentSlot, node->config->occupiedTimeout)) {
              node->slotMap->oneHopSlotsStatus[currentSlotIndex] = OCCUPIED;
              node->slotMap->oneHopSlotsIds[currentSlotIndex] = newId;
              node->slotMap->oneHopSlotsLastUpdated[currentSlotIndex] = localTime;
            };
          };
          break;

        case COLLIDING: ;
          // if the slot is currently colliding, we only overwrite it if the collision
          // is expired
          if(oneHopSlotIsExpired(node, currentSlot, node->config->collidingTimeout)) {
            node->slotMap->oneHopSlotsStatus[currentSlotIndex] = OCCUPIED;
            node->slotMap->oneHopSlotsIds[currentSlotIndex] = newId;
            node->slotMap->oneHopSlotsLastUpdated[currentSlotIndex] = localTime;
          };
          break;
      };

      /** if the ping is a new reservation attempt, record that;
      /   it is considered a new reservation if the two hop slot map in the message does not state this slot as 
      /   reserved by the sender (i. e. from the perspective of the sending node the slot was not acknowledged yet)
      */
      if (msg->twoHopSlotIds[currentSlotIndex] != msg->senderId) {
        node->slotMap->lastReservationTime = localTime;
      };

      break;
  };
};

void SlotMap_UpdateTwoHopSlotMap(Node node, Message msg) {
  /** To update the two hop slot map of this node, the information from the one hop slot map 
  *   from the message is used (one hop of the neighbor node is two hop of this node)
  */
  msg->multiHopStatus = &msg->oneHopSlotStatus[0];
  msg->multiHopIds = &msg->oneHopSlotIds[0];

  updateMultiHopSlotMap(node, msg, &node->slotMap->twoHopSlotsStatus[0], &node->slotMap->twoHopSlotsIds[0], &node->slotMap->twoHopSlotsLastUpdated[0]);
};

void SlotMap_UpdateThreeHopSlotMap(Node node, Message msg) {
  /** To update the three hop slot map of this node, the information from the two hop slot map 
  *   from the message is used (two hop of the neighbor node is three hop of this node)
  */
  msg->multiHopStatus = &msg->twoHopSlotStatus[0];
  msg->multiHopIds = &msg->twoHopSlotIds[0];

  updateMultiHopSlotMap(node, msg, &node->slotMap->threeHopSlotsStatus[0], &node->slotMap->threeHopSlotsIds[0], &node->slotMap->threeHopSlotsLastUpdated[0]);
};

bool SlotMap_GetOneHopSlotMapStatus(Node node, int *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  };
  memcpy(buffer, &node->slotMap->oneHopSlotsStatus[0], sizeof(int) * size);
  return true;
};

bool SlotMap_GetOneHopSlotMapIds(Node node, int8_t *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  };
  memcpy(buffer, &node->slotMap->oneHopSlotsIds[0], sizeof(int8_t) * size);
  return true;
};


bool SlotMap_GetTwoHopSlotMapStatus(Node node, int *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  };
  memcpy(buffer, &node->slotMap->twoHopSlotsStatus[0], sizeof(int) * size);
  return true;
};

bool SlotMap_GetTwoHopSlotMapIds(Node node, int8_t *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  }; 
  memcpy(buffer, &node->slotMap->twoHopSlotsIds[0], sizeof(int8_t) * size);
  return true;
};

bool SlotMap_GetThreeHopSlotMapStatus(Node node, int *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  };
  memcpy(buffer, &node->slotMap->threeHopSlotsStatus[0], sizeof(int) * size);
  return true;
};

bool SlotMap_GetThreeHopSlotMapIds(Node node, int8_t *buffer, int8_t size) {
  if(size < NUM_SLOTS) {
    return false;
  };
  memcpy(buffer, &node->slotMap->threeHopSlotsIds[0], sizeof(int8_t) * size);
  return true;
};

int8_t SlotMap_CheckOwnSlotsForCollisions(Node node, Message msg, int8_t *buffer, int8_t size) {
  int8_t numOwnSlots = node->slotMap->numOwnSlots;
  if(size < numOwnSlots) {
    return -1;
  };
  
  int8_t collidingSlotCnt = 0; 

  // check for all own slots if they are reported as colliding in the message or as occupied by a different node;
  // if so, they are considered colliding
  for (int i = 0; i < numOwnSlots; ++i) {
    if (slotReportedColliding(msg, node->slotMap->ownSlots[i]) || slotReportedOccupiedByOtherNode(node, msg, node->slotMap->ownSlots[i])) {
      buffer[collidingSlotCnt] = node->slotMap->ownSlots[i];
      ++collidingSlotCnt;
    };
  };
  return collidingSlotCnt;
};

int8_t SlotMap_CheckPendingSlotsForCollisions(Node node, Message msg, int8_t *buffer, int8_t size) {
  int8_t numPendingSlots = node->slotMap->numPendingSlots;
  if(size < numPendingSlots)
    return -1;
  
  int8_t collidingSlotCnt = 0; 

  // check for all pending slots if they are reported as colliding in the message or as occupied by a different node;
  // if so, they are considered colliding
  for (int i = 0; i < numPendingSlots; ++i) {
    if (slotReportedColliding(msg, node->slotMap->pendingSlots[i]) || slotReportedOccupiedByOtherNode(node, msg, node->slotMap->pendingSlots[i])) {
      buffer[collidingSlotCnt] = node->slotMap->pendingSlots[i];
      ++collidingSlotCnt;
    };
  };
  return collidingSlotCnt;
};

bool SlotMap_SlotReservationGoalMet(Node node) {
  if ((node->slotMap->numOwnSlots + node->slotMap->numPendingSlots) >= node->config->slotGoal) {
    return true;
  };

  return false;
};

int8_t SlotMap_GetReservableSlot(Node node) {
  /** A slot is considered reservable by this node if it is either free for a three hop neighborhood
  *   (meaning in all three slot maps of this node) or if it is colliding in any one of the three slot maps
  *   of this node and at the same time not reported/perceived as occupied by a node; colliding slots must 
  *   be considered reservable to avoid deadlocks (e.g. two nodes trying to reserve the last two free slots 
  *   alternatingly)
  */
  int8_t freeSlots[NUM_SLOTS];
  int8_t numFreeSlots = findFreeForThisNodeSlotsInThreeHopNeighborhood(node, &freeSlots[0]);

  int8_t collidingSlots[NUM_SLOTS];
  int8_t numCollidingSlots = findCollidingSlotsInThreeHopNeighborhood(node, &collidingSlots[0]);

  int16_t reservableSlots[NUM_SLOTS]; // maximum number of slots that can be reservable are all slots

  for (int i = 0; i < numFreeSlots; ++i) {
    reservableSlots[i] = freeSlots[i];
  };
  for (int i = 0; i < numCollidingSlots; ++i) {
    reservableSlots[i + numFreeSlots] = collidingSlots[i];
  };

  if ((numFreeSlots+numCollidingSlots) == 0) {
    return -1;
  };

  // get one random slot of all reservable ones
  int16_t randomSlot = RandomNumbers_GetRandomElementFrom(node, &reservableSlots[0], (numFreeSlots+numCollidingSlots));

  return (int8_t) randomSlot;
};

int8_t SlotMap_CalculateNextOwnOrPendingSlotNum(Node node, int8_t currentSlot) {
  // total number of own and pending slots
  int16_t numOwnAndPending = node->slotMap->numOwnSlots + node->slotMap->numPendingSlots;

  if (numOwnAndPending == 0) {
    return -1;
  };

  // copy all own and pending slots into an array
  int8_t selection[MAX_NUM_OWN_SLOTS + MAX_NUM_PENDING_SLOTS];
  memcpy(&selection[0], &node->slotMap->ownSlots[0], sizeof(int8_t) * node->slotMap->numOwnSlots);
  memcpy(&selection[node->slotMap->numOwnSlots], &node->slotMap->pendingSlots[0], sizeof(int8_t) * node->slotMap->numPendingSlots);

  // get the slot that comes next from all own and pending slots
  int8_t nextSlot = getNextSlotFromSelection(node, &selection[0], numOwnAndPending);

  return nextSlot;
};

void SlotMap_UpdatePendingSlotAcks(Node node, Message msg) {
  for(int i = 0; i < MAX_NUM_PENDING_SLOTS; ++i) {
    // stop when we find the first -1 value, because array is padded with -1
    if (node->slotMap->pendingSlots[i] == -1) {
      return;
    };
    // check if the current pending slot was acknowledged in this message
    int8_t pendingSlotNum = node->slotMap->pendingSlots[i];
    if(msg->oneHopSlotIds[pendingSlotNum - 1] == node->id) { // subtract -1 from the slot num to convert it to an index of the array
      // slot was acknowledged, so add the ID of the acknowledging node
      for(int j = 0; j < (MAX_NUM_NODES - 1); ++j) {
        if (node->slotMap->pendingSlotAcknowledgedBy[i][j] == -1) {
          node->slotMap->pendingSlotAcknowledgedBy[i][j] = msg->senderId;
          break;
        };
      };
    };
  };
};

bool SlotMap_AddPendingSlot(Node node, int8_t slotNum, int8_t *neighborsArray, int8_t neighborsArraySize) {
  int8_t numPending = node->slotMap->numPendingSlots; // numPending is also the index of the first "free" element of the pendingSlots array
  if (numPending == MAX_NUM_PENDING_SLOTS) {
      return false; // cannot add another pending slot
  };

  node->slotMap->pendingSlots[numPending] = slotNum;
  node->slotMap->localTimePendingSlotAdded[numPending] = ProtocolClock_GetLocalTime(node->clock);

  // add the current neighbors to know which/how many nodes need to acknowledge the slot
  for(int j = 0; j < neighborsArraySize; ++j) {
    node->slotMap->pendingSlotsNeighbors[numPending][j] = neighborsArray[j];
  };

  node->slotMap->numPendingSlots = numPending + 1;
  return true;
};

bool SlotMap_ChangePendingToOwn(Node node, int8_t slotNum) {
  for(int i = 0; i < node->slotMap->numPendingSlots; ++i) {
    if (node->slotMap->pendingSlots[i] == slotNum) {
      // add to own slots
      int8_t numOwn = node->slotMap->numOwnSlots; // numOwn is also the index of the first "free" element of the ownSlots array
      node->slotMap->ownSlots[numOwn] = slotNum;
      ++node->slotMap->numOwnSlots;

      SlotMap_ReleasePendingSlot(node, slotNum);
      return true;
    };
  };
  return false;
};

bool SlotMap_OwnNetworkExists(Node node, int8_t *collidingSlots, int8_t collidingSlotsSize) {
  
  // check if another node in this network has reserved a slot;
  // if so, the creation was successful and this network exists
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->oneHopSlotsStatus[i] == OCCUPIED) {
      return true;
    };
  };

  // no other node has reserved a slot, so check if all own or pending slots are colliding
  // find own slots reported as colliding
  int8_t collidingOwnSlots[MAX_NUM_OWN_SLOTS];
  int8_t numCollidingOwnSlots = 0;
  for (int i = 0; i < collidingSlotsSize; ++i) {
    int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->ownSlots[0], collidingSlots[i], node->slotMap->numOwnSlots);
    if (idx != -1) {
      collidingOwnSlots[numCollidingOwnSlots] = node->slotMap->ownSlots[idx];
      ++numCollidingOwnSlots;
    };
  };

  // find pending slots reported as colliding
  int8_t collidingPendingSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numCollidingPendingSlots = 0;
  for (int i = 0; i < collidingSlotsSize; ++i) {
    int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->pendingSlots[0], collidingSlots[i], node->slotMap->numPendingSlots);
    if (idx != -1) {
      collidingPendingSlots[numCollidingPendingSlots] = node->slotMap->pendingSlots[idx];
      ++numCollidingPendingSlots;
    };
  };

  if ((node->slotMap->numOwnSlots == numCollidingOwnSlots) && (node->slotMap->numPendingSlots == numCollidingPendingSlots)) {
    // all own and pending slots are colliding, so the network does not exist
    return false;
  };
  // not all own and pending slots are colliding, so the network does exist
  return true;
};

bool SlotMap_ClearToSend(Node node) {
  int8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);
  // it is okay to send if the current slot is free, colliding or reserved by this node or if no frame has started (no network yet)
  return (SlotMap_SlotIsFreeForThisNode(node, currentSlot) || SlotMap_SlotIsColliding(node, currentSlot) || 
    SlotMap_IsOwnSlot(node, currentSlot) || SlotMap_IsPendingSlot(node, currentSlot) || currentSlot == 0);
};

bool SlotMap_SlotIsFree(Node node, int8_t slotNum) {
  // find all "three hop free" slots
  int8_t freeSlots[NUM_SLOTS];
  int8_t numFreeSlots = findFreeSlotsInThreeHopNeighborhood(node, &freeSlots[0]);

  // check if the queried slot is among the free slots
  int16_t idx = Util_Int8tArrayFindElement(&freeSlots[0], slotNum, numFreeSlots);
  if (idx != -1) {
    // slot was found (index is not -1), so it is free
    return true;
  };

  // slot was not found, so it is not free
  return false;
};

bool SlotMap_SlotIsFreeForThisNode(Node node, int8_t slotNum) {
  // find all "three hop free" slots and slots that are reported being occupied by this node
  int8_t freeSlots[NUM_SLOTS];
  int8_t numFreeSlots = findFreeForThisNodeSlotsInThreeHopNeighborhood(node, &freeSlots[0]);
  
  // check if the queried slot is among the free slots
  int16_t idx = Util_Int8tArrayFindElement(&freeSlots[0], slotNum, numFreeSlots);
  if (idx != -1) {
    // slot was found (index is not -1)
    return true;
  };

  // slot was not found, so it is not free
  return false;
};

bool SlotMap_SlotIsColliding(Node node, int8_t slotNum) {
  // find all colliding slots
  int8_t collidingSlots[NUM_SLOTS];
  int8_t numCollidingSlots = findCollidingSlotsInThreeHopNeighborhood(node, &collidingSlots[0]);

  // check if the queries slot is among the colliding slots
  int16_t idx = Util_Int8tArrayFindElement(&collidingSlots[0], slotNum, numCollidingSlots);
  if (idx != -1) {
    // slot was found (index is not -1), so it is colliding
    return true;
  };
  // slot was not found, so it is not colliding
  return false;
};

int8_t SlotMap_GetAcknowledgedPendingSlots(Node node, int8_t *buffer, int8_t size) {
  if(size < node->slotMap->numPendingSlots) {
    // buffer too small
    return -1;
  };
  int8_t numAcknowledged = 0;
  for(int i = 0; i < node->slotMap->numPendingSlots; ++i) {
    if (isAcknowledged(node, node->slotMap->pendingSlots[i])) {
      buffer[numAcknowledged] = node->slotMap->pendingSlots[i];
      ++numAcknowledged;
    };
  };
  return numAcknowledged;
};

int8_t SlotMap_GetPendingSlots(Node node, int8_t *buffer, int8_t size) {
  
  if(size < node->slotMap->numPendingSlots) {
    // buffer too small
    return -1;
  };
  
  for(int i = 0; i < node->slotMap->numPendingSlots; ++i) {
    buffer[i] = node->slotMap->pendingSlots[i];
  };
  return node->slotMap->numPendingSlots;
};

int8_t SlotMap_GetOwnSlots(Node node, int8_t *buffer, int8_t size) {
  if(size < node->slotMap->numOwnSlots) {
    // buffer too small
    return -1;
  };

  for(int i = 0; i < node->slotMap->numOwnSlots; ++i) {
    buffer[i] = node->slotMap->ownSlots[i];
  };
  return node->slotMap->numOwnSlots;
};

int64_t SlotMap_GetLastReservationTime(Node node) {
  return node->slotMap->lastReservationTime;
};

bool SlotMap_IsOwnSlot(Node node, int8_t slotNum) {
  // check if the queried slotNum is in the own slots array
  int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->ownSlots[0], slotNum, node->slotMap->numOwnSlots);
  if (idx == -1) {
    // slotNum was not found
    return false;
  };
  // slotNum was found
  return true;
};

bool SlotMap_IsPendingSlot(Node node, int8_t slotNum) {
  // check if the queried slotNum is in the pending slots array
  int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->pendingSlots[0], slotNum, node->slotMap->numPendingSlots);
  if (idx == -1) {
    // slotNum was not found
    return false;
  };
  // slotNum was found
  return true;
};

bool SlotMap_ReleaseOwnSlot(Node node, int8_t slotNum) {
  int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->ownSlots[0], slotNum, node->slotMap->numOwnSlots);
  if (idx == -1) {
    // slotNum is not own slot
    return false;
  };

  // remove from own
  // decrement numOwnSlots 
  int8_t newNumOwn = --node->slotMap->numOwnSlots; 
  // let last element of ownSlots array overwrite the own slot that has to be removed (as order is not important)
  node->slotMap->ownSlots[idx] = node->slotMap->ownSlots[newNumOwn]; 
  return true;
};

bool SlotMap_ReleasePendingSlot(Node node, int8_t slotNum) {
  int8_t idx = Util_Int8tArrayFindElement(&node->slotMap->pendingSlots[0], slotNum, node->slotMap->numPendingSlots);
  if (idx == -1) {
    // slotNum is not pending slot
    return false;
  };

  // remove from pending
  // decrement numPendingSlots 
  int8_t newNumPending = --node->slotMap->numPendingSlots; 
  // let last element of pendingSlots array overwrite the pending slot that has to be removed (as order is not important)
  node->slotMap->pendingSlots[idx] = node->slotMap->pendingSlots[newNumPending]; 
  // set the slot that has overwritten the other to -1 again
  node->slotMap->pendingSlots[newNumPending] = -1; 
  // make sure to do the same for the nodes who acknowledged or need to acknowledge the other pending slot
  for (int i = 0; i < (MAX_NUM_NODES - 1); ++i) {
    node->slotMap->pendingSlotAcknowledgedBy[idx][i] = node->slotMap->pendingSlotAcknowledgedBy[newNumPending][i];
    node->slotMap->pendingSlotAcknowledgedBy[newNumPending][i] = -1;
    node->slotMap->pendingSlotsNeighbors[idx][i] = node->slotMap->pendingSlotsNeighbors[newNumPending][i];
    node->slotMap->pendingSlotsNeighbors[newNumPending][i] = -1;
  };
  return true;
};

void SlotMap_RemoveExpiredSlotsFromOneHopSlotMap(Node node) {
  removeExpiredSlotsFromSlotMap(node, &node->slotMap->oneHopSlotsStatus[0], &node->slotMap->oneHopSlotsIds[0], &node->slotMap->oneHopSlotsLastUpdated[0]);
};

void SlotMap_RemoveExpiredSlotsFromTwoHopSlotMap(Node node) {
  removeExpiredSlotsFromSlotMap(node, &node->slotMap->twoHopSlotsStatus[0], &node->slotMap->twoHopSlotsIds[0], &node->slotMap->twoHopSlotsLastUpdated[0]);
};

void SlotMap_RemoveExpiredSlotsFromThreeHopSlotMap(Node node) {
  removeExpiredSlotsFromSlotMap(node, &node->slotMap->threeHopSlotsStatus[0], &node->slotMap->threeHopSlotsIds[0], &node->slotMap->threeHopSlotsLastUpdated[0]);
};

static void removeExpiredSlotsFromSlotMap(Node node, int *slotMapStatus, int8_t *slotMapIds, int64_t *slotMapLastUpdated) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);

  int32_t timeout = 0;
  // iterate over every slot in the slot map that was passed to this function and set the status to FREE
  // if the slot expired/timed out
  for(int i = 0; i < NUM_SLOTS; ++i) {
    int slotNum = i+1;
    if (SlotMap_IsOwnSlot(node, slotNum)) { 
      timeout = node->config->ownSlotExpirationTimeOut;
    } else {
      timeout = node->config->slotExpirationTimeOut;
    };

    if (localTime > (slotMapLastUpdated[i] + timeout) && slotMapLastUpdated[i] != 0) {
      #ifdef SIMULATION
      if (slotMapIds[i] != 0)
        mexPrintf("Node %" PRIu8 ": slot %" PRIu8 " of node %" PRIu8 " timed out \n", node->id, (i+1), slotMapIds[i]);
      #endif
      slotMapStatus[i] = FREE;
      slotMapIds[i] = 0;
    };
  };

};

int16_t SlotMap_RemoveExpiredPendingSlots(Node node, int8_t *buffer, int8_t size) {

  int8_t expiredPendingSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numExpiredPending = 0;
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  
  // find expired pending slots
  for(int i = 0; i < node->slotMap->numPendingSlots; ++i) {
    if (localTime > node->slotMap->localTimePendingSlotAdded[i] + node->config->ownSlotExpirationTimeOut) {
      #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 ": pending slot is expired: %" PRId64 "\n", localTime, node->id, node->slotMap->pendingSlots[i]);
      #endif

      expiredPendingSlots[numExpiredPending] = node->slotMap->pendingSlots[i];
      ++numExpiredPending;
    };
  };

  // do not remove if buffer is too small
  if (numExpiredPending > size) {
    return -1;
  };
  
  // release expired pending slots
  for(int i = 0; i < numExpiredPending; ++i) {
    SlotMap_ReleasePendingSlot(node, expiredPendingSlots[i]);

    // add removed slot to buffer
    buffer[i] = expiredPendingSlots[i];
  };
  return numExpiredPending;
};

int16_t SlotMap_RemoveExpiredOwnSlots(Node node, int8_t *buffer, int8_t size) {
  int8_t expiredOwnSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numExpiredOwn = 0;
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  
  // find expired own slots
  for(int i = 0; i < node->slotMap->numOwnSlots; ++i) {
    int8_t slotNum = node->slotMap->ownSlots[i];
    int64_t slotLastAcknowledged = node->slotMap->twoHopSlotsLastUpdated[slotNum - 1];

    if (localTime > (slotLastAcknowledged + node->config->ownSlotExpirationTimeOut)) {
      #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 ": own slot is expired: %" PRId8 " (last ack: %"PRId64 ")\n", localTime, node->id, node->slotMap->ownSlots[i], slotLastAcknowledged);
      #endif 
      expiredOwnSlots[numExpiredOwn] = node->slotMap->ownSlots[i];
      ++numExpiredOwn;
    };
  };

  // do not remove if buffer is too small
  if (numExpiredOwn > size) {
    return -1;
  };

  // release expired own slots
  for(int i = 0; i < numExpiredOwn; ++i) {
    SlotMap_ReleaseOwnSlot(node, expiredOwnSlots[i]);

    // add removed slot to buffer
    buffer[i] = expiredOwnSlots[i];  
  };
  return numExpiredOwn;
};

static bool isAcknowledged(Node node, int8_t queriedPendingSlot) {
  // loop over all pending slots until the pending slot is found
  for(int i = 0; i < MAX_NUM_PENDING_SLOTS; ++i) {
    if (node->slotMap->pendingSlots[i] == -1) {
      return false;
    };

    if (node->slotMap->pendingSlots[i] == queriedPendingSlot) {
      // check if enough neighbors have acknowledged the slot 
      // (number of neighbors at the time the slot was reserved need to acknowledge)

      int8_t numNeighborsThatNeedToAck = 0;
      for(int j = 0; j < (MAX_NUM_NODES - 1); ++j) {
        if (node->slotMap->pendingSlotsNeighbors[i][j] == -1) {
          numNeighborsThatNeedToAck = j;
          break;
        };
      };

      // then get number of neighbors who actually acked
      int8_t numNeighborsThatHaveAcked = 0;
      for(int j = 0; j < (MAX_NUM_NODES - 1); ++j) {
        if (node->slotMap->pendingSlotAcknowledgedBy[i][j] == -1) {
          numNeighborsThatHaveAcked = j;
          break;
        };
      };
      
      if (numNeighborsThatHaveAcked >= numNeighborsThatNeedToAck) {
        return true;
      } else {
        return false;
      };
    };
  };
};

void SlotMap_ExtendTimeouts(Node node) {
  // extend the timeout by the time the nodes sleep at max
  int64_t extensionTime = (node->config->frameLength * node->config->sleepFrames);

  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->oneHopSlotsStatus[i] != FREE) {
      node->slotMap->oneHopSlotsLastUpdated[i] += extensionTime;
    };

    if (node->slotMap->twoHopSlotsStatus[i] != FREE) {
      node->slotMap->twoHopSlotsLastUpdated[i] += extensionTime;
    };

    if (node->slotMap->threeHopSlotsStatus[i] != FREE) {
      node->slotMap->threeHopSlotsLastUpdated[i] += extensionTime;
    };
  };
};

static bool oneHopSlotIsExpired(Node node, int8_t currentSlot, int64_t timeout) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // slot is expired if local time is bigger or equal than when the slot was last updated plus the timeout
  return (localTime >= (node->slotMap->oneHopSlotsLastUpdated[currentSlot - 1] + timeout));
};

static bool multiHopSlotIsExpired(Node node, int8_t currentSlot, int64_t timeout, int64_t *multiHopLastUpdated) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // slot is expired if local time is bigger or equal than when the slot was last updated plus the timeout
  return (localTime >= (multiHopLastUpdated[currentSlot - 1] + timeout));
};

static void updateMultiHopSlotMap(Node node, Message msg, int *multiHopSlotMapStatus, int8_t *multiHopSlotMapIds, int64_t *multiHopSlotMapLastUpdate) {
  // this function is used to update either two- or three-hop slot map (depending on which slot map is passed) to avoid code duplication

  // iterate over all slots
  for(int slotIdx = 0; slotIdx < NUM_SLOTS; ++slotIdx) {
    // get current status and ID of the slot
    int currentStatus = multiHopSlotMapStatus[slotIdx];
    int8_t currentId = multiHopSlotMapIds[slotIdx];
    // get status and ID of the slot from the message
    int newStatus = msg->multiHopStatus[slotIdx];
    int8_t newId = msg->multiHopIds[slotIdx];

    // first check if one hop and two hop are reported occupied by different nodes; if so, set slot to colliding
    // in order to avoid a deadlock in certain situations
    if (msg->oneHopSlotStatus[slotIdx] == OCCUPIED && msg->twoHopSlotStatus[slotIdx] == OCCUPIED) {
      if (msg->oneHopSlotIds[slotIdx] != msg->twoHopSlotIds[slotIdx]) {
        multiHopSlotMapStatus[slotIdx] = COLLIDING;
        multiHopSlotMapIds[slotIdx] = 0;
        multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
        continue;
      };
    };
    
    switch(newStatus) {
      case OCCUPIED:
        switch(currentStatus) {
          case FREE:
            // current status is FREE, new status is OCCUPIED: update immediately
            multiHopSlotMapStatus[slotIdx] = newStatus;
            multiHopSlotMapIds[slotIdx] = newId;
            multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
            break;
          case OCCUPIED:
            // current status is OCCUPIED, new status is OCCUPIED
            if(newId == currentId) {
              // same node that already reserved the slot, so only update time
              multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
            } else {
              // newly reported node is different from node that reserved the slot so far
              if(multiHopSlotIsExpired(node, slotIdx+1, node->config->occupiedTimeout, multiHopSlotMapLastUpdate)) {
                // old reservation is expired, so overwrite with new one
                multiHopSlotMapStatus[slotIdx] = newStatus;
                multiHopSlotMapIds[slotIdx] = newId;
                multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
              } else {
                // old reservation is still valid; two different nodes are reported to occupy the same slot, so set it to COLLIDING
                multiHopSlotMapStatus[slotIdx] = COLLIDING;
                multiHopSlotMapIds[slotIdx] = 0;
                multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
              };
            };
            break;
          case COLLIDING:
            // current status is COLLIDING, new status is OCCUPIED
            // if colliding report of slot is expired, overwrite it; otherwise, do nothing
            if(multiHopSlotIsExpired(node, slotIdx+1, node->config->collidingTimeoutMultiHop, multiHopSlotMapLastUpdate)) {
              multiHopSlotMapStatus[slotIdx] = newStatus;
              multiHopSlotMapIds[slotIdx] = newId;
              multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
            };
            break;
        };
        
        int8_t slot = slotIdx + 1;
        bool slotIsOwnSlot = SlotMap_IsOwnSlot(node, slot);
        bool slotIsPendingSlot = SlotMap_IsPendingSlot(node, slot);
        
        // if slot is own or pending slot but reported occupied by another node, set it to colliding to
        // prevent deadlocks and instead make it reservable again
        if(slotIsOwnSlot || slotIsPendingSlot) {
          if(newId != node->id) {
            multiHopSlotMapStatus[slotIdx] = COLLIDING;
            multiHopSlotMapIds[slotIdx] = 0;
            multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
          };
        };
        break;

      case COLLIDING:
        // newly reported status is COLLIDING, so overwrite slot immediately
        multiHopSlotMapStatus[slotIdx] = newStatus;
        multiHopSlotMapIds[slotIdx] = 0;
        multiHopSlotMapLastUpdate[slotIdx] = ProtocolClock_GetLocalTime(node->clock);
        break;
      case FREE:
        // newly reported status is FREE; only overwrite if current status of slot is expired
        if(multiHopSlotIsExpired(node, slotIdx+1, node->config->occupiedToFreeTimeoutMultiHop, multiHopSlotMapLastUpdate)) {
          #ifdef SIMULATION
            #if DEBUG_VERBOSE
              mexPrintf("Node %" PRIu8 " multi hop slot is expired: %d \n", node->id, (slotIdx + 1));
            #endif
          #endif
          multiHopSlotMapStatus[slotIdx] = newStatus;
          multiHopSlotMapIds[slotIdx] = 0;
        };
        break;
    };
  };
};

static bool slotReportedColliding(Message msg, int8_t slotNum) {
  // slot is reported colliding if it is colliding in one and/or two hop slot map of the message
  if (msg->oneHopSlotStatus[slotNum - 1] == COLLIDING || msg->twoHopSlotStatus[slotNum - 1] == COLLIDING) {
    return true;
  };

  return false;
};

static bool slotReportedOccupiedByOtherNode(Node node, Message msg, int8_t slotNum) {
  // slot is reported occupied by another node if it is occupied in one and/or two hop slot map
  // and the corresponding ID is not this node's ID
  if (((msg->oneHopSlotStatus[slotNum - 1] == OCCUPIED) && (msg->oneHopSlotIds[slotNum - 1] != node->id)) ||
    ((msg->twoHopSlotStatus[slotNum - 1] == OCCUPIED) && (msg->twoHopSlotIds[slotNum - 1] != node->id))) {
    return true;
  };
  return false;
};

static int8_t findFreeSlotsInThreeHopNeighborhood(Node node, int8_t *freeSlots) {
  
  // first find free slots in the individual slot maps
  int8_t oneHopFreeSlots[NUM_SLOTS];
  int8_t numOneHopFree = 0;
  int8_t twoHopFreeSlots[NUM_SLOTS];
  int8_t numTwoHopFree = 0;
  int8_t threeHopFreeSlots[NUM_SLOTS];
  int8_t numThreeHopFree = 0;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    int slotNum = i+1;
    if (node->slotMap->oneHopSlotsStatus[i] == FREE) {
      oneHopFreeSlots[numOneHopFree] = slotNum;
      ++numOneHopFree;
    };

    if (node->slotMap->twoHopSlotsStatus[i] == FREE) {
      twoHopFreeSlots[numTwoHopFree] = slotNum;
      ++numTwoHopFree;
    };

    if (node->slotMap->threeHopSlotsStatus[i] == FREE) {
      threeHopFreeSlots[numThreeHopFree] = slotNum;
      ++numThreeHopFree;
    };
  };

  // slot is truly free if it is free in all three slot maps, so we need the intersection (common elements of arrays)
  // intersect one and two hop
  int8_t intersectionOneHopTwoHop[NUM_SLOTS];
  int16_t numCommonOneHopTwoHop = Util_IntersectSortedInt8tArrays(&oneHopFreeSlots[0], numOneHopFree, &twoHopFreeSlots[0], numTwoHopFree, &intersectionOneHopTwoHop[0]);

  // intersect again with three hop
  int16_t numFreeSlots = Util_IntersectSortedInt8tArrays(&intersectionOneHopTwoHop[0], numCommonOneHopTwoHop, &threeHopFreeSlots[0], numThreeHopFree, freeSlots);
  return numFreeSlots;
};

static int8_t findFreeForThisNodeSlotsInThreeHopNeighborhood(Node node, int8_t *freeSlots) {
  // find slots that are either free or reported occupied by this node, so that this node can safely use them
  int8_t oneHopFreeSlots[NUM_SLOTS];
  int8_t numOneHopFree = 0;
  int8_t twoHopFreeSlots[NUM_SLOTS];
  int8_t numTwoHopFree = 0;
  int8_t threeHopFreeSlots[NUM_SLOTS];
  int8_t numThreeHopFree = 0;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    int slotNum = i+1;

    bool oneHopReportedOccupiedByThisNode = (node->slotMap->oneHopSlotsStatus[i] == OCCUPIED && node->slotMap->oneHopSlotsIds[i] == node->id);
    if (node->slotMap->oneHopSlotsStatus[i] == FREE || oneHopReportedOccupiedByThisNode) {
      oneHopFreeSlots[numOneHopFree] = slotNum;
      ++numOneHopFree;
    };

    bool twoHopReportedOccupiedByThisNode = (node->slotMap->twoHopSlotsStatus[i] == OCCUPIED && node->slotMap->twoHopSlotsIds[i] == node->id);
    if (node->slotMap->twoHopSlotsStatus[i] == FREE || twoHopReportedOccupiedByThisNode) {
      twoHopFreeSlots[numTwoHopFree] = slotNum;
      ++numTwoHopFree;
    };

    bool threeHopReportedOccupiedByThisNode = (node->slotMap->threeHopSlotsStatus[i] == OCCUPIED && node->slotMap->threeHopSlotsIds[i] == node->id);
    if (node->slotMap->threeHopSlotsStatus[i] == FREE || threeHopReportedOccupiedByThisNode) {
      threeHopFreeSlots[numThreeHopFree] = slotNum;
      ++numThreeHopFree;
    };
  };

  // slot is truly free if it is free in all three slot maps, so we need the intersection (common elements of arrays)
  // intersect one and two hop
  int8_t intersectionOneHopTwoHop[NUM_SLOTS];
  int16_t numCommonOneHopTwoHop = Util_IntersectSortedInt8tArrays(&oneHopFreeSlots[0], numOneHopFree, &twoHopFreeSlots[0], numTwoHopFree, &intersectionOneHopTwoHop[0]);

  // intersect again with three hop
  int16_t numFreeSlots = Util_IntersectSortedInt8tArrays(&intersectionOneHopTwoHop[0], numCommonOneHopTwoHop, &threeHopFreeSlots[0], numThreeHopFree, freeSlots);
  return numFreeSlots;
};

static int8_t findCollidingSlotsInThreeHopNeighborhood(Node node, int8_t *collidingSlots) {
  // find slots that are colliding in at least one of the slot maps, but at the same time not occupied in any of the other two 
  // by a node other than this, because then they are not reservable by this node

  int8_t oneHopCollidingSlots[NUM_SLOTS];
  int8_t numOneHopColliding = 0;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->oneHopSlotsStatus[i] == COLLIDING) {
      // check if slot is not occupied by another node than this in the other two slot maps
      bool twoHopNotOccupied = (node->slotMap->twoHopSlotsStatus[i] != OCCUPIED) || node->slotMap->twoHopSlotsIds[i] == node->id;
      bool threeHopNotOccupied = (node->slotMap->threeHopSlotsStatus[i] != OCCUPIED) || node->slotMap->threeHopSlotsIds[i] == node->id;

      if (twoHopNotOccupied && threeHopNotOccupied) {
        oneHopCollidingSlots[numOneHopColliding] = i+1;
        ++numOneHopColliding;
      };
    };
  };

  int8_t twoHopCollidingSlots[NUM_SLOTS];
  int8_t numTwoHopColliding = 0;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->twoHopSlotsStatus[i] == COLLIDING) {
      // check if slot is not occupied by another node than this in the other two slot maps
      bool oneHopNotOccupied = (node->slotMap->oneHopSlotsStatus[i] != OCCUPIED) || node->slotMap->oneHopSlotsIds[i] == node->id;
      bool threeHopNotOccupied = (node->slotMap->threeHopSlotsStatus[i] != OCCUPIED) || node->slotMap->threeHopSlotsIds[i] == node->id;

      if (oneHopNotOccupied && threeHopNotOccupied) {
        twoHopCollidingSlots[numTwoHopColliding] = i+1;
        ++numTwoHopColliding;
      };
    };
  };

  int8_t threeHopCollidingSlots[NUM_SLOTS];
  int8_t numThreeHopColliding = 0;
  for (int i = 0; i < NUM_SLOTS; ++i) {
    if (node->slotMap->threeHopSlotsStatus[i] == COLLIDING) {
      // check if slot is not occupied by another node than this in the other two slot maps
      bool oneHopNotOccupied = (node->slotMap->oneHopSlotsStatus[i] != OCCUPIED) || node->slotMap->oneHopSlotsIds[i] == node->id;
      bool twoHopNotOccupied = (node->slotMap->twoHopSlotsStatus[i] != OCCUPIED) || node->slotMap->twoHopSlotsIds[i] == node->id;

      if (oneHopNotOccupied && twoHopNotOccupied) {
        threeHopCollidingSlots[numThreeHopColliding] = i+1;
        ++numThreeHopColliding;
      };
    };
  };

  // get union of the colliding slots of all slot maps
  memcpy(collidingSlots, &oneHopCollidingSlots[0], sizeof(int8_t) * numOneHopColliding);
  int8_t numCollidingSlots = numOneHopColliding;
  
  // add colliding slots from two hop slot map that are not in already
  for (int i = 0; i < numTwoHopColliding; ++i) {
    int8_t element = twoHopCollidingSlots[i];
    int8_t idx = Util_Int8tArrayFindElement(collidingSlots, element, numCollidingSlots);
    if (idx == -1) {
      collidingSlots[numCollidingSlots] = element;
      ++numCollidingSlots;
    };
  };

  // add colliding slots from three hop slot map that are not in already
  for (int i = 0; i < numThreeHopColliding; ++i) {
    int8_t element = threeHopCollidingSlots[i];
    int8_t idx = Util_Int8tArrayFindElement(collidingSlots, element, numCollidingSlots);
    if (idx == -1) {
      collidingSlots[numCollidingSlots] = element;
      ++numCollidingSlots;
    };
  };

  return numCollidingSlots;
};

static int8_t getNextSlotFromSelection(Node node, int8_t *selection, int8_t size) {
  // from a selection of slots, get the one that comes next
  int8_t currentSlot = TimeKeeping_CalculateCurrentSlotNum(node);

  // array to hold all distances of the slots in the selection to the current slot 
  int8_t distanceFromCurrentSlot[MAX_NUM_PENDING_SLOTS + MAX_NUM_OWN_SLOTS];
  
  // calculate the distance in slots from the current slot
  for(int i = 0; i < size; ++i) {
    distanceFromCurrentSlot[i] = selection[i] - currentSlot;
    // slot is in the next frame, so add number of slots per frame to it
    if (distanceFromCurrentSlot[i] <= 0) {
      distanceFromCurrentSlot[i] += NUM_SLOTS;
    };
  };

  int8_t minIdx = (int8_t) Util_Int8tFindIdxOfMinimumInArray(&distanceFromCurrentSlot[0], size);

  if (minIdx == -1) {
    return -1;
  };

  return selection[minIdx];
};

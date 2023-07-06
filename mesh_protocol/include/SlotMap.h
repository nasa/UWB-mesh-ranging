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

/** @file SlotMap.h
*   @brief Maintains all internal slot maps
*
*   Struct contains all internal slot maps, which contain information about which slots are free, 
*   occupied or colliding, the nodes that reserved them and when the status was last updated. It 
*   also maintains the pending slots of this node (slot that were reserved but not yet acknowledged)
*   and the own slots (reserved and acknowledged). The functions are used to update the slot maps based
*   on the current status and other parameters.
*
*/

#ifndef SLOT_MAP_H
#define SLOT_MAP_H

#include <string.h>

#include "Constants.h"
#include "Node.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"
#include "Util.h"
#include "Config.h"
#include "RandomNumbers.h"

#ifdef SIMULATION
#include "mex.h"
#endif

enum SlotOccupancy {
  FREE, OCCUPIED, COLLIDING
};

typedef struct SlotMapStruct * SlotMap;

typedef enum SlotOccupancy SlotOccupancy;

/** 
* ONE HOP SLOT MAP
* One hop means all nodes that are in direct range of this node; if one of these nodes sends a message, this node receives it
* The one hop slot map of this node is included in its pings, so other nodes can update their two hop slot maps based on it (to make sure they do not reserve
* slots that are already reserved anywhere in their two hop neighborhood, as these can lead to collisions of pings and ranging messages)
*
* oneHopSlotsStatus: status of the slots as directly perceived by this node (FREE: no one hop neighbor uses the slot;
*   OCCUPIED: one neighbor has reserved the slot; COLLIDING: a collision was received in this slot, so more than one neighbor wanted to use it)
* oneHopSlotsIds: IDs of the node that uses the corresponding slot; 0 if slot is FREE or COLLIDING
* oneHopSlotsLastUpdated: last time a ping was received in an OCCUPIED slot or a collision was perceived in a COLLIDING slot
*
* TWO HOP SLOT MAP
* Two hop means nodes that are neighbors of one hop neighbors, but not the neighbors themselves; this includes this node, as it is a neighbor of its neighbors;
* this node does not receive messages from its two hop neighbors directly.
* The two hop slot map of this node is included in its pings, so other nodes can update their three hop slot maps based on it (to make sure they do not reserve
* slots that are already reserved anywhere in their three hop neighborhood, as these can lead to collisions of ranging messages)
*
* twoHopSlotsStatus: same as oneHopSlotsStatus, only for two hop neighbors
* twoHopSlotsIds: same as oneHopSlotsIds, only for two hop neighbors
* twoHopSlotsLastUpdated: same as oneHopSlotsLastUpdated, only for two hop neighbors
*
* THREE HOP SLOT MAP
* Three hop means nodes that are neighbors of two hop neighbors of this node
* The three hop slot map of this node is not included in its pings, as nodes are allowed to reserve slots that are already reserved in their four hop 
* neighborhood, as these cannot lead to collisions
*
* threeHopSlotsStatus: same as oneHopSlotsStatus, only for three hop neighbors
* threeHopSlotsIds: same as oneHopSlotsIds, only for three hop neighbors
* threeHopSlotsLastUpdated: same as oneHopSlotsLastUpdated, only for three hop neighbors
*
* pendingSlots: array of slots that this node reserved but that were not acknowledged yet; 
* numPendingSlots: number of pending slots of this node
* pendingSlotsNeighbors: ID of the neighbors of the node at the time the corresponding pending slot was added; 
*   these neighbors need to acknowledge the pending slot. Note: currently only the number of the acknowledgements is checked, but not the ID (simpler version)
* localTimePendingSlotAdded: contains local time the corresponding pending slot was added
* pendingSlotAcknowledgedBy: contains neighbors that have acknowledged the corresponding slot
* ownSlots: array of slots this node reserved that were acknowledged 
* numOwnSlots: number of own slots of this node
* collisionTimes: local times when this node received collisions; deleted regularly if older than one frame; 
* used to signal collisions to other nodes when this node is not in a network and therefore does not know slot numbers of colliding slots
* numCollisionsRecorded: number of collisions in collisionTimes 
* lastReservationTime: local time of the last time another node tried to reserve a slot (used for duty cycling)
*/
typedef struct SlotMapStruct {
  int oneHopSlotsStatus[NUM_SLOTS];
  int8_t oneHopSlotsIds[NUM_SLOTS];
  int64_t oneHopSlotsLastUpdated[NUM_SLOTS];

  int twoHopSlotsStatus[NUM_SLOTS];
  int8_t twoHopSlotsIds[NUM_SLOTS];
  int64_t twoHopSlotsLastUpdated[NUM_SLOTS];

  int threeHopSlotsStatus[NUM_SLOTS];
  int8_t threeHopSlotsIds[NUM_SLOTS];
  int64_t threeHopSlotsLastUpdated[NUM_SLOTS];

  int8_t pendingSlots[MAX_NUM_PENDING_SLOTS];
  int8_t numPendingSlots;
  int8_t pendingSlotsNeighbors[MAX_NUM_PENDING_SLOTS][MAX_NUM_NODES - 1]; // for every pending slot: IDs of neighbors at the time the slot was added (neighbors that need to acknowledge)
  int64_t localTimePendingSlotAdded[MAX_NUM_PENDING_SLOTS];
  int8_t pendingSlotAcknowledgedBy[MAX_NUM_PENDING_SLOTS][MAX_NUM_NODES - 1];

  int8_t ownSlots[MAX_NUM_OWN_SLOTS];
  int8_t numOwnSlots;

  int64_t lastReservationTime;
} SlotMapStruct;

/** Constructor */
SlotMap SlotMap_Create();

/** Update the one hop slot map of this node based on information in a ping of another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
* @param currentSlot is the current slot at the time this message was received  
*/
void SlotMap_UpdateOneHopSlotMap(Node node, Message msg, int8_t currentSlot);

/** Update the two hop slot map of this node based on information in a ping of another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
*/
void SlotMap_UpdateTwoHopSlotMap(Node node, Message msg);

/** Update the two hop slot map of this node based on information in a ping of another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
*/
void SlotMap_UpdateThreeHopSlotMap(Node node, Message msg);

/** Get the one hop status of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the status should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the status; false if it failed
*/
bool SlotMap_GetOneHopSlotMapStatus(Node node, int *buffer, int8_t size);

/** Get the one hop IDs of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the IDs should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the Ids; false if it failed
*/
bool SlotMap_GetOneHopSlotMapIds(Node node, int8_t *buffer, int8_t size);

/** Get the one hop last updated time of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the time should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the times; false if it failed
*/
bool SlotMap_GetOneHopSlotMapLastUpdated(Node node, int64_t *buffer, int8_t size);

/** Get the two hop status of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the status should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the status; false if it failed
*/
bool SlotMap_GetTwoHopSlotMapStatus(Node node, int *buffer, int8_t size);

/** Get the two hop IDs of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the IDs should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the IDs; false if it failed
*/
bool SlotMap_GetTwoHopSlotMapIds(Node node, int8_t *buffer, int8_t size);

/** Get the three hop status of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the status should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the status; false if it failed
*/
bool SlotMap_GetThreeHopSlotMapStatus(Node node, int *buffer, int8_t size);

/** Get the three hop IDs of all slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the IDs should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return true if buffer contains the IDs; false if it failed
*/
bool SlotMap_GetThreeHopSlotMapIds(Node node, int8_t *buffer, int8_t size);

/** Checks if own slots are reported as colliding or occupied by a different node in a ping message of another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
* @param buffer is a pointer to a buffer where the slot numbers of the colliding own slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return number of colliding own slots
*/
int8_t SlotMap_CheckOwnSlotsForCollisions(Node node, Message msg, int8_t *buffer, int8_t size);

/** Checks if pending slots are reported as colliding or occupied by a different node in a ping message of another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
* @param buffer is a pointer to a buffer where the slot numbers of the colliding pending slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return number of colliding pending slots
*/
int8_t SlotMap_CheckPendingSlotsForCollisions(Node node, Message msg, int8_t *buffer, int8_t size);

/** Check if this node has reserved enough slots
* @param node is the Node struct of the node that should perform this action
* return true if no further slots should be reserved by this node; return false otherwise
*/
bool SlotMap_SlotReservationGoalMet(Node node);

/** Get the slot number of a slot than can be reserved by this node
* @param node is the Node struct of the node that should perform this action
* return slot number of a reservable slot or -1 if there are no reservable slots
*
* If there are more than one reservable slots, one of them is chosen randomly
*/
int8_t SlotMap_GetReservableSlot(Node node);

/** Calculate the slot number of either the next own or pending slot, whichever comes first
* @param node is the Node struct of the node that should perform this action
* @param currentSlot is the slot number of the current slot
* return slot number of the next own or pending slot or -1 if there are no own and pending slots
*/
int8_t SlotMap_CalculateNextOwnOrPendingSlotNum(Node node, int8_t currentSlot);

/** Update pending slots based on a ping message from another node
* @param node is the Node struct of the node that should perform this action
* @param msg is a ping message from another node
*
* This function checks if a pending slot was acknowledged by the node that sent the message (if it is contained in its one hop slot map)
* and if so adds the acknowledgement; once all necessary acknowledgements are there, the slot can be added to own slots (uding a different function)
*/
void SlotMap_UpdatePendingSlotAcks(Node node, Message msg);

/** Add a slot to the pending slots
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot to be added
* @param neighborsArray is a pointer to an array containing the IDs of the current one hop neighbors of the node
* @param arraySize is the size of the array (to avoid illegal memory access)
* returns true if the slot was added or false if it could not be added (maximum number of pending slots reached)
*/
bool SlotMap_AddPendingSlot(Node node, int8_t slotNum, int8_t *neighborsArray, int8_t neighborsArraySize);

/** Change pending slot to own slot
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the pending slot that should be made an own slot
* return true if the slot was added to own or false if the slot was not a pending slot
*/
bool SlotMap_ChangePendingToOwn(Node node, int8_t slotNum);

/** Check if the network created by this node was actually successfully created
* @param node is the Node struct of the node that should perform this action
* @param collidingSlots is a pointer to an array containing the slots reported colliding by another node
* @param collidingSlotsSize is the size of the array (to avoid illegal memory access)
* return true if the network was created successfully; false if node cannot be sure that any other node received the initial ping of this node
*
* Checks if all own slots are colliding and no other node reserved a slot, which means this node cannot be 
* sure that the network really exists (meaning any other node actually received a message from this node)
*/
bool SlotMap_OwnNetworkExists(Node node, int8_t *collidingSlots, int8_t collidingSlotsSize);

/** Checks if this slot can be used to send a ping
* @param node is the Node struct of the node that should perform this action
*
* It is okay to send if the current slot is free, colliding or reserved by this node or if no frame has started (no network yet)
*/
bool SlotMap_ClearToSend(Node node);

/** Checks if a slot is free in a three hop neighborhood
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot that should be checked
* return true if slot is free; false otherwise
* 
* Check is based on all informations in the slot maps
*/
bool SlotMap_SlotIsFree(Node node, int8_t slotNum);

/** Checks if a slot is free for this node in a three hop neighborhood
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot that should be checked
* return true if slot is free or reported as being occupied by this node; false otherwise
* 
* "free for this node" means the slot can either be free or being reported occupied by this node in
* any of the slot maps; it is then also fine for this node to use the slot
*/
bool SlotMap_SlotIsFreeForThisNode(Node node, int8_t slotNum);

/** Checks if a slot is colliding in a three hop neighborhood
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot that should be checked
* return true if slot is colliding; false otherwise
*
* Check is based on all informations in the slot maps
*/
bool SlotMap_SlotIsColliding(Node node, int8_t slotNum);

/** Get all pending slots of this node that were acknowledged
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the acknowledged pending slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return the number of acknowledged pending slots or -1 if buffer is too small
*/
int8_t SlotMap_GetAcknowledgedPendingSlots(Node node, int8_t *buffer, int8_t size);

/** Get all pending slots of this node
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the pending slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return the number of pending slots
*/
int8_t SlotMap_GetPendingSlots(Node node, int8_t *buffer, int8_t size);

/** Get all own slots of this node
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the own slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return the number of own slots
*/
int8_t SlotMap_GetOwnSlots(Node node, int8_t *buffer, int8_t size);

/** Remove all collisions from collisionTimes that are older than a certain period of time
* @param node is the Node struct of the node that should perform this action
*/
void SlotMap_RemoveOutdatedCollisions(Node node);

/** Get the last time another node tried to reserve a new slot
* @param node is the Node struct of the node that should perform this action
*/
int64_t SlotMap_GetLastReservationTime(Node node);

/** Check if slot is own slot
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot to be checked
*/
bool SlotMap_IsOwnSlot(Node node, int8_t slotNum);

/** Check if slot is pending slot
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot to be checked
*/
bool SlotMap_IsPendingSlot(Node node, int8_t slotNum);

/** Remove slot from own slots
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot to be removed
* return true if slot was released or false if it was not an own slot
*/
bool SlotMap_ReleaseOwnSlot(Node node, int8_t slotNum);

/** Remove slot from pending slots
* @param node is the Node struct of the node that should perform this action
* @param slotNum is the number of the slot to be removed
* return true if slot was released or false if it was not a pending slot
*/
bool SlotMap_ReleasePendingSlot(Node node, int8_t slotNum);

/** Remove all expired slots from one hop slot map
* @param node is the Node struct of the node that should perform this action
* 
* Slots are expired if they timed out (see config for value)
*/
void SlotMap_RemoveExpiredSlotsFromOneHopSlotMap(Node node);

/** Remove all expired slots from two hop slot map
* @param node is the Node struct of the node that should perform this action
* 
* Slots are expired if they timed out (see config for value)
*/
void SlotMap_RemoveExpiredSlotsFromTwoHopSlotMap(Node node);

/** Remove all expired slots from three hop slot map
* @param node is the Node struct of the node that should perform this action
* 
* Slots are expired if they timed out (see config for value)
*/
void SlotMap_RemoveExpiredSlotsFromThreeHopSlotMap(Node node);

/** Remove all expired pending slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the removed pending slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return number of removed pending slots
*/
int16_t SlotMap_RemoveExpiredPendingSlots(Node node, int8_t *buffer, int8_t size);

/** Remove all expired own slots
* @param node is the Node struct of the node that should perform this action
* @param buffer is a pointer to a buffer where the removed own slots should be stored
* @param size is the size of the buffer (to avoid illegal memory access)
* return number of removed own slots
*/
int16_t SlotMap_RemoveExpiredOwnSlots(Node node, int8_t *buffer, int8_t size);

/** Extend timeouts of slots after the node has slept
* @param node is the Node struct of the node that should perform this action
* 
* During sleeping, all slots would usually expire, that's why the timeouts have to be extended when the node
* wakes up
*/
void SlotMap_ExtendTimeouts(Node node);


#endif

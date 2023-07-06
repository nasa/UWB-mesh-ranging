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

#ifndef MESSAGE_H
#define MESSAGE_H

#include "Constants.h"
#include "Node.h"

/** Types a message can have */
enum MessageTypes {
  PING, COLLISION, POLL, RESPONSE, FINAL, RESULT
};

/** Time it takes to transmit a message in time tics
* This is NOT time of flight but the time that it takes to transmit the message with a given data rate.
* Should be set to realistic values depending on the actual data size of the different messages and the transmission rate of the UWB modem
*/
enum MessageSizes {
  // in time tics
  PING_SIZE = 20, POLL_SIZE = 9, RESPONSE_SIZE = 12, FINAL_SIZE = 15, RESULT_SIZE = 2, WAITTIME = 4
};

typedef struct MessageStruct * Message;
typedef enum MessageTypes MessageTypes;
typedef enum MessageSizes MessageSizes;

/** 
* type: MessageTypes type of the message
* senderId: Node ID of the sender of the message
* recipientId: Node ID of the intended recipient of the message (only for POLL, RESPONSE, FINAL and RESULT)
* timestamp: local time of the receiving node at the time the message would arrive at the antenna in reality (preamble, NOT when the message is complete); 
*   determined and added by MATLAB simulation
* networkId: ID of the network the sending node belongs to
* networkAge: age of the network the sending node belongs to as calculated by the sending node (in time tics)
* timeSinceFrameStart: time tics since beginning of the current frame as counted by the sending node 
* oneHopSlotStatus: array of the status of each slot as directly perceived ("one hop") by the sending node; see enum "SlotOccupancy" in SlotMap.h for possible values
* oneHopSlotIds: array of the ID of nodes occupying each slot; 0 if slot is FREE
* twoHopSlotStatus: array of the status of each slot as reported by neighbors ("two hop") of the sending node; see enum "SlotOccupancy" in SlotMap.h for possible values
* twoHopSlotIds: array of the ID of nodes reported occupying each slot; 0 if slot is FREE
* collisionTimes: array of "number of time tics before the sending time of the message" at which collisions were received; used to report collisions to nodes in other networks
*   (cause their slots are likely shifted) or when the sending node does not belong to a network yet
* numCollisions: size of the collision times array
* multiHopStatus: can either hold oneHopSlotStatus or twoHopSlotStatus; only used internally and not set by the nodes
* multiHopIds: can either hold oneHopSlotIds or twoHopSlotIds; only used internally and not set by the nodes
*/
typedef struct MessageStruct {
  MessageTypes type;
  int8_t senderId;
  int8_t recipientId;
  int64_t timestamp;                  // timestamp of arrival 
  uint8_t networkId;
  int64_t networkAge;                 // network age at time of sending (not at completion of the message - therefore arrival of preamble is used later)
  int64_t timeSinceFrameStart;
  int oneHopSlotStatus[NUM_SLOTS];
  int8_t oneHopSlotIds[NUM_SLOTS];
  int twoHopSlotStatus[NUM_SLOTS];
  int8_t twoHopSlotIds[NUM_SLOTS];
  int64_t collisionTimes[MAX_NUM_COLLISIONS_RECORDED];  // used to report collisions to foreign networks (contains time since the collision happened, so it is independent of slot synchronization)
  int8_t numCollisions;               // number of collision times actually contained in the message
  double distance;
  int16_t pingNum;

  // used to give the driver access to the received ranging message
  uint8_t* rx_buffer;
  uint32_t frame_len;

  // used internally to hold two- or three-hop maps:
  int *multiHopStatus; // this is only a pointer to one of the other arrays, not an array itself
  int8_t *multiHopIds;
} MessageStruct;

/** Constructor
* @param t is the type of the message to be created
*/
Message Message_Create(MessageTypes t);

/** Destructor
* Messages need to be destroyed at certain points, otherwise memory will leak
*/
void Message_Destroy(Message self);
#endif

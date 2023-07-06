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

#include "../include/StateActions.h"

void StateActions_ListeningUnconnectedIncomingMsgAction(Node node, Message msg) {
    switch(msg->type) {
      case PING: ;
        #ifdef SIMULATION
        int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
        mexPrintf("%" PRId64 ":Node %" PRIu8 " received ping from Node %" PRIu8 " in slot %" PRIu8 "\n", localTime, node->id, msg->senderId, TimeKeeping_CalculateCurrentSlotNum(node));
        #endif
        MessageHandler_HandlePingUnconnected(node, msg);
        break;
    };
};

void StateActions_ListeningUnconnectedTimeTicAction(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  
  // check if the initial wait time (time to check if there are already networks) is over
  bool waitTimeOver = TimeKeeping_InitialWaitTimeOver(node);
  bool nothingScheduled = Scheduler_NothingScheduledYet(node);

  // if the wait time is over and no ping is scheduled, schedule an initial ping
  if (waitTimeOver && nothingScheduled) {
    Scheduler_ScheduleNextPing(node);
  };
  
  // in case a schedule was missed, cancel the schedule
  int64_t timeNextSchedule = Scheduler_GetTimeOfNextSchedule(node);
  if (localTime > timeNextSchedule && timeNextSchedule != -1) {
    Scheduler_CancelScheduledPing(node);
  };
};

void StateActions_ListeningConnectedTimeTicAction(Node node) {

  bool nothingScheduled = Scheduler_NothingScheduledYet(node);

  // schedule new ping if none is scheduled right now
  if (nothingScheduled) {
    Scheduler_ScheduleNextPing(node);
  };

  // remove expired slots from slot maps (expired = nodes that occupied the
  // slots have not sent a message for a certain period of time)
  SlotMap_RemoveExpiredSlotsFromOneHopSlotMap(node);
  SlotMap_RemoveExpiredSlotsFromTwoHopSlotMap(node);
  SlotMap_RemoveExpiredSlotsFromThreeHopSlotMap(node);

  // release expired pending and own slots
  int8_t removedPending[NUM_SLOTS];
  int8_t removedOwn[NUM_SLOTS];
  int16_t numRemovedPending = SlotMap_RemoveExpiredPendingSlots(node, &removedPending[0], NUM_SLOTS);
  int16_t numRemovedOwn = SlotMap_RemoveExpiredOwnSlots(node, &removedOwn[0], NUM_SLOTS);

  // check if the next schedule is for one of the expired slots and if so, cancel it
  int8_t nextScheduledSlot = Scheduler_GetSlotOfNextSchedule(node);
  int16_t indexPending = Util_Int8tArrayFindElement(&removedPending[0], nextScheduledSlot, numRemovedPending);
  if (indexPending != -1) {
    Scheduler_CancelScheduledPing(node);
  };

  int16_t indexOwn = Util_Int8tArrayFindElement(&removedOwn[0], nextScheduledSlot, numRemovedOwn);
  if (indexOwn != -1) {
    Scheduler_CancelScheduledPing(node);
  };

  // remove absent neighbors (nodes that haven't been heard for a certain 
  // period of time)
  Neighborhood_RemoveAbsentNeighbors(node);

  // in case a scheduled ping was missed, cancel the schedule so it does not block from scheduling a new ping
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  int64_t timeNextSchedule = Scheduler_GetTimeOfNextSchedule(node);
  if (localTime > timeNextSchedule && timeNextSchedule != -1) {
    Scheduler_CancelScheduledPing(node);
  };
};

void StateActions_ListeningConnectedIncomingMsgAction(Node node, Message msg) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);

  switch(msg->type) {
    case PING:
      #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 " received ping from Node %" PRIu8 "\n", localTime, node->id, msg->senderId);
      #endif

#if DEBUG_VERBOSE
        // print information about the received message (if debugging, keep in mind this is what the other node "sees", not this one)
        printf("Sender: %" PRId8 "\n", msg->senderId);
        printf("Network: %" PRIu8 "\n", msg->networkId);

        for(int i = 0; i < NUM_SLOTS; ++i) {
          printf("1H (S%d): %d \n", (i+1), msg->oneHopSlotStatus[i]);
          printf("1H ID (S%d): %" PRId8 "\n", (i+1), msg->oneHopSlotIds[i]);
          printf("2H (S%d): %d \n", (i+1), msg->twoHopSlotStatus[i]);
          printf("2H ID (S%d): %" PRId8 "\n", (i+1), msg->twoHopSlotIds[i]);
        };
#endif

      MessageHandler_HandlePingConnected(node, msg);
      break;
    case POLL:
     #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 " received poll from Node %" PRIu8 " \n", localTime, node->id, msg->senderId);
      #endif
      RangingManager_RecordRangingMsgIn(node, msg);
      break;
    case RESPONSE:
     #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 " received response from Node %" PRIu8 " \n", localTime, node->id, msg->senderId);
      #endif
      RangingManager_RecordRangingMsgIn(node, msg);
      break;
    case FINAL:
     #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 " received final from Node %" PRIu8 " \n", localTime, node->id, msg->senderId);
      #endif
      RangingManager_RecordRangingMsgIn(node, msg);
      break;
    case RESULT:
      #ifdef SIMULATION
      mexPrintf("%" PRId64 ": Node %" PRIu8 " received result from Node %" PRIu8 " \n", localTime, node->id, msg->senderId);
      #endif
      RangingManager_RecordRangingMsgIn(node, msg);
      Neighborhood_UpdateRanging(node, msg->senderId, msg->timestamp, msg->distance);
      break;
  };
};

void StateActions_SendingConnectedTimeTicAction(Node node) {
  bool sendingFinished = Driver_SendingFinished(node);
  // send ping if it is scheduled, but don't send if it is already transmitting
  if (sendingFinished) {
    MessageHandler_SendPing(node);
    Scheduler_CancelScheduledPing(node);
  };
};

void StateActions_SendingUnconnectedTimeTicAction(Node node) {
  bool sendingFinished = Driver_SendingFinished(node);
  // send ping if it is scheduled, but don't send if it is already transmitting
  if (sendingFinished) {
    MessageHandler_SendInitialPing(node);
    Scheduler_CancelScheduledPing(node);
  };
};

void StateActions_RangingPollTimeTicAction(Node node) {
  int8_t* neighbors[MAX_NUM_NODES];
  int8_t numNeighbors = Neighborhood_GetOneHopNeighbors(node, &neighbors[0], MAX_NUM_NODES);
  bool sendingFinished = Driver_SendingFinished(node);

  // start ranging by sending a poll if there are neighbors and no transmission is ongoing
  if (numNeighbors > 0 && sendingFinished) {
    MessageHandler_SendRangingPollMessage(node);
  };
};

void StateActions_RangingResponseTimeTicAction(Node node, Message pollMsgIn) {
  bool sendingFinished = Driver_SendingFinished(node);

  // send response if no transmission is ongoing
  if (sendingFinished) {
    MessageHandler_SendRangingResponseMessage(node, pollMsgIn);
  };
};

void StateActions_RangingFinalTimeTicAction(Node node, Message responseMsgIn) {
  bool sendingFinished = Driver_SendingFinished(node);

  // send final if no transmission is ongoing
  if (sendingFinished) {
    MessageHandler_SendRangingFinalMessage(node, responseMsgIn);
  };
};

void StateActions_RangingResultTimeTicAction(Node node, Message finalMsgIn) {
  bool sendingFinished = Driver_SendingFinished(node);

  // send result if no transmission is ongoing
  if (sendingFinished) { 
    MessageHandler_SendRangingResultMessage(node, finalMsgIn);
  };
};

void StateActions_IdleTimeTicAction(Node node) {
  // don't do anything
  // if during IDLE a node should do other things, this can be implemented here
};

void StateActions_IdleIncomingMsgAction(Node node, Message msg) {
  // process the message as if the node was listening connected
  StateActions_ListeningConnectedIncomingMsgAction(node, msg);
};

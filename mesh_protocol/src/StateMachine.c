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

#include "../include/StateMachine.h"

StateMachine StateMachine_Create() {
  StateMachine self = calloc(1, sizeof(StateMachineStruct));
  self->state = OFF;

  return self;
};

States StateMachine_GetState(Node node) {
  return node->stateMachine->state;
};

void StateMachine_Run(Node node, Events event, Message msg) {
  
  // execute actions depending on the current state of the state machine and the
  // event that happened (TURN_ON, TIME_TIC or INCOMING_MSG)
  switch(node->stateMachine->state) {
    case OFF:
      switch(event) {
        case TURN_ON:
          // change state to listening unconnected after the node was turned on
          node->stateMachine->state = LISTENING_UNCONNECTED;
          break;
      };
      break;
    case LISTENING_UNCONNECTED:
      switch(event) {
        case INCOMING_MSG:
          if (msg->type == PING) {
            // change state to listening connected, because this node will join the network of the sending node
            node->stateMachine->state = LISTENING_CONNECTED;

            StateActions_ListeningUnconnectedIncomingMsgAction(node, msg);
          };
          break;
        case TIME_TIC: ;
          bool pingScheduled = Scheduler_PingScheduledToNow(node);
          bool sendingAllowed = GuardConditions_ListeningUncToSendingUncAllowed(node);

          if (pingScheduled && sendingAllowed) {
            // send initial ping
            node->stateMachine->state = SENDING_UNCONNECTED;  
            StateActions_SendingUnconnectedTimeTicAction(node);
          } else {
            StateActions_ListeningUnconnectedTimeTicAction(node);
          };

          break;
      };
      break;
    case SENDING_UNCONNECTED:
      switch(event) {
        case TIME_TIC: ;
          bool sendingFinished = Driver_SendingFinished(node);
          bool backToListeningAllowed = GuardConditions_SendingUncToListeningConAllowed(node);
          
          // after sending the initial ping, transition to connected listening
          if (sendingFinished && backToListeningAllowed) {
            node->stateMachine->state = LISTENING_CONNECTED;
            StateActions_ListeningConnectedTimeTicAction(node);
          } else {
            StateActions_SendingUnconnectedTimeTicAction(node);
          };
          break;
      };
      break;

    case LISTENING_CONNECTED:
      switch(event) {
        case INCOMING_MSG: ;
          switch(msg->type) {
            case PING: ;
              // when receiving a ping, execute the corresponding action to handle it
              StateActions_ListeningConnectedIncomingMsgAction(node, msg);
              break;
            case POLL: ;
              if (msg->recipientId == node->id) {
                // when receiving a poll, transition to RESPONSE state
                node->stateMachine->state = RANGING_RESPONSE;
                // handle the poll by executing the corresponding action
                StateActions_ListeningConnectedIncomingMsgAction(node, msg);
                StateActions_RangingResponseTimeTicAction(node, msg);
              };
              break;
          };
          break;
        case TIME_TIC: ;
          bool pingScheduled = Scheduler_PingScheduledToNow(node);
          bool sendingAllowed = GuardConditions_ListeningConToSendingConAllowed(node);
          bool backToUnconnected = GuardConditions_ListeningConToListeningUncAllowed(node);
          bool rangingPollAllowed = GuardConditions_RangingPollAllowed(node);
          bool idleingAllowed = GuardConditions_IdleingAllowed(node);

          // transition to IDLE if that is allowed (duty cycling)
          if (idleingAllowed) {
            node->stateMachine->state = IDLE;
            StateActions_IdleTimeTicAction(node);
          };

          // transition to sending a ping if it is due and sending is allowed
          if (pingScheduled && sendingAllowed && node->stateMachine->state == LISTENING_CONNECTED) {
            node->stateMachine->state = SENDING_CONNECTED;
            // execute the corresponding action
            StateActions_SendingConnectedTimeTicAction(node);
          } else if(pingScheduled && !sendingAllowed) {
            // if a ping is scheduled but sending is not allowed, cancel it
            Scheduler_CancelScheduledPing(node);
          };

          // if ping is not scheduled but ranging is allowed, transition to sending a poll
          if (!pingScheduled && rangingPollAllowed && node->stateMachine->state == LISTENING_CONNECTED) {
            // get next ranging neighbor
            int8_t nextRangingNeighborId = Neighborhood_GetNextRangingNeighbor(node);
            if (nextRangingNeighborId != -1) {
              node->stateMachine->state = RANGING_POLL;
              StateActions_RangingPollTimeTicAction(node);
            };
          };

          // if no state transition was done, execute the listening connected action
          if(node->stateMachine->state == LISTENING_CONNECTED) {
            StateActions_ListeningConnectedTimeTicAction(node);
            if(backToUnconnected) {
              // transition back to listening unconnected when the criteria are fulfilled (basically if no other node responds)
              node->stateMachine->state = LISTENING_UNCONNECTED;

              // reset wait time so the node waits for some time before it tries starting a new network again
              TimeKeeping_ResetTime(node);

              StateActions_ListeningUnconnectedTimeTicAction(node);
            };
          };
          break;

      };
      break;

      case SENDING_CONNECTED: ;
        switch(event) {
          case TIME_TIC: ;
            bool sendingFinished = Driver_SendingFinished(node);
            bool backToListeningAllowed = GuardConditions_SendingConToListeningConAllowed(node);
        
            // transition back to listening if sending is finished
            if (sendingFinished && backToListeningAllowed) {
              node->stateMachine->state = LISTENING_CONNECTED;
              StateActions_ListeningConnectedTimeTicAction(node);
            };
            
            // otherwise stay in this state and execute the corresponding action
            if(node->stateMachine->state == SENDING_CONNECTED) {
              StateActions_SendingConnectedTimeTicAction(node);
            };

            break;
          };
        break;

      case RANGING_POLL: ;
        switch(event) {
          case TIME_TIC: ;
            bool sendingFinished = Driver_SendingFinished(node);
            // when sending poll is finished, listen for a response
            if (sendingFinished) {
              RangingManager_RecordRangingMsgOut(node);
              node->stateMachine->state = RANGING_LISTEN;
              StateActions_ListeningConnectedTimeTicAction(node);
            };
            break;
        };
        break;

      case RANGING_LISTEN: ;
        switch(event) {
          case INCOMING_MSG: ;
            if (msg->recipientId == node->id) {
              // handle the message by executing the corresponding action
              StateActions_ListeningConnectedIncomingMsgAction(node, msg);

              // depending on the type of the message, transition to a different state
              switch(msg->type){
                case RESPONSE:
                  // transition to WAIT state (from there it will transition to sending final)
                  node->stateMachine->state = RANGING_FINAL;
                  StateActions_RangingFinalTimeTicAction(node, msg);
                  break;
                case FINAL:
                  // transition to WAIT state (from there it will transition to sending result)
                  node->stateMachine->state = RANGING_RESULT;
                  StateActions_RangingResultTimeTicAction(node, msg);
                  break;
                case RESULT:
                  // ranging is finished, go back to listening
                  node->stateMachine->state = LISTENING_CONNECTED;
                  StateActions_ListeningConnectedIncomingMsgAction(node, msg);
                  break;
              };
            };
            break;

          case TIME_TIC: ;
            bool rangingTimedOut = RangingManager_HasRangingTimedOut(node);
            // check if other node did not respond for too long and if so, go back to listening
            if (rangingTimedOut) {
              node->stateMachine->state = LISTENING_CONNECTED;
              StateActions_ListeningConnectedTimeTicAction(node);
            };
            break;
        };
        break;

    case RANGING_RESPONSE: ;
      switch(event) {
        case TIME_TIC: ;
          bool sendingFinished = Driver_SendingFinished(node);
          // when sending is finished, listen for a response
          if (sendingFinished) {
            RangingManager_RecordRangingMsgOut(node);
            node->stateMachine->state = RANGING_LISTEN;
            StateActions_ListeningConnectedTimeTicAction(node);
          };
          break;
      };
      break;
    
    case RANGING_FINAL: ;
      switch(event) {
        case TIME_TIC: ;
          bool sendingFinished = Driver_SendingFinished(node);
          // when sending is finished, listen for a response
          if (sendingFinished) {
            RangingManager_RecordRangingMsgOut(node);
            node->stateMachine->state = RANGING_LISTEN;

          };
          break;
      };
      break;

    case RANGING_RESULT: ;
      switch(event) {
        case TIME_TIC: ;
          bool sendingFinished = Driver_SendingFinished(node);
          // when sending is finished, go back to normal listening (ranging is finished)
          if (sendingFinished) {
            RangingManager_RecordRangingMsgOut(node);
            node->stateMachine->state = LISTENING_CONNECTED;
            StateActions_ListeningConnectedTimeTicAction(node);
          };
          break;
      };
      break;

    case IDLE: ;
      switch(event) {
        bool idleEnd;
        case INCOMING_MSG: ;
          idleEnd = GuardConditions_IdleToListeningConAllowedIncomingMsg(node, msg);
          // if the node should respond to the message, end the idle and go back to listening 
          // (with the next ping, the node will then send its information)
          if (idleEnd) {
            SlotMap_ExtendTimeouts(node);
            TimeKeeping_SetLastTimeIdled(node);
            node->stateMachine->state = LISTENING_CONNECTED;
            StateActions_ListeningConnectedIncomingMsgAction(node, msg);
          } else {
            // otherwise process message but keep idleing
            StateActions_IdleIncomingMsgAction(node, msg);
          };

          break;

        case TIME_TIC: ;
          idleEnd = GuardConditions_IdleToListeningConAllowed(node);
          // if idle should end, extend the timesouts of the slots in the slot map so 
          // they are not removed and go back to listening
          if (idleEnd) {
            SlotMap_ExtendTimeouts(node);
            TimeKeeping_SetLastTimeIdled(node);
            node->stateMachine->state = LISTENING_CONNECTED;
            StateActions_ListeningConnectedTimeTicAction(node);
          } else {
            // otherwise keep idleing
            StateActions_IdleTimeTicAction(node);
          };
          break;
      };
      break;
  }

};





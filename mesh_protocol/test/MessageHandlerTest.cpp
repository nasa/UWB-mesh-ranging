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

#include <gtest/gtest.h>

extern "C" {
#include "../include/MessageHandler.h"
#include "../include/TimeKeeping.h"
#include "../include/NetworkManager.h"
#include "../include/RandomNumbers.h"
#include "../include/StateActions.h"
#include "../include/SlotMap.h"
#include "../include/Scheduler.h"
#include "../include/Message.h"
#include "../include/Neighborhood.h"
#include "../test/fff.h"
}

DEFINE_FFF_GLOBALS;
FAKE_VALUE_FUNC(int64_t, RandomNumbers_GetRandomIntBetween, Node, int64_t, int64_t);
FAKE_VALUE_FUNC(int16_t, RandomNumbers_GetRandomElementFrom, Node, int16_t*, int16_t);


class MessageHandlerTestGeneral : public ::testing::Test {
 protected:
  void SetUp() override {
    // reset fakes
    //RESET_FAKE(TimeKeeping_RecordPreamble);

    node = Node_Create();
    messageHandler = MessageHandler_Create();
    scheduler = Scheduler_Create();
    networkManager = NetworkManager_Create();
    timeKeeping = TimeKeeping_Create();
    slotMap = SlotMap_Create();
    neighborhood = Neighborhood_Create();

    int64_t *time = (int64_t *)malloc(1);
    *time = 5;
    clock = ProtocolClock_Create(time);
    config = Config_Create();

    Node_SetMessageHandler(node, messageHandler);
    Node_SetScheduler(node, scheduler);
    Node_SetNetworkManager(node, networkManager);
    Node_SetTimeKeeping(node, timeKeeping);
    Node_SetClock(node, clock);
    Node_SetSlotMap(node, slotMap);
    Node_SetNeighborhood(node, neighborhood);
    Node_SetConfig(node, config);
  }

   //void TearDown() override {}

  Node node;
  MessageHandler messageHandler;
  Scheduler scheduler;
  NetworkManager networkManager;
  TimeKeeping timeKeeping;
  ProtocolClock clock;
  SlotMap slotMap;
  Neighborhood neighborhood;
  Config config;
};


TEST_F(MessageHandlerTestGeneral, handlePingUnconnected) {
  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  msg->oneHopSlotStatus[0] = FREE;
  msg->oneHopSlotStatus[1] = OCCUPIED;
  msg->oneHopSlotStatus[2] = FREE;
  msg->oneHopSlotStatus[3] = FREE;
  msg->oneHopSlotIds[0] = 0;
  msg->oneHopSlotIds[1] = 3;
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 0;

  msg->twoHopSlotStatus[0] = FREE;
  msg->twoHopSlotStatus[1] = FREE;
  msg->twoHopSlotStatus[2] = FREE;
  msg->twoHopSlotStatus[3] = COLLIDING;
  msg->twoHopSlotIds[0] = 0;
  msg->twoHopSlotIds[1] = 0;
  msg->twoHopSlotIds[2] = 0;
  msg->twoHopSlotIds[3] = 0;
  msg->networkId = 4;

  MessageHandler_HandlePingUnconnected(node, msg);
  EXPECT_EQ(CONNECTED, NetworkManager_GetNetworkStatus(node));
  EXPECT_EQ(msg->networkId, NetworkManager_GetNetworkId(node));
  
  int twoHopStatusbuffer[4];
  SlotMap_GetTwoHopSlotMapStatus(node, &twoHopStatusbuffer[0], 4);

  int threeHopStatusbuffer[4];
  SlotMap_GetThreeHopSlotMapStatus(node, &threeHopStatusbuffer[0], 4);

  EXPECT_EQ(0, twoHopStatusbuffer[0]);
  EXPECT_EQ(1, twoHopStatusbuffer[1]);

  EXPECT_EQ(0, threeHopStatusbuffer[2]);
  EXPECT_EQ(2, threeHopStatusbuffer[3]);

  int8_t neighbors[2] = {-1, -1};
  Neighborhood_GetOneHopNeighbors(node, &neighbors[0], 2);

  EXPECT_EQ(2, neighbors[0]);
  EXPECT_EQ(-1, neighbors[1]);
};

TEST_F(MessageHandlerTestGeneral, handlePingConnectedForeignNotPrecedingPendingSlotCollides) {
  // should not switch networks even if pending slot collides, because there is another node in the network
  int64_t time = 1;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  node->id = 1;

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->networkId = 2;
  msg->timestamp = 1;
  msg->timeSinceFrameStart = 0;
  MessageHandler_HandlePingUnconnected(node, msg);

  time = 110;
  int8_t neighbors[1] = {2}; 
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);

  time = 250;

  Message foreignMsg = Message_Create(PING);
  foreignMsg->senderId = 4;
  foreignMsg->networkId = 4;
  foreignMsg->timestamp = 250;
  foreignMsg->networkAge = 50;
  foreignMsg->numCollisions = 1;
  foreignMsg->collisionTimes[0] = 140;

  MessageHandler_HandlePingConnected(node, foreignMsg);

  EXPECT_EQ(CONNECTED, NetworkManager_GetNetworkStatus(node));
  EXPECT_EQ(2, NetworkManager_GetNetworkId(node));
};

TEST_F(MessageHandlerTestGeneral, handlePingConnectedForeignNotPrecedingPendingSlotCollidesNoOtherNode) {
  // should switch networks because pending slot collides and there is no other node
  int64_t time = 1;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  node->id = 1;

  time = 110;
  int8_t neighbors[1] = {2}; 
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);

  time = 250;

  Message foreignMsg = Message_Create(PING);
  foreignMsg->senderId = 4;
  foreignMsg->networkId = 4;
  foreignMsg->timestamp = 250;
  foreignMsg->networkAge = 50;
  foreignMsg->numCollisions = 1;
  foreignMsg->collisionTimes[0] = 140;

  MessageHandler_HandlePingConnected(node, foreignMsg);

  EXPECT_EQ(CONNECTED, NetworkManager_GetNetworkStatus(node));
  EXPECT_EQ(4, NetworkManager_GetNetworkId(node));
};

#include <gtest/gtest.h>

extern "C" {
#include "../include/Node.h"
#include "../include/NetworkManager.h"
#include "../include/SlotMap.h"
#include "../include/RandomNumbers.h"
//#include "../include/TimeKeeping.h"
//#include "../include/Config.h"
#include "../test/fff.h"
}

DEFINE_FFF_GLOBALS;
FAKE_VALUE_FUNC(int64_t, RandomNumbers_GetRandomIntBetween, Node, int64_t, int64_t); // not used (remove when implementation is done)
FAKE_VALUE_FUNC(int16_t, RandomNumbers_GetRandomElementFrom, Node, int16_t*, int16_t);

//FAKE_VALUE_FUNC(bool, SlotMap_SlotReservationGoalMet, Node); // not used (remove when implementation is done)
//FAKE_VALUE_FUNC(uint8_t, SlotMap_GetReservableSlot, Node); // not used (remove when implementation is done)
//FAKE_VALUE_FUNC(uint8_t, SlotMap_CalculateNextOwnOrPendingSlotNum, Node, uint8_t); // not used (remove when implementation is done)
//FAKE_VOID_FUNC(SlotMap_UpdatePendingSlotAcks, Node, Message);

class NetworkManagerTestGeneral : public ::testing::Test {
 protected:
  void SetUp() override {
    node = Node_Create();

    int64_t *time = (int64_t *)malloc(1);
    *time = 5;
    clock = ProtocolClock_Create(time);
    networkManager = NetworkManager_Create();
    conf = Config_Create();
    timeKeeping = TimeKeeping_Create();

    Node_SetNetworkManager(node, networkManager);
    Node_SetClock(node, clock);
    Node_SetConfig(node, conf);
    Node_SetTimeKeeping(node, timeKeeping);
  }

   //void TearDown() override {}

  Node node;
  ProtocolClock clock;
  NetworkManager networkManager;
  Config conf;
  TimeKeeping timeKeeping;
};

TEST_F(NetworkManagerTestGeneral, notConnectedAfterCreation) {
  EXPECT_EQ(NOT_CONNECTED, NetworkManager_GetNetworkStatus(node));
}

TEST_F(NetworkManagerTestGeneral, createNetworkSetsProperties) {
  node->id = 23;

  NetworkManager_CreateNetwork(node);

  EXPECT_EQ(CONNECTED, NetworkManager_GetNetworkStatus(node));
  EXPECT_EQ(node->id, NetworkManager_GetNetworkId(node));
}

TEST_F(NetworkManagerTestGeneral, calculateNetworkAgeForSelfCreatedNetwork) {
  node->id = 1;

  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  EXPECT_EQ(0, NetworkManager_CalculateNetworkAge(node));

  time = 25;
  EXPECT_EQ(20, NetworkManager_CalculateNetworkAge(node));
}

TEST_F(NetworkManagerTestGeneral, calculateNetworkAgeNotConnected) {
  EXPECT_EQ(0, NetworkManager_CalculateNetworkAge(node));
}

TEST_F(NetworkManagerTestGeneral, pingFromForeignNetworkDifferentId) {
  node->id = 1;
  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  //TimeKeeping_RecordPreamble(node);
  Message msg = Message_Create(PING);
  msg->networkId = 2;
  msg->networkAge = 0;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  EXPECT_EQ(true, NetworkManager_IsPingFromForeignNetwork(node, msg));
}

TEST_F(NetworkManagerTestGeneral, pingFromForeignNetworkDifferentAge) {
  node->id = 1;
  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  //TimeKeeping_RecordPreamble(node);
  Message msg = Message_Create(PING);
  msg->networkId = 1;
  msg->networkAge = 5;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  EXPECT_EQ(true, NetworkManager_IsPingFromForeignNetwork(node, msg));
}

TEST_F(NetworkManagerTestGeneral, pingFromSameNetwork) {
  node->id = 1;
  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  time = 10;
  //TimeKeeping_RecordPreamble(node);
  Message msg = Message_Create(PING);
  msg->networkId = 1;
  msg->networkAge = 5;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  EXPECT_EQ(false, NetworkManager_IsPingFromForeignNetwork(node, msg));
}

TEST_F(NetworkManagerTestGeneral, foreignNetworkPrecedes) {
  node->id = 1;
  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  //TimeKeeping_RecordPreamble(node);
  Message msg = Message_Create(PING);
  msg->networkId = 2;
  msg->networkAge = 5;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  EXPECT_EQ(true, NetworkManager_IsForeignNetworkPreceding(node, msg));
}

TEST_F(NetworkManagerTestGeneral, foreignNetworkDoesNotPrecede) {
  node->id = 1;
  NetworkManager_CreateNetwork(node);

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  time = 10;
  //TimeKeeping_RecordPreamble(node);
  Message msg = Message_Create(PING);
  msg->networkId = 2;
  msg->networkAge = 5;
  msg->timestamp = ProtocolClock_GetLocalTime(node->clock);

  EXPECT_EQ(false, NetworkManager_IsForeignNetworkPreceding(node, msg));
}
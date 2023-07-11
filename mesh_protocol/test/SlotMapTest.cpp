#include <gtest/gtest.h>

extern "C" {
#include "../include/Node.h"
#include "../include/SlotMap.h"
#include "../test/fff.h"
}

class SlotMapTestGeneral : public ::testing::Test {
 protected:
  void SetUp() override {

    node = Node_Create();
    slotMap = SlotMap_Create();
    timeKeeping = TimeKeeping_Create();
    config = Config_Create();

    int64_t *time = (int64_t *)malloc(1);
    *time = 5;
    clock = ProtocolClock_Create(time);

    Node_SetSlotMap(node, slotMap);
    Node_SetClock(node, clock);
    Node_SetTimeKeeping(node, timeKeeping);
    Node_SetConfig(node, config);
  }
  
  // void TearDown() override {}
  Node node;
  SlotMap slotMap;
  ProtocolClock clock;
  TimeKeeping timeKeeping;
  Config config;
};

TEST_F(SlotMapTestGeneral, getPendingSlotsChecksSize) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[1] = { 23 };

  int8_t newPendingSlot = 1;
  int8_t neighborIds[1] = {2};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, 1, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 2, &neighborIds[0], neighborsArraySize);
    
  EXPECT_EQ(-1, SlotMap_GetPendingSlots(node, &test[0], 1));
}

TEST_F(SlotMapTestGeneral, getPendingSlotsRespectsArrayBounds) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[6] = { 23, 24, 25, 26, 27, 28 };
  
  EXPECT_EQ(0, SlotMap_GetPendingSlots(node, &test[0], 5));
  EXPECT_EQ(23, test[0]);
  EXPECT_EQ(28, test[5]);
}

TEST_F(SlotMapTestGeneral, addOnePendingSlot) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[5];
  
  int8_t newPendingSlot = 1;
  int8_t neighborIds[2] = {2, 3};
  int8_t neighborsArraySize = 2;
  SlotMap_AddPendingSlot(node, newPendingSlot, &neighborIds[0], neighborsArraySize);
  
  EXPECT_EQ(1, SlotMap_GetPendingSlots(node, &test[0], 5));
  EXPECT_EQ(1, test[0]);
}

TEST_F(SlotMapTestGeneral, addTwoPendingSlots) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[5];
  
  int8_t neighborIds[2] = {2, 3};
  int8_t neighborsArraySize = 2;
  SlotMap_AddPendingSlot(node, 1, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 4, &neighborIds[0], neighborsArraySize);

  EXPECT_EQ(2, SlotMap_GetPendingSlots(node, &test[0], 5));
  EXPECT_EQ(1, test[0]);
  EXPECT_EQ(4, test[1]);
}

TEST_F(SlotMapTestGeneral, addTooManyPendingSlots) {
  #define MAX_NUM_PENDING_SLOTS 5

  int8_t test[6] = {-1, -1, -1, -1, -1, -1};
  
  int8_t newPendingSlot = 1;
  int8_t neighborIds[2] = {2, 3};
  int8_t neighborsArraySize = 2;
  SlotMap_AddPendingSlot(node, 1, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 2, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 3, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 4, &neighborIds[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 5, &neighborIds[0], neighborsArraySize);
  bool result = SlotMap_AddPendingSlot(node, 6, &neighborIds[0], neighborsArraySize);

  EXPECT_EQ(5, SlotMap_GetPendingSlots(node, &test[0], 5));
  EXPECT_EQ(false, result);
  EXPECT_EQ(1, test[0]);
  EXPECT_EQ(5, test[4]);
  EXPECT_EQ(-1, test[5]);
}

TEST_F(SlotMapTestGeneral, acknowledgePendingSlot) {
  #define MAX_NUM_PENDING_SLOTS 5
  #define NUM_SLOTS 5
  node->id = 4;

  int8_t newPendingSlot = 1;
  int8_t neighborIds[1] = {2};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, newPendingSlot, &neighborIds[0], neighborsArraySize);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotIds[0] = 4;
  msg->oneHopSlotIds[1] = -1;

  SlotMap_UpdatePendingSlotAcks(node, msg);

  //printf("pendingSlots: %" PRId8 "\n", node->slotMap->pendingSlots[0]);
  //printf("acknowledgedBy: %" PRId8 "\n", node->slotMap->pendingSlotAcknowledgedBy[0][0]);
  
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetAcknowledgedPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(1, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);
}

TEST_F(SlotMapTestGeneral, acknowledgePendingSlotTwoNeighbors) {
  #define MAX_NUM_PENDING_SLOTS 5
  #define NUM_SLOTS 5
  node->id = 4;

  int8_t newPendingSlot = 1;
  int8_t neighborIds[2] = {2, 3};
  int8_t neighborsArraySize = 2;
  SlotMap_AddPendingSlot(node, newPendingSlot, &neighborIds[0], neighborsArraySize);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotIds[0] = 4;
  msg->oneHopSlotIds[1] = -1;

  SlotMap_UpdatePendingSlotAcks(node, msg);
  
  // should not be acknowledged yet (only one neighbor acked)
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetAcknowledgedPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(-1, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);

  // now let second neighbor acknowledge
  Message msg2 = Message_Create(PING);
  msg2->senderId = 3;
  msg2->oneHopSlotIds[0] = 4;
  msg2->oneHopSlotIds[1] = -1;

  SlotMap_UpdatePendingSlotAcks(node, msg2);
  
  SlotMap_GetAcknowledgedPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(1, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);
}

TEST_F(SlotMapTestGeneral, acknowledgeTwoPendingSlots) {
  #define MAX_NUM_PENDING_SLOTS 5
  #define NUM_SLOTS 5
  node->id = 4;

  int8_t newPendingSlot = 1;
  int8_t neighborIds[1] = {2};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, newPendingSlot, &neighborIds[0], neighborsArraySize);

  int8_t newPendingSlot2 = 3;
  SlotMap_AddPendingSlot(node, newPendingSlot2, &neighborIds[0], neighborsArraySize);
  
  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotIds[0] = -1;
  msg->oneHopSlotIds[1] = -1;
  msg->oneHopSlotIds[2] = 4;
  msg->oneHopSlotIds[3] = -1;

  SlotMap_UpdatePendingSlotAcks(node, msg);

  //printf("pendingSlots: %" PRId8 "\n", node->slotMap->pendingSlots[0]);
  //printf("acknowledgedBy: %" PRId8 "\n", node->slotMap->pendingSlotAcknowledgedBy[0][0]);
  
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetAcknowledgedPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(3, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);
}

TEST_F(SlotMapTestGeneral, changePendingToOwnAddsOwn) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[5];
  int8_t neighborIds1[1] = {1};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, 1, &neighborIds1[0], neighborsArraySize);
  bool result = SlotMap_ChangePendingToOwn(node, 1);
  
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetOwnSlots(node, &buffer[0], 5);
  EXPECT_EQ(true, result);
  EXPECT_EQ(1, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);
}

TEST_F(SlotMapTestGeneral, changeTwoPendingSlotsToOwn) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[5];
  int8_t neighborIds1[1] = {1};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, 3, &neighborIds1[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 1, &neighborIds1[0], neighborsArraySize);
  SlotMap_ChangePendingToOwn(node, 1);
  SlotMap_ChangePendingToOwn(node, 3);
  
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetOwnSlots(node, &buffer[0], 5);
  EXPECT_EQ(1, buffer[0]);
  EXPECT_EQ(3, buffer[1]);
}

TEST_F(SlotMapTestGeneral, changePendingToOwnRemovesPending) {
  //#define MAX_NUM_PENDING_SLOTS 5
  int8_t test[5];
  int8_t neighborIds1[1] = {1};
  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, 1, &neighborIds1[0], neighborsArraySize);
  SlotMap_ChangePendingToOwn(node, 1);
  
  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  int8_t numPending = SlotMap_GetPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(0, numPending);
  EXPECT_EQ(-1, buffer[0]);
}

TEST_F(SlotMapTestGeneral, changePendingToOwnRetainsNeighborsOfOtherPendingSlots) {
  //#define MAX_NUM_PENDING_SLOTS 5
  node->id = 5;
  int8_t test[5];
  
  int8_t neighborIds1[1] = {1};
  int8_t neighborIds2[1] = {2};
  int8_t neighborIds3[1] = {3};
  int8_t neighborIds4[1] = {4};

  int8_t neighborsArraySize = 1;
  SlotMap_AddPendingSlot(node, 1, &neighborIds1[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 2, &neighborIds2[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 3, &neighborIds3[0], neighborsArraySize);
  SlotMap_AddPendingSlot(node, 4, &neighborIds4[0], neighborsArraySize);

  EXPECT_EQ(4, SlotMap_GetPendingSlots(node, &test[0], 5));
  EXPECT_EQ(1, test[0]);
  EXPECT_EQ(2, test[1]);
  EXPECT_EQ(3, test[2]);
  EXPECT_EQ(4, test[3]);

  int8_t test2[5];
  bool result = SlotMap_ChangePendingToOwn(node, 2);
  EXPECT_EQ(true, result);
  EXPECT_EQ(3, SlotMap_GetPendingSlots(node, &test2[0], 5));
  EXPECT_EQ(1, test2[0]);
  EXPECT_EQ(4, test2[1]); // this test relies on the current implementation
                          // if the implementation is changed to retain the order of the pending slots, this must be changed
  EXPECT_EQ(3, test2[2]);

  // now acknowledge slot 4 and check if the correct slot was set to acknowledged (means the neighbors have been retained)
  Message msg = Message_Create(PING);
  msg->senderId = 4;
  msg->oneHopSlotIds[0] = -1;
  msg->oneHopSlotIds[1] = -1;
  msg->oneHopSlotIds[2] = -1;
  msg->oneHopSlotIds[3] = 5;
  SlotMap_UpdatePendingSlotAcks(node, msg);

  int8_t buffer[5] = {-1, -1, -1, -1, -1}; 
  SlotMap_GetAcknowledgedPendingSlots(node, &buffer[0], 5);
  EXPECT_EQ(4, buffer[0]);
  EXPECT_EQ(-1, buffer[1]);
}

TEST_F(SlotMapTestGeneral, updateOneHopSlotMapToOccupied) {
  Message msg = Message_Create(PING);
  msg->senderId = 2;
  int8_t currentSlot = 1;

  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetOneHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(OCCUPIED, statusbuffer[0]);
  EXPECT_EQ(FREE, statusbuffer[1]);
  EXPECT_EQ(FREE, statusbuffer[2]);
  EXPECT_EQ(FREE, statusbuffer[3]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetOneHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(2, idbuffer[0]);
  EXPECT_EQ(0, idbuffer[1]);
  EXPECT_EQ(0, idbuffer[2]);
  EXPECT_EQ(0, idbuffer[3]);
}

TEST_F(SlotMapTestGeneral, updateOneHopSlotMapNotTimedout) {
  #define OCCUPIED_TIMEOUT 500

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  int8_t currentSlot = 1;

  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);

  // update again when slot not timed out/expired
  time = 504;

  Message msg2 = Message_Create(PING);
  msg2->senderId = 3;

  SlotMap_UpdateOneHopSlotMap(node, msg2, currentSlot);

  int statusbuffer[4];
  bool result = SlotMap_GetOneHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, result);
  EXPECT_EQ(OCCUPIED, statusbuffer[0]);
  EXPECT_EQ(FREE, statusbuffer[1]);
  EXPECT_EQ(FREE, statusbuffer[2]);
  EXPECT_EQ(FREE, statusbuffer[3]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetOneHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(2, idbuffer[0]);
  EXPECT_EQ(0, idbuffer[1]);
  EXPECT_EQ(0, idbuffer[2]);
  EXPECT_EQ(0, idbuffer[3]);
}

TEST_F(SlotMapTestGeneral, updateOneHopSlotMapTimedout) {
  #define OCCUPIED_TIMEOUT 500

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  int8_t currentSlot = 1;

  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);

  // update again when slot is timed out/expired
  time = 505;

  Message msg2 = Message_Create(PING);
  msg2->senderId = 3;

  SlotMap_UpdateOneHopSlotMap(node, msg2, currentSlot);

  int statusbuffer[4];
  bool result = SlotMap_GetOneHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, result);
  EXPECT_EQ(OCCUPIED, statusbuffer[0]);
  EXPECT_EQ(FREE, statusbuffer[1]);
  EXPECT_EQ(FREE, statusbuffer[2]);
  EXPECT_EQ(FREE, statusbuffer[3]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetOneHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(3, idbuffer[0]);
  EXPECT_EQ(0, idbuffer[1]);
  EXPECT_EQ(0, idbuffer[2]);
  EXPECT_EQ(0, idbuffer[3]);
}

TEST_F(SlotMapTestGeneral, updateOneHopSlotMapToColliding) {
  Message msg = Message_Create(COLLISION);
  int8_t currentSlot = 1;

  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetOneHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(COLLIDING, statusbuffer[0]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetOneHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(0, idbuffer[0]);
}

TEST_F(SlotMapTestGeneral, updateOneHopSlotMapToOccupiedCollisionTimedout) {
  #define COLLIDING_TIMEOUT 100

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(COLLISION);
  int8_t currentSlot = 1;

  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);

  // update again when slot is timed out/expired
  time = 105;

  Message msg2 = Message_Create(PING);
  msg2->senderId = 3;

  SlotMap_UpdateOneHopSlotMap(node, msg2, currentSlot);

  int statusbuffer[4];
  bool result = SlotMap_GetOneHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, result);
  EXPECT_EQ(OCCUPIED, statusbuffer[0]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetOneHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(3, idbuffer[0]);
}

//TEST_F(SlotMapTestGeneral, int8tContainsElement) {
//int8_t test[4] = {1,2,3,4};
//int8_t element = 3;
//bool result = int8tArrayContainsElement(&test[0], &element, 4);
//EXPECT_EQ(true, result);
//};

//TEST_F(SlotMapTestGeneral, int8tDoesNotContainElement) {
//int8_t test[4] = {1,2,3,4};
//int8_t element = 5;
//bool result = int8tArrayContainsElement(&test[0], &element, 4);
//EXPECT_EQ(false, result);
//};

TEST_F(SlotMapTestGeneral, updateMultiHopSlotMapToOccupied) {
  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotStatus[0] = 0;
  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotStatus[2] = 0;
  msg->oneHopSlotStatus[3] = 1;
  msg->oneHopSlotIds[0] = 0;
  msg->oneHopSlotIds[1] = 1;
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 2;

  SlotMap_UpdateTwoHopSlotMap(node, msg);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetTwoHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(FREE, statusbuffer[0]);
  EXPECT_EQ(OCCUPIED, statusbuffer[1]);
  EXPECT_EQ(FREE, statusbuffer[2]);
  EXPECT_EQ(OCCUPIED, statusbuffer[3]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetTwoHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(0, idbuffer[0]);
  EXPECT_EQ(1, idbuffer[1]);
  EXPECT_EQ(0, idbuffer[2]);
  EXPECT_EQ(2, idbuffer[3]);
}

TEST_F(SlotMapTestGeneral, multiHopIsOccupiedSetColliding) {
  #define OCCUPIED_TIMEOUT 500

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotStatus[0] = 0;
  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotStatus[2] = 0;
  msg->oneHopSlotStatus[3] = 1;
  msg->oneHopSlotIds[0] = 0;
  msg->oneHopSlotIds[1] = 1;
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 2;

  SlotMap_UpdateTwoHopSlotMap(node, msg);

  time = 504;

  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotIds[1] = 3;

  SlotMap_UpdateTwoHopSlotMap(node, msg);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetTwoHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(FREE, statusbuffer[0]);
  EXPECT_EQ(COLLIDING, statusbuffer[1]);
  EXPECT_EQ(FREE, statusbuffer[2]);
  EXPECT_EQ(OCCUPIED, statusbuffer[3]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetTwoHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(0, idbuffer[0]);
  EXPECT_EQ(0, idbuffer[1]);
  EXPECT_EQ(0, idbuffer[2]);
  EXPECT_EQ(2, idbuffer[3]);
}

TEST_F(SlotMapTestGeneral, multiHopIsOccupiedButTimedout) {
  #define OCCUPIED_TIMEOUT 500

  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotStatus[0] = 0;
  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotStatus[2] = 0;
  msg->oneHopSlotStatus[3] = 1;
  msg->oneHopSlotIds[0] = 0;
  msg->oneHopSlotIds[1] = 1;
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 2;

  SlotMap_UpdateTwoHopSlotMap(node, msg);

  time = 505;

  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotIds[1] = 3;

  SlotMap_UpdateTwoHopSlotMap(node, msg);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetTwoHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(OCCUPIED, statusbuffer[1]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetTwoHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(3, idbuffer[1]);
}


TEST_F(SlotMapTestGeneral, multiHopPendingSlotReportedOccupied) {
  #define OCCUPIED_TIMEOUT 500
  node->id = 1;
  int8_t slotNum = 1;
  int8_t neighbors[1] = {2};

  SlotMap_AddPendingSlot(node, slotNum, &neighbors[0], 1);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotStatus[0] = 1;
  msg->oneHopSlotStatus[1] = 0;
  msg->oneHopSlotStatus[2] = 0;
  msg->oneHopSlotStatus[3] = 0;
  msg->oneHopSlotIds[0] = 3;
  msg->oneHopSlotIds[1] = 0;
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 0;
              
  SlotMap_UpdateTwoHopSlotMap(node, msg);

  int statusbuffer[4];
  bool statusresult = SlotMap_GetTwoHopSlotMapStatus(node, &statusbuffer[0], 4);

  EXPECT_EQ(true, statusresult);
  EXPECT_EQ(COLLIDING, statusbuffer[0]);

  int8_t idbuffer[4];
  bool idresult = SlotMap_GetTwoHopSlotMapIds(node, &idbuffer[0], 4);

  EXPECT_EQ(true, idresult);
  EXPECT_EQ(0, idbuffer[0]);
}

TEST_F(SlotMapTestGeneral, checkOwnSlotsForCollisions) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  bool result = SlotMap_ChangePendingToOwn(node, 2);
  EXPECT_EQ(true, result);

  Message msg = Message_Create(PING);
  msg->senderId = 2;
  msg->oneHopSlotStatus[0] = 0;
  msg->oneHopSlotStatus[1] = 1;
  msg->oneHopSlotStatus[2] = 0;
  msg->oneHopSlotStatus[3] = 0;
  msg->oneHopSlotIds[0] = 0;
  msg->oneHopSlotIds[1] = 3; // colliding because reserved by other node
  msg->oneHopSlotIds[2] = 0;
  msg->oneHopSlotIds[3] = 0;

  int8_t collidingOwnSlots[2];
  int8_t numCollidingOwn = SlotMap_CheckOwnSlotsForCollisions(node, msg, &collidingOwnSlots[0], 2);

  EXPECT_EQ(2, collidingOwnSlots[0]);
  EXPECT_EQ(1, numCollidingOwn); 
}

TEST_F(SlotMapTestGeneral, ownNetworkShouldExist) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  SlotMap_ChangePendingToOwn(node, 2);

  int8_t collidingSlots[2] = {3, 4};
  
  bool exists = SlotMap_OwnNetworkExists(node, &collidingSlots[0], 2);

  EXPECT_EQ(true, exists);
}

TEST_F(SlotMapTestGeneral, ownNetworkShouldNotExist) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  SlotMap_ChangePendingToOwn(node, 2);

  int8_t collidingSlots[2] = {2, 4};
  
  bool exists = SlotMap_OwnNetworkExists(node, &collidingSlots[0], 2);

  EXPECT_EQ(false, exists);
}

TEST_F(SlotMapTestGeneral, ownNetworkShouldNotExist2) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1); // do not change to own

  int8_t collidingSlots[2] = {2, 4};
  
  bool exists = SlotMap_OwnNetworkExists(node, &collidingSlots[0], 2);

  EXPECT_EQ(false, exists);
}

TEST_F(SlotMapTestGeneral, ownNetworkShouldExistDueToOtherNode) {
  Message msg = Message_Create(PING);
  msg->senderId = 3;
  int8_t currentSlot = 1;
  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot); // other node has slot, so network should still exist

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  SlotMap_ChangePendingToOwn(node, 2);

  int8_t collidingSlots[2] = {2, 4};
  
  bool exists = SlotMap_OwnNetworkExists(node, &collidingSlots[0], 2);

  EXPECT_EQ(true, exists);
}

TEST_F(SlotMapTestGeneral, isPendingSlot) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);

  bool shouldBePending = SlotMap_IsPendingSlot(node, 2);
  bool shouldNotBePending = SlotMap_IsPendingSlot(node, 1);

  EXPECT_EQ(true, shouldBePending);
  EXPECT_EQ(false, shouldNotBePending);
};

TEST_F(SlotMapTestGeneral, isOwnSlot) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  SlotMap_AddPendingSlot(node, 1, &neighbors[0], 1);
  SlotMap_ChangePendingToOwn(node, 2);

  bool shouldBeOwn = SlotMap_IsOwnSlot(node, 2);
  bool shouldNotBeOwn = SlotMap_IsOwnSlot(node, 1);

  EXPECT_EQ(true, shouldBeOwn);
  EXPECT_EQ(false, shouldNotBeOwn);
};

TEST_F(SlotMapTestGeneral, releaseOwnSlot) {

  node->id = 1;
  int8_t neighbors[1] = {2};
  SlotMap_AddPendingSlot(node, 2, &neighbors[0], 1);
  SlotMap_AddPendingSlot(node, 1, &neighbors[0], 1);
  SlotMap_AddPendingSlot(node, 3, &neighbors[0], 1);
  SlotMap_ChangePendingToOwn(node, 2);
  SlotMap_ChangePendingToOwn(node, 1);
  SlotMap_ChangePendingToOwn(node, 3);

  SlotMap_ReleaseOwnSlot(node, 1);

  EXPECT_EQ(true, SlotMap_IsOwnSlot(node, 3));
  EXPECT_EQ(true, SlotMap_IsOwnSlot(node, 2));
  EXPECT_EQ(false, SlotMap_IsOwnSlot(node, 1));
};

TEST_F(SlotMapTestGeneral, clearToSendSlotFree) {
  node->id = 1;
  int64_t time = 5;
  ProtocolClock clock = ProtocolClock_Create(&time);
  Node_SetClock(node, clock);

  TimeKeeping_SetFrameStartTime(node, time);

  Message msg = Message_Create(PING);
  msg->senderId = 2;

  msg->oneHopSlotStatus[0] = FREE;
  msg->oneHopSlotStatus[1] = FREE;
  msg->oneHopSlotStatus[2] = FREE;
  msg->oneHopSlotStatus[3] = OCCUPIED;

  msg->twoHopSlotStatus[0] = FREE;
  msg->twoHopSlotStatus[1] = OCCUPIED;
  msg->twoHopSlotStatus[2] = COLLIDING;
  msg->twoHopSlotStatus[3] = FREE;

  int8_t currentSlot = 1;
  SlotMap_UpdateOneHopSlotMap(node, msg, currentSlot);
  SlotMap_UpdateTwoHopSlotMap(node, msg);
  SlotMap_UpdateThreeHopSlotMap(node, msg);

  bool inSlot1 = SlotMap_ClearToSend(node);
  
  time = 105;
  bool inSlot2 = SlotMap_ClearToSend(node);

  time = 205;
  bool inSlot3 = SlotMap_ClearToSend(node);

  time = 305;
  bool inSlot4 = SlotMap_ClearToSend(node);

  EXPECT_EQ(false, inSlot1);
  EXPECT_EQ(false, inSlot2);
  EXPECT_EQ(true, inSlot3);
  EXPECT_EQ(false, inSlot4);
}




TEST(UtilTest, intersect) {
  int8_t array1[5] = {1,2,3,4,5};
  //int8_t array2[7] = {2,1,6,5,8,9,0};
  int8_t array2[7] = {2,4,5,6,7,8,9};
  int8_t intersection[5];

  int16_t numCommonElements = Util_IntersectSortedInt8tArrays(&array1[0], 5, &array2[0], 7, &intersection[0]);
  EXPECT_EQ(3, numCommonElements);
  
};

TEST(UtilTest, sort) {
  int8_t array1[5] = {5,1,4,9};
  Util_SortInt8tArray(&array1[0], 4, &array1[0]);

  EXPECT_EQ(1, array1[0]);
  EXPECT_EQ(4, array1[1]);
  EXPECT_EQ(5, array1[2]);
  EXPECT_EQ(9, array1[3]);
};
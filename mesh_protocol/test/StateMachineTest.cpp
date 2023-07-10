#include <gtest/gtest.h>

extern "C" {
#include "../include/Node.h"
#include "../include/StateMachine.h"
#include "../include/ProtocolClock.h"
#include "../include/Message.h"
#include "../include/Scheduler.h"
#include "../include/TimeKeeping.h"
#include "../include/GuardConditions.h"
#include "../include/Driver.h"
#include "../test/fff.h"
}

DEFINE_FFF_GLOBALS;
FAKE_VOID_FUNC(StateActions_ListeningUnconnectedIncomingMsgAction, Node, Message);
FAKE_VOID_FUNC(StateActions_ListeningUnconnectedTimeTicAction, Node);
FAKE_VOID_FUNC(StateActions_SendingUnconnectedTimeTicAction, Node);
FAKE_VOID_FUNC(StateActions_ListeningConnectedTimeTicAction, Node);
FAKE_VOID_FUNC(StateActions_SendingConnectedTimeTicAction, Node);
FAKE_VOID_FUNC(StateActions_RangingPollTimeTicAction, Node);
FAKE_VOID_FUNC(StateActions_IdleTimeTicAction, Node);


FAKE_VOID_FUNC(StateActions_ListeningConnectedIncomingMsgAction, Node, Message);
FAKE_VOID_FUNC(StateActions_RangingListenIncomingMsgAction, Node, Message);
FAKE_VOID_FUNC(StateActions_RangingResponseTimeTicAction, Node, Message);
FAKE_VOID_FUNC(StateActions_RangingFinalTimeTicAction, Node, Message);
FAKE_VOID_FUNC(StateActions_RangingResultTimeTicAction, Node, Message);
FAKE_VOID_FUNC(StateActions_IdleIncomingMsgAction, Node, Message);

FAKE_VALUE_FUNC(bool, GuardConditions_ListeningUncToSendingUncAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_SendingUncToListeningConAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_ListeningConToSendingConAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_ListeningConToListeningUncAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_RangingPollAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_SendingConToListeningConAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_IdleToListeningConAllowed, Node);
FAKE_VALUE_FUNC(bool, GuardConditions_IdleToListeningConAllowedIncomingMsg, Node, Message);
FAKE_VALUE_FUNC(bool, GuardConditions_IdleingAllowed, Node);

FAKE_VALUE_FUNC(int64_t, RandomNumbers_GetRandomIntBetween, Node, int64_t, int64_t);
FAKE_VALUE_FUNC(bool, SlotMap_SlotReservationGoalMet, Node);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetReservableSlot, Node);
FAKE_VALUE_FUNC(int8_t, SlotMap_CalculateNextOwnOrPendingSlotNum, Node, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetAcknowledgedPendingSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_ChangePendingToOwn, Node, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_CheckOwnSlotsForCollisions, Node, Message, int8_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_CheckPendingSlotsForCollisions, Node, Message, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_OwnNetworkExists, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_IsOwnSlot, Node, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_IsPendingSlot, Node, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_ReleasePendingSlot, Node, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_ReleaseOwnSlot, Node, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapStatus, Node, int*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapStatus, Node, int*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapStatus, Node, int*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetCollisionTimes, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_AddPendingSlot, Node, int8_t, int8_t*, int8_t);
FAKE_VALUE_FUNC(int16_t, SlotMap_RemoveExpiredPendingSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(int16_t, SlotMap_RemoveExpiredOwnSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetOwnSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetPendingSlots, Node, int8_t*, int8_t);

FAKE_VOID_FUNC(SlotMap_UpdatePendingSlotAcks, Node, Message);
FAKE_VOID_FUNC(SlotMap_UpdateOneHopSlotMap, Node, Message, int8_t)
FAKE_VOID_FUNC(SlotMap_UpdateTwoHopSlotMap, Node, Message);
FAKE_VOID_FUNC(SlotMap_UpdateThreeHopSlotMap, Node, Message);
FAKE_VOID_FUNC(SlotMap_RecordCollisionTime, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromOneHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromTwoHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromThreeHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_ExtendTimeouts, Node);
FAKE_VOID_FUNC(SlotMap_RemoveOutdatedCollisions, Node);

// LISTENING UNCONNECTED
class StateMachineTestListeningUnconnected : public ::testing::Test {
 protected:
  void SetUp() override {
    // reset fakes
    RESET_FAKE(StateActions_ListeningUnconnectedIncomingMsgAction);
    RESET_FAKE(StateActions_ListeningUnconnectedTimeTicAction);
    RESET_FAKE(StateActions_SendingUnconnectedTimeTicAction);
    RESET_FAKE(GuardConditions_ListeningUncToSendingUncAllowed);

    node = Node_Create();
    sm = StateMachine_Create();
    scheduler = Scheduler_Create();
    msg = Message_Create(PING);

    Node_SetStateMachine(node, sm);
    StateMachine_Run(node, TURN_ON, NULL);

  }

  // void TearDown() override {}
  Node node;
  StateMachine sm;
  Scheduler scheduler;
  Message msg;
};

TEST(StateMachineTest, offAfterCreation) {
  Node node = Node_Create();
  StateMachine sm = StateMachine_Create();
  Node_SetStateMachine(node, sm);
  EXPECT_EQ(OFF, StateMachine_GetState(node));
}

TEST_F(StateMachineTestListeningUnconnected, listeningUnconnectedAfterTurnOn) {
  // run listening unconnected

  EXPECT_EQ(LISTENING_UNCONNECTED, StateMachine_GetState(node));
}

TEST_F(StateMachineTestListeningUnconnected, listeningConnectedAfterPingReceived) {
  // run listening unconnected

  int64_t testTime = 1234;
  ProtocolClock clock = ProtocolClock(&testTime);

  Node_SetClock(node, clock);

  StateMachine_Run(node, INCOMING_MSG, msg);
  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));

  Message_Destroy(msg);
}

TEST_F(StateMachineTestListeningUnconnected, listeningUnconnectedStateActionCalledAfterPingReceived) {
  // run listening unconnected

  StateMachine_Run(node, INCOMING_MSG, msg);
  EXPECT_EQ(StateActions_ListeningUnconnectedIncomingMsgAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningUnconnected, noStateChangeTimeTicPingNotScheduled) {
  // run listening unconnected

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_UNCONNECTED, StateMachine_GetState(node));
}

TEST_F(StateMachineTestListeningUnconnected, listeningUnconnectedStateActionCalledTimeTicPingNotScheduled) {
  // run listening unconnected
  // guards satisfied but ping not scheduled
  //GuardConditions_ListeningUncToSendingUncAllowed_fake.return_val = true;

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  StateMachine_Run(node, TIME_TIC, NULL);
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 0);
  EXPECT_EQ(StateActions_ListeningUnconnectedTimeTicAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningUnconnected, listeningUnconnectedStateActionCalledTimeTicGuardNotSatisfied) {
  // run listening unconnected
  // ping scheduled but guards not satisfied
  GuardConditions_ListeningUncToSendingUncAllowed_fake.return_val = false;

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 1);

  StateMachine_Run(node, TIME_TIC, NULL);
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 0);
  EXPECT_EQ(StateActions_ListeningUnconnectedTimeTicAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningUnconnected, stateChangeTimeTicPingScheduled) {
  // run listening unconnected
  // guards satisfied and ping scheduled
  GuardConditions_ListeningUncToSendingUncAllowed_fake.return_val = true;

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 1);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(SENDING_UNCONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_ListeningUnconnectedTimeTicAction_fake.call_count, 0);
}

// SENDING UNCONNECTED

class StateMachineTestSendingUnconnected : public ::testing::Test {
 protected:
  void SetUp() override {
    // reset fakes
    RESET_FAKE(StateActions_ListeningUnconnectedIncomingMsgAction);
    RESET_FAKE(StateActions_ListeningUnconnectedTimeTicAction);
    RESET_FAKE(StateActions_SendingUnconnectedTimeTicAction);
    RESET_FAKE(GuardConditions_ListeningUncToSendingUncAllowed);

    node = Node_Create();
    sm = StateMachine_Create();
    scheduler = Scheduler_Create();
    msg = Message_Create(PING);

    Node_SetStateMachine(node, sm);

    // set to sending unconnected by scheduling ping to now, allowing state change and
    // running time tic
    GuardConditions_ListeningUncToSendingUncAllowed_fake.return_val = true;
    int64_t testTime = 1;
    ProtocolClock clock = ProtocolClock_Create(&testTime);

    Node_SetClock(node, clock);
    Node_SetScheduler(node, scheduler);

    Scheduler_SchedulePingAtTime(node, 1);

    StateMachine_Run(node, TURN_ON, NULL);
    StateMachine_Run(node, TIME_TIC, NULL);
  }

  // void TearDown() override {}
  Node node;
  StateMachine sm;
  Scheduler scheduler;
  Message msg;
};

TEST_F(StateMachineTestSendingUnconnected, noStateChangeWhenSendingUncNotFinished) {
  GuardConditions_SendingUncToListeningConAllowed_fake.return_val = true;
  bool sendingFinishedFlag = false;
  bool isReceivingFlag = false;
  Driver driver = Driver_Create(&sendingFinishedFlag, &isReceivingFlag);
  Node_SetDriver(node, driver);

  // another time tic while in state sending unconnected
  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(SENDING_UNCONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 2);
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 0);
}

TEST_F(StateMachineTestSendingUnconnected, noStateChangeWhenGuardCondNotSatisfied) {
  GuardConditions_SendingUncToListeningConAllowed_fake.return_val = false;
  bool sendingFinishedFlag = true;
  bool isReceivingFlag = false;
  Driver driver = Driver_Create(&sendingFinishedFlag, &isReceivingFlag);
  Node_SetDriver(node, driver);

  // another time tic while in state sending unconnected
  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(SENDING_UNCONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 2);
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 0);
}

TEST_F(StateMachineTestSendingUnconnected, stateChangeWhenSendingFinished) {
  GuardConditions_SendingUncToListeningConAllowed_fake.return_val = true;
  bool sendingFinishedFlag = true;
  bool isReceivingFlag = false;
  Driver driver = Driver_Create(&sendingFinishedFlag, &isReceivingFlag);
  Node_SetDriver(node, driver);

  // another time tic while in state sending unconnected
  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingUnconnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
}

// LISTENING CONNECTED

class StateMachineTestListeningConnected : public ::testing::Test {
 protected:
  void SetUp() override {
    // reset fakes
    RESET_FAKE(StateActions_ListeningUnconnectedIncomingMsgAction);
    RESET_FAKE(StateActions_ListeningUnconnectedTimeTicAction);
    RESET_FAKE(StateActions_SendingUnconnectedTimeTicAction);
    RESET_FAKE(GuardConditions_ListeningUncToSendingUncAllowed);

    node = Node_Create();
    sm = StateMachine_Create();
    scheduler = Scheduler_Create();
    msg = Message_Create(PING);
    timekeeping = TimeKeeping_Create();
    config = Config_Create();
    neighborhood = Neighborhood_Create();

    Node_SetStateMachine(node, sm);

    // set to listining connected by triggering an incoming msg event
    StateMachine_Run(node, TURN_ON, NULL);
    StateMachine_Run(node, INCOMING_MSG, msg);
  }

  // void TearDown() override {}
  Node node;
  StateMachine sm;
  Scheduler scheduler;
  Message msg;
  TimeKeeping timekeeping;
  Config config;
  Neighborhood neighborhood;
};

TEST_F(StateMachineTestListeningConnected, stateActionCalledIncomingPing) {
  StateMachine_Run(node, INCOMING_MSG, msg);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedIncomingMsgAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningConnected, timeTicNoPingScheduledNow) {
  // ping not scheduled to current time
  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_SendingConnectedTimeTicAction_fake.call_count, 0);
}

TEST_F(StateMachineTestListeningConnected, timeTicSendingNotAllowed) {
  // ping scheduled but sending not allowed
  GuardConditions_ListeningConToSendingConAllowed_fake.return_val = false;

  int64_t testTime = 5;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_SendingConnectedTimeTicAction_fake.call_count, 0);
}

TEST_F(StateMachineTestListeningConnected, timeTicSendingAllowedAndScheduled) {
  // ping scheduled but sending not allowed
  GuardConditions_ListeningConToSendingConAllowed_fake.return_val = true;

  int64_t testTime = 5;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(SENDING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 0);
  EXPECT_EQ(StateActions_SendingConnectedTimeTicAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningConnected, cancelScheduleIfSendingNotAllowed) {
  // ping scheduled but sending not allowed
  GuardConditions_ListeningConToSendingConAllowed_fake.return_val = false;

  int64_t testTime = 5;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(-1, Scheduler_GetTimeOfNextSchedule(node));
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningConnected, backToUnconnected) {
  // going back to unconnected listening is allowed (i.e. timeout)
  GuardConditions_ListeningConToSendingConAllowed_fake.return_val = false;
  GuardConditions_ListeningConToListeningUncAllowed_fake.return_val = true;

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);
  Node_SetTimeKeeping(node, timekeeping);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_UNCONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_ListeningUnconnectedTimeTicAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningConnected, rangingDue) {
  // ping was already sent and ranging is due
  GuardConditions_ListeningConToSendingConAllowed_fake.return_val = false;
  GuardConditions_ListeningConToListeningUncAllowed_fake.return_val = false;
  GuardConditions_RangingPollAllowed_fake.return_val = true;

  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);
  Node_SetConfig(node, config);
  Node_SetNeighborhood(node, neighborhood);

  Scheduler_SchedulePingAtTime(node, 5);

  // add neighbor
  Neighborhood_AddOrUpdateOneHopNeighbor(node, 3);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(RANGING_POLL, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_RangingPollTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 0);
  EXPECT_EQ(StateActions_ListeningUnconnectedTimeTicAction_fake.call_count, 0);
}

TEST_F(StateMachineTestListeningConnected, incomingPoll) {
  // ping not scheduled to current time
  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  Message msg = Message_Create(POLL);
  msg->recipientId = 1;
  node->id = 1;
  
  StateMachine_Run(node, INCOMING_MSG, msg);

  EXPECT_EQ(RANGING_RESPONSE, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedIncomingMsgAction_fake.call_count, 1);
}

TEST_F(StateMachineTestListeningConnected, incomingPollOtherId) {
  // ping not scheduled to current time
  int64_t testTime = 1;
  ProtocolClock clock = ProtocolClock_Create(&testTime);

  Node_SetClock(node, clock);
  Node_SetScheduler(node, scheduler);

  Scheduler_SchedulePingAtTime(node, 5);

  StateMachine_Run(node, TIME_TIC, NULL);

  Message msg = Message_Create(POLL);
  msg->recipientId = 1;
  node->id = 2;
  
  StateMachine_Run(node, INCOMING_MSG, msg);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_ListeningConnectedIncomingMsgAction_fake.call_count, 0);
}

//TEST_F(StateMachineTestListeningConnected, respondsAfterPoll) {
//  // ping not scheduled to current time
//  int64_t testTime = 1;
//  ProtocolClock clock = ProtocolClock_Create(&testTime);

//  Node_SetClock(node, clock);
//  Node_SetScheduler(node, scheduler);

//  Scheduler_SchedulePingAtTime(node, 5);

//  StateMachine_Run(node, TIME_TIC, NULL);

//  Message msg = Message_Create(POLL);
//  StateMachine_Run(node, INCOMING_MSG, msg);

//  EXPECT_EQ(RANGING_WAIT, StateMachine_GetState(node));
//  EXPECT_EQ(StateActions_ListeningConnectedIncomingMsgAction_fake.call_count, 1);

//  testTime = 6;
//  StateMachine_Run(node, TIME_TIC, NULL);
//  EXPECT_EQ(RANGING_RESPONSE, StateMachine_GetState(node));
//}

// SENDING CONNECTED

class StateMachineTestSendingConnected : public ::testing::Test {
 protected:
  void SetUp() override {
    // reset fakes
    RESET_FAKE(StateActions_ListeningUnconnectedIncomingMsgAction);
    RESET_FAKE(StateActions_ListeningUnconnectedTimeTicAction);
    RESET_FAKE(StateActions_SendingUnconnectedTimeTicAction);
    RESET_FAKE(GuardConditions_ListeningUncToSendingUncAllowed);

    node = Node_Create();
    sm = StateMachine_Create();
    scheduler = Scheduler_Create();
    msg = Message_Create(PING);

    Node_SetStateMachine(node, sm);

    // set to listining connected by triggering an incoming msg event
    StateMachine_Run(node, TURN_ON, NULL);
    StateMachine_Run(node, INCOMING_MSG, msg);

    // set to sending connected by scheduling ping and triggering time tic
    GuardConditions_ListeningConToSendingConAllowed_fake.return_val = true;
    int64_t testTime = 1;
    ProtocolClock clock = ProtocolClock_Create(&testTime);
    Node_SetClock(node, clock);
    Node_SetScheduler(node, scheduler);
    Scheduler_SchedulePingAtTime(node, 1);

    StateMachine_Run(node, TIME_TIC, NULL);
  }

  // void TearDown() override {}
  Node node;
  StateMachine sm;
  Scheduler scheduler;
  Message msg;
};

TEST_F(StateMachineTestSendingConnected, keepSendingWhileNotFinished) {
  GuardConditions_SendingConToListeningConAllowed_fake.return_val = true;
  bool sendingFinishedFlag = false;
  bool isReceivingFlag = false;
  Driver driver = Driver_Create(&sendingFinishedFlag, &isReceivingFlag);
  Node_SetDriver(node, driver);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(SENDING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingConnectedTimeTicAction_fake.call_count, 2);
}

TEST_F(StateMachineTestSendingConnected, changeToListeningWhenFinished) {
  GuardConditions_SendingConToListeningConAllowed_fake.return_val = true;
  bool sendingFinishedFlag = true;
  bool isReceivingFlag = false;
  Driver driver = Driver_Create(&sendingFinishedFlag, &isReceivingFlag);
  Node_SetDriver(node, driver);

  StateMachine_Run(node, TIME_TIC, NULL);

  EXPECT_EQ(LISTENING_CONNECTED, StateMachine_GetState(node));
  EXPECT_EQ(StateActions_SendingConnectedTimeTicAction_fake.call_count, 1);
  EXPECT_EQ(StateActions_ListeningConnectedTimeTicAction_fake.call_count, 1);
}
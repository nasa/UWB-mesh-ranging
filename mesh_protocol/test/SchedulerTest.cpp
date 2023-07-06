#include <gtest/gtest.h>

extern "C" {
#include "../include/Scheduler.h"
#include "../include/Node.h"
#include "../include/HALClock.h"
#include "../include/StateMachine.h"
#include "../include/SlotMap.h"
#include "../include/Message.h"
#include "../include/StateActions.h"
#include "../test/fff.h"
}

DEFINE_FFF_GLOBALS;
FAKE_VALUE_FUNC(uint64_t, RandomNumbers_GetRandomIntBetween, Node, uint64_t, uint64_t);
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
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapStatus, Node, SlotOccupancy*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetOneHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapStatus, Node, SlotOccupancy*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetTwoHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapStatus, Node, SlotOccupancy*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapIds, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_GetThreeHopSlotMapLastUpdated, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetCollisionTimes, Node, int64_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_AddPendingSlot, Node, int8_t, int8_t*, int8_t);
FAKE_VALUE_FUNC(int16_t, SlotMap_RemoveExpiredPendingSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(int16_t, SlotMap_RemoveExpiredOwnSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(bool, SlotMap_ClearToSend, Node);
FAKE_VALUE_FUNC(int64_t, SlotMap_GetLastReservationTime, Node);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetOwnSlots, Node, int8_t*, int8_t);
FAKE_VALUE_FUNC(int8_t, SlotMap_GetPendingSlots, Node, int8_t*, int8_t);

FAKE_VOID_FUNC(SlotMap_UpdateOneHopSlotMap, Node, Message, int8_t);
FAKE_VOID_FUNC(SlotMap_UpdateTwoHopSlotMap, Node, Message);
FAKE_VOID_FUNC(SlotMap_UpdateThreeHopSlotMap, Node, Message);
FAKE_VOID_FUNC(SlotMap_UpdatePendingSlotAcks, Node, Message);
FAKE_VOID_FUNC(SlotMap_RecordCollisionTime, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromOneHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromTwoHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_RemoveExpiredSlotsFromThreeHopSlotMap, Node);
FAKE_VOID_FUNC(SlotMap_ExtendTimeouts, Node);
FAKE_VOID_FUNC(SlotMap_RemoveOutdatedCollisions, Node);



class SchedulerTestGeneral : public ::testing::Test {
 protected:
  void SetUp() override {
    RESET_FAKE(RandomNumbers_GetRandomIntBetween);
    RESET_FAKE(SlotMap_SlotReservationGoalMet);
    RESET_FAKE(SlotMap_GetReservableSlot);
    RESET_FAKE(SlotMap_CalculateNextOwnOrPendingSlotNum);

    node = Node_Create();
    scheduler = Scheduler_Create();
    timeKeeping = TimeKeeping_Create();
    sm = StateMachine_Create();
    msg = Message_Create(PING);
    neighborhood = Neighborhood_Create();
    networkManager = NetworkManager_Create();
    conf = Config_Create();
    
    int64_t *time = (int64_t *)malloc(1);
    *time = 5;
    HALClock clock = HALClock_Create(time);

    Node_SetScheduler(node, scheduler);
    Node_SetClock(node, clock);
    Node_SetTimeKeeping(node, timeKeeping);
    Node_SetStateMachine(node, sm);
    Node_SetNeighborhood(node, neighborhood);
    Node_SetNetworkManager(node, networkManager);
    Node_SetConfig(node, conf);
  }

   //void TearDown() override {}

  Node node;
  Scheduler scheduler;
  TimeKeeping timeKeeping;
  StateMachine sm;
  Message msg;
  Neighborhood neighborhood;
  NetworkManager networkManager;
  Config conf;
};

TEST_F(SchedulerTestGeneral, noScheduleAfterCreation) {
  uint64_t noScheduleValue = -1;
  EXPECT_EQ(noScheduleValue, Scheduler_GetTimeOfNextSchedule(node));
}

TEST_F(SchedulerTestGeneral, schedulePingAtTime) {
  uint64_t scheduleTime = 7;
  bool worked = Scheduler_SchedulePingAtTime(node, scheduleTime);
  EXPECT_EQ(scheduleTime, Scheduler_GetTimeOfNextSchedule(node));
  EXPECT_EQ(true, worked);
}

TEST_F(SchedulerTestGeneral, schedulePingToPast) {
  int64_t scheduleTime = 3;
  bool worked = Scheduler_SchedulePingAtTime(node, scheduleTime);
  EXPECT_EQ(-1, Scheduler_GetTimeOfNextSchedule(node));
  EXPECT_EQ(false, worked);
}

TEST_F(SchedulerTestGeneral, scheduledToNowWhenNotScheduled) {
  EXPECT_EQ(false, Scheduler_PingScheduledToNow(node));
}

TEST_F(SchedulerTestGeneral, scheduledToNowWhenScheduled) {
  uint64_t scheduleTime = 5;
  Scheduler_SchedulePingAtTime(node, scheduleTime);
  EXPECT_EQ(true, Scheduler_PingScheduledToNow(node));
}

TEST_F(SchedulerTestGeneral, cancelScheduledPingWhenScheduled) {
  uint64_t scheduleTime = 5;
  Scheduler_SchedulePingAtTime(node, scheduleTime);
  Scheduler_CancelScheduledPing(node);

  EXPECT_EQ(0, Scheduler_GetTimeOfNextSchedule(node));
}

TEST_F(SchedulerTestGeneral, cancelScheduledPingWhenNotScheduled) {
  Scheduler_CancelScheduledPing(node);
  EXPECT_EQ(0, Scheduler_GetTimeOfNextSchedule(node));
}

TEST_F(SchedulerTestGeneral, nothingScheduledYetWhenNothingScheduled) {
  EXPECT_EQ(true, Scheduler_NothingScheduledYet(node));
}

TEST_F(SchedulerTestGeneral, nothingScheduledYetWhenAlreadyScheduled) {
  uint64_t scheduleTime = 5;
  Scheduler_SchedulePingAtTime(node, scheduleTime);

  EXPECT_EQ(false, Scheduler_NothingScheduledYet(node));
}

TEST_F(SchedulerTestGeneral, getSlotOfNextSchedule) {
  uint64_t scheduleTime = 105;
  Scheduler_SchedulePingAtTime(node, scheduleTime);
  
  EXPECT_EQ(2, Scheduler_GetSlotOfNextSchedule(node));
}

TEST_F(SchedulerTestGeneral, scheduleNextPingUnconnected) {
  RandomNumbers_GetRandomIntBetween_fake.return_val = 123;

  StateMachine_Run(node, TURN_ON, NULL);

  Scheduler_ScheduleNextPing(node);

  EXPECT_EQ(123, Scheduler_GetTimeOfNextSchedule(node));
};

TEST_F(SchedulerTestGeneral, scheduleNextPingUnconnectedUseCorrectArguments) {
  StateMachine_Run(node, TURN_ON, NULL);

  Scheduler_ScheduleNextPing(node);

  ASSERT_EQ(5, RandomNumbers_GetRandomIntBetween_fake.arg1_history[0]);
  ASSERT_EQ(1005, RandomNumbers_GetRandomIntBetween_fake.arg2_history[0]); // depends on TestConfig initialPingUpperLimit
};

TEST_F(SchedulerTestGeneral, scheduleNextPingConnectedGoalNotMet) {
  SlotMap_SlotReservationGoalMet_fake.return_val = false;
  SlotMap_GetReservableSlot_fake.return_val = 4;
  RandomNumbers_GetRandomIntBetween_fake.return_val = 3;
  uint64_t frameStart = 0;

  TimeKeeping_SetFrameStartTime(node, frameStart);

  // set state to listening connected
  StateMachine_Run(node, TURN_ON, NULL);
  StateMachine_Run(node, INCOMING_MSG, msg);

  Scheduler_ScheduleNextPing(node);
  
  ASSERT_EQ(0, RandomNumbers_GetRandomIntBetween_fake.arg0_history[0]);
  ASSERT_EQ(8, RandomNumbers_GetRandomIntBetween_fake.arg1_history[0]);
  EXPECT_EQ(335, Scheduler_GetTimeOfNextSchedule(node)); // slot 4 start + delay*PING_SIZE + guardPeriodLength
};

TEST_F(SchedulerTestGeneral, scheduleNextPingConnectedGoalMet) {
  SlotMap_SlotReservationGoalMet_fake.return_val = true;
  SlotMap_CalculateNextOwnOrPendingSlotNum_fake.return_val = 2;
  RandomNumbers_GetRandomIntBetween_fake.return_val = 2;

  uint64_t frameStart = 0;
  TimeKeeping_SetFrameStartTime(node, frameStart);

  // set state to listening connected
  StateMachine_Run(node, TURN_ON, NULL);
  StateMachine_Run(node, INCOMING_MSG, msg);

  Scheduler_ScheduleNextPing(node);
  
  ASSERT_EQ(0, RandomNumbers_GetRandomIntBetween_fake.arg0_history[0]);
  ASSERT_EQ(8, RandomNumbers_GetRandomIntBetween_fake.arg1_history[0]);
  EXPECT_EQ(125, Scheduler_GetTimeOfNextSchedule(node)); // slot 2 start + delay*PING_SIZE + guardPeriodLength
};

TEST_F(SchedulerTestGeneral, scheduleNextPingConnectedGoalMetCurrentIsOwnSlot) {
  SlotMap_SlotReservationGoalMet_fake.return_val = true;
  SlotMap_CalculateNextOwnOrPendingSlotNum_fake.return_val = 1; // current is also slot 1 but already began
  RandomNumbers_GetRandomIntBetween_fake.return_val = 2;

  uint64_t frameStart = 0;
  TimeKeeping_SetFrameStartTime(node, frameStart);

  // set state to listening connected
  StateMachine_Run(node, TURN_ON, NULL);
  StateMachine_Run(node, INCOMING_MSG, msg);

  Scheduler_ScheduleNextPing(node);
  
  ASSERT_EQ(0, RandomNumbers_GetRandomIntBetween_fake.arg0_history[0]);
  ASSERT_EQ(8, RandomNumbers_GetRandomIntBetween_fake.arg1_history[0]);
  EXPECT_EQ(425, Scheduler_GetTimeOfNextSchedule(node)); // next slot 1 start + delay*PING_SIZE + guardPeriodLength
};
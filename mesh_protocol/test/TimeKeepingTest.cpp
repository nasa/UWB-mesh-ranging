#include <gtest/gtest.h>

extern "C" {
#include "../include/Node.h"
#include "../include/TimeKeeping.h"
#include "../include/Config.h"
#include "../test/fff.h"
}

class TimeKeepingTestGeneral : public ::testing::Test {
 protected:
  void SetUp() override {
    node = Node_Create();
    tk = TimeKeeping_Create();
    conf = Config_Create();

    Node_SetTimeKeeping(node, tk);
    Node_SetConfig(node, conf);
  }

   //void TearDown() override {}

  Node node;
  TimeKeeping tk;
  Config conf;
};

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotAtTimeSecondSlot) {
  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 105;
  EXPECT_EQ(2, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotAtTimeFirstSlot) {
  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 15;
  EXPECT_EQ(1, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotAtTimeSecondFrame) {
  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 400;
  EXPECT_EQ(1, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotAtTimeBoundary) {
  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 399;
  EXPECT_EQ(4, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotOtherFrameStart) {
  int64_t frameStartTime = 111;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 210;
  EXPECT_EQ(1, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotOtherFrameStart2) {
  int64_t frameStartTime = 111;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 211;
  EXPECT_EQ(2, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotNegativeFrameStart) {
  int64_t frameStartTime = -100;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 200;
  EXPECT_EQ(4, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateOwnSlotNegativeFrameStart2) {
  int64_t frameStartTime = -299;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t queryTime = 1701;
  EXPECT_EQ(1, TimeKeeping_CalculateOwnSlotAtTime(node, queryTime));
}

TEST_F(TimeKeepingTestGeneral, calculateCurrentSlotNumIsOneWhenNoFrameStart) {
  EXPECT_EQ(1, TimeKeeping_CalculateCurrentSlotNum(node));
}

TEST_F(TimeKeepingTestGeneral, calculateCurrentSlotNumGeneral) {
  int64_t time = 99;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  EXPECT_EQ(1, TimeKeeping_CalculateCurrentSlotNum(node));
}

TEST_F(TimeKeepingTestGeneral, calculateCurrentFrameNumIsZeroWhenNoFrameStart) {
  EXPECT_EQ(0, TimeKeeping_CalculateCurrentFrameNum(node));
}

TEST_F(TimeKeepingTestGeneral, calculateCurrentFrameNumFirstFrame) {
  int64_t time = 399;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  EXPECT_EQ(1, TimeKeeping_CalculateCurrentFrameNum(node));
}

TEST_F(TimeKeepingTestGeneral, calculateCurrentFrameNumSecondFrame) {
  int64_t time = 500;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 100;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  EXPECT_EQ(2, TimeKeeping_CalculateCurrentFrameNum(node));
}

TEST_F(TimeKeepingTestGeneral, calculateNextStartOfSlotForSlotInThisFrame) {
  int64_t time = 500;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 100;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  uint8_t querySlot = 2;
  int64_t nextStart = TimeKeeping_CalculateNextStartOfSlot(node, querySlot);

  EXPECT_EQ(600, nextStart);
}

TEST_F(TimeKeepingTestGeneral, calculateNextStartOfSlotForSlotInNextFrame) {
  int64_t time = 700;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 100;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  uint8_t querySlot = 2;
  int64_t nextStart = TimeKeeping_CalculateNextStartOfSlot(node, querySlot);

  EXPECT_EQ(1000, nextStart);
}

TEST_F(TimeKeepingTestGeneral, initialWaitTimeOverNotResetTrue) {
  int64_t time = 1000;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  bool waitTimeIsOver = TimeKeeping_InitialWaitTimeOver(node);

  EXPECT_EQ(true, waitTimeIsOver);
}

TEST_F(TimeKeepingTestGeneral, initialWaitTimeOverNotResetTrue2) {
  int64_t time = 2000;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  bool waitTimeIsOver = TimeKeeping_InitialWaitTimeOver(node);

  EXPECT_EQ(true, waitTimeIsOver);
}

TEST_F(TimeKeepingTestGeneral, initialWaitTimeOverNotResetFalse) {
  int64_t time = 999;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  bool waitTimeIsOver = TimeKeeping_InitialWaitTimeOver(node);

  EXPECT_EQ(false, waitTimeIsOver);
}

TEST_F(TimeKeepingTestGeneral, initialWaitTimeOverResetFalse) {
  int64_t time = 200;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);
  
  TimeKeeping_ResetTime(node);

  time = 1199;

  bool waitTimeIsOver = TimeKeeping_InitialWaitTimeOver(node);

  EXPECT_EQ(false, waitTimeIsOver);
}

TEST_F(TimeKeepingTestGeneral, initialWaitTimeOverResetTrue) {
  int64_t time = 200;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);
  
  TimeKeeping_ResetTime(node);

  time = 1200;

  bool waitTimeIsOver = TimeKeeping_InitialWaitTimeOver(node);

  EXPECT_EQ(true, waitTimeIsOver);
}

TEST_F(TimeKeepingTestGeneral, calculateNetworkAgeForPreamble) {
  int64_t time = 200;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  Message msg = Message_Create(PING);
  msg->timestamp = 200;
  msg->networkAge = 123;

  time = 220;
  int64_t networkAgeWhenPreambleWasReceived = TimeKeeping_CalculateNetworkAgeFromMsg(node, msg);

  EXPECT_EQ(143, networkAgeWhenPreambleWasReceived);
}

TEST_F(TimeKeepingTestGeneral, getTimeRemainingInCurrentSlotMidSlot) {
  int64_t time = 77;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t remainingTime = TimeKeeping_GetTimeRemainingInCurrentSlot(node);

  EXPECT_EQ(23, remainingTime);
}

TEST_F(TimeKeepingTestGeneral, getTimeRemainingInCurrentSlotBeginningOfSlot) {
  int64_t time = 200;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 0;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t remainingTime = TimeKeeping_GetTimeRemainingInCurrentSlot(node);

  EXPECT_EQ(100, remainingTime);
}

TEST_F(TimeKeepingTestGeneral, getTimeRemainingInCurrentSlotEndOfSlot) {
  int64_t time = 349;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 250;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t remainingTime = TimeKeeping_GetTimeRemainingInCurrentSlot(node);

  EXPECT_EQ(1, remainingTime);
}

TEST_F(TimeKeepingTestGeneral, calculateTimeSinceFrameStartFirstFrame) {
  int64_t time = 349;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 200;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t timeSinceFrameStart = TimeKeeping_CalculateTimeSinceFrameStart(node);

  EXPECT_EQ(149, timeSinceFrameStart);
}

TEST_F(TimeKeepingTestGeneral, calculateTimeSinceFrameStartSecondFrame) {
  int64_t time = 670;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 200;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t timeSinceFrameStart = TimeKeeping_CalculateTimeSinceFrameStart(node);

  EXPECT_EQ(70, timeSinceFrameStart);
}

TEST_F(TimeKeepingTestGeneral, calculateTimeSinceFrameStartSecondFrameAtStart) {
  int64_t time = 600;
  HALClock clock = HALClock_Create(&time);
  Node_SetClock(node, clock);

  int64_t frameStartTime = 200;
  TimeKeeping_SetFrameStartTime(node, frameStartTime);

  int64_t timeSinceFrameStart = TimeKeeping_CalculateTimeSinceFrameStart(node);

  EXPECT_EQ(0, timeSinceFrameStart);
}
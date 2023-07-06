#include "../include/Config.h"

Config Config_Create() {
  Config self = calloc(1, sizeof(ConfigStruct));

  // all time values in time tics
  // 4 nodes:
  self->frameLength = 10000;
  self->slotLength = 2500;
  self->slotGoal = 1;
  self->initialPingUpperLimit = 10000;
  self->initialWaitTime = 10000;
  self->guardPeriodLength = 500;
  self->networkAgeToleranceSameNetwork = 490;
  self->rangingTimeOut = 500;
  self->slotExpirationTimeOut = 12500;
  self->ownSlotExpirationTimeOut = 22500; 
  self->absentNeighborTimeOut = 15000; 
  self->rangingRefreshTime = 2500; 
  self->occupiedTimeout = 20000;
  self->occupiedToFreeTimeoutMultiHop = 12500;
  self->collidingTimeoutMultiHop = 10000;
  self->collidingTimeout = 2500;

  // // 6 nodes:
  // self->frameLength = 2100;
  // self->slotLength = 350;
  // self->slotGoal = 1;
  // self->initialPingUpperLimit = 10000;
  // self->initialWaitTime = 2100;
  // self->guardPeriodLength = 50;
  // self->networkAgeToleranceSameNetwork = 49; 
  // self->rangingTimeOut = 50;
  // self->slotExpirationTimeOut = 2450;
  // self->ownSlotExpirationTimeOut = 4200; 
  // self->absentNeighborTimeOut = 3150; 
  // self->rangingRefreshTime = 350; 
  // self->occupiedTimeout = 4200;
  // self->occupiedToFreeTimeoutMultiHop = 2450;
  // self->collidingTimeoutMultiHop = 2100;
  // self->collidingTimeout = 350;

  self->sleepFrames = 0;
  self->wakeFrames = 0; // only relevant if sleepFrames set

  return self;
};

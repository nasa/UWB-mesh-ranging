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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

#include "../include/Node.h"
#include "../include/StateMachine.h"
#include "../include/Scheduler.h"
#include "../include/StateActions.h"
#include "../include/GuardConditions.h"
#include "../include/Driver.h"
#include "../include/RangingManager.h"
#include "../include/Message.h"

#include "../include/IndividualNodeConfig.h"
#include "../include/DWM1001_Constants.h"

#include "../deca_driver/deca_device_api.h"
#include "../deca_driver/deca_regs.h"
#include "../deca_driver/deca_param_types.h"
#include "../deca_driver/deca_types.h"

#include "../deca_driver/port/port_platform.h"
#include "../UART/UART.h"
#include "../config/sdk_config.h"

#include "app_timer.h"
#include "nrf_drv_clock.h"

APP_TIMER_DEF(m_repeated_timer_id);     /**< Handler for repeated timer used to run the state machine on TIME_TIC events. */

static uint32 status_reg = 0;

static timetic_flag = false;

static uint64 get_rx_timestamp_u64(void);
static uint64 get_systime_u64(void);
static void initializeConfigStructs(StateMachine stateMachine, Scheduler scheduler, ProtocolClock clock, TimeKeeping timeKeeping, 
  NetworkManager networkManager, MessageHandler messageHandler, SlotMap slotMap, Neighborhood neighborhood, RangingManager rangingManager,
  LCG lcg, Config protocolConfig, Driver driver);

// pointer to node and time are needed in the timer event function, so we pass them as a struct
typedef struct TimerContextStruct * TimerContext;
typedef struct TimerContextStruct{
  Node node;
  int64_t *time;
} TimerContextStruct;


/**@brief Function starting the internal LFCLK oscillator.
 *
 * @details This is needed by RTC1 which is used by the Application Timer
 *          (When SoftDevice is enabled the LFCLK is always running and this is not needed).
 */
static void lfclk_request(void)
{
    ret_code_t err_code = nrf_drv_clock_init();
    APP_ERROR_CHECK(err_code);
    nrf_drv_clock_lfclk_request(NULL);
}

/**@brief Timeout handler for the repeated timer.
 */
static void repeated_timer_handler(void * p_context)
{
  // cast the context pointer back to a the struct
  TimerContextStruct *ctx = (TimerContextStruct*) p_context;

  // set flag that makes StateMachine run 
  timetic_flag = true;
  // increment the time
  ++(*(ctx->time));       
}

/**@brief Create timers.
 */
static void create_timers()
{
    ret_code_t err_code;

    // Create timers
    err_code = app_timer_create(&m_repeated_timer_id,
                                APP_TIMER_MODE_REPEATED,
                                repeated_timer_handler);
    APP_ERROR_CHECK(err_code);
}

int main(void) {

  lfclk_request();
  app_timer_init();

  // keep looping/waiting until user presses the button
  // pull pin up, cause button is connected to ground
  nrf_gpio_cfg_input(START_BTN_GPIO_PIN,NRF_GPIO_PIN_PULLUP);
  while (1) {
    int res = nrf_gpio_pin_read(START_BTN_GPIO_PIN);
    if (res == 0) {
      // break when button is pushed
      break;
    };
  };
  // these variables must be in scope during the whole execution
  bool txFinished = true;
  int64_t time = 0;

  int id = NODE_ID;
  uint32_t seed = RANDOM_SEED;

  /* Create all the structs that hold the data of the node */
  // we cannot use the Constructors on DWM1001-DEV, because they allocate the structs on the heap;
  // the heap is not sufficient so at some point calloc() returns NULL

  struct NodeStruct node;
  struct StateMachineStruct stateMachine;
  struct SchedulerStruct scheduler;
  struct ProtocolClockStruct clock;
  clock.time = &time;
  struct TimeKeepingStruct timeKeeping;
  struct NetworkManagerStruct networkManager;
  struct MessageHandlerStruct messageHandler;
  struct SlotMapStruct slotMap;
  struct NeighborhoodStruct neighborhood;
  struct RangingManagerStruct rangingManager;
  struct LCGStruct lcg;
  lcg.next = seed;
  struct ConfigStruct protocolConfig; 
  struct DriverStruct driver;
  driver.txFinishedFlag = &txFinished;

  initializeConfigStructs(&stateMachine, &scheduler, &clock, &timeKeeping, 
    &networkManager, &messageHandler, &slotMap, &neighborhood, &rangingManager,
    &lcg, &protocolConfig, &driver);

  // set the structs as pointers for the Node struct, so we only have to pass around the Node struct
  Node_SetDriver(&node, &driver);
  Node_SetStateMachine(&node, &stateMachine);
  Node_SetScheduler(&node, &scheduler);
  Node_SetClock(&node, &clock);
  Node_SetTimeKeeping(&node, &timeKeeping);
  Node_SetNetworkManager(&node, &networkManager);
  Node_SetMessageHandler(&node, &messageHandler);
  Node_SetSlotMap(&node, &slotMap);
  Node_SetNeighborhood(&node, &neighborhood);
  Node_SetRangingManager(&node, &rangingManager);
  Node_SetLCG(&node, &lcg);
  Node_SetConfig(&node, &protocolConfig);

  node.id = id;

  /* Set up the timer that runs the state machine on time tics */
  // Config is done in sdk_config.h

  // add the node and time as context pointer, so we have them available in the timer handler function
  struct TimerContextStruct timerContext;
  timerContext.node = &node;
  timerContext.time = &time;

  create_timers();
  
  // start timer
  ret_code_t err_code;
  err_code = app_timer_start(m_repeated_timer_id, APP_TIMER_TICKS(TICS_PER_SECOND/1000), &timerContext);
  APP_ERROR_CHECK(err_code);

  /* Set up DWM1000 */

  /* Setup DW1000 IRQ pin */  
  nrf_gpio_cfg_input(DW1000_IRQ, NRF_GPIO_PIN_NOPULL); 		//irq

  /*Initialization UART*/
  boUART_Init ();
  
  /* Reset DW1000 */
  reset_DW1000(); 

  /* Set SPI clock to 2MHz */
  port_set_dw1000_slowrate();			
  
  /* Init the DW1000 */
  if (dwt_initialise(DWT_LOADUCODE) == DWT_ERROR)
  {
    //Init of DW1000 Failed
    while (1) {};
  }

  // Read antenna delay from OTP
  uint32_t ant_delay;
  dwt_otpread(0x01c, &ant_delay, 1);

  // Add antenna delay to driver so it can be read when handling the ranging messages
  node.driver->rx_antenna_delay = ant_delay;
  node.driver->tx_antenna_delay = ant_delay;
  
  // Set SPI to 8MHz clock
  port_set_dw1000_fastrate();

    /* Configure DW1000. */
  dwt_configure(&config);

  /* Apply default antenna delay value. */
  dwt_setrxantennadelay(node.driver->rx_antenna_delay);
  dwt_settxantennadelay(node.driver->tx_antenna_delay);

  /* Set preamble timeout for expected frames. */
  dwt_setpreambledetecttimeout(PRE_TIMEOUT); // PRE_TIMEOUT; specified as multiple of PAC size; e.g. PAC size 8 takes roughly 8us to transmit, timeout of 125 then equals 1ms; 0 means no timeout
          
  /* Set expected response's delay and timeout. */
  dwt_setrxaftertxdelay(POLL_TX_TO_RESP_RX_DLY_UUS);
  dwt_setrxtimeout(RX_TIMEOUT); // Maximum value timeout with DW1000 is 65ms; 0 means no timeout

  printf("STARTING \n");

  // turn on node
  StateMachine_Run(&node, TURN_ON, NULL);

  // start main loop
  while(1) {

    // enable receiver if transmission is finished
    int8_t state = dwt_read8bitoffsetreg(SYS_STATE_ID, 2);
    bool isIdle = (state == 0x01);
    bool isRx = (state == 0x05);
    bool isRxWait = (state == 0x03);

    if(isIdle) {
      dwt_rxenable(DWT_START_RX_IMMEDIATE);
    };

    if (isIdle | isRx | isRxWait) {
      // poll for messages
      while (!((status_reg = dwt_read32bitreg(SYS_STATUS_ID)) & (SYS_STATUS_RXFCG | SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR))) {
        if (timetic_flag) {
          timetic_flag = false;

          // fix the time so that it does not change during execution of state machine
          ProtocolClock_FixLocalTime(node.clock);

          StateMachine_Run(&node, TIME_TIC, NULL);

          // unfix the time
          ProtocolClock_UnfixLocalTime(node.clock);
        };
      };

      // If a message was received, run the state machine with INCOMING_MSG event
      if (dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_RXFCG) {
        // received message
        int64_t localTime = ProtocolClock_GetLocalTime((&node)->clock);
        uint8_t slotNum = TimeKeeping_CalculateCurrentSlotNum((&node));
      
        uint32 frame_len;

        /* Clear good RX frame event in the DW1000 status register. */
        dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_RXFCG);

        /* A frame has been received, read it into the local buffer. */
        frame_len = dwt_read32bitreg(RX_FINFO_ID) & RX_FINFO_RXFL_MASK_1023;
        if (frame_len <= RX_BUFFER_LEN)
        {
          dwt_readrxdata(rx_buffer, frame_len, 0);
        };

        /** Create message from the data that was received */
        Message msg;
        struct MessageStruct message;
        msg = &message;

        // first check if it is a ranging message or not
        if (dwt_read32bitreg(RX_FINFO_ID) & RX_FINFO_RNG) {
          // it is a ranging message

          /* Check that the frame is a poll sent by "SS TWR initiator" example.
          * As the sequence number field of the frame is not relevant, it is cleared to simplify the validation of the frame. */
          rx_buffer[ALL_MSG_SN_IDX] = 0;

          // check if this node is the intended recipient of the message
          if (rx_buffer[DESTINATION_ID_IDX] == node.id) {
            // determine the type of ranging message
            if (memcmp(rx_buffer, rx_poll_msg, ALL_MSG_COMMON_LEN_FIRST_PART) == 0 
              && rx_buffer[MSG_IDX_SECOND_PART] == rx_poll_msg[MSG_IDX_SECOND_PART]) {
              // it is a POLL

              /* Calculate timestamp of arrival in time tics */
              int64_t currentTime = ProtocolClock_GetLocalTime((&node)->clock);
              uint64 sys_time = (get_systime_u64()/US_TO_DWT);
              uint64 rx_time = (get_rx_timestamp_u64()/US_TO_DWT);
              uint64 timediffToNow = round((sys_time - rx_time)/(1000000/TICS_PER_SECOND));

  #if DEBUG_VERBOSE
              printf("%d: Node %" PRId8 " received POLL in slot %" PRIu8 " \r\n", (int) localTime, node.id, slotNum);
  #endif
              msg->type = POLL;

              msg->recipientId = rx_buffer[DESTINATION_ID_IDX];
              msg->senderId = rx_buffer[SOURCE_ID_IDX];

              // use the current time and subtract the difference between the rx_timestamp and the systime of the DW1000 to
              // account for messages that take more than 1ms to complete
              msg->timestamp = currentTime - timediffToNow;

              // add pointer to rx_buffer to the message so the Driver can access it
              msg->rx_buffer = &rx_buffer[0];
              msg->frame_len = frame_len;
        
              // run state machine (happens after this if/else structure)

            } else if (memcmp(rx_buffer, rx_resp_msg, ALL_MSG_COMMON_LEN_FIRST_PART) == 0 
              && rx_buffer[MSG_IDX_SECOND_PART] == rx_resp_msg[MSG_IDX_SECOND_PART]) {
              // it is a RESPONSE

              /* Calculate timestamp of arrival in time tics */
              int64_t currentTime = ProtocolClock_GetLocalTime((&node)->clock);
              uint64 sys_time = (get_systime_u64()/US_TO_DWT);
              uint64 rx_time = (get_rx_timestamp_u64()/US_TO_DWT);
              uint64 timediffToNow = round((sys_time - rx_time)/(1000000/TICS_PER_SECOND));

  #if DEBUG_VERBOSE
              printf("%d: Node %" PRId8 " received RESPONSE in slot %" PRIu8 " \r\n", (int) localTime, node.id, slotNum);
  #endif
              msg->type = RESPONSE;
          
              msg->recipientId = rx_buffer[DESTINATION_ID_IDX];
              msg->senderId = rx_buffer[SOURCE_ID_IDX];

              // use the current time and subtract the difference between the rx_timestamp and the systime of the DW1000 to
              // account for messages that take more than 1ms to complete
              msg->timestamp = currentTime - timediffToNow;

              // add pointer to rx_buffer to the message so the Driver can access it
              msg->rx_buffer = &rx_buffer[0];
              msg->frame_len = frame_len;

              // run state machine (happens after this if/else structure

            } else if (memcmp(rx_buffer, rx_final_msg, ALL_MSG_COMMON_LEN_FIRST_PART) == 0 
              && rx_buffer[MSG_IDX_SECOND_PART] == rx_final_msg[MSG_IDX_SECOND_PART]) {
              // it is a FINAL
              /* Calculate timestamp of arrival in time tics */
              int64_t currentTime = ProtocolClock_GetLocalTime((&node)->clock);
              uint64 sys_time = (get_systime_u64()/US_TO_DWT);
              uint64 rx_time = (get_rx_timestamp_u64()/US_TO_DWT);
              uint64 timediffToNow = round((sys_time - rx_time)/(1000000/TICS_PER_SECOND));

  #if DEBUG_VERBOSE
              printf("%d: Node %" PRId8 " received FINAL in slot %" PRIu8 " \r\n", (int) localTime, node.id, slotNum);
  #endif
              msg->type = FINAL;
          
              msg->recipientId = rx_buffer[DESTINATION_ID_IDX];
              msg->senderId = rx_buffer[SOURCE_ID_IDX];

              // use the current time and subtract the difference between the rx_timestamp and the systime of the DW1000 to
              // account for messages that take more than 1ms to complete
              msg->timestamp = currentTime - timediffToNow;

              // add pointer to rx_buffer to the message so the Driver can access it
              msg->rx_buffer = &rx_buffer[0];
              msg->frame_len = frame_len;

              // run state machine (happens after this if/else structure
                    
            } else if (memcmp(rx_buffer, rx_result_msg, ALL_MSG_COMMON_LEN_FIRST_PART) == 0 
              && rx_buffer[MSG_IDX_SECOND_PART] == rx_result_msg[MSG_IDX_SECOND_PART]) {
              // it is a RESULT

              /* Calculate timestamp of arrival in time tics */
              int64_t currentTime = ProtocolClock_GetLocalTime((&node)->clock);
              uint64 sys_time = (get_systime_u64()/US_TO_DWT);
              uint64 rx_time = (get_rx_timestamp_u64()/US_TO_DWT);
              uint64 timediffToNow = round((sys_time - rx_time)/(1000000/TICS_PER_SECOND));

  #if DEBUG_VERBOSE
              printf("%d: Node %" PRId8 " received RESULT in slot %" PRIu8 " \r\n", (int) localTime, node.id, slotNum);
  #endif

              msg->type = RESULT;

              msg->recipientId = rx_buffer[DESTINATION_ID_IDX];
              msg->senderId = rx_buffer[SOURCE_ID_IDX];

              // use the current time and subtract the difference between the rx_timestamp and the systime of the DW1000 to
              // account for messages that take more than 1ms to complete
              msg->timestamp = currentTime - timediffToNow;

              // add pointer to rx_buffer to the message so the Driver can access it
              msg->rx_buffer = &rx_buffer[0];
              msg->frame_len = frame_len;

              union {
                float distanceVal;
                unsigned char bytes[4];
              } dist;
              dist.bytes[0] = rx_buffer[RESULT_MSG_DIST_IDX];
              dist.bytes[1] = rx_buffer[RESULT_MSG_DIST_IDX + 1];
              dist.bytes[2] = rx_buffer[RESULT_MSG_DIST_IDX + 2];
              dist.bytes[3] = rx_buffer[RESULT_MSG_DIST_IDX + 3];

              float distance = dist.distanceVal;
              msg->distance = distance;
  #if DEBUG || DEBUG_VERBOSE
              printf("Received resulting distance to Node %d: %f \n", msg->senderId, distance);
  #endif
  #if EVAL
              uint8_t slotNum = TimeKeeping_CalculateCurrentSlotNum(&node);
              printf("RX DIST %d %f %d %d 0 \n", msg->senderId, distance, (int) (currentTime - timediffToNow), (int) slotNum);
  #endif
            };

            // fix the time so that it does not change during execution of state machine
            ProtocolClock_FixLocalTime(node.clock);

            // run state machine with incoming message
            StateMachine_Run(&node, INCOMING_MSG, msg);

            // unfix the time
            ProtocolClock_UnfixLocalTime(node.clock);
          
          };

        } else {

          /* Calculate timestamp of arrival in time tics */
          int64_t currentTime = ProtocolClock_GetLocalTime((&node)->clock);
          uint64 sys_time = (get_systime_u64()/US_TO_DWT);
          uint64 rx_time = (get_rx_timestamp_u64()/US_TO_DWT);
          uint64 timediffToNow = round((sys_time - rx_time)/(1000000/TICS_PER_SECOND)); // sys_time and rx_time are in microseconds (1000000 us per s)

  #if DEBUG || DEBUG_VERBOSE
          printf("%d: Node %" PRId8 " received ping message in slot %" PRIu8 " \r\n", (int) localTime, node.id, slotNum);
  #endif
          // it is not a ranging message (i.e. it is a PING)
          int offset = 0;
          // create values out of the byte array by shifting the bits correctly
          int32_t type = (rx_buffer[offset]) + (rx_buffer[offset + 1] << 8) + (rx_buffer[offset + 2] << 16) + (rx_buffer[offset + 3] << 24);

          msg->type = PING;

          offset += sizeof(int);
          msg->senderId = rx_buffer[offset];

          offset += sizeof(int8_t);
          msg->recipientId = rx_buffer[offset];

          offset += sizeof(int8_t);
          msg->networkId = rx_buffer[offset];

          offset += sizeof(int8_t);
          msg->networkAge = rx_buffer[offset] + (rx_buffer[offset + 1] << 8) + (rx_buffer[offset + 2] << 16) + (rx_buffer[offset + 3] << 24)
            + (rx_buffer[offset + 4] << 32) + (rx_buffer[offset + 5] << 40) + (rx_buffer[offset + 6] << 48) + (rx_buffer[offset + 7] << 56);

          offset += sizeof(int64_t);
          msg->timeSinceFrameStart = rx_buffer[offset] + (rx_buffer[offset + 1] << 8) + (rx_buffer[offset + 2] << 16) + (rx_buffer[offset + 3] << 24)
            + (rx_buffer[offset + 4] << 32) + (rx_buffer[offset + 5] << 40) + (rx_buffer[offset + 6] << 48) + (rx_buffer[offset + 7] << 56);

          offset += sizeof(int64_t);
          for(int i = 0; i < NUM_SLOTS; ++i) {
            msg->oneHopSlotStatus[i] = (rx_buffer[offset + i*sizeof(int)]) + (rx_buffer[offset + i*sizeof(int) + 1] << 8) + (rx_buffer[offset + i*sizeof(int) + 2] << 16) + (rx_buffer[offset + i*sizeof(int) + 3] << 24);
          };

          offset += (sizeof(int) * NUM_SLOTS);
          for(int i = 0; i < NUM_SLOTS; ++i) {
            msg->oneHopSlotIds[i] = rx_buffer[offset + i];
          };

          offset += sizeof(int8_t) * NUM_SLOTS;
          for(int i = 0; i < NUM_SLOTS; ++i) {
            msg->twoHopSlotStatus[i] = (rx_buffer[offset + i*sizeof(int)]) + (rx_buffer[offset + i*sizeof(int) + 1] << 8) + (rx_buffer[offset + i*sizeof(int) + 2] << 16) + (rx_buffer[offset + i*sizeof(int) + 3] << 24);
          };

          offset += sizeof(int) * NUM_SLOTS;
          for(int i = 0; i < NUM_SLOTS; ++i) {
            msg->twoHopSlotIds[i] = rx_buffer[offset + i];
          };

          offset += sizeof(int8_t) * NUM_SLOTS;
          msg->pingNum = rx_buffer[offset];

          // use the current time and subtract the difference between the rx_timestamp and the systime of the DW1000 to
          // account for messages that take more than 1ms to complete
          msg->timestamp = currentTime - timediffToNow;

  #if DEBUG_VERBOSE
          // print information about the received message (if debugging, keep in mind this is what the other node "sees", not this one)
          printf("Type: % " PRId32 " \n", type);
          printf("Sender: %" PRId8 "\n", msg->senderId);
          printf("Network: %" PRIu8 "\n", msg->networkId);
          for(int i = 0; i < NUM_SLOTS; ++i) {
            printf("1H (S%d): %d \n", (i+1), msg->oneHopSlotStatus[i]);
            printf("1H ID (S%d): %" PRId8 "\n", (i+1), msg->oneHopSlotIds[i]);
            printf("2H (S%d): %d \n", (i+1), msg->twoHopSlotStatus[i]);
            printf("2H ID (S%d): %" PRId8 "\n", (i+1), msg->twoHopSlotIds[i]);
          };
  #endif

  #if DEBUG || DEBUG_VERBOSE
          printf("Ping %d by Node %d \n", msg->pingNum, msg->senderId);
  #endif

          // fix the time so that it does not change during execution of state machine
          ProtocolClock_FixLocalTime(node.clock);

          // run state machine with incoming message
          StateMachine_Run(&node, INCOMING_MSG, msg);

          // unfix the time
          ProtocolClock_UnfixLocalTime(node.clock);

        
  #if EVAL
          uint8_t slotNum = TimeKeeping_CalculateCurrentSlotNum(&node);
          printf("RX PING %d 0 %d %d %d \n", msg->senderId, (int) (currentTime - timediffToNow), (int) slotNum, (int) msg->pingNum);
  #endif

        };

        // clear the rx_buffer
        memset(&rx_buffer, 0, RX_BUF_LEN);

      } else {
        /* Clear RX error/timeout events in the DW1000 status register. */
        dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_ALL_RX_TO | SYS_STATUS_ALL_RX_ERR);

        /* Reset RX to properly reinitialise LDE operation. */
        dwt_rxreset();
      };
    };
  };
}

/*! ------------------------------------------------------------------------------------------------------------------
* COPIED FROM SS_RESP_MAIN.c
* @fn get_rx_timestamp_u64()
*
* @brief Get the RX time-stamp in a 64-bit variable.
*        /!\ This function assumes that length of time-stamps is 40 bits, for both TX and RX!
*
* @param  none
*
* @return  64-bit value of the read time-stamp.
*/
static uint64 get_rx_timestamp_u64(void)
{
  uint8 ts_tab[5];
  uint64 ts = 0;
  int i;
  dwt_readrxtimestamp(ts_tab);
  for (i = 4; i >= 0; i--)
  {
    ts <<= 8;
    ts |= ts_tab[i];
  }
  return ts;
}

static uint64 get_systime_u64(void)
{
  uint8 ts_tab[5];
  uint64 ts = 0;
  int i;
  dwt_readsystime(ts_tab);
  for (i = 4; i >= 0; i--)
  {
    ts <<= 8;
    ts |= ts_tab[i];
  }
  return ts;
}

static void initializeConfigStructs(StateMachine stateMachine, Scheduler scheduler, ProtocolClock clock, TimeKeeping timeKeeping, 
  NetworkManager networkManager, MessageHandler messageHandler, SlotMap slotMap, Neighborhood neighborhood, RangingManager rangingManager,
  LCG lcg, Config protocolConfig, Driver driver) {

  // do all the static initialization

  // StateMachine
  stateMachine->state = 0;

  // Scheduler
  scheduler->timeNextSchedule = -1;

  // ProtocolClock
  clock->correctionValue = 0;

  // TimeKeeping
  timeKeeping->frameStartSet = false;
  timeKeeping->frameStartTime = 0;
  timeKeeping->lastIdledTime = 0;
  timeKeeping->lastResetAt = 0;

  // NetworkManager
  networkManager->currentNetworkStartedByThisNode = false;
  networkManager->localTimeAtJoining = 0;
  networkManager->networkAgeAtJoining = 0;
  networkManager->networkId = 0;
  networkManager->networkStatus = NOT_CONNECTED;

  // SlotMap
  int i;
  for (i = 0; i < NUM_SLOTS; ++i) {
    slotMap->oneHopSlotsStatus[i] = 0;
    slotMap->oneHopSlotsIds[i] = 0;
    slotMap->oneHopSlotsLastUpdated[i] = 0;
    slotMap->twoHopSlotsStatus[i] = 0;
    slotMap->twoHopSlotsIds[i] = 0;
    slotMap->twoHopSlotsLastUpdated[i] = 0;
    slotMap->threeHopSlotsStatus[i] = 0;
    slotMap->threeHopSlotsIds[i] = 0;
    slotMap->threeHopSlotsLastUpdated[i] = 0;
  };
  slotMap->numPendingSlots = 0;
  for (i = 0; i < MAX_NUM_PENDING_SLOTS; ++i) {
    slotMap->pendingSlots[i] = -1;
    slotMap->localTimePendingSlotAdded[i] = -1;
    int j;
    for (j = 0; j < (MAX_NUM_NODES - 1); ++j) {
      slotMap->pendingSlotsNeighbors[i][j] = -1;
      slotMap->pendingSlotAcknowledgedBy[i][j] = -1;
    };
  };
  slotMap->numOwnSlots = 0;
  for (i = 0; i < MAX_NUM_OWN_SLOTS; ++i) {
    slotMap->ownSlots[i] = 0;
  };
  slotMap->lastReservationTime = 0;
  
  // Neighborhood
  neighborhood->numOneHopNeighbors = 0;
  for (i = 0; i < (MAX_NUM_NODES - 1); ++i) {
    neighborhood->oneHopNeighbors[i] = 0;
    neighborhood->oneHopNeighborsJoinedTime[i] = 0;
    neighborhood->oneHopNeighborsLastRanging[i] = 0;
    neighborhood->oneHopNeighborsLastSeen[i] = 0;
  };

  // RangingManager
  rangingManager->lastIncomingRangingMsg = 0;
  rangingManager->lastRangingMsgInTime = 0;
  rangingManager->lastRangingMsgOutTime = 0;

  // Config
  // 6 nodes:
  protocolConfig->frameLength = 1200;
  protocolConfig->slotLength = 200;
  protocolConfig->slotGoal = 1;
  protocolConfig->initialPingUpperLimit = 1000;
  protocolConfig->initialWaitTime = 1200;
  protocolConfig->guardPeriodLength = 20;
  protocolConfig->networkAgeToleranceSameNetwork = 19; 
  protocolConfig->rangingTimeOut = 20;
  protocolConfig->slotExpirationTimeOut = 1400;
  protocolConfig->ownSlotExpirationTimeOut = 2400; 
  protocolConfig->absentNeighborTimeOut = 1800; 
  protocolConfig->rangingRefreshTime = 160; 
  protocolConfig->occupiedTimeout = 2400;
  protocolConfig->occupiedToFreeTimeoutMultiHop = 1400;
  protocolConfig->collidingTimeoutMultiHop = 1200;
  protocolConfig->collidingTimeout = 200;

  protocolConfig->sleepFrames = 0;
  protocolConfig->wakeFrames = 0; // only relevant if sleepFrames set
  // Driver  
  driver->lastTxStartTime = 0;
};

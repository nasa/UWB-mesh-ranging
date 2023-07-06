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

/** Driver to run the protocol on the DWM1001-DEV board
*
*/
#include "../include/DWM1001_Constants.h"
#include "../include/Driver.h"
#include "../deca_driver/deca_device_api.h"

/** DECAWAVE RANGING VARIABLES */

/* Frame sequence number, incremented after each transmission. */
static uint8 frame_seq_nb = 0;

/* Hold copy of status register state here for reference so that it can be examined at a debug breakpoint. */
static uint32 status_reg = 0;

/* Timestamps of frames transmission/reception. */
static uint64 poll_tx_ts;
static uint64 resp_rx_ts;
static uint64 final_tx_ts;

static uint64 poll_rx_ts;
static uint64 resp_tx_ts;
static uint64 final_rx_ts;

/* Hold copies of computed time of flight and distance here for reference so that it can be examined at a debug breakpoint. */
static double tof;
static double distance;

/*Transactions Counters */
static volatile int tx_count = 0 ; // Successful transmit counter
static volatile int rx_count = 0 ; // Successful receive counter 

/** END DECAWAVE RANGING VARIABLES */

static uint64 get_tx_timestamp_u64(void);
static uint64 get_rx_timestamp_u64(void);
static void final_msg_set_ts(uint8 *ts_field, uint64 ts);
static void final_msg_get_ts(const uint8 *ts_field, uint32 *ts);


Driver Driver_Create(bool *txFinishedFlag, bool *isReceiving) {
  // allocate memory for the Driver struct
  Driver self = calloc(1, sizeof(DriverStruct));
  
  self->txFinishedFlag = txFinishedFlag;
  self->sentMessage = false;

  return self;
};

bool Driver_SendingFinished(Node node) {
  // if the txFinishedFlag is false, check if transmission is finished by now
  if (!(*node->driver->txFinishedFlag)) {
    // check if TXFRS bit (bit 7) is set, which means the transmission is finished
    *node->driver->txFinishedFlag = dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS; 
  };
  
  return *node->driver->txFinishedFlag; 
};

void Driver_TransmitPing(Node node, Message msg) {

  static int16_t pingsSent = 0;

  /* Turn off the receiver, so that a message can be sent */
  dwt_forcetrxoff();

  /** Write the Message to the TX buffer of DW1000 */
  // write type
  uint8_t buffer[127]; // 127 is maximum length in non-extended mode
  // set all to zero first
  memset(buffer, 0, 127);
  // offset is the current index in the buffer 
  int offset = 0;
  //dwt_writetodevice(TX_BUFFER_ID, offset, sizeof(msg->type), *msg->type);
  int tmp = msg->type;
  memcpy(&buffer[0], &tmp, sizeof(int));

  // write senderId
  offset += sizeof(int);
  memcpy(&buffer[offset], &node->id, sizeof(int8_t));
  // write recipientId
  offset += sizeof(int8_t);
  memcpy(&buffer[offset], &msg->recipientId, sizeof(int8_t));
  // write networkId
  offset += sizeof(int8_t);
  memcpy(&buffer[offset], &msg->networkId, sizeof(uint8_t));
  // write networkAge
  offset += sizeof(uint8_t);
  memcpy(&buffer[offset], &msg->networkAge, sizeof(int64_t));
  // write timeSinceFrameStart
  offset += sizeof(int64_t);
  memcpy(&buffer[offset], &msg->timeSinceFrameStart, sizeof(int64_t));
  // write oneHopSlotStatus
  offset += sizeof(int64_t);
  memcpy(&buffer[offset], &msg->oneHopSlotStatus, sizeof(int) * NUM_SLOTS);
  // write oneHopSlotIds
  offset += (sizeof(int) * NUM_SLOTS);
  memcpy(&buffer[offset], &msg->oneHopSlotIds, sizeof(int8_t) * NUM_SLOTS);
  // write twoHopSlotStatus
  offset += (sizeof(int8_t) * NUM_SLOTS);
  memcpy(&buffer[offset], &msg->twoHopSlotStatus, sizeof(int) * NUM_SLOTS);
  // write twoHopSlotIds
  offset += (sizeof(int) * NUM_SLOTS);
  memcpy(&buffer[offset], &msg->twoHopSlotIds, sizeof(int8_t) * NUM_SLOTS);
  offset += (sizeof(int8_t) * NUM_SLOTS);

  memcpy(&buffer[offset], &pingsSent, sizeof(int16_t));
  offset += (sizeof(int16_t));

  // clear TXFRS
  dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);
  // calculate length of frame
  uint16_t length = offset + 2; // framelength must be two bytes longer than data to account for CRC 
  dwt_writetxdata(length, buffer, 0);

  /** Set transmit frame control register */
  dwt_writetxfctrl(length, 0, 0);

  /** Start transmission */
  int ret = dwt_starttx(DWT_START_TX_IMMEDIATE);

  if (ret == DWT_ERROR) {
    printf("TRANSMISSION FAILED \n");
  };

  *node->driver->txFinishedFlag = false;

  /* Poll DW1000 until TX frame sent event set. See NOTE 5 below. */
  while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS))
  {};

  /* Clear TXFRS event. */
  dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);

  *node->driver->txFinishedFlag = true;
  
  // reenable the receiver
  dwt_rxenable(DWT_START_RX_IMMEDIATE);

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  uint8_t slotNum = TimeKeeping_CalculateCurrentSlotNum(node);

#if DEBUG
  printf("%d: Node %" PRId8 " sent ping %d in slot %" PRIu8 " \n", (int) localTime, node->id, pingsSent, slotNum);
#endif

#if EVAL
  printf("TX PING %d 0 %d %d %d \n", (int) node->id, (int) localTime, (int) slotNum, (int) pingsSent);
#endif

  pingsSent += 1;
};

void Driver_TransmitPoll(Node node, Message msg) {
  /* Turn off the receiver, so that a message can be sent */
  dwt_forcetrxoff();

  /** See description in Driver_TransmitPing */

  /* Write frame data to DW1000 and prepare transmission. See NOTE 8 below. */
  tx_poll_msg[ALL_MSG_SN_IDX] = frame_seq_nb;

  // write ID of source (own ID) and destination (intended recipient's ID); only one of the bytes is currently used
  // source:
  tx_poll_msg[5] = 0;
  tx_poll_msg[6] = node->id;
  // destination:
  tx_poll_msg[7] = 0;
  tx_poll_msg[8] = msg->recipientId;

  dwt_writetxdata(sizeof(tx_poll_msg), tx_poll_msg, 0); /* Zero offset in TX buffer. */
  dwt_writetxfctrl(sizeof(tx_poll_msg), 0, 1); /* Zero offset in TX buffer, ranging. */

  /* Start transmission, indicating that a response is expected so that reception is enabled automatically after the frame is sent and the delay
   * set by dwt_setrxaftertxdelay() has elapsed. */
  dwt_starttx(DWT_START_TX_IMMEDIATE | DWT_RESPONSE_EXPECTED);

  *node->driver->txFinishedFlag = false;

  /* Poll DW1000 until TX frame sent event set. See NOTE 5 below. */
  while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS))
  {};

  /* Clear TXFRS event. */
  dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);

  *node->driver->txFinishedFlag = true;

  // reenable the receiver
  dwt_rxenable(DWT_START_RX_IMMEDIATE);

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
#if DEBUG_VERBOSE
  printf("%d: Node %" PRId8 " sent POLL \n", (int) localTime, node->id);
#endif
};

void Driver_TransmitResponse(Node node, Message msg) {
  /* Turn off the receiver, so that a message can be sent */
  dwt_forcetrxoff();

  /** See description in Driver_TransmitPing */

  uint32 resp_tx_time;
  int ret;

  /* Retrieve poll reception timestamp. */
  poll_rx_ts = get_rx_timestamp_u64();

  /* Set send time for response. See NOTE 9 below. */
  resp_tx_time = (poll_rx_ts + (POLL_RX_TO_RESP_TX_DLY_UUS * UUS_TO_DWT_TIME)) >> 8;
  dwt_setdelayedtrxtime(resp_tx_time);

  /* Set expected delay and timeout for final message reception. See NOTE 4 and 5 below. */
  dwt_setrxaftertxdelay(RESP_TX_TO_FINAL_RX_DLY_UUS);
  dwt_setrxtimeout(FINAL_RX_TIMEOUT_UUS);

  /* Write and send the response message. See NOTE 10 below.*/
  tx_resp_msg[ALL_MSG_SN_IDX] = frame_seq_nb;

  // write ID of source (own ID) and destination (intended recipient's ID); only one of the bytes is currently used
  // source:
  tx_resp_msg[5] = 0;
  tx_resp_msg[6] = node->id;
  // destination:
  tx_resp_msg[7] = 0;
  tx_resp_msg[8] = msg->senderId; // destination of response is the sender of the poll

  dwt_writetxdata(sizeof(tx_resp_msg), tx_resp_msg, 0); /* Zero offset in TX buffer. */
  dwt_writetxfctrl(sizeof(tx_resp_msg), 0, 1); /* Zero offset in TX buffer, ranging. */
  ret = dwt_starttx(DWT_START_TX_DELAYED | DWT_RESPONSE_EXPECTED);

  if (ret == DWT_ERROR) {
    // reenable the receiver
    dwt_rxenable(DWT_START_RX_IMMEDIATE);
    return;
  };

  *node->driver->txFinishedFlag = false;

  if (ret == DWT_SUCCESS) {
    /* Poll DW1000 until TX frame sent event set. See NOTE 5 below. */
    while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS))
    {};

    /* Clear TXFRS event. */
    dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);

    *node->driver->txFinishedFlag = true;

    /* Increment frame sequence number after transmission of the poll message (modulo 256). */
    frame_seq_nb++;

    int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
#if DEBUG_VERBOSE
    printf("%d: Node %" PRId8 " sent RESPONSE \n", (int) localTime, node->id);
#endif
  } else {
  /* If we end up in here then we have not succeded in transmitting the packet we sent up.
  POLL_RX_TO_RESP_TX_DLY_UUS is a critical value for porting to different processors. 
  For slower platforms where the SPI is at a slower speed or the processor is operating at a lower 
  frequency (Comparing to STM32F, SPI of 18MHz and Processor internal 72MHz)this value needs to be increased.
  Knowing the exact time when the responder is going to send its response is vital for time of flight 
  calculation. The specification of the time of respnse must allow the processor enough time to do its 
  calculations and put the packet in the Tx buffer. So more time is required for a slower system(processor).
  */

  /* Reset RX to properly reinitialise LDE operation. */
  dwt_rxreset();

  *node->driver->txFinishedFlag = true;
  }

  // reenable the receiver
  dwt_rxenable(DWT_START_RX_IMMEDIATE);

};

void Driver_TransmitFinal(Node node, Message msg) {
  /** See description in Driver_TransmitPing */

  /* Turn off the receiver, so that a message can be sent */
  dwt_forcetrxoff();

  uint32 final_tx_time;
  int ret;

  /* Retrieve poll transmission and response reception timestamp. */
  poll_tx_ts = get_tx_timestamp_u64();
  resp_rx_ts = get_rx_timestamp_u64();

  /* Compute final message transmission time. See NOTE 10 below. */
  final_tx_time = (resp_rx_ts + (RESP_RX_TO_FINAL_TX_DLY_UUS * UUS_TO_DWT_TIME)) >> 8;
  dwt_setdelayedtrxtime(final_tx_time);

  /* Final TX timestamp is the transmission time we programmed plus the TX antenna delay. */
  final_tx_ts = (((uint64)(final_tx_time & 0xFFFFFFFEUL)) << 8) + node->driver->tx_antenna_delay;

  /* Write all timestamps in the final message. See NOTE 11 below. */
  final_msg_set_ts(&tx_final_msg[FINAL_MSG_POLL_TX_TS_IDX], poll_tx_ts);
  final_msg_set_ts(&tx_final_msg[FINAL_MSG_RESP_RX_TS_IDX], resp_rx_ts);
  final_msg_set_ts(&tx_final_msg[FINAL_MSG_FINAL_TX_TS_IDX], final_tx_ts);

  /* Write and send final message. See NOTE 8 below. */
  tx_final_msg[ALL_MSG_SN_IDX] = frame_seq_nb;

  // write ID of source (own ID) and destination (intended recipient's ID); only one of the bytes is currently used
  // source:
  tx_final_msg[5] = 0;
  tx_final_msg[6] = node->id;
  // destination:
  tx_final_msg[7] = 0;
  tx_final_msg[8] = msg->senderId; // destination of final is the sender of the response

  dwt_writetxdata(sizeof(tx_final_msg), tx_final_msg, 0); /* Zero offset in TX buffer. */
  dwt_writetxfctrl(sizeof(tx_final_msg), 0, 1); /* Zero offset in TX buffer, ranging. */
  ret = dwt_starttx(DWT_START_TX_DELAYED);

  /* Poll DW1000 until TX frame sent event set. See NOTE 5 below. */
  while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS))
  {};

  /* Clear TXFRS event. */
  dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);

  *node->driver->txFinishedFlag = true;

  // reenable the receiver
  dwt_rxenable(DWT_START_RX_IMMEDIATE);

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);

#if DEBUG_VERBOSE
  printf("%d: Node %" PRId8 " sent FINAL \n", (int) localTime, node->id);
#endif
};

void Driver_TransmitResult(Node node, Message msg) {
  ///** See description in Driver_TransmitPing */

  // calculate and print distance
  uint32 poll_tx_ts, resp_rx_ts, final_tx_ts;
  uint32 poll_rx_ts_32, resp_tx_ts_32, final_rx_ts_32;
  double Ra, Rb, Da, Db;
  int64 tof_dtu;

  /* Retrieve response transmission and final reception timestamps. */
  resp_tx_ts = get_tx_timestamp_u64();
  final_rx_ts = get_rx_timestamp_u64();

  /* Get timestamps embedded in the final message. */
  final_msg_get_ts(&msg->rx_buffer[FINAL_MSG_POLL_TX_TS_IDX], &poll_tx_ts);
  final_msg_get_ts(&msg->rx_buffer[FINAL_MSG_RESP_RX_TS_IDX], &resp_rx_ts);
  final_msg_get_ts(&msg->rx_buffer[FINAL_MSG_FINAL_TX_TS_IDX], &final_tx_ts);

  /* Compute time of flight. 32-bit subtractions give correct answers even if clock has wrapped. See NOTE 12 below. */
  poll_rx_ts_32 = (uint32)poll_rx_ts;
  resp_tx_ts_32 = (uint32)resp_tx_ts;
  final_rx_ts_32 = (uint32)final_rx_ts;
  Ra = (double)(resp_rx_ts - poll_tx_ts);
  Rb = (double)(final_rx_ts_32 - resp_tx_ts_32);
  Da = (double)(final_tx_ts - resp_rx_ts);
  Db = (double)(resp_tx_ts_32 - poll_rx_ts_32);
  tof_dtu = (int64)((Ra * Rb - Da * Db) / (Ra + Rb + Da + Db));

  tof = tof_dtu * DWT_TIME_UNITS;
  distance = tof * SPEED_OF_LIGHT;

  /* Transmit distance back to the other node */
  
  tx_result_msg[ALL_MSG_SN_IDX] = frame_seq_nb;

  // write ID of source (own ID) and destination (intended recipient's ID); only one of the bytes is currently used
  // source:
  tx_result_msg[5] = 0;
  tx_result_msg[6] = node->id;
  // destination:
  tx_result_msg[7] = 0;
  tx_result_msg[8] = msg->senderId; // destination of final is the sender of the response

  // write distance value; use union to convert the float to bytes easily
  union {
    float distanceVal;
    unsigned char bytes[4];
  } dist;
  dist.distanceVal = distance;

  for (int i = 0; i < sizeof(float); ++i) {
    tx_result_msg[RESULT_MSG_DIST_IDX + i] = dist.bytes[i];
  };

  int64_t currentTime = ProtocolClock_GetLocalTime(node->clock);

  dwt_writetxdata(sizeof(tx_result_msg), tx_result_msg, 0); /* Zero offset in TX buffer. */
  dwt_writetxfctrl(sizeof(tx_result_msg), 0, 1); /* Zero offset in TX buffer, ranging. */
  dwt_starttx(DWT_START_TX_IMMEDIATE);

  /* Poll DW1000 until TX frame sent event set. See NOTE 5 below. */
  while (!(dwt_read32bitreg(SYS_STATUS_ID) & SYS_STATUS_TXFRS))
  {};

  /* Clear TXFRS event. */
  dwt_write32bitreg(SYS_STATUS_ID, SYS_STATUS_TXFRS);

  *node->driver->txFinishedFlag = true;

#if DEBUG
  printf("Transmit resulting distance to Node %d: %f \n", msg->senderId, distance);
#endif

#if EVAL
  uint8_t slotNum = TimeKeeping_CalculateCurrentSlotNum(node);
  printf("TX DIST %d %f %d %d 0 \n", (int) msg->senderId, distance, (int) currentTime, (int) slotNum);
#endif

  Neighborhood_UpdateRanging(node, msg->senderId, msg->timestamp, distance);

  // reenable the receiver
  dwt_rxenable(DWT_START_RX_IMMEDIATE);

};

void Driver_SetOutMsgAddress(Node node, Message *msgOutAddress) {
  /** The address that is used to deliver the message back to MATLAB in simulation */
  node->driver->msgOutAddress = msgOutAddress;
};

bool Driver_IsReceiving(Node node) {
  uint32_t current_sys_status = dwt_read32bitoffsetreg(SYS_STATUS_ID, 0);
  // check if RXPRD bit (bit 8) is set, which means the receiver detected a preamble; 
  // this bit is cleared by the next receiver enable
  return ((current_sys_status & (1 << 8)) != 0);
};

bool Driver_GetMessageSentFlag(Node node) {
  return node->driver->sentMessage;
};

void Driver_SetMessageSentFlag(Node node, bool value) {
  node->driver->sentMessage = value;
};

/** DECAWAVE FUNCTIONS CPOIED FROM EXAMPLE SS_INIT_MAIN.C */

 /* @fn get_tx_timestamp_u64()
 *
 * @brief Get the TX time-stamp in a 64-bit variable.
 *        /!\ This function assumes that length of time-stamps is 40 bits, for both TX and RX!
 *
 * @param  none
 *
 * @return  64-bit value of the read time-stamp.
 */
static uint64 get_tx_timestamp_u64(void)
{
    uint8 ts_tab[5];
    uint64 ts = 0;
    int i;
    dwt_readtxtimestamp(ts_tab);
    for (i = 4; i >= 0; i--)
    {
        ts <<= 8;
        ts |= ts_tab[i];
    }
    return ts;
}

/*! ------------------------------------------------------------------------------------------------------------------
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

/*! ------------------------------------------------------------------------------------------------------------------
 * @fn final_msg_set_ts()
 *
 * @brief Fill a given timestamp field in the final message with the given value. In the timestamp fields of the final
 *        message, the least significant byte is at the lower address.
 *
 * @param  ts_field  pointer on the first byte of the timestamp field to fill
 *         ts  timestamp value
 *
 * @return none
 */
static void final_msg_set_ts(uint8 *ts_field, uint64 ts)
{
    int i;
    for (i = 0; i < FINAL_MSG_TS_LEN; i++)
    {
        ts_field[i] = (uint8) ts;
        ts >>= 8;
    }
}

/*! ------------------------------------------------------------------------------------------------------------------
 * @fn final_msg_get_ts()
 *
 * @brief Read a given timestamp value from the final message. In the timestamp fields of the final message, the least
 *        significant byte is at the lower address.
 *
 * @param  ts_field  pointer on the first byte of the timestamp field to read
 *         ts  timestamp value
 *
 * @return none
 */
static void final_msg_get_ts(const uint8 *ts_field, uint32 *ts)
{
    int i;
    *ts = 0;
    for (i = 0; i < FINAL_MSG_TS_LEN; i++)
    {
        *ts += ts_field[i] << (i * 8);
    }
}

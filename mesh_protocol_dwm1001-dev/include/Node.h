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

/** @file Node.h
*   @brief The Node struct holds all other structs and is passed around to the functions so they can access the data they need 
*   
*   
*/

#ifndef NODE_H
#define NODE_H

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <inttypes.h>
#include "Message.h"

typedef struct NodeStruct * Node;
typedef struct StateMachineStruct * StateMachine;
typedef struct ProtocolClockStruct * ProtocolClock;
typedef struct SchedulerStruct * Scheduler;
typedef struct DriverStruct * Driver;
typedef struct TimeKeepingStruct * TimeKeeping;
typedef struct NetworkManagerStruct * NetworkManager;
typedef struct MessageHandlerStruct * MessageHandler;
typedef struct SlotMapStruct * SlotMap;
typedef struct NeighborhoodStruct * Neighborhood;
typedef struct RangingManagerStruct * RangingManager;
typedef struct LCGStruct * LCG;
typedef struct ConfigStruct * Config;

/**
* id: ID of this node (must be unique among all nodes whose networks could ever get in range of each other) 
* stateMachine: struct that holds the data of the StateMachine
* clock: struct that holds the data of the ProtocolClock
* scheduler: struct that holds the data of the Scheduler
* timeKeeping: struct that holds the data of the TimeKeeping
* networkManager: struct that holds the data of the NetworkManager
* messageHandler: struct that holds the data of the MessageHandler
* slotMap: struct that holds the data of the SlotMap
* neighborhood: struct that holds the data of the Neighborhood
* rangingManager: struct that holds the data of the RangingManager
* lcg: struct that holds the data of the LCG
* config: struct that holds the data of the Config
*/
typedef struct NodeStruct{
  int8_t id;
  StateMachine stateMachine;
  ProtocolClock clock;
  Scheduler scheduler;
  Driver driver;
  TimeKeeping timeKeeping;
  NetworkManager networkManager;
  MessageHandler messageHandler;
  SlotMap slotMap;
  Neighborhood neighborhood;
  RangingManager rangingManager;
  LCG lcg;
  Config config;
} NodeStruct;

/** Constructor */
Node Node_Create();

/** Sets the StateMachine struct as a property of the Node struct
* @param self is the Node struct
* @param stateMachine is the StateMachine struct
*/
void Node_SetStateMachine(Node self, StateMachine stateMachine);

/** Sets the ProtocolClock struct as a property of the Node struct
* @param self is the Node struct
* @param clock is the ProtocolClock struct
*/
void Node_SetClock(Node self, ProtocolClock clock);

/** Sets the Scheduler struct as a property of the Node struct
* @param self is the Node struct
* @param scheduler is the Scheduler struct
*/
void Node_SetScheduler(Node self, Scheduler scheduler);

/** Sets the Driver struct as a property of the Node struct
* @param self is the Node struct
* @param driver is the Driver struct
*/
void Node_SetDriver(Node self, Driver driver);

/** Sets the TimeKeeping struct as a property of the Node struct
* @param self is the Node struct
* @param timeKeeping is the TimeKeeping struct
*/
void Node_SetTimeKeeping(Node self, TimeKeeping timeKeeping);

/** Sets the NetworkManager struct as a property of the Node struct
* @param self is the Node struct
* @param networkManager is the NetworkManager struct
*/
void Node_SetNetworkManager(Node self, NetworkManager networkManager);

/** Sets the MessageHandler struct as a property of the Node struct
* @param self is the Node struct
* @param messageHandler is the MessageHandler struct
*/
void Node_SetMessageHandler(Node self, MessageHandler messageHandler);

/** Sets the SlotMap struct as a property of the Node struct
* @param self is the Node struct
* @param slotMap is the SlotMap struct
*/
void Node_SetSlotMap(Node self, SlotMap slotMap);

/** Sets the Neighborhood struct as a property of the Node struct
* @param self is the Node struct
* @param neighborhood is the Neighborhood struct
*/
void Node_SetNeighborhood(Node self, Neighborhood neighborhood);

/** Sets the RangingManager struct as a property of the Node struct
* @param self is the Node struct
* @param rangingManager is the RangingManager struct
*/
void Node_SetRangingManager(Node self, RangingManager rangingManager);

/** Sets the LCG struct as a property of the Node struct
* @param self is the Node struct
* @param lcg is the LCG struct
*/
void Node_SetLCG(Node self, LCG lcg);

/** Sets the Config struct as a property of the Node struct
* @param self is the Node struct
* @param config is the Config struct
*/
void Node_SetConfig(Node self, Config config);

#endif

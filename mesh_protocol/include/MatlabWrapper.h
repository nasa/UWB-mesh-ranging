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


/** @file MatlabWrapper.h
*   @brief This is the file from which the mex-function for MATLAB is created
*   It connects MATLAB to the C code and makes it possible to run the protocol functions from MATLAB, as well as
*   get data from the nodes to MATLAB.
*   MATLAB acts as a simulation environment and distributes messages that one node sent to the other nodes.
*   It checks if the nodes are in range, if a collision happened etc.
*   It also checks whether all nodes have reserved enough slots, if slots collide and if all neighbors are in the same network; otherwise
*   the simulation continues until a timeout is reached, which then terminates the simulation as "FAILED"
*
*/ 

#ifndef MATLAB_WRAPPER_H
#define MATLAB_WRAPPER_H

#include "mex.h"
#include "matrix.h"

#include <string.h>

#include "Node.h"
#include "StateMachine.h"
#include "Scheduler.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"
#include "NetworkManager.h"
#include "MessageHandler.h"
#include "SlotMap.h"
#include "Neighborhood.h"
#include "RangingManager.h"
#include "LCG.h"
#include "Config.h"
#include "Util.h"
#include "Message.h"
 
typedef struct WrapperStruct * Wrapper;

/**
* nodes: array of all node structs in the simulation
* ids: array of ids of the nodes in the simulation
* outmMsg: array that messages are put in that a node sent; space for one message per node
* txFinished: array of txFinished flags for every node
* isReceiving: array of isReceiving flags for every node; determined and set by MATLAB
* numNodes: number of nodes in the simulation
* localTimes: array that holds the local time of every node
* lastTxStartTimes: array that holds the start times of the last transmission of every node; to determine if a transmission is finished
* initialRandomSeeds: array that holds the initial random seeds of every node that were created by MATLAB
* clockSkew: array that holds the clockSkew of every node
* lastSkewTime: array that holds the last time an additional tic was added or skipped because of the clock skew for every node
*/
typedef struct WrapperStruct{
  Node nodes[MAX_NUM_NODES];
  int8_t ids[MAX_NUM_NODES];
  Message outMsg[MAX_NUM_NODES];
  bool txFinished[MAX_NUM_NODES];
  bool isReceiving[MAX_NUM_NODES];

  int8_t numNodes;
  int64_t localTimes[MAX_NUM_NODES];
  int64_t lastTxStartTimes[MAX_NUM_NODES];
  MessageSizes lastTxMsgSize[MAX_NUM_NODES];
  uint32_t initialRandomSeeds[MAX_NUM_NODES];

  int clockSkew[MAX_NUM_NODES]; // add an additional or skip a tic every x tics
  int64_t lastSkewTime[MAX_NUM_NODES]; 

} WrapperStruct;

/** Add a node to the simulation
* @param wrapper is the MatlabWrapper of the simulation
* @param node is the Node struct of the node that should be added
* return new number of nodes
*/
int8_t Wrapper_AddNode(Wrapper wrapper, Node node);

/** Get the number of nodes in the simulation
* @param wrapper is the MatlabWrapper of the simulation
* return number of nodes
*/
int8_t Wrapper_GetNumNodes(Wrapper wrapper);

#endif

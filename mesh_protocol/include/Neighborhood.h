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

/** @file Neighborhood.h
*   @brief Maintains a representation of the neighborhood of the node
*
*   Keeps IDs of current neighbors (nodes in one hop range), when the node last received a message from them and when it did ranging last with them
*/  

#ifndef NEIGHBORHOOD_H
#define NEIGHBORHOOD_H

#include "Node.h"
#include "ProtocolClock.h"
#include "Util.h"
#include "Config.h"

#ifdef SIMULATION
#include "mex.h"
#endif

typedef struct NeighborhoodStruct * Neighborhood;

/**
* numOneHopNeighbors: total number of other nodes in one hop range
* oneHopNeighbors: array containing the ID of all one hop neighbors
* oneHopNeighorsLastSeen: last time a ping of the neighbor was received in local time in time tics
* oneHopNeighorsLastRanging: last time a successful ranging was done with the neighbor in local time in time tics
* oneHopNeighborsJoinedTime: time the neighbor joined the neighborhood
*/
typedef struct NeighborhoodStruct {
  int8_t numOneHopNeighbors;
  int8_t oneHopNeighbors[MAX_NUM_NODES - 1];
  int64_t oneHopNeighborsLastSeen[MAX_NUM_NODES - 1];
  int64_t oneHopNeighborsLastRanging[MAX_NUM_NODES - 1];
  int64_t oneHopNeighborsJoinedTime[MAX_NUM_NODES - 1];
  double oneHopNeighborsLastDistance[MAX_NUM_NODES - 1];
} NeighborhoodStruct;

/** Constructor */
Neighborhood Neighborhood_Create();

/** Add neighbor if it is not yet present or update the "last seen" time if it is already in the array
* @param node is the Node struct of this node
* @param id is the ID of the neighbor that should be added 
*/
void Neighborhood_AddOrUpdateOneHopNeighbor(Node node, int8_t id);

/** Get the IDs of the current one hop neighbors of the node
* @param node is the Node struct of this node
* @param buffer is a pointer to the buffer that the IDs should be written to
* @param size is the size of the buffer (used to avoid illegal memory access)
* return number of neighbors; return -1 if buffer is too small
*/
int8_t Neighborhood_GetOneHopNeighbors(Node node, int8_t *buffer, int8_t size);

/** Remove all neighbors that are considered gone
* @param node is the Node struct of this node
* 
* a neighbor is considered absent when the node did not receive ping for a certain amount of time (Config.h: absentNeighborTimeOut)
*/
void Neighborhood_RemoveAbsentNeighbors(Node node);

/** Update the time of the last ranging with the neighbor
* @param node is the Node struct of this node
* @param id is the ID of the neighbor whose value should be updated
*
* This function gets the current time from the clock to set the property.
*/
void Neighborhood_UpdateRanging(Node node, int8_t id, int64_t updateTime, double distance);

/** Get the neighbor that should be done ranging with next time
* @param node is the Node struct of this node
* return ID of the neighbor that is the next to do ranging; 
* returns -1 if there are no neighbors or if the last ranging with the next neighbor is too recent
* The next neighbor is determined based on how old the current ranging value is (oldest value is the next neighbor for ranging)
*/
int8_t Neighborhood_GetNextRangingNeighbor(Node node);

/** Get the neighbor that was the last to join the neighborhood
* @param node is the Node struct of this node
* return ID of the neighbor that joined the neighborhood last 
* return -1 if there are no neighbors or if the last ranging was too recent
*/
int8_t Neighborhood_GetNewestNeighbor(Node node);

/** Get the time of joining of the neighbor that was the last to join the neighborhood
* @param node is the Node struct of this node
* return local time when the newest neighbor joined the neighborhood
*/
int64_t Neighborhood_GetTimeWhenNewestNeighborJoined(Node node);

#endif

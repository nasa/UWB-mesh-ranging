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

#include "../include/Neighborhood.h"

static bool removeNeighbor(Node node, int8_t neighborId);

Neighborhood Neighborhood_Create() {
  Neighborhood self = calloc(1, sizeof(NeighborhoodStruct));
  
  // initialize values
  self->numOneHopNeighbors = 0;
  for(int i = 0; i < (MAX_NUM_NODES - 1); ++i) {
    // use -1 as a sentinel value
    self->oneHopNeighbors[i] = -1;
    self->oneHopNeighborsLastSeen[i] = -1;
    self->oneHopNeighborsLastRanging[i] = -1;
    self->oneHopNeighborsLastDistance[i] = -1;
  };

  return self;
};

void Neighborhood_AddOrUpdateOneHopNeighbor(Node node, int8_t id) {
  // find neighbor in array (if present)
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  int8_t currentNumNeighbors = node->neighborhood->numOneHopNeighbors;
  int8_t idx = Util_Int8tArrayFindElement(&node->neighborhood->oneHopNeighbors[0], id, currentNumNeighbors);

  if (idx == -1) {
    // neighbor not in array yet, so add neighbor
    node->neighborhood->oneHopNeighbors[currentNumNeighbors] = id;
    node->neighborhood->oneHopNeighborsLastSeen[currentNumNeighbors] = localTime;
    node->neighborhood->oneHopNeighborsLastRanging[currentNumNeighbors] = 0;

    ++node->neighborhood->numOneHopNeighbors;
  } else {
    // already in array, so update last seen
    node->neighborhood->oneHopNeighborsLastSeen[idx] = localTime;
  };
};

int8_t Neighborhood_GetOneHopNeighbors(Node node, int8_t *buffer, int8_t size) {
  if(size < node->neighborhood->numOneHopNeighbors) {
    // size of buffer is too small
    return -1;
  };

  for(int i = 0; i < node->neighborhood->numOneHopNeighbors; ++i) {
    buffer[i] = node->neighborhood->oneHopNeighbors[i];
  };
  return node->neighborhood->numOneHopNeighbors;
};

void Neighborhood_RemoveAbsentNeighbors(Node node) {
 
  int8_t absentNeighbors[MAX_NUM_NODES - 1];
  int8_t numAbsentNeighbors = 0;
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  
  // find absent neighbors (neighbors that have not been seen for a time longer than the absentNeighborTimeOut)
  for(int i = 0; i < node->neighborhood->numOneHopNeighbors; ++i) {
    if(localTime > (node->neighborhood->oneHopNeighborsLastSeen[i] + node->config->absentNeighborTimeOut)) {
      absentNeighbors[numAbsentNeighbors] = node->neighborhood->oneHopNeighbors[i];
      ++numAbsentNeighbors;
    };
  };

  // remove absent neighbors
  for(int i = 0; i < numAbsentNeighbors; ++i) {
    removeNeighbor(node, absentNeighbors[i]);
  };

};

void Neighborhood_UpdateRanging(Node node, int8_t id, int64_t updateTime, double distance) {
  // update the time when the last time ranging was done with this particular neighbor

  // find the index of the neighbor in the array
  int16_t idx = Util_Int8tArrayFindElement(&node->neighborhood->oneHopNeighbors[0], id, node->neighborhood->numOneHopNeighbors);
  // update time
  node->neighborhood->oneHopNeighborsLastRanging[idx] = updateTime;
  // update distance
  node->neighborhood->oneHopNeighborsLastDistance[idx] = distance;
};

int8_t Neighborhood_GetNextRangingNeighbor(Node node) {
  // find the neighbor that was not ranged for the longest time
  if (node->neighborhood->numOneHopNeighbors == 0) {
    return -1;
  };

  int16_t minIdx = Util_Int64tFindIdxOfMinimumInArray(&node->neighborhood->oneHopNeighborsLastRanging[0], node->neighborhood->numOneHopNeighbors);
  int64_t lastRangingTime = node->neighborhood->oneHopNeighborsLastRanging[minIdx]; 

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  if (localTime < (lastRangingTime + node->config->rangingRefreshTime)) {
    // last ranging was too recent, so return -1 to indicate that no poll should be sent
    return -1;
  };

  return node->neighborhood->oneHopNeighbors[minIdx];
};

int8_t Neighborhood_GetNewestNeighbor(Node node) {
  // find index of the neighbor that was added last
  int16_t idxNewestNeighbor = Util_Int64tFindIdxOfMaximumInArray(&node->neighborhood->oneHopNeighborsJoinedTime[0], node->neighborhood->numOneHopNeighbors);

  if (idxNewestNeighbor == -1) {
    // no neighbors
    return -1;
  };

  return node->neighborhood->oneHopNeighbors[idxNewestNeighbor];
};

int64_t Neighborhood_GetTimeWhenNewestNeighborJoined(Node node) {
  // find index of the neighbor that was added last
  int16_t idxNewestNeighbor = Util_Int64tFindIdxOfMaximumInArray(&node->neighborhood->oneHopNeighborsJoinedTime[0], node->neighborhood->numOneHopNeighbors);

  if (idxNewestNeighbor == -1) {
    // no neighbors
    return -1;
  };
  // return the time when the newest neighbor joined the neighborhood
  return node->neighborhood->oneHopNeighborsJoinedTime[idxNewestNeighbor];
};

static bool removeNeighbor(Node node, int8_t neighborId) {
  // find index of neighbor that should be removed
  int8_t idx = Util_Int8tArrayFindElement(&node->neighborhood->oneHopNeighbors[0], neighborId, node->neighborhood->numOneHopNeighbors);
  if (idx == -1) {
    // id not found
    return false;
  };

  // decrement numOneHopNeighbors 
  int8_t newNumNeighbors = --node->neighborhood->numOneHopNeighbors; 
  // let last element of oneHopNeighbors array overwrite the neighbor that has to be removed (as order is not important)
  node->neighborhood->oneHopNeighbors[idx] = node->neighborhood->oneHopNeighbors[newNumNeighbors]; 
  node->neighborhood->oneHopNeighborsLastSeen[idx] = node->neighborhood->oneHopNeighborsLastSeen[newNumNeighbors];
  node->neighborhood->oneHopNeighborsLastRanging[idx] = node->neighborhood->oneHopNeighborsLastRanging[newNumNeighbors];
  node->neighborhood->oneHopNeighborsLastDistance[idx] = node->neighborhood->oneHopNeighborsLastDistance[newNumNeighbors];

  return true;
};

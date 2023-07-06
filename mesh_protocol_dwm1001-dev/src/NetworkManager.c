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

#include "../include/NetworkManager.h"

static bool isConnectedAndHasId(Node node);

NetworkManager NetworkManager_Create() {
  NetworkManager self = calloc(1, sizeof(NetworkManagerStruct));
  // start unconnected
  self->networkStatus = NOT_CONNECTED;
  self->networkId = 0;
  self->currentNetworkStartedByThisNode = false;

  return self;
};

void NetworkManager_CreateNetwork(Node node) {
  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);

  // start a new network that has the same ID as this node
  NetworkManager_SetNetworkStatus(node, CONNECTED);
  NetworkManager_SetNetworkId(node, node->id);
  node->networkManager->networkAgeAtJoining = 0;
  node->networkManager->localTimeAtJoining = localTime;
};

int64_t NetworkManager_CalculateNetworkAge(Node node) {
  if (!isConnectedAndHasId(node)) {
    return 0;
  };

  int64_t localTime = ProtocolClock_GetLocalTime(node->clock);
  // the age of the network is the time that passed since this node joined the network plus the age of the network when this node joined
  int64_t networkAge = (localTime - node->networkManager->localTimeAtJoining) + node->networkManager->networkAgeAtJoining;
  return networkAge;
};

bool NetworkManager_IsPingFromForeignNetwork(Node node, Message msg) {
  if(msg->type != PING) {
    return false;
  };

  if(!isConnectedAndHasId(node)) {
    // every network is foreign if the node is not connected to a network
    return true;
  };

  int64_t ownNetworkAge = NetworkManager_CalculateNetworkAge(node);
  // calculate the age of the foreign network NOW for the age that is contained in the ping, but evaluate it at the time the preamble was received
  // to be independent from the length of the transmission
  int64_t foreignNetworkAge = TimeKeeping_CalculateNetworkAgeFromMsg(node, msg);
  int64_t tolerance = node->config->networkAgeToleranceSameNetwork; // there might be small errors that must be tolerated

  bool sameId = (msg->networkId == NetworkManager_GetNetworkId(node));
  bool networksAreSameAge = (foreignNetworkAge <= ownNetworkAge + tolerance) && (foreignNetworkAge >= ownNetworkAge - tolerance);

  // networks are the same if the ID and the age is the same
  if(sameId && networksAreSameAge) {
    // same network, return false
    return false;
  };
  return true;
};

bool NetworkManager_IsForeignNetworkPreceding(Node node, Message msg) {
  int64_t ownNetworkAge = NetworkManager_CalculateNetworkAge(node);
  int64_t foreignNetworkAge = TimeKeeping_CalculateNetworkAgeFromMsg(node, msg);

  // foreign network precedes if it is older than this network
  return (foreignNetworkAge > ownNetworkAge);
};

bool NetworkManager_DoNetworksHaveSameAge(Node node, Message msg) {
  int64_t ownNetworkAge = NetworkManager_CalculateNetworkAge(node);
  int64_t foreignNetworkAge = TimeKeeping_CalculateNetworkAgeFromMsg(node, msg);

  return (foreignNetworkAge == ownNetworkAge);
};

bool NetworkManager_CurrentNetworkStartedByThisNode(Node node) {
  if(node->networkManager->networkStatus == CONNECTED) {
    return node->networkManager->currentNetworkStartedByThisNode;
  };
  return false;
};

NetworkStatus NetworkManager_GetNetworkStatus(Node node) {
  return node->networkManager->networkStatus;
};

uint8_t NetworkManager_GetNetworkId(Node node) {
  if (node->networkManager->networkStatus == NOT_CONNECTED) {
    return 0;
  };

  return node->networkManager->networkId;
};

void NetworkManager_SetNetworkStatus(Node node, NetworkStatus status) {
  node->networkManager->networkStatus = status;
};

void NetworkManager_SetNetworkId(Node node, uint8_t id) {
  node->networkManager->networkId = id;
  if(id == node->id) {
    node->networkManager->currentNetworkStartedByThisNode = true;
  } else {
    node->networkManager->currentNetworkStartedByThisNode = false;
  };
};

void NetworkManager_SaveNetworkAgeAtJoining(Node node, int64_t networkAge) {
  // save the age of the network when this node joined to be able to calculate the current network age later
  node->networkManager->networkAgeAtJoining = networkAge;
};

void NetworkManager_SaveLocalTimeAtJoining(Node node, int64_t localTime) {
// save the local time when this node joined to be able to calculate the current network age later
  node->networkManager->localTimeAtJoining = localTime;
};

static bool isConnectedAndHasId(Node node) {
  bool isConnected = node->networkManager->networkStatus == CONNECTED;
  bool hasId = node->networkManager->networkId != 0;

  return (isConnected && hasId);
};




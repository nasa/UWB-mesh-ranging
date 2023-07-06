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

/** @file NetworkManager.h
*   @brief Creates and maintains information about the network
*
*/  

#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include "Node.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"

#ifdef SIMULATION
#include "mex.h"
#endif

enum NetworkStatus {
  NOT_CONNECTED, CONNECTED
};

typedef struct NetworkManagerStruct * NetworkManager;
typedef enum NetworkStatus NetworkStatus;

/** NetworkManagerStruct
* networkStatus: CONNECTED or NOT_CONNECTED
* networkId: ID of the network the node is connected to; networkId is the ID of the node who originally created the network; is 0 if not connected
* networkAgeAtJoining: age of the network when this node joined it
* localTimeAtJoining: local time of thise node when it joined the network
* currentNetworkStartedByThisNode: true if the current network was created by this node; false if the network was created by another node
*/
typedef struct NetworkManagerStruct {
  NetworkStatus networkStatus;
  uint8_t networkId;
  uint64_t networkAgeAtJoining;
  uint64_t localTimeAtJoining;
  bool currentNetworkStartedByThisNode;
} NetworkManagerStruct;

/** Constructor */
NetworkManager NetworkManager_Create();

/** Calculate the age of the own network 
* @param node is the Node struct of the node that should perform this action
* return age of the own network
*
*/
int64_t NetworkManager_CalculateNetworkAge(Node node);

/** Determines if a ping was sent by a node of this network or of a foreign network
* @param node is the Node struct of the node that should perform this action
* @param msg is the message that contains the ping
* return true if the ping is from a foreign network
*/
bool NetworkManager_IsPingFromForeignNetwork(Node node, Message msg);

/** Determines if the foreign network of which a ping was received is preceding over this one
* @param node is the Node struct of the node that should perform this action
* @param msg is the message that contains the ping 
* return true if the foreign network precedes over the own network
* 
* preceding means that nodes of the not preceding network will join the preceding network when they come in range to it;
* a network is preceding when it is older (network age)
*/
bool NetworkManager_IsForeignNetworkPreceding(Node node, Message msg);

/** Determines if foreign network and own network have the exact same age
* @param node is the Node struct of the node that should perform this action
* @param msg is the message that contains the ping 
* return true if the foreign network has the same age as the own one
* 
* a network is preceding when it is older (network age)
*/
bool NetworkManager_DoNetworksHaveSameAge(Node node, Message msg);

/** Get the network status of this node 
* @param node is the Node struct of the node that should perform this action
* return CONNECTED or NOT_CONNECTED
*/
NetworkStatus NetworkManager_GetNetworkStatus(Node node);

/** Get the network ID of the network this node is connected to
* @param node is the Node struct of the node that should perform this action
* return network ID or 0 if not connected
*/
uint8_t NetworkManager_GetNetworkId(Node node);

/** Set all network parameters for this node for the case of a new network
* @param node is the Node struct of the node that should perform this action
*
* Creates a new network for this node by setting all the necessary parameters; 
* network ID will be the ID of this node, and network age will be 0; this node will be the creator of the network then
*/
void NetworkManager_CreateNetwork(Node node);

/** Set the network status of this node
* @param node is the Node struct of the node that should perform this action
* @param status is the network status that should be set (CONNECTED or NOT_CONNECTED)
*/
void NetworkManager_SetNetworkStatus(Node node, NetworkStatus status);

/** Set the network ID of this node
* @param node is the Node struct of the node that should perform this action
* @param 
*/
void NetworkManager_SetNetworkId(Node node, uint8_t id);

/** Save the age of the network at the time this node joined it
* @param node is the Node struct of the node that should perform this action
* @param networkAge is the network age at the time the node joined it
*/
void NetworkManager_SaveNetworkAgeAtJoining(Node node, int64_t networkAge);

/** Save the local time of this node when it joined its current network
* @param node is the Node struct of the node that should perform this action
* @param localTime is the local time of the node at the time it joined the network
*/
void NetworkManager_SaveLocalTimeAtJoining(Node node, int64_t localTime);

#endif

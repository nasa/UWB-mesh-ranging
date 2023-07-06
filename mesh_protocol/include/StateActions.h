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

/** @file StateActions.h
*   @brief Contains all actions that should be executed on a run of the state machine (time tic or incoming msg)
*   The actions depend on the current state of the node
*/  

#ifndef STATE_ACTIONS_H
#define STATE_ACTIONS_H

#include <inttypes.h>
#include <stdio.h>
#include "Node.h"
#include "ProtocolClock.h"
#include "TimeKeeping.h"
#include "Scheduler.h"
#include "MessageHandler.h"

#ifdef SIMULATION
#include "mex.h"
#endif

/** Actions to carry out when the node is unconnected listening and a message comes in
* @param node is the Node struct of the node that should perform this action
* @param msg is an incoming message from another node
*/
void StateActions_ListeningUnconnectedIncomingMsgAction(Node node, Message msg);

/** Actions to carry out on a time tic when the node is unconnected listening
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_ListeningUnconnectedTimeTicAction(Node node);

/** Actions to carry out on a time tic when the node is unconnected sending
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_SendingUnconnectedTimeTicAction(Node node);

/** Actions to carry out on a time tic when the node is connected listening
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_ListeningConnectedTimeTicAction(Node node);

/** Actions to carry out when the node is connected listening and a message comes in
* @param node is the Node struct of the node that should perform this action
* @param msg is an incoming message from another node
*/
void StateActions_ListeningConnectedIncomingMsgAction(Node node, Message msg);

/** Actions to carry out on a time tic when the node is connected sending
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_SendingConnectedTimeTicAction(Node node);

/** Actions to carry out on a time tic when the node is in ranging poll 
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_RangingPollTimeTicAction(Node node);

/** Actions to carry out when the node is listening for ranging messages and a message comes in
* @param node is the Node struct of the node that should perform this action
* @param msg is an incoming message from another node
*/
void StateActions_RangingListenIncomingMsgAction(Node node, Message msg);

/** Actions to carry out on a time tic when the node received a poll msg and should respond with a response msg
* @param node is the Node struct of the node that should perform this action
* @param pollMsgIn is the poll message the node responds to
*/
void StateActions_RangingResponseTimeTicAction(Node node, Message pollMsgIn);

/** Actions to carry out on a time tic when the node received a response msg and should respond with a final msg
* @param node is the Node struct of the node that should perform this action
* @param responseMsgIn is the response message the node responds to
*/
void StateActions_RangingFinalTimeTicAction(Node node, Message responseMsgIn);

/** Actions to carry out on a time tic when the node received a final msg and should respond with a result msg
* @param node is the Node struct of the node that should perform this action
* @param finalMsgIn is the final message the node responds to
*/
void StateActions_RangingResultTimeTicAction(Node node, Message finalMsgIn);

/** Actions to carry out on a time tic when the node is in idle
* @param node is the Node struct of the node that should perform this action
*/
void StateActions_IdleTimeTicAction(Node node);

/** Actions to carry out on a time tic when the node is in idle and a message comes in 
* @param node is the Node struct of the node that should perform this action
* @param msg is an incoming message from another node
*/
void StateActions_IdleIncomingMsgAction(Node node, Message msg);

#endif

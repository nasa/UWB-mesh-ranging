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


// THIS IS AN IMPLEMENTATION OF CONSTANTS SOLELY FOR UNIT TESTS

/** @file Constants.h
*   @brief Defines some constants that cannot got into config because their value is needed at compile time
*/  

#ifndef CONSTANTS_H
#define CONSTANTS_H

/** Write output to the console in simulation */
// uncomment if used with MATLAB simulation
//#define SIMULATION 1
#define DEBUG 0
#define DEBUG_VERBOSE 0

/** Number of slots per frame */
#define NUM_SLOTS 4

/** Maximum number of pending slots per node */
#define MAX_NUM_PENDING_SLOTS 5

/** Maximum number of own slots per node */
#define MAX_NUM_OWN_SLOTS 5

/** Maximum number of nodes */
#define MAX_NUM_NODES 6

/** Maximum number of collisions that are recorded for the current frame
* If more collisions occur, the oldest will be overwritten
*/
#define MAX_NUM_COLLISIONS_RECORDED 8

// 32767 is what LCG assumes as RAND_MAX, but MATLAB seems to use 2^32-1 as RAND_MAX; so the number had to be hardcoded here to work in simulation
#define RAND_MAX_LCG 32767

#endif

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

/** @file ProtocolClock.h
*   @brief Clock that is used in the protocol
*   
*   Used by other functions to get the current local time. The time is read from an address 
*   that is set on creation of the ProtocolClock struct. This way an adapter can be written for different implementations
*   that knows how to read the actual time from the system and writes it to the address.
*/  

#ifndef PROTOCOL_CLOCK_H
#define PROTOCOL_CLOCK_H

#include "Node.h"

typedef struct ProtocolClockStruct * ProtocolClock;

typedef struct ProtocolClockStruct{
  int64_t *time;
  int64_t correctionValue;
  bool timeIsFixed;
  int64_t *fixedTime;
} ProtocolClockStruct;

/** Constructor
* @param time is a pointer to the address that holds the current time
*/
ProtocolClock ProtocolClock_Create(int64_t *time);

/** Destructor 
* @param clock is the ProtocolClock struct to be destroyed
*/
void ProtocolClock_Destroy(ProtocolClock clock);

/** Correct the time by the value specified
* @param self is the ProtocolClock struct
* @param correctionValue is the time should be corrected by
*/
void ProtocolClock_CorrectTime(ProtocolClock self, int64_t correctionValue);

/** Get the current local time of this node
* @param self is the ProtocolClock struct
* return the current local time
*/
int64_t ProtocolClock_GetLocalTime(ProtocolClock self);

/** Fix the time that is returned by ProtocolClock_GetLocalTime()
* @param self is the ProtocolClock struct
* This can be run before the state machine is started to make sure that the localTime does not change
* throughout the execution; call ProtocolClock_UnfixLocalTime() to make it return the correct time again
*/
void ProtocolClock_FixLocalTime(ProtocolClock self);

/** Stop fixing the localTime
* @param self is the ProtocolClock struct
*/
void ProtocolClock_UnfixLocalTime(ProtocolClock self);

#endif

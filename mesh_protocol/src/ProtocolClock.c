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

#include "../include/ProtocolClock.h"

ProtocolClock ProtocolClock_Create(int64_t *time) {
// allocate memory for the ProtocolClock struct
  ProtocolClock self = calloc(1, sizeof(ProtocolClockStruct));

  // set the time pointer to the address the actual time will be stored at 
  self->time = time;

  // correction value is calculated from other messages and added to the time of this node;
  // the goal is too keep the nodes' times synchronized under varying clock drift
  self->correctionValue = 0;

  self->timeIsFixed = false;
  self->fixedTime = 0;
  return self;
};

void ProtocolClock_Destroy(ProtocolClock clock) {
  free(clock);
};

int64_t ProtocolClock_GetLocalTime(ProtocolClock self) {
  if (!self->timeIsFixed) {
    return (*self->time + self->correctionValue);
  } else {
    return self->fixedTime;
  };
};

void ProtocolClock_CorrectTime(ProtocolClock self, int64_t correctionValue) {
  /** correctionValue is calculated from the difference between this node's 
  *   "time since beginning of the frame" and the "time since beginning of the frame" that another node sends with its ping.
  *   As the beginning of the current frame should be identical for all nodes of the same network
  *   (neglecting ToF), it is suitable to monitor the clock drift with this value. The exact way how
  *   the correctionValue is calculated may be changed.
  */
  self->correctionValue += correctionValue;
};

void ProtocolClock_FixLocalTime(ProtocolClock self) {
  self->timeIsFixed = true;
  self->fixedTime = *self->time + self->correctionValue;
};

void ProtocolClock_UnfixLocalTime(ProtocolClock self) {
  self->timeIsFixed = false;
};

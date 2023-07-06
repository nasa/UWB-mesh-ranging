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

/** @file LCG.h
*   @brief Implementation of a random number generator (Linear Congruential Generator)
*
*   Reimplementation of rand() as in https://stackoverflow.com/a/10198842 by Matteo Italia
*   Reimplementation was necessary to save the current seed/state of the RNG and thus be able to generate the same sequence of numbers again
*   which is not possible with the rand() function of C. Otherwise it should behave the same (with the same limitations regarding randomness).
*   The state does not need to be saved manually, it is sufficient to create the LCG Struct which will then hold the seed for the node throughout calls
*/  

#ifndef LCG_H
#define LCG_H

#include <stdint.h>
#include <inttypes.h>
#include "Node.h"

typedef struct LCGStruct * LCG;

/** 
* next: next seed that will be used to generate a random number
*/
typedef struct LCGStruct {
  uint32_t next;
} LCGStruct;

/** Constructor
* @param seed is the first seed to use for the random number generator
* return LCG struct
*/
LCG LCG_Create(uint32_t seed);

/** Get a new random number
* @param node is the Node struct of the node that should perform this action
* return random integer between 0 and 32768 
*/
int LCG_Rand(Node node);

/** Use a new seed
* @param node is the Node struct of the node that should perform this action
* @param seed is the new seed to be used
*/
void LCG_Reseed(Node node, uint32_t seed);

#endif

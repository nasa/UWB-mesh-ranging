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

/** @file RandomNumbers.h
*   @brief Facilitates the generation of random numbers for different purposes
*
*   Can be used to easily get a random slot from a selection of free slots, a random time to schedule a ping etc.
*   The numbers generated are only pseudo-random and are only as good as the RNG that is used to generate them!
*   These functions should not be used for cryptography or similar purposes where a high degree of randomness is important.
*/  

#ifndef RANDOM_NUMBERS_H
#define RANDOM_NUMBERS_H

#include <stdlib.h>
#include <inttypes.h>
#include "Node.h"
#include "LCG.h"

/** Draw a random integer from a given range, including bounds
* @param node is the Node struct of the node that should perform this action
* @param lowerBound is the lower bound of the range that the random integer should be drawn from
* @param upperBound is the upper bound of the range that the random integer should be drawn from
* return a random number that lies within the range
*/
int64_t RandomNumbers_GetRandomIntBetween(Node node, int64_t lowerBound, int64_t upperBound);

/** Draw a random element from an array of numbers
* @param node is the Node struct of the node that should perform this action
* @param array is the array the element should be drawn from
* @param numElements is the number of elements in the array
* return a random element of the array
*/
int16_t RandomNumbers_GetRandomElementFrom(Node node, int16_t *array, int16_t numElements);

#endif

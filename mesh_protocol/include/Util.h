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

/** @file Util.h
*   @brief Utility functions
*/  

#ifndef MNP_UTIL_H
#define MNP_UTIL_H

#include <string.h>
#include <stdint.h>

/** Find index of an element in an int8_t array
* @param array is a pointer to the int8_t-array that should be searched
* @param element is the int8_t element that should be found in the array
* @param arraySize is the size of the array (to avoid illegal memory access)
* return index of the element in the array or -1 if the array does not contain the element
*/
int16_t Util_Int8tArrayFindElement(int8_t *array, int8_t element, int16_t arraySize);

/** Get intersection of two int8_t arrays
* @param array1 is a pointer to the first int8_t-array; array must be sorted
* @param size1 is the size of the first array (to avoid illegal memory access)
* @param array2 is a pointer to the second int8_t-array; array must be sorted
* @param size2 is the size of the second array (to avoid illegal memory access)
* @param intersection is a pointer to an array that should contain the intersection of the arrays; 
*   must be at least as big as the smaller of the two input arrays

* return number of elements of the intersection
*
* Intersection of two arrays means elements that are present in both arrays
*/
int16_t Util_IntersectSortedInt8tArrays(int8_t *array1, int8_t size1, int8_t *array2, int8_t size2, int8_t *intersection);

/** Sort an int8_t array in ascending order
* @param array is a pointer to the array that should be sorted
* @param arraySize is the size of the array
* @param sorted is a pointer to an array that should contain the sorted values; must be at least as big as the input array
*/
void Util_SortInt8tArray(int8_t *array, int8_t arraySize, int8_t *sorted);

/** Find the index of the smallest value in an int8_t array
* @param array is a pointer to the int8_t-array that should be searched
* @param arraySize is the size of the array (to avoid illegal memory access)
* return index of the smallest value in the array. If it contains more than one element with the smallest value, the index of the first one is returned
*/
int16_t Util_Int8tFindIdxOfMinimumInArray(int8_t *array, int16_t arraySize);

/** Find the index of the smallest value in an int64_t array
* @param array is a pointer to the int64_t-array that should be searched
* @param arraySize is the size of the array (to avoid illegal memory access)
* return index of the smallest value in the array. If it contains more than one element with the smallest value, the index of the first one is returned
*/
int16_t Util_Int64tFindIdxOfMinimumInArray(int64_t *array, int16_t arraySize);

/** Find the index of the biggest value in an int64_t array
* @param array is a pointer to the int64_t-array that should be searched
* @param arraySize is the size of the array (to avoid illegal memory access)
* return index of the biggest value in the array. If it contains more than one element with the biggest value, the index of the first one is returned
*/
int16_t Util_Int64tFindIdxOfMaximumInArray(int64_t *array, int16_t arraySize);

#endif

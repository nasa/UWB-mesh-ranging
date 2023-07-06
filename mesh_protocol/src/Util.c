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

#include "../include/Util.h"

static int compare( const void* a, const void* b);

int16_t Util_Int8tArrayFindElement(int8_t *array, int8_t element, int16_t arraySize) {
  // compare each array element with the element that should be found
  for (int i = 0; i < arraySize; ++i) {
    if (array[i] == element) {
      return i;
    };
  };
  return -1;
};

int16_t Util_IntersectSortedInt8tArrays(int8_t *array1, int8_t size1, int8_t *array2, int8_t size2, int8_t *intersection) {
  int16_t i = 0;
  int16_t j = 0;
  int16_t numCommonElements = 0;

  // intersect arrays by comparing individual elements and always 
  // incrementing the smaller one if they are not equal; this only works with sorted arrays
  while((i < size1) && (j < size2)) {
    if (array1[i] == array2[j]) {
      intersection[numCommonElements] = array1[i];
      ++numCommonElements;
      ++i;
      ++j;
    } else if (array1[i] < array2[j]) {
      ++i;
    } else {
      ++j;
    }
  };
  return numCommonElements;
};

void Util_SortInt8tArray(int8_t *array, int8_t arraySize, int8_t *sorted) {
  memcpy(array, sorted, arraySize);
  qsort(sorted, arraySize, sizeof(int8_t), compare);
};

int16_t Util_Int8tFindIdxOfMinimumInArray(int8_t *array, int16_t arraySize) {
  int16_t minIdx = 0;
  int8_t minValue = array[0];
  // iterate over the array and save the smallest value and its index
  for (int i = 1; i < arraySize; ++i) {
    if (array[i] < minValue) {
      minValue = array[i];
      minIdx = i;
    };
  };
  return minIdx;
};

int16_t Util_Int64tFindIdxOfMinimumInArray(int64_t *array, int16_t arraySize) {
  int16_t minIdx = 0;
  int64_t minValue = array[0];
  // iterate over the array and save the smallest value and its index
  for (int i = 1; i < arraySize; ++i) {
    if (array[i] < minValue) {
      minValue = array[i];
      minIdx = i;
    };
  };
  return minIdx;
};

int16_t Util_Int64tFindIdxOfMaximumInArray(int64_t *array, int16_t arraySize) {
  int16_t maxIdx = 0;
  int64_t maxValue = array[0];
  // iterate over the array and save the biggest value and its index
  for (int i = 1; i < arraySize; ++i) {
    if (array[i] > maxValue) {
      maxValue = array[i];
      maxIdx = i;
    };
  };
  return maxIdx;
};

static int compare( const void* a, const void* b) {
   // (c) Alex Reece; https://stackoverflow.com/questions/3893937/sorting-an-array-in-c
   int8_t int_a = * ( (int8_t*) a );
   int8_t int_b = * ( (int8_t*) b );

   if(int_a == int_b){
    return 0;
   }else if(int_a < int_b){
    return -1;
   }else{
    return 1;
   };
};

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

#ifdef SIMULATION
#include "mex.h"
#endif

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

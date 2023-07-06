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

#ifdef SIMULATION
#include "mex.h"
#endif

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
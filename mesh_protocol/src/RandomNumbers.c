#include "../include/RandomNumbers.h"


int64_t RandomNumbers_GetRandomIntBetween(Node node, int64_t lowerBound, int64_t upperBound) {
  // from http://c-faq.com/lib/randrange.html
  int randomNum = LCG_Rand(node);

  int64_t randomInt = (int64_t) lowerBound + randomNum / (RAND_MAX_LCG / (upperBound - lowerBound + 1) + 1); 

  return randomInt;
};

int16_t RandomNumbers_GetRandomElementFrom(Node node, int16_t *array, int16_t numElements) {
  int64_t randomIdx = RandomNumbers_GetRandomIntBetween(node, 0, (numElements - 1));

  return array[randomIdx];
};
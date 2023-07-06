#include "../include/LCG.h"

LCG LCG_Create(uint32_t seed) {
  LCG self = calloc(1, sizeof(LCGStruct));
  self->next = seed;

  return self;
};

int LCG_Rand(Node node) {
  /** reimplementation of rand from https://stackoverflow.com/a/10198842 by Matteo Italia */
  node->lcg->next = node->lcg->next * 1103515245 + 12345;
  return (uint32_t)((node->lcg->next/65536) % 32768);
};

void LCG_Reseed(Node node, uint32_t seed) {
  node->lcg->next = seed;
};
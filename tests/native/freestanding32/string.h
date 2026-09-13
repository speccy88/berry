#ifndef TEST_FREESTANDING_STRING_H
#define TEST_FREESTANDING_STRING_H
#include <stddef.h>
void *memcpy(void *dest, const void *src, size_t bytes);
void *memset(void *dest, int value, size_t bytes);
int memcmp(const void *left, const void *right, size_t bytes);
int strcmp(const char *left, const char *right);
#endif

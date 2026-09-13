#ifndef TEST_FREESTANDING_ASSERT_H
#define TEST_FREESTANDING_ASSERT_H
#include <stdlib.h>
#define assert(condition) ((condition) ? (void)0 : abort())
#endif

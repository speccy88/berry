#ifndef TEST_FREESTANDING_STDLIB_H
#define TEST_FREESTANDING_STDLIB_H
/* Test-only declarations for Linux/i386 host-width execution without libc. */
#include <stddef.h>
void *malloc(size_t bytes);
void free(void *ptr);
void abort(void) __attribute__((noreturn));
#endif

#ifndef TEST_FREESTANDING_STDIO_H
#define TEST_FREESTANDING_STDIO_H
/* Only the formats used by test_p2_heap.c are implemented; unsupported
 * formats abort rather than silently producing misleading test output. */
int printf(const char *format, ...);
int puts(const char *text);
#endif

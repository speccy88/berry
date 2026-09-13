#ifndef TEST_FREESTANDING32_RUNTIME_H
#define TEST_FREESTANDING32_RUNTIME_H
/* HOST-ONLY Linux/i386 runtime: actual 32-bit pointers/size_t and execution,
 * not a redefinition of size_t, allocator model, or P2/Catalina emulation.
 * No libc/multilib installation required. Production allocator is unchanged.
 */
#if !defined(__i386__) || !defined(__linux__)
#error This test runtime requires Linux/i386
#endif
#include <stdarg.h>
#include <stddef.h>

typedef char test_size_t_is_32_bits[sizeof(size_t) == 4 ? 1 : -1];
typedef char test_pointer_is_32_bits[sizeof(void *) == 4 ? 1 : -1];

static void test_exit(int status) __attribute__((noreturn));
static void test_exit(int status)
{
    __asm__ volatile ("int $0x80" : : "a"(1), "b"(status) : "memory");
    __builtin_unreachable();
}

void abort(void)
{
    test_exit(134);
}

static int test_write(const char *text, size_t bytes)
{
    size_t written = 0;
    while (written < bytes) {
        int result;
        __asm__ volatile ("int $0x80" : "=a"(result)
            : "a"(4), "b"(1), "c"(text + written), "d"(bytes - written)
            : "memory");
        if (result <= 0) {
            test_exit(125);
        }
        written += (size_t)result;
    }
    return (int)written;
}

static int test_text(const char *text)
{
    size_t bytes = 0;
    while (text[bytes]) {
        ++bytes;
    }
    return test_write(text, bytes);
}

static int test_unsigned(unsigned value)
{
    char digits[16];
    size_t position = sizeof(digits);
    do {
        digits[--position] = (char)('0' + value % 10);
        value /= 10;
    } while (value);
    return test_write(digits + position, sizeof(digits) - position);
}

int printf(const char *format, ...)
{
    va_list args;
    int written = 0;
    va_start(args, format);
    for (; *format; ++format) {
        if (*format != '%') {
            written += test_write(format, 1);
            continue;
        }
        ++format;
        switch (*format) {
        case 's':
            written += test_text(va_arg(args, const char *));
            break;
        case 'u':
            written += test_unsigned(va_arg(args, unsigned));
            break;
        case 'd': {
            int value = va_arg(args, int);
            if (value < 0) {
                written += test_write("-", 1);
            }
            written += test_unsigned(value < 0 ? 0u - (unsigned)value : (unsigned)value);
            break;
        }
        default:
            abort();
        }
    }
    va_end(args);
    return written;
}

int puts(const char *text)
{
    return test_text(text) + test_write("\n", 1);
}

void *memcpy(void *dest, const void *src, size_t bytes)
{
    unsigned char *out = dest;
    const unsigned char *in = src;
    size_t i;
    for (i = 0; i < bytes; ++i) {
        out[i] = in[i];
    }
    return dest;
}

void *memset(void *dest, int value, size_t bytes)
{
    unsigned char *out = dest;
    size_t i;
    for (i = 0; i < bytes; ++i) {
        out[i] = (unsigned char)value;
    }
    return dest;
}

int memcmp(const void *left, const void *right, size_t bytes)
{
    const unsigned char *a = left;
    const unsigned char *b = right;
    size_t i;
    for (i = 0; i < bytes; ++i) {
        if (a[i] != b[i]) {
            return (int)a[i] - (int)b[i];
        }
    }
    return 0;
}

int strcmp(const char *left, const char *right)
{
    while (*left && *left == *right) {
        ++left;
        ++right;
    }
    return (int)(unsigned char)*left - (int)(unsigned char)*right;
}

int main(int argc, char **argv);
void test_start(unsigned *stack) __attribute__((noreturn, used));
void test_start(unsigned *stack)
{
    test_exit(main((int)stack[0], (char **)(stack + 1)));
}

__asm__(".global _start\n"
    "_start:\n"
    "xorl %ebp, %ebp\n"
    "movl %esp, %eax\n"
    "andl $-16, %esp\n"
    "subl $12, %esp\n"
    "pushl %eax\n"
    "call test_start\n"
    "ud2\n");
#endif

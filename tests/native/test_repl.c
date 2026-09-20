/* Real production REPL with owned host-reader buffers. No UART/hardware proof. */
#include "berry.h"
#include "be_repl.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char **lines;
static size_t next_line, reads, frees;
static unsigned checks, failures;
#define CHECK(x) do { ++checks; if (!(x)) { ++failures; \
    fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #x); } } while (0)

static char *reader(const char *prompt)
{
    const char *src;
    char *copy;
    (void)prompt;
    /* Fail boundedly if a broken continuation keeps requesting EOF. */
    if (++reads > 100) { fprintf(stderr, "reader called after EOF repeatedly\n"); exit(2); }
    src = lines[next_line];
    if (!src) return NULL;
    ++next_line;
    copy = malloc(strlen(src) + 1);
    if (!copy) exit(3);
    strcpy(copy, src);
    return copy;
}
static void release(char *line)
{
    CHECK(line != NULL);
    ++frees;
    free(line);
}
static void run(bvm *vm, const char **input, size_t count)
{
    int top = be_top(vm);
    lines = input;
    next_line = reads = frees = 0;
    CHECK(be_repl(vm, reader, release) == 0);
    CHECK(frees == count);
    CHECK(reads == count + 1);
    CHECK(be_top(vm) == top);
}
int main(void)
{
    bvm *vm = be_vm_new();
    const char *eof[] = { NULL };
    const char *incomplete[] = { "def abandoned()", NULL };
    const char *loop_eof[] = { "for i : 0..2", "print(i)", NULL };
    const char *normal[] = { "var kept = 37", "2 + 3", "def twice(x)",
        "return x * 2", "end", "twice(kept)", "for i : 1..3", "kept += i", "end",
        "var =", "raise 'value_error', 'deliberate'", "kept", NULL };
    const char *resume[] = { "assert(kept == 43)", "assert(twice(5) == 10)", NULL };
    if (!vm) return 3;
    run(vm, eof, 0);
    run(vm, incomplete, 1);
    run(vm, loop_eof, 2);
    run(vm, normal, 12);
    run(vm, resume, 2);
    be_vm_delete(vm);
    printf("REPL checks=%u failures=%u\n", checks, failures);
    return failures ? 1 : 0;
}

/* Host-only byte fixtures for the verbatim P2 editor/interrupt code plus the
 * real Berry VM and REPL. No substituted VM functions or simulated board logs. */
#include "berry.h"
#include "be_repl.h"
#include "p2_vm_state.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const unsigned char *input;
static size_t cursor;
static char output[32768];
static size_t output_size;
static int interrupt_after, polls, interrupt_key, reading;
static unsigned checks, failures;
#define CHECK(x) do { ++checks; if (!(x)) { ++failures; \
    fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #x); } } while (0)
/* UART/cog/timing are explicit host platform seams. */
static int _cogid(void) { return 0; }
/* No wall-clock wait is needed for byte fixtures. */
static void _waitms(int ms) { (void)ms; }
static void p2_smartserial_init(int rx, int tx, int baud)
{ (void)rx; (void)tx; (void)baud; }
static int p2_smartserial_rx(void)
{
    if (!input[cursor]) { fprintf(stderr, "fixture UART exhausted\n"); exit(2); }
    return input[cursor++];
}
static int p2_smartserial_rxcheck(void)
{
    if (reading) return p2_smartserial_rx();
    if (interrupt_after && ++polls == interrupt_after) return interrupt_key;
    return -1;
}
static void p2_smartserial_tx(int ch)
{
    if (output_size + 1 >= sizeof(output)) abort();
    output[output_size++] = (char)ch;
    output[output_size] = 0;
}
/* Concurrency idle transfer is intentionally excluded, not mocked as success. */
#define BE_P2_PROFILE 0
#define BE_P2_PROFILE_MINIMAL 0
/* Native UART has no actual pins or baud rate. */
#define BERRY_P2_RX_PIN 0
#define BERRY_P2_TX_PIN 0
#define BERRY_P2_BAUD 0
#include "p2_editor.inc"

static char *reader(const char *prompt)
{
    char *line;
    reading = 1;
    line = p2_readline(prompt);
    reading = 0;
    return line;
}
static void feed(const char *bytes)
{
    input = (const unsigned char *)bytes;
    cursor = output_size = 0;
    output[0] = 0;
}
static void evaluate(bvm *vm, const char *source)
{
    int top = be_top(vm);
    int rc = be_loadstring(vm, source);
    if (!rc) rc = be_pcall(vm, 0);
    CHECK(rc == BE_OK);
    if (rc) be_dumpexcept(vm);
    be_pop(vm, be_top(vm) - top);
}
static void session(bvm *vm, const char *bytes, int exits, const char *expected)
{
    int top = be_top(vm);
    feed(bytes);
    CHECK(be_repl(vm, reader, p2_freeline) == 0);
    CHECK(cursor == strlen(bytes));
    CHECK(p2_take_exit_request() == exits);
    CHECK(be_top(vm) == top);
    if (expected) CHECK(strstr(output, expected) != NULL);
    evaluate(vm, "assert(kept == 37)");
}
int main(void)
{
    bvm *vm = be_vm_new();
    unsigned i;
    if (!vm) return 3;
    p2_serial_init();
    evaluate(vm, "var kept = 37");
    session(vm, "\003", 0, "KeyboardInterrupt");
    session(vm, "kept = 99\003", 0, "KeyboardInterrupt");
    session(vm, "def abandoned()\rkept = 99\r\003", 0, "KeyboardInterrupt");
    session(vm, "for i : 1..3\rkept = 99\003", 0, "KeyboardInterrupt");
    session(vm, "\004", 1, NULL);
    session(vm, "def abandoned()\r\004", 1, NULL);
    session(vm, "2 + \0043\r\004", 1, "\r\n5\r\n");
    session(vm, "var =\rkept\r\004", 1, "syntax_error");
    session(vm, "raise 'value_error', 'deliberate'\rkept\r\004", 1, "value_error");
    session(vm, "def twice(x)\rreturn x * 2\rend\rtwice(kept)\r\004", 1, "\r\n74\r\n");
    session(vm, "var total = 0\rfor i : 1..3\rtotal += i\rend\rtotal\r\004", 1, "\r\n6\r\n");
    /* Actual VM poll hook -> actual P2 interrupt -> Berry protected call. */
    interrupt_after = 3;
    interrupt_key = 3;
    polls = 0;
    session(vm, "while true end\rkept\r\004", 1, "KeyboardInterrupt");
    CHECK(polls >= interrupt_after);
    interrupt_after = 0;
    for (i = 0; i < 50; ++i) {
        session(vm, "def discarded()\r\003", 0, "KeyboardInterrupt");
        session(vm, "kept\r\004", 1, "\r\n37\r\n");
    }
    /* Existing editing and CR/LF contract. */
    feed("12\033[D3\033[F\b4\r\n\004");
    CHECK(strcmp(reader("> "), "134") == 0);
    CHECK(reader("> ") == NULL);
    CHECK(p2_take_exit_request() == 1);
    be_vm_delete(vm);
    printf("P2 editor/REPL checks=%u failures=%u (native UART fixtures only)\n", checks, failures);
    return failures ? 1 : 0;
}

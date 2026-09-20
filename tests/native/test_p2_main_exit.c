#define _POSIX_C_SOURCE 200809L
/* Native boundary test for the real P2 main source. The child must remain alive
 * after the production entry point reports an interpreter exit; a return is a
 * Catalina-startup regression. Hardware/VM boundaries are explicit mocks. */
#include "berry.h"
#include "be_repl.h"
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define BE_P2_PROFILE_NAME "native-test"
#define P2_BUILD_DATE_STR "date"
#define P2_BUILD_TIME_STR "time"
#define P2_BUILD_BINARY_BYTES 0u
#define P2_BUILD_CODE_BYTES 0u
#define P2_BUILD_CONST_BYTES 0u
#define P2_BUILD_INIT_BYTES 0u
#define P2_BUILD_DATA_BYTES 0u
#define BE_P2_HEAP_BYTES 0u
#define BE_P2_EXTERNAL_RAM_BYTES 0u
#define BE_P2_XMM_BYTES 0u
#define BE_P2_PSRAM_BLOCK_BASE 0u
#define BE_P2_HEAP_USES_EXTERNAL_RAM 0

static int output_fd = -1;
static int repl_calls;

static void p2_serial_init(void) {}
static void p2_serial_puts(const char *s)
{
    size_t n = strlen(s);
    if (output_fd >= 0 && write(output_fd, s, n) != (ssize_t)n) _exit(91);
}
static int p2_cog_registry_startup(void) { return 1; }
bvm *be_vm_new(void) { return (bvm *)1; }
static int p2_take_exit_request(void) { return 0; }
static char *p2_readline(const char *prompt) { (void)prompt; return NULL; }
static void p2_freeline(char *line) { (void)line; }
int be_repl(bvm *vm, breadline reader, bfreeline freeline)
{
    (void)vm;
    (void)reader;
    (void)freeline;
    ++repl_calls;
    return BE_EXIT;
}

#define main production_p2_main
#include "p2_main.inc"
#undef main

static int require(int condition, const char *message)
{
    if (!condition) fprintf(stderr, "FAIL: %s\n", message);
    return condition;
}

int main(void)
{
    int pipefd[2], status;
    struct pollfd readable;
    struct timespec now, deadline;
    char output[4096] = {0};
    char *marker;
    size_t used = 0;
    ssize_t n;
    pid_t child;

    if (pipe(pipefd) != 0) return 2;
    child = fork();
    if (child < 0) return 3;
    if (child == 0) {
        close(pipefd[0]);
        output_fd = pipefd[1];
        production_p2_main();
        _exit(90); /* A return would permit Catalina startup. */
    }
    close(pipefd[1]);
    readable.fd = pipefd[0];
    readable.events = POLLIN | POLLHUP;
    if (!require(clock_gettime(CLOCK_MONOTONIC, &deadline) == 0,
                 "could not set production output deadline")) goto fail;
    deadline.tv_sec += 1;
    while (strstr(output, "[Berry interpreter exited]\n") == NULL) {
        long milliseconds;
        if (!require(clock_gettime(CLOCK_MONOTONIC, &now) == 0,
                     "could not read production output clock")) goto fail;
        milliseconds = (deadline.tv_sec - now.tv_sec) * 1000L
            + (deadline.tv_nsec - now.tv_nsec + 999999L) / 1000000L;
        if (!require(milliseconds > 0, "documented exit marker missing before deadline")) goto fail;
        if (milliseconds > 1000) milliseconds = 1000;
        readable.revents = 0;
        if (!require(poll(&readable, 1, (int)milliseconds) > 0,
                     "documented exit marker missing before deadline")) goto fail;
        n = read(pipefd[0], output + used, sizeof(output) - used - 1);
        if (!require(n > 0, "production output ended before exit marker")) goto fail;
        used += (size_t)n;
        output[used] = '\0';
    }

    marker = strstr(output, "[Berry interpreter exited]\n");
    if (!require(marker + strlen("[Berry interpreter exited]\n") == output + used,
                 "output followed the exit marker in the same production read")) goto fail;

    readable.revents = 0;
    if (!require(poll(&readable, 1, 250) == 0,
                 "unexpected output after exit marker (restart/return)")) goto fail;
    if (!require(waitpid(child, &status, WNOHANG) == 0,
                 "production main returned after exit marker")) goto fail;
    if (!require(kill(child, SIGKILL) == 0, "could not end bounded child")) return 4;
    if (!require(waitpid(child, &status, 0) == child, "child reap failed")) return 5;
    printf("P2 production exit terminal-state checks passed\n");
    return 0;

fail:
    kill(child, SIGKILL);
    waitpid(child, &status, 0);
    return 1;
}

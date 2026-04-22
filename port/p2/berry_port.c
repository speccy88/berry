#include "berry.h"
#include "be_sys.h"
#include "berry_port.h"
#include "p2_smartserial.h"

#include <propeller2.h>
#include <string.h>

enum {
    BERRY_P2_BAUD = 115200,
    BERRY_P2_RX_PIN = 63,
    BERRY_P2_TX_PIN = 62
};

void p2_serial_init(void)
{
    p2_smartserial_init(BERRY_P2_RX_PIN, BERRY_P2_TX_PIN, BERRY_P2_BAUD);
    _waitms(100);
}

static const char *map_prompt(const char *prompt)
{
    if (!prompt || !*prompt) {
        return "berry> ";
    }
    if (!strcmp(prompt, "> ")) {
        return "berry> ";
    }
    if (!strcmp(prompt, ">> ")) {
        return "...> ";
    }
    return prompt;
}

static void serial_write_char(int ch)
{
    if (ch == '\n') {
        p2_smartserial_tx('\r');
    }
    p2_smartserial_tx(ch);
}

void p2_serial_puts(const char *s)
{
    while (*s) {
        serial_write_char(*s++);
    }
}

static char *serial_readline(char *buffer, size_t size)
{
    int pos = 0;
    int limit = (int)size;

    if (!buffer || limit <= 0) {
        return NULL;
    }

    for (;;) {
        int ch = p2_smartserial_rx();

        if (ch < 0) {
            continue;
        }

        if (ch == '\r' || ch == '\n') {
            serial_write_char('\n');
            if (pos + 1 < limit) {
                buffer[pos++] = '\n';
            }
            break;
        }

        if ((ch == '\b' || ch == 127) && pos > 0) {
            pos--;
            serial_write_char('\b');
            serial_write_char(' ');
            serial_write_char('\b');
            continue;
        }

        if (pos + 1 >= limit) {
            break;
        }

        buffer[pos++] = (char)ch;
        serial_write_char(ch);
    }

    buffer[pos] = '\0';
    return buffer;
}

BERRY_API void be_writebuffer(const char *buffer, size_t length)
{
    int remaining = (int)length;

    while (remaining-- > 0) {
        serial_write_char((unsigned char)*buffer++);
    }
}

BERRY_API char *be_readstring(char *buffer, size_t size)
{
    return serial_readline(buffer, size);
}

char *p2_readline(const char *prompt)
{
    static char line[256];

    p2_serial_puts(map_prompt(prompt));
    return serial_readline(line, sizeof(line));
}

void p2_freeline(char *line)
{
    (void)line;
}

void *be_fopen(const char *filename, const char *modes)
{
    (void)filename;
    (void)modes;
    return NULL;
}

int be_fclose(void *hfile)
{
    (void)hfile;
    return -1;
}

size_t be_fwrite(void *hfile, const void *buffer, size_t length)
{
    (void)hfile;
    be_writebuffer((const char *)buffer, length);
    return length;
}

size_t be_fread(void *hfile, void *buffer, size_t length)
{
    size_t pos = 0;
    char *dst = (char *)buffer;
    (void)hfile;

    while (pos < length) {
        int ch = p2_smartserial_rx();
        if (ch < 0) {
            continue;
        }
        dst[pos++] = (char)ch;
        if (ch == '\r') {
            dst[pos - 1] = '\n';
            break;
        }
        if (ch == '\n') {
            break;
        }
    }

    return pos;
}

char *be_fgets(void *hfile, void *buffer, int size)
{
    (void)hfile;
    return be_readstring((char *)buffer, (size_t)size);
}

int be_fseek(void *hfile, long offset)
{
    (void)hfile;
    (void)offset;
    return -1;
}

long int be_ftell(void *hfile)
{
    (void)hfile;
    return 0;
}

long int be_fflush(void *hfile)
{
    (void)hfile;
    return 0;
}

size_t be_fsize(void *hfile)
{
    (void)hfile;
    return 0;
}

int be_isdir(const char *path)
{
    (void)path;
    return 0;
}

int be_isfile(const char *path)
{
    (void)path;
    return 0;
}

int be_isexist(const char *path)
{
    (void)path;
    return 0;
}

char *be_getcwd(char *buf, size_t size)
{
    if (buf && size >= 2) {
        buf[0] = '/';
        buf[1] = '\0';
        return buf;
    }
    return NULL;
}

int be_chdir(const char *path)
{
    (void)path;
    return -1;
}

int be_mkdir(const char *path)
{
    (void)path;
    return -1;
}

int be_unlink(const char *filename)
{
    (void)filename;
    return -1;
}

int be_dirfirst(bdirinfo *info, const char *path)
{
    (void)info;
    (void)path;
    return -1;
}

int be_dirnext(bdirinfo *info)
{
    (void)info;
    return -1;
}

int be_dirclose(bdirinfo *info)
{
    (void)info;
    return 0;
}

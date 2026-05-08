/*
 * Temporary RAM SD-card loader for Berry Spin2 binaries.
 *
 * The host side loads this program with loadp2 -t, then sends an ASCII-safe
 * protocol over the terminal channel.  The loader writes files to Catalina's
 * mounted DOSFS SD card and verifies a CRC32 for each file.
 */
#include <ctype.h>
#include <fs.h>
#include <hmi.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum {
    LINE_MAX_LEN = 700,
    CHUNK_MAX_BYTES = 256,
    PATH_MAX_LEN = 128
};

static void out(const char *text)
{
    t_string(1, (char *)text);
}

static void outln(const char *text)
{
    out(text);
    t_char(1, '\n');
}

static int read_line(char *line, int size)
{
    int pos = 0;

    if (!line || size <= 1) {
        return -1;
    }

    for (;;) {
        int ch = k_wait() & 0xff;

        if (ch == '\r' || ch == '\n') {
            line[pos] = '\0';
            return pos;
        }
        if ((ch == 8 || ch == 127) && pos > 0) {
            --pos;
            continue;
        }
        if (ch < 32 || ch > 126) {
            continue;
        }
        if (pos + 1 < size) {
            line[pos++] = (char)ch;
        }
    }
}

static int hex_value(int ch)
{
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    }
    ch = toupper(ch);
    if (ch >= 'A' && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return -1;
}

static int hex_decode(const char *hex, uint8_t *outbuf, int outmax)
{
    int len = (int)strlen(hex);
    int i;
    int pos = 0;

    if ((len & 1) != 0) {
        return -1;
    }
    for (i = 0; i < len; i += 2) {
        int hi;
        int lo;

        if (pos >= outmax) {
            return -1;
        }
        hi = hex_value((unsigned char)hex[i]);
        lo = hex_value((unsigned char)hex[i + 1]);
        if (hi < 0 || lo < 0) {
            return -1;
        }
        outbuf[pos++] = (uint8_t)((hi << 4) | lo);
    }
    return pos;
}

static uint32_t crc32_update(uint32_t crc, const uint8_t *data, uint32_t size)
{
    uint32_t i;

    crc = ~crc;
    for (i = 0; i < size; ++i) {
        int bit;

        crc ^= data[i];
        for (bit = 0; bit < 8; ++bit) {
            uint32_t mask = (uint32_t)-(int32_t)(crc & 1u);
            crc = (crc >> 1) ^ (0xedb88320u & mask);
        }
    }
    return ~crc;
}

static const char *fs_path(const char *path)
{
    while (path && *path == '/') {
        ++path;
    }
    return path && *path ? path : "";
}

static int ensure_parent_dirs(const char *path)
{
    char parent[PATH_MAX_LEN];
    char *slash;
    size_t len;

    path = fs_path(path);
    slash = strrchr(path, '/');
    if (!slash) {
        return 0;
    }

    len = (size_t)(slash - path);
    if (len == 0 || len >= sizeof(parent)) {
        return 0;
    }
    memcpy(parent, path, len);
    parent[len] = '\0';

    /*
     * _mkdirr may report failure when the directory already exists on some
     * DOSFS paths.  Treat it as best-effort; the following _create is the real
     * success test.
     */
    (void)_mkdirr(parent, 0);
    return 0;
}

static int parse_put_header(const char *line,
    char *path,
    uint32_t *size,
    uint32_t *expected_crc)
{
    const char *p = line + 4;
    char *end;
    int pos = 0;

    while (*p == ' ') {
        ++p;
    }
    while (*p && *p != ' ' && pos + 1 < PATH_MAX_LEN) {
        path[pos++] = *p++;
    }
    path[pos] = '\0';
    if (path[0] == '\0' || *p != ' ') {
        return -1;
    }
    while (*p == ' ') {
        ++p;
    }
    *size = (uint32_t)strtoul(p, &end, 10);
    if (end == p || *end != ' ') {
        return -1;
    }
    p = end;
    while (*p == ' ') {
        ++p;
    }
    *expected_crc = (uint32_t)strtoul(p, &end, 16);
    if (end == p) {
        return -1;
    }
    return 0;
}

static int receive_file(const char *header)
{
    char path[PATH_MAX_LEN];
    char line[LINE_MAX_LEN];
    uint8_t chunk[CHUNK_MAX_BYTES];
    uint32_t expected_size;
    uint32_t expected_crc;
    uint32_t actual_size = 0;
    uint32_t actual_crc = 0;
    int fd;
    int failed = 0;

    if (parse_put_header(header, path, &expected_size, &expected_crc) != 0) {
        outln("ERR bad PUT header");
        return -1;
    }

    ensure_parent_dirs(path);
    (void)_unlink(fs_path(path));
    fd = _create(fs_path(path), 1);
    if (fd < 0) {
        out("ERR create ");
        outln(path);
        return -1;
    }

    for (;;) {
        int got;
        int wrote;

        if (read_line(line, sizeof(line)) < 0) {
            failed = 1;
            break;
        }
        if (strcmp(line, "END") == 0) {
            break;
        }
        if (line[0] != ':') {
            failed = 1;
            continue;
        }
        got = hex_decode(line + 1, chunk, sizeof(chunk));
        if (got < 0 || actual_size + (uint32_t)got > expected_size) {
            failed = 1;
            continue;
        }
        wrote = _write(fd, (const char *)chunk, got);
        if (wrote != got) {
            failed = 1;
            continue;
        }
        actual_crc = crc32_update(actual_crc, chunk, (uint32_t)got);
        actual_size += (uint32_t)got;
    }

    _close(fd);
    if (failed || actual_size != expected_size || actual_crc != expected_crc) {
        (void)_unlink(fs_path(path));
        out("ERR verify ");
        outln(path);
        return -1;
    }

    out("OK ");
    out(path);
    out(" ");
    t_integer(1, (int)actual_size);
    t_char(1, '\n');
    return 0;
}

static void make_dir(const char *line)
{
    const char *path = line + 6;

    while (*path == ' ') {
        ++path;
    }
    (void)_mkdirr(fs_path(path), 0);
    out("OK MKDIR ");
    outln(path);
}

int main(void)
{
    char line[LINE_MAX_LEN];

    if (_mount(0, 0) != 0) {
        outln("ERR mount failed");
        return 1;
    }

    outln("BERRY_SDLOAD READY");
    for (;;) {
        if (read_line(line, sizeof(line)) < 0) {
            return 1;
        }
        if (strcmp(line, "QUIT") == 0) {
            outln("BERRY_SDLOAD BYE");
            return 0;
        }
        if (strncmp(line, "MKDIR ", 6) == 0) {
            make_dir(line);
            continue;
        }
        if (strncmp(line, "PUT ", 4) == 0) {
            (void)receive_file(line);
            continue;
        }
        outln("ERR unknown command");
    }
}

#include "berry.h"
#include "be_sys.h"
#include "berry_port.h"
#include "p2_serial.h"

#if defined(__CATALINA__)
#include <stdio.h>
#include <fs.h>
extern VOLINFO __vi;
#else
#include <propeller2.h>
#endif
#include <stdlib.h>
#include <string.h>

#if defined(__CATALINA__)
#define P2_FS_PATH_MAX 256

static int p2_fs_mounted;
static char p2_cwd[P2_FS_PATH_MAX] = "/";

typedef struct {
    FILEINFO info;
    uint8_t scratch[SECTOR_SIZE];
} p2_file_handle;

typedef struct {
    DIRINFO di;
    DIRENT entry;
    uint8_t scratch[SECTOR_SIZE];
    char name[13];
} p2_dir_handle;

static int p2_resolve_path(const char *path, char *out, size_t size);

static int p2_fs_ensure_mounted(void)
{
    if (!p2_fs_mounted) {
        if (_mount(0, 0) != 0) {
            return -1;
        }
        p2_fs_mounted = 1;
    }
    return 0;
}

static const char *p2_catalina_fs_path(const char *path)
{
    if (!path || !*path || (path[0] == '/' && path[1] == '\0')) {
        return "";
    }
    if (path[0] == '/') {
        return path + 1;
    }
    return path;
}

static int p2_dir_decode_name(const DIRENT *entry, char *name, size_t size)
{
    int i;
    int j = 0;

    if (!entry || !name || size < 2) {
        return -1;
    }

    memset(name, 0, size);
    for (i = 0; i < 8 && j + 1 < (int)size; ++i) {
        uint8_t ch = entry->name[i];
        if (!ch || ch == ' ') {
            break;
        }
        name[j++] = (char)ch;
    }
    for (i = 8; i < 11 && j + 1 < (int)size; ++i) {
        uint8_t ch = entry->name[i];
        if (!ch || ch == ' ') {
            break;
        }
        if (i == 8 && j + 2 < (int)size) {
            name[j++] = '.';
        }
        name[j++] = (char)ch;
    }
    name[j] = '\0';
    return j > 0 ? 0 : -1;
}

static int p2_dir_load_next(p2_dir_handle *dir)
{
    while (DFS_GetNext(&__vi, &dir->di, &dir->entry) == DFS_OK) {
        if (dir->entry.name[0] == 0) {
            continue;
        }
        if (dir->entry.attr & ATTR_VOLUME_ID) {
            continue;
        }
        if (dir->entry.attr & ATTR_HIDDEN) {
            continue;
        }
        if (p2_dir_decode_name(&dir->entry, dir->name, sizeof(dir->name)) == 0) {
            return 0;
        }
    }
    return -1;
}

static int p2_is_plus_mode(const char *modes)
{
    while (modes && *modes) {
        if (*modes == '+') {
            return 1;
        }
        ++modes;
    }
    return 0;
}

static int p2_open_mode(const char *modes, uint8_t *mode, int *truncate_existing, int *append)
{
    char base = 'r';
    int readwrite = p2_is_plus_mode(modes);

    if (modes && *modes) {
        base = *modes;
    }

    *truncate_existing = 0;
    *append = 0;
    switch (base) {
    case 'r':
        *mode = readwrite ? (DFS_READ | DFS_WRITE) : DFS_READ;
        break;
    case 'w':
        *mode = readwrite ? (DFS_READ | DFS_WRITE) : DFS_WRITE;
        *truncate_existing = 1;
        break;
    case 'a':
        *mode = readwrite ? (DFS_READ | DFS_WRITE) : DFS_WRITE;
        *append = 1;
        break;
    default:
        return -1;
    }
    return 0;
}

static int p2_mode_allows_write(const char *modes)
{
    if (!modes || !*modes) {
        return 0;
    }
    return modes[0] == 'w' || modes[0] == 'a' || strchr(modes, '+') != NULL;
}

static int p2_open_fileinfo(const char *fs_path,
    uint8_t mode,
    uint8_t *scratch,
    FILEINFO *info)
{
    uint32_t result;

    result = DFS_OpenFile(&__vi, (uint8_t *)fs_path, mode, scratch, info);
    if (result == DFS_OK) {
        return 0;
    }

    /*
     * Catalina's current DOSFS write-sector shim on P2 can report failure
     * even after a create/write path has physically succeeded. Retry once
     * if the target now exists.
     */
    if (DFS_OpenFile(&__vi, (uint8_t *)fs_path, DFS_READ, scratch, info) == DFS_OK) {
        if ((mode & DFS_WRITE) == 0) {
            return 0;
        }
        result = DFS_OpenFile(&__vi, (uint8_t *)fs_path, mode, scratch, info);
        if (result == DFS_OK) {
            return 0;
        }
    }

    return -1;
}

static int p2_path_exists(const char *path)
{
    FILEINFO fileinfo;
    DIRINFO dirinfo;
    uint8_t scratch[SECTOR_SIZE];

    if (!path) {
        return 0;
    }

    if (DFS_OpenFile(&__vi, (uint8_t *)p2_catalina_fs_path(path), DFS_READ, scratch, &fileinfo) == DFS_OK) {
        return 1;
    }

    memset(&dirinfo, 0, sizeof(dirinfo));
    dirinfo.scratch = scratch;
    return DFS_OpenDir(&__vi, (uint8_t *)p2_catalina_fs_path(path), &dirinfo) == DFS_OK;
}

static int p2_path_push_segment(char *dst, size_t *length, const char *segment, size_t seglen)
{
    if (*length > 1 && dst[*length - 1] != '/') {
        if (*length + 1 >= P2_FS_PATH_MAX) {
            return -1;
        }
        dst[(*length)++] = '/';
    }
    if (*length + seglen >= P2_FS_PATH_MAX) {
        return -1;
    }
    memcpy(dst + *length, segment, seglen);
    *length += seglen;
    dst[*length] = '\0';
    return 0;
}

static void p2_path_pop_segment(char *dst, size_t *length)
{
    while (*length > 1 && dst[*length - 1] == '/') {
        dst[--(*length)] = '\0';
    }
    while (*length > 1 && dst[*length - 1] != '/') {
        dst[--(*length)] = '\0';
    }
    if (*length == 0) {
        dst[0] = '/';
        dst[1] = '\0';
        *length = 1;
    } else {
        dst[*length] = '\0';
    }
}

static int p2_resolve_path(const char *path, char *out, size_t size)
{
    const char *src;
    size_t len = 0;

    if (!out || size < 2) {
        return -1;
    }

    if (!path || !*path) {
        path = ".";
    }

    if (path[0] == '/') {
        out[len++] = '/';
        out[len] = '\0';
        src = path;
        while (*src == '/') {
            ++src;
        }
    } else {
        size_t cwd_len = strlen(p2_cwd);
        if (cwd_len >= size) {
            return -1;
        }
        memcpy(out, p2_cwd, cwd_len + 1);
        len = cwd_len;
        src = path;
    }

    while (*src) {
        const char *segment = src;
        size_t seglen = 0;

        while (*src && *src != '/') {
            ++src;
            ++seglen;
        }
        while (*src == '/') {
            ++src;
        }

        if (seglen == 0 || (seglen == 1 && segment[0] == '.')) {
            continue;
        }
        if (seglen == 2 && segment[0] == '.' && segment[1] == '.') {
            p2_path_pop_segment(out, &len);
            continue;
        }
        if (p2_path_push_segment(out, &len, segment, seglen) != 0) {
            return -1;
        }
    }

    if (len == 0) {
        out[0] = '/';
        out[1] = '\0';
    }
    return 0;
}
#endif

enum {
    BERRY_P2_BAUD = 115200,
    BERRY_P2_RX_PIN = 63,
    BERRY_P2_TX_PIN = 62
};

static int p2_exit_requested;
static int p2_swallow_newline;

void p2_serial_init(void)
{
    p2_smartserial_init(BERRY_P2_RX_PIN, BERRY_P2_TX_PIN, BERRY_P2_BAUD);
#if !defined(__CATALINA__)
    _waitms(100);
#endif
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
#if defined(__CATALINA__)
    const int echo_input = 0;
#else
    const int echo_input = 1;
#endif

    if (!buffer || limit <= 0) {
        return NULL;
    }

    for (;;) {
        int ch = p2_smartserial_rx();

        if (ch < 0) {
            continue;
        }

        if (p2_swallow_newline) {
            if (ch == p2_swallow_newline) {
                p2_swallow_newline = 0;
                continue;
            }
            p2_swallow_newline = 0;
        }

        if (ch == 3 || ch == 4) {
            if (pos == 0) {
                p2_exit_requested = 1;
                serial_write_char('\n');
                return NULL;
            }
            continue;
        }

        if (ch == '\r' || ch == '\n') {
            p2_swallow_newline = (ch == '\r') ? '\n' : '\r';
            serial_write_char('\n');
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
        if (echo_input) {
            serial_write_char(ch);
        }
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

    p2_serial_puts("\r");
    p2_serial_puts(map_prompt(prompt));
    return serial_readline(line, sizeof(line));
}

void p2_freeline(char *line)
{
    (void)line;
}

void p2_clear_exit_request(void)
{
    p2_exit_requested = 0;
}

int p2_take_exit_request(void)
{
    int requested = p2_exit_requested;
    p2_exit_requested = 0;
    return requested;
}

void *be_fopen(const char *filename, const char *modes)
{
#if defined(__CATALINA__)
    char path[P2_FS_PATH_MAX];
    const char *fs_path;
    p2_file_handle *handle;
    uint8_t mode;
    int truncate_existing;
    int append;
    int allow_write;

    if (p2_fs_ensure_mounted() != 0
        || p2_resolve_path(filename, path, sizeof(path)) != 0
        || p2_open_mode(modes, &mode, &truncate_existing, &append) != 0) {
        return NULL;
    }
    fs_path = p2_catalina_fs_path(path);
    allow_write = p2_mode_allows_write(modes);

    handle = malloc(sizeof(*handle));
    if (!handle) {
        return NULL;
    }
    memset(handle, 0, sizeof(*handle));
    if (truncate_existing) {
        DFS_UnlinkFile(&__vi, (uint8_t *)fs_path, handle->scratch);
    }
    if (p2_open_fileinfo(fs_path, mode, handle->scratch, &handle->info) != 0) {
        if (allow_write && DFS_OpenFile(&__vi, (uint8_t *)fs_path, DFS_READ, handle->scratch, &handle->info) == DFS_OK) {
            /* accept the create as successful and reuse the handle */
        } else {
            free(handle);
            return NULL;
        }
    }
    if (append) {
        DFS_Seek(&handle->info, handle->info.filelen, handle->scratch);
    } else if (truncate_existing && allow_write && handle->info.filelen > 0) {
        /*
         * If Catalina reported a false failure after recreating the file,
         * re-opening read-only can leave the old size cached in the handle.
         * Force the logical position back to the start for Berry semantics.
         */
        DFS_Seek(&handle->info, 0, handle->scratch);
    }
    return handle;
#else
    (void)filename;
    (void)modes;
    return NULL;
#endif
}

int be_fclose(void *hfile)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;

    if (!handle) {
        return -1;
    }
    free(handle);
    return 0;
#else
    (void)hfile;
    return -1;
#endif
}

size_t be_fwrite(void *hfile, const void *buffer, size_t length)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;
    uint32_t count = 0;
    uint32_t result;

    if (!handle) {
        return 0;
    }
    result = DFS_WriteFile(&handle->info, handle->scratch, (uint8_t *)buffer, &count, (uint32_t)length);
    if (result != DFS_OK && count == 0) {
        return 0;
    }
    return (size_t)count;
#else
    (void)hfile;
    be_writebuffer((const char *)buffer, length);
    return length;
#endif
}

size_t be_fread(void *hfile, void *buffer, size_t length)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;
    uint32_t count = 0;

    if (!handle) {
        return 0;
    }
    if (DFS_ReadFile(&handle->info, handle->scratch, (uint8_t *)buffer, &count, (uint32_t)length) != DFS_OK
        && count == 0) {
        return 0;
    }
    return (size_t)count;
#else
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
#endif
}

char *be_fgets(void *hfile, void *buffer, int size)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;
    char *dst = (char *)buffer;
    int pos = 0;

    if (!handle || !buffer || size <= 1) {
        return NULL;
    }
    while (pos + 1 < size) {
        uint32_t count = 0;
        if (DFS_ReadFile(&handle->info, handle->scratch, (uint8_t *)(dst + pos), &count, 1) != DFS_OK
            && count == 0) {
            break;
        }
        if (count == 0) {
            break;
        }
        if (dst[pos++] == '\n') {
            break;
        }
    }
    if (pos == 0) {
        return NULL;
    }
    dst[pos] = '\0';
    return dst;
#else
    (void)hfile;
    return be_readstring((char *)buffer, (size_t)size);
#endif
}

int be_fseek(void *hfile, long offset)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;
    uint32_t pos;

    if (!handle) {
        return -1;
    }
    pos = offset < 0 ? 0u : (uint32_t)offset;
    if (pos > handle->info.filelen) {
        pos = handle->info.filelen;
    }
    DFS_Seek(&handle->info, pos, handle->scratch);
    return 0;
#else
    (void)hfile;
    (void)offset;
    return -1;
#endif
}

long int be_ftell(void *hfile)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;

    if (!handle) {
        return -1;
    }
    return (long int)handle->info.pointer;
#else
    (void)hfile;
    return 0;
#endif
}

long int be_fflush(void *hfile)
{
#if defined(__CATALINA__)
    if (!hfile) {
        return -1;
    }
    return 0;
#else
    (void)hfile;
    return 0;
#endif
}

size_t be_fsize(void *hfile)
{
#if defined(__CATALINA__)
    p2_file_handle *handle = (p2_file_handle *)hfile;

    if (!handle) {
        return 0;
    }
    return (size_t)handle->info.filelen;
#else
    (void)hfile;
    return 0;
#endif
}

int be_isdir(const char *path)
{
#if defined(__CATALINA__)
    char fullpath[P2_FS_PATH_MAX];
    FILEINFO fileinfo;
    uint8_t scratch[SECTOR_SIZE];

    if (p2_fs_ensure_mounted() != 0 || p2_resolve_path(path, fullpath, sizeof(fullpath)) != 0) {
        return 0;
    }
    if (!strcmp(fullpath, "/")) {
        return 1;
    }
    return DFS_OpenFile(&__vi, (uint8_t *)p2_catalina_fs_path(fullpath), DFS_OPENDIR, scratch, &fileinfo) == DFS_OK;
#else
    (void)path;
    return 0;
#endif
}

int be_isfile(const char *path)
{
#if defined(__CATALINA__)
    void *hfile;

    if (p2_fs_ensure_mounted() != 0) {
        return 0;
    }
    hfile = be_fopen(path, "r");
    if (!hfile) {
        return 0;
    }
    be_fclose(hfile);
    return 1;
#else
    (void)path;
    return 0;
#endif
}

int be_isexist(const char *path)
{
#if defined(__CATALINA__)
    return be_isdir(path) || be_isfile(path);
#else
    (void)path;
    return 0;
#endif
}

char *be_getcwd(char *buf, size_t size)
{
#if defined(__CATALINA__)
    size_t len = strlen(p2_cwd);
    if (!buf || size <= len) {
        return NULL;
    }
    memcpy(buf, p2_cwd, len + 1);
    return buf;
#else
    if (buf && size >= 2) {
        buf[0] = '/';
        buf[1] = '\0';
        return buf;
    }
    return NULL;
#endif
}

int be_chdir(const char *path)
{
#if defined(__CATALINA__)
    char fullpath[P2_FS_PATH_MAX];

    if (p2_fs_ensure_mounted() != 0 || p2_resolve_path(path, fullpath, sizeof(fullpath)) != 0) {
        return -1;
    }
    if (!be_isdir(fullpath)) {
        return -1;
    }
    strcpy(p2_cwd, fullpath);
    return 0;
#else
    (void)path;
    return -1;
#endif
}

int be_mkdir(const char *path)
{
#if defined(__CATALINA__)
    char fullpath[P2_FS_PATH_MAX];
    FILEINFO fileinfo;
    uint8_t scratch[SECTOR_SIZE];
    uint32_t result;

    if (p2_fs_ensure_mounted() != 0 || p2_resolve_path(path, fullpath, sizeof(fullpath)) != 0) {
        return -1;
    }
    result = DFS_OpenFile(&__vi, (uint8_t *)p2_catalina_fs_path(fullpath), DFS_CREATEDIR, scratch, &fileinfo);
    if (result != DFS_OK) {
        if (be_isdir(fullpath)) {
            return 0;
        }
        return -1;
    }
    return 0;
#else
    (void)path;
    return -1;
#endif
}

int be_unlink(const char *filename)
{
#if defined(__CATALINA__)
    char fullpath[P2_FS_PATH_MAX];
    uint8_t scratch[SECTOR_SIZE];
    const char *fs_path;

    if (p2_fs_ensure_mounted() != 0 || p2_resolve_path(filename, fullpath, sizeof(fullpath)) != 0) {
        return -1;
    }
    fs_path = p2_catalina_fs_path(fullpath);
    if (_unlink(fs_path) == 0) {
        return 0;
    }
    if (DFS_UnlinkDir(&__vi, (uint8_t *)fs_path, scratch) == DFS_OK) {
        return 0;
    }
    return p2_path_exists(fullpath) ? -1 : 0;
#else
    (void)filename;
    return -1;
#endif
}

int be_rename(const char *from, const char *to)
{
#if defined(__CATALINA__)
    char srcpath[P2_FS_PATH_MAX];
    char dstpath[P2_FS_PATH_MAX];
    const char *src_fs;
    const char *dst_fs;

    if (p2_fs_ensure_mounted() != 0
        || p2_resolve_path(from, srcpath, sizeof(srcpath)) != 0
        || p2_resolve_path(to, dstpath, sizeof(dstpath)) != 0) {
        return -1;
    }
    src_fs = p2_catalina_fs_path(srcpath);
    dst_fs = p2_catalina_fs_path(dstpath);
    if (_rename(src_fs, dst_fs) == 0) {
        return 0;
    }
    return be_isexist(srcpath) ? -1 : 0;
#else
    (void)from;
    (void)to;
    return -1;
#endif
}

int be_dirfirst(bdirinfo *info, const char *path)
{
#if defined(__CATALINA__)
    char fullpath[P2_FS_PATH_MAX];
    p2_dir_handle *dir;

    if (!info) {
        return -1;
    }
    memset(info, 0, sizeof(*info));
    if (p2_fs_ensure_mounted() != 0 || p2_resolve_path(path, fullpath, sizeof(fullpath)) != 0) {
        return -1;
    }
    if (!be_isdir(fullpath)) {
        return -1;
    }
    dir = malloc(sizeof(*dir));
    if (!dir) {
        return -1;
    }
    memset(dir, 0, sizeof(*dir));
    dir->di.scratch = dir->scratch;
    if (DFS_OpenDir(&__vi, (uint8_t *)p2_catalina_fs_path(fullpath), &dir->di) != DFS_OK) {
        free(dir);
        return -1;
    }
    if (p2_dir_load_next(dir) != 0) {
        free(dir);
        return -1;
    }
    info->dir = dir;
    info->file = &dir->entry;
    info->name = dir->name;
    return 0;
#else
    (void)info;
    (void)path;
    return -1;
#endif
}

int be_dirnext(bdirinfo *info)
{
#if defined(__CATALINA__)
    p2_dir_handle *dir;

    if (!info || !info->dir) {
        return -1;
    }
    dir = (p2_dir_handle *)info->dir;
    if (p2_dir_load_next(dir) != 0) {
        info->file = NULL;
        info->name = NULL;
        return -1;
    }
    info->file = &dir->entry;
    info->name = dir->name;
    return 0;
#else
    (void)info;
    return -1;
#endif
}

int be_dirclose(bdirinfo *info)
{
#if defined(__CATALINA__)
    if (info && info->dir) {
        free(info->dir);
        info->dir = NULL;
        info->file = NULL;
        info->name = NULL;
    }
    return 0;
#else
    (void)info;
    return 0;
#endif
}

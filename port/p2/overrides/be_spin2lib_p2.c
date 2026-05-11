/********************************************************************
** Propeller 2 Spin2/PASM binary loader module for Berry.
** v1 uses integer handles and a small Hub-RAM mailbox protocol.
********************************************************************/
#include "berry.h"
#include "be_module.h"
#include "be_string.h"
#include "be_sys.h"

#include <cog.h>
#include <propeller2.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum {
    SPIN2_HANDLE_MAX = 4,
    SPIN2_PATH_MAX = 96,
    SPIN2_ARGS_MAX = 8,
    SPIN2_METHOD_MAX = 64,
    SPIN2_ERROR_MAX = 96,
    SPIN2_FLEXSPIN_ENTRY_OFFSET = 0x404,
    SPIN2_DEFAULT_CALL_TIMEOUT_MS = 1000
};

enum {
    SPIN2_MBOX_IDLE = 0,
    SPIN2_MBOX_REQUEST = 1,
    SPIN2_MBOX_RUNNING = 2,
    SPIN2_MBOX_DONE = 3,
    SPIN2_MBOX_ERROR = 4,
    SPIN2_MBOX_STOP = 5
};

typedef struct spin2_mailbox {
    volatile int state;
    int method_id;
    int argc;
    int argv[SPIN2_ARGS_MAX];
    int result;
    uintptr_t par;
    uintptr_t method_addr;
    char error[SPIN2_ERROR_MAX];
} spin2_mailbox;

typedef struct spin2_handle {
    int used;
    int cog;
    unsigned char *program;
    size_t program_size;
    uint32_t method_count;
    uint32_t *method_table;
    spin2_mailbox *mailbox;
    int mailbox_abi;
    char filename[SPIN2_PATH_MAX];
} spin2_handle;

static spin2_handle g_spin2_handles[SPIN2_HANDLE_MAX];
static char g_spin2_path[SPIN2_PATH_MAX] = "/spin2";

static void spin2_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static bint spin2_require_int(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    return be_toint(vm, index);
}

static uintptr_t spin2_optional_pointer(bvm *vm, int index)
{
    if (be_top(vm) < index || be_isnil(vm, index)) {
        return 0;
    }
    if (be_iscomptr(vm, index)) {
        return (uintptr_t)be_tocomptr(vm, index);
    }
    if (be_isint(vm, index)) {
        return (uintptr_t)be_toint(vm, index);
    }
    be_raise(vm, "type_error", "par must be an int, comptr, or nil");
    return 0;
}

static int spin2_ascii_lower(int ch)
{
    return (ch >= 'A' && ch <= 'Z') ? ch - 'A' + 'a' : ch;
}

static int spin2_ext_eq(const char *name, const char *ext)
{
    size_t name_len = strlen(name);
    size_t ext_len = strlen(ext);
    size_t i;

    if (name_len < ext_len) {
        return 0;
    }
    name += name_len - ext_len;
    for (i = 0; i < ext_len; ++i) {
        if (spin2_ascii_lower((unsigned char)name[i]) != spin2_ascii_lower((unsigned char)ext[i])) {
            return 0;
        }
    }
    return 1;
}

static int spin2_name_eq(const char *name, const char *expected)
{
    size_t i;

    if (!name || !expected) {
        return 0;
    }
    for (i = 0; name[i] && expected[i]; ++i) {
        if (spin2_ascii_lower((unsigned char)name[i]) != spin2_ascii_lower((unsigned char)expected[i])) {
            return 0;
        }
    }
    return name[i] == '\0' && expected[i] == '\0';
}

static int spin2_name_starts_with(const char *name, const char *prefix)
{
    size_t i;

    if (!name || !prefix) {
        return 0;
    }
    for (i = 0; prefix[i]; ++i) {
        if (!name[i] || spin2_ascii_lower((unsigned char)name[i]) != spin2_ascii_lower((unsigned char)prefix[i])) {
            return 0;
        }
    }
    return 1;
}

static int spin2_is_binary_name(const char *name)
{
    return name &&
        (spin2_ext_eq(name, ".bin") ||
         spin2_ext_eq(name, ".binary") ||
         spin2_ext_eq(name, ".p2"));
}

static const char *spin2_basename(const char *path)
{
    const char *base = path;

    if (!path) {
        return "";
    }
    while (*path) {
        if (*path == '/' || *path == '\\') {
            base = path + 1;
        }
        ++path;
    }
    return base;
}

static int spin2_join_path(const char *dir, const char *file, char *out, size_t out_size)
{
    size_t dir_len;
    size_t file_len;
    int need_slash;

    if (!file || !out || out_size == 0) {
        return -1;
    }
    if (file[0] == '/' || strchr(file, '/')) {
        file_len = strlen(file);
        if (file_len + 1 > out_size) {
            return -1;
        }
        memcpy(out, file, file_len + 1);
        return 0;
    }

    if (!dir || !dir[0]) {
        dir = ".";
    }
    dir_len = strlen(dir);
    file_len = strlen(file);
    need_slash = dir_len > 0 && dir[dir_len - 1] != '/';
    if (dir_len + (need_slash ? 1u : 0u) + file_len + 1u > out_size) {
        return -1;
    }
    memcpy(out, dir, dir_len);
    out[dir_len] = '\0';
    if (need_slash) {
        out[dir_len++] = '/';
    }
    memcpy(out + dir_len, file, file_len + 1);
    return 0;
}

static int spin2_alloc_handle(void)
{
    int i;

    for (i = 0; i < SPIN2_HANDLE_MAX; ++i) {
        if (!g_spin2_handles[i].used) {
            memset(&g_spin2_handles[i], 0, sizeof(g_spin2_handles[i]));
            g_spin2_handles[i].cog = -1;
            g_spin2_handles[i].used = 1;
            return i;
        }
    }
    return -1;
}

static spin2_handle *spin2_require_handle(bvm *vm, int index)
{
    bint handle_id = spin2_require_int(vm, index, "handle must be an int");

    if (handle_id < 0 || handle_id >= SPIN2_HANDLE_MAX || !g_spin2_handles[handle_id].used) {
        be_raise(vm, "value_error", "invalid spin2 handle");
    }
    return &g_spin2_handles[handle_id];
}

static void spin2_free_handle(spin2_handle *handle)
{
    if (!handle || !handle->used) {
        return;
    }
    if (handle->cog >= 0) {
        if (handle->mailbox) {
            handle->mailbox->state = SPIN2_MBOX_STOP;
            _cogatn(1u << handle->cog);
        }
        _cogstop(handle->cog);
    }
    free(handle->program);
    free(handle->mailbox);
    memset(handle, 0, sizeof(*handle));
    handle->cog = -1;
}

static void spin2_parse_method_table(spin2_handle *handle)
{
    uint32_t count;

    handle->method_count = 0;
    handle->method_table = NULL;
    handle->mailbox_abi = 0;
    if (!handle->program || handle->program_size < sizeof(uint32_t)) {
        return;
    }
    memcpy(&count, handle->program, sizeof(count));
    if (count == 0 || count > SPIN2_METHOD_MAX) {
        return;
    }
    if ((size_t)(count + 1u) * sizeof(uint32_t) > handle->program_size) {
        return;
    }
    handle->method_count = count;
    handle->method_table = (uint32_t *)(void *)(handle->program + sizeof(uint32_t));
    handle->mailbox_abi = 1;
}

static uintptr_t spin2_resolve_method_address(spin2_handle *handle, uint32_t raw)
{
    size_t long_count;

    if (!handle || !handle->program) {
        return 0;
    }
    long_count = handle->program_size / sizeof(uint32_t);
    if (raw < long_count) {
        return (uintptr_t)(handle->program + ((size_t)raw * sizeof(uint32_t)));
    }
    if (raw < handle->program_size) {
        return (uintptr_t)(handle->program + raw);
    }
    return (uintptr_t)raw;
}

static int spin2_is_flexspin_standalone(const spin2_handle *handle)
{
    uint32_t first;
    uint32_t entry;

    if (!handle || !handle->program || handle->program_size <= SPIN2_FLEXSPIN_ENTRY_OFFSET + sizeof(uint32_t)) {
        return 0;
    }
    memcpy(&first, handle->program, sizeof(first));
    memcpy(&entry, handle->program + SPIN2_FLEXSPIN_ENTRY_OFFSET, sizeof(entry));

    /*
     * FlexSpin high-level .BIN files include a hub boot area at 0x400 and a
     * COGINIT launcher at 0x404. Older copies on SD may have non-zero clock
     * header words at the start, so do not depend only on long 0 being zero.
     */
    return (first == 0u && entry != 0u) || entry == 0xf20ff000u;
}

static int spin2_is_known_highlevel_image(const char *file)
{
    const char *name = spin2_basename(file);

    return spin2_name_starts_with(name, "S2_") && !spin2_name_eq(name, "S2_27DIT.BIN");
}

static int spin2_load_file(const char *path, unsigned char **data, size_t *size)
{
    void *file;
    size_t length;
    size_t padded;
    unsigned char *buffer;
    size_t got;

    file = be_fopen(path, "rb");
    if (!file) {
        return -1;
    }
    length = be_fsize(file);
    if (length == 0u) {
        be_fclose(file);
        return -1;
    }
    padded = (length + 3u) & ~(size_t)3u;
    buffer = (unsigned char *)calloc(1u, padded);
    if (!buffer) {
        be_fclose(file);
        return -1;
    }
    got = be_fread(file, buffer, length);
    be_fclose(file);
    if (got != length) {
        free(buffer);
        return -1;
    }
    *data = buffer;
    *size = padded;
    return 0;
}

static int m_spin2_path(bvm *vm)
{
    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        const char *path;
        size_t len;

        if (!be_isstring(vm, 1)) {
            be_raise(vm, "type_error", "path must be a string");
        }
        path = be_tostring(vm, 1);
        len = strlen(path);
        if (len == 0 || len >= sizeof(g_spin2_path)) {
            be_raise(vm, "value_error", "path is empty or too long");
        }
        memcpy(g_spin2_path, path, len + 1);
    }
    be_pushstring(vm, g_spin2_path);
    be_return(vm);
}

static int m_spin2_list(bvm *vm)
{
    const char *path = g_spin2_path;
    bdirinfo info;
    int res;

    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        if (!be_isstring(vm, 1)) {
            be_raise(vm, "type_error", "directory must be a string");
        }
        path = be_tostring(vm, 1);
    }

    res = be_dirfirst(&info, path);
    be_newobject(vm, "list");
    while (res == 0) {
        if (spin2_is_binary_name(info.name)) {
            be_pushstring(vm, info.name);
            be_data_push(vm, -2);
            be_pop(vm, 1);
        }
        res = be_dirnext(&info);
    }
    be_dirclose(&info);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_spin2_start(bvm *vm)
{
    const char *file;
    char path[SPIN2_PATH_MAX * 2];
    uintptr_t par;
    int slot;
    spin2_handle *handle;
    size_t entry_offset = 0;
    void *entry;
    void *start_par;
    int cog;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "file must be a string");
    }
    file = be_tostring(vm, 1);
    par = spin2_optional_pointer(vm, 2);
    if (spin2_join_path(g_spin2_path, file, path, sizeof(path)) != 0) {
        be_raise(vm, "value_error", "spin2 path is too long");
    }
    if (spin2_is_known_highlevel_image(file)) {
        be_raise(vm, "value_error", "high-level FlexSpin image is not relocatable; use a mailbox binary");
    }

    slot = spin2_alloc_handle();
    if (slot < 0) {
        be_raise(vm, "runtime_error", "no spin2 handle slots available");
    }
    handle = &g_spin2_handles[slot];
    if (spin2_load_file(path, &handle->program, &handle->program_size) != 0) {
        spin2_free_handle(handle);
        be_raise(vm, "io_error", "failed to load spin2 binary");
    }
    if (spin2_is_flexspin_standalone(handle)) {
        spin2_free_handle(handle);
        be_raise(vm, "value_error", "high-level FlexSpin image is not relocatable; use a mailbox binary");
    }
    spin2_parse_method_table(handle);
    if (handle->method_count > 0u) {
        entry_offset = (size_t)(handle->method_count + 1u) * sizeof(uint32_t);
        handle->mailbox = (spin2_mailbox *)calloc(1u, sizeof(spin2_mailbox));
        if (!handle->mailbox) {
            spin2_free_handle(handle);
            be_raise(vm, "memory_error", "failed to allocate spin2 mailbox");
        }
        handle->mailbox->state = SPIN2_MBOX_IDLE;
        handle->mailbox->par = par;
    }
    if (entry_offset >= handle->program_size) {
        entry_offset = 0;
    }
    entry = handle->program + entry_offset;
    start_par = handle->mailbox_abi ? (void *)handle->mailbox : NULL;

    cog = _cogstart_PASM(ANY_COG, entry, start_par);
    if (cog < 0) {
        spin2_free_handle(handle);
        be_raise(vm, "runtime_error", "no free cog for spin2 binary");
    }
    handle->cog = cog;
    strncpy(handle->filename, path, sizeof(handle->filename) - 1);
    handle->filename[sizeof(handle->filename) - 1] = '\0';

    be_pushint(vm, (bint)slot);
    be_return(vm);
}

static int m_spin2_call(bvm *vm)
{
    spin2_handle *handle = spin2_require_handle(vm, 1);
    bint method_id = spin2_require_int(vm, 2, "method_id must be an int");
    int argc = be_top(vm) - 2;
    int i;
    bint waited = 0;
    bint timeout_ms = SPIN2_DEFAULT_CALL_TIMEOUT_MS;

    if (!handle->mailbox_abi || !handle->mailbox || handle->cog < 0) {
        be_raise(vm, "runtime_error", "spin2 object is not running");
    }
    if (method_id < 0 || (uint32_t)method_id >= handle->method_count || !handle->method_table) {
        be_raise(vm, "value_error", "method_id is outside the binary call table");
    }
    if (argc > SPIN2_ARGS_MAX) {
        be_raise(vm, "value_error", "too many spin2 method arguments");
    }
    if (handle->mailbox->state != SPIN2_MBOX_IDLE && handle->mailbox->state != SPIN2_MBOX_DONE) {
        be_raise(vm, "runtime_error", "spin2 mailbox is busy");
    }

    memset((void *)handle->mailbox, 0, sizeof(*handle->mailbox));
    handle->mailbox->state = SPIN2_MBOX_RUNNING;
    handle->mailbox->method_id = (int)method_id;
    handle->mailbox->argc = argc;
    handle->mailbox->method_addr = spin2_resolve_method_address(handle, handle->method_table[method_id]);
    for (i = 0; i < argc; ++i) {
        handle->mailbox->argv[i] = (int)spin2_require_int(vm, i + 3, "spin2 call arguments must be ints");
    }

    handle->mailbox->state = SPIN2_MBOX_REQUEST;
    _cogatn(1u << handle->cog);

    while (waited < timeout_ms) {
        if (handle->mailbox->state == SPIN2_MBOX_DONE) {
            be_pushint(vm, (bint)handle->mailbox->result);
            handle->mailbox->state = SPIN2_MBOX_IDLE;
            be_return(vm);
        }
        if (handle->mailbox->state == SPIN2_MBOX_ERROR) {
            const char *error = handle->mailbox->error[0] ? handle->mailbox->error : "spin2 method failed";
            handle->mailbox->state = SPIN2_MBOX_IDLE;
            be_raise(vm, "runtime_error", error);
        }
        _waitms(1);
        ++waited;
    }

    /* Long-running Spin2 methods are allowed in v1; nil means the request was
     * handed off but no completion was observed during the short guard wait. */
    be_pushnil(vm);
    be_return(vm);
}

static int m_spin2_stop(bvm *vm)
{
    spin2_handle *handle = spin2_require_handle(vm, 1);

    spin2_free_handle(handle);
    be_return_nil(vm);
}

static int m_spin2_info(bvm *vm)
{
    spin2_handle *handle = spin2_require_handle(vm, 1);

    be_newobject(vm, "map");

    be_pushstring(vm, "cog");
    be_pushint(vm, (bint)handle->cog);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "size");
    be_pushint(vm, (bint)handle->program_size);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "methods");
    be_pushint(vm, (bint)handle->method_count);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "abi");
    be_pushstring(vm, handle->mailbox_abi ? "mailbox" : "standalone");
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "file");
    be_pushstring(vm, handle->filename);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pop(vm, 1);
    be_return(vm);
}

static int m_spin2_member(bvm *vm)
{
    const char *name = be_tostring(vm, 1);

    if (!strcmp(name, "path")) be_pushntvfunction(vm, m_spin2_path);
    else if (!strcmp(name, "list")) be_pushntvfunction(vm, m_spin2_list);
    else if (!strcmp(name, "start")) be_pushntvfunction(vm, m_spin2_start);
    else if (!strcmp(name, "call")) be_pushntvfunction(vm, m_spin2_call);
    else if (!strcmp(name, "stop")) be_pushntvfunction(vm, m_spin2_stop);
    else if (!strcmp(name, "info")) be_pushntvfunction(vm, m_spin2_info);
    else be_pushnil(vm);
    be_return(vm);
}

void be_cache_spin2module(bvm *vm)
{
    bstring *name = be_newstr(vm, "spin2");

    be_newmodule(vm);
    spin2_module_set_func(vm, "member", m_spin2_member);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}

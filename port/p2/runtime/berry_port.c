#include "berry.h"
#include "be_sys.h"
#include "berry_conf_p2.h"
#include "berry_port.h"
#include "p2_serial.h"
#include "p2_smartserial.h"

#if defined(__CATALINA__)
#include <stdio.h>
#include <fs.h>
#if defined(__CATALINA_LARGE)
#include <hmalloc.h>
#endif
#include <plugin.h>
#include <propeller2.h>
#include <sd.h>
extern VOLINFO __vi;
extern unsigned int __pstart;
extern volatile int berry_p2_sd_read_diag_phase;
extern volatile int berry_p2_sd_read_diag_response;
extern volatile int berry_p2_sd_read_diag_token;
#else
#include <propeller2.h>
#endif
#include <stdint.h>
#include <string.h>

#if defined(__CATALINA__)
#define P2_FS_PATH_MAX 256
#define P2_FS_FILE_SLOTS 4
#define P2_FS_DIR_SLOTS 2
#define P2_SD_TIMEOUT_MS 3000u
#define P2_EDGE_SD_DO 58
#define P2_EDGE_SD_DI 59
#define P2_EDGE_SD_CS 60
#define P2_EDGE_SD_CLK 61
#define P2_EDGE_FLASH_DO 58
#define P2_EDGE_FLASH_DI 59
#define P2_EDGE_FLASH_CLK 60
#define P2_EDGE_FLASH_CS 61
#define P2_EDGE_FLASH_RESET_ENABLE 0x66u
#define P2_EDGE_FLASH_RESET_MEMORY 0x99u
#define P2_EDGE_FLASH_DEEP_POWER_DOWN 0xB9u
#define P2_FS_MOUNT_IO_ERROR -2
#ifndef P2_FS_TRACE
#define P2_FS_TRACE 0
#endif
static int p2_fs_mounted;
static int p2_sd_bus_prepared;
static int p2_sd_initialized;
static char p2_cwd[P2_FS_PATH_MAX] = "/";
#if defined(__CATALINA_LARGE)
static uint8_t *p2_mount_scratch;
#else
static uint8_t p2_mount_scratch[SECTOR_SIZE];
#endif

static volatile long p2_sd_long_param;

typedef struct {
    int used;
    FILEINFO info;
    uint8_t *scratch;
#if !defined(__CATALINA_LARGE)
    uint8_t scratch_storage[SECTOR_SIZE];
#endif
} p2_file_handle;

typedef struct {
    int used;
    DIRINFO di;
    DIRENT entry;
    uint8_t *scratch;
#if !defined(__CATALINA_LARGE)
    uint8_t scratch_storage[SECTOR_SIZE];
#endif
    char name[13];
} p2_dir_handle;

static p2_file_handle p2_file_slots[P2_FS_FILE_SLOTS];
static p2_dir_handle p2_dir_slots[P2_FS_DIR_SLOTS];

static int p2_resolve_path(const char *path, char *out, size_t size);

static void p2_fs_trace(const char *stage)
{
#if P2_FS_TRACE
    printf("[p2.fs] %s\r\n", stage);
    fflush(stdout);
#else
    (void)stage;
#endif
}

static uint8_t *p2_sector_scratch_alloc(uint8_t *storage)
{
#if defined(__CATALINA_LARGE)
    (void)storage;
    return (uint8_t *)hub_malloc(SECTOR_SIZE);
#else
    return storage;
#endif
}

static void p2_sector_scratch_free(uint8_t *scratch)
{
#if defined(__CATALINA_LARGE)
    if (scratch) {
        hub_free(scratch);
    }
#else
    (void)scratch;
#endif
}

static uint8_t *p2_mount_scratch_get(void)
{
#if defined(__CATALINA_LARGE)
    if (!p2_mount_scratch) {
        p2_mount_scratch = (uint8_t *)hub_malloc(SECTOR_SIZE);
    }
#endif
    return p2_mount_scratch;
}

static uint8_t p2_edge_flash_transfer(uint8_t value)
{
    uint8_t in = 0;
    int bit;

    for (bit = 0; bit < 8; ++bit) {
        if (value & 0x80u) {
            _pinh(P2_EDGE_FLASH_DI);
        } else {
            _pinl(P2_EDGE_FLASH_DI);
        }
        value <<= 1;
        _waitus(1);
        _pinh(P2_EDGE_FLASH_CLK);
        _waitus(1);
        in = (uint8_t)((in << 1) | (_pinr(P2_EDGE_FLASH_DO) ? 1u : 0u));
        _pinl(P2_EDGE_FLASH_CLK);
    }
    return in;
}

static void p2_edge_flash_command(uint8_t command)
{
    _pinh(P2_EDGE_FLASH_CS);
    _pinl(P2_EDGE_FLASH_CLK);
    _pinl(P2_EDGE_FLASH_DI);
    _pinf(P2_EDGE_FLASH_DO);
    _waitus(2);
    _pinl(P2_EDGE_FLASH_CS);
    (void)p2_edge_flash_transfer(command);
    _pinh(P2_EDGE_FLASH_CS);
    _waitus(2);
}

static void p2_prepare_sd_bus(void)
{
    int i;

    /*
     * On the P2 Edge, SD and boot flash share pins 58..61, but flash CS is
     * the SD clock pin. Put flash into deep power-down before SD activity so
     * SD clocks do not let flash drive MISO.
     */
    p2_edge_flash_command(P2_EDGE_FLASH_RESET_ENABLE);
    p2_edge_flash_command(P2_EDGE_FLASH_RESET_MEMORY);
    _waitms(100);
    p2_edge_flash_command(P2_EDGE_FLASH_DEEP_POWER_DOWN);
    _waitus(10);

    _pinh(P2_EDGE_SD_CS);
    _pinl(P2_EDGE_SD_CLK);
    _pinh(P2_EDGE_SD_DI);
    _pinf(P2_EDGE_SD_DO);
    for (i = 0; i < 10; ++i) {
        int bit;
        for (bit = 0; bit < 8; ++bit) {
            _pinh(P2_EDGE_SD_CLK);
            _waitus(2);
            _pinl(P2_EDGE_SD_CLK);
            _waitus(2);
        }
    }
    p2_sd_bus_prepared = 1;
}

static void p2_release_sd_bus_from_current_cog(void)
{
    /*
     * The P2 combines pin drive state from all cogs.  The Catalina SD service
     * cog must be the only cog driving the shared SD/flash pins; otherwise a
     * stale high drive from the application/loader cog can keep CS or CLK from
     * actually changing on the board.
     */
    _pinf(P2_EDGE_SD_CS);
    _pinf(P2_EDGE_SD_CLK);
    _pinf(P2_EDGE_SD_DI);
    _pinf(P2_EDGE_SD_DO);
}

static int p2_service_request_timed(int svc, void *param, uint32_t timeout_ms)
{
    unsigned short entry;
    int code;
    int cog;
    int lock;
    int have_lock = 0;
    volatile request_t *request;
    uint32_t spins;

    entry = *SERVICE_POINTER(svc);
    code = (int)(entry & 0x7Fu);
    if (code == 0) {
        return BERRY_P2_FS_RESULT_SD_NO_SERVICE;
    }

    cog = (int)((entry >> 12) & 0x0Fu);
    lock = (int)((entry >> 7) & 0x1Fu);
    request = REQUEST_BLOCK(cog);
    if (!request) {
        return BERRY_P2_FS_RESULT_SD_NO_SERVICE;
    }
    if (request->request != 0) {
        return BERRY_P2_FS_RESULT_SD_BUSY;
    }

    if (lock < LOCK_MAX) {
        if (!_locktry(lock)) {
            return BERRY_P2_FS_RESULT_SD_BUSY;
        }
        have_lock = 1;
    }

    request->response = 0;
    request->request = ((unsigned int)code << 24)
        | ((unsigned int)(uintptr_t)param & 0x00FFFFFFu);

    spins = timeout_ms * 10000u;
    while (request->request != 0) {
        if (--spins == 0) {
            if (have_lock) {
                _lockrel(lock);
            }
            return BERRY_P2_FS_RESULT_SD_TIMEOUT;
        }
    }

    if (have_lock) {
        _lockrel(lock);
    }
    return (int)request->response;
}

static int p2_long_service_timed(int svc, long par, uint32_t timeout_ms)
{
    p2_sd_long_param = par;
    return p2_service_request_timed(svc, (void *)&p2_sd_long_param, timeout_ms);
}

static int p2_fs_init_sd(void)
{
    if (p2_sd_initialized) {
        return 0;
    }
#if defined(__BERRY_P2_DIRECT_SD_IO)
    p2_sd_initialized = 1;
    return 0;
#else
    p2_sd_initialized = 1;
    return 0;
#endif
}

static void p2_decode_sd_service(berry_p2_fs_info *info)
{
    unsigned short entry;

    if (!info) {
        return;
    }

    entry = *SERVICE_POINTER(SVC_SD_INIT);
    info->sd_service_entry = (int)entry;
    info->sd_service_cog = (int)(entry >> 12);
    info->sd_service_lock = (int)((entry >> 7) & 0x1Fu);
    info->sd_service_code = (int)(entry & 0x7Fu);
#if defined(__BERRY_P2_DIRECT_SD_IO)
    info->sd_request = (int)berry_p2_sd_read_diag_phase;
    info->sd_response = (int)berry_p2_sd_read_diag_response;
    info->sd_service_code = (int)berry_p2_sd_read_diag_token;
#else
    if (info->sd_service_code != 0) {
        volatile request_t *request = REQUEST_BLOCK(info->sd_service_cog);
        if (request) {
            info->sd_request = (int)request->request;
            info->sd_response = (int)request->response;
        }
    }
#endif
}

static p2_file_handle *p2_file_alloc(void)
{
    int i;

    /*
     * The Catalina P2 image runs very close to the 512 KiB hub limit, and the
     * C library heap is not dependable there.  File handles therefore live in
     * a tiny fixed pool while Berry-owned objects still use Berry's allocator.
     */
    for (i = 0; i < P2_FS_FILE_SLOTS; ++i) {
        if (!p2_file_slots[i].used) {
            memset(&p2_file_slots[i], 0, sizeof(p2_file_slots[i]));
            p2_file_slots[i].used = 1;
            p2_file_slots[i].scratch = p2_sector_scratch_alloc(
#if defined(__CATALINA_LARGE)
                NULL
#else
                p2_file_slots[i].scratch_storage
#endif
            );
            if (!p2_file_slots[i].scratch) {
                memset(&p2_file_slots[i], 0, sizeof(p2_file_slots[i]));
                return NULL;
            }
            return &p2_file_slots[i];
        }
    }
    return NULL;
}

static void p2_file_free(p2_file_handle *handle)
{
    if (handle) {
        p2_sector_scratch_free(handle->scratch);
        memset(handle, 0, sizeof(*handle));
    }
}

static p2_dir_handle *p2_dir_alloc(void)
{
    int i;

    for (i = 0; i < P2_FS_DIR_SLOTS; ++i) {
        if (!p2_dir_slots[i].used) {
            memset(&p2_dir_slots[i], 0, sizeof(p2_dir_slots[i]));
            p2_dir_slots[i].used = 1;
            p2_dir_slots[i].scratch = p2_sector_scratch_alloc(
#if defined(__CATALINA_LARGE)
                NULL
#else
                p2_dir_slots[i].scratch_storage
#endif
            );
            if (!p2_dir_slots[i].scratch) {
                memset(&p2_dir_slots[i], 0, sizeof(p2_dir_slots[i]));
                return NULL;
            }
            return &p2_dir_slots[i];
        }
    }
    return NULL;
}

static void p2_dir_free(p2_dir_handle *dir)
{
    if (dir) {
        p2_sector_scratch_free(dir->scratch);
        memset(dir, 0, sizeof(*dir));
    }
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

static int p2_dir_char_valid(uint8_t ch)
{
    /*
     * Catalina DOSFS exposes raw 8.3 directory entries.  If the root has stale
     * or partially erased entries, their bytes can be non-printable even though
     * DFS_GetNext() reports success.  Keep listing conservative: Berry scripts
     * need ordinary DOS names, not every possible legacy codepage byte.
     */
    return (ch >= 'A' && ch <= 'Z')
        || (ch >= 'a' && ch <= 'z')
        || (ch >= '0' && ch <= '9')
        || ch == '$' || ch == '%' || ch == '\'' || ch == '-' || ch == '_'
        || ch == '@' || ch == '~' || ch == '`' || ch == '!' || ch == '('
        || ch == ')' || ch == '{' || ch == '}' || ch == '^' || ch == '#'
        || ch == '&';
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
        if (!p2_dir_char_valid(ch)) {
            return -1;
        }
        name[j++] = (char)ch;
    }
    if (j == 0) {
        return -1;
    }
    for (i = 8; i < 11 && j + 1 < (int)size; ++i) {
        uint8_t ch = entry->name[i];
        if (!ch || ch == ' ') {
            break;
        }
        if (!p2_dir_char_valid(ch)) {
            return -1;
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
    int scanned = 0;

    while (DFS_GetNext(&__vi, &dir->di, &dir->entry) == DFS_OK) {
        uint8_t first = (uint8_t)dir->entry.name[0];
        if (++scanned > 1024) {
            return -1;
        }
        if (first == 0) {
            continue;
        }
        if (first == 0xE5 || (dir->entry.attr & 0xC0) != 0) {
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

static void p2_fs_info_init(berry_p2_fs_info *info)
{
    if (!info) {
        return;
    }
    memset(info, 0, sizeof(*info));
    info->sd_init_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->raw_sector0_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->dfs_sector0_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->sd_service_entry = -1;
    info->sd_service_cog = -1;
    info->sd_service_lock = -1;
    info->sd_service_code = -1;
    info->sd_request = -1;
    info->sd_response = -1;
    info->fil_cog = -1;
    info->fil_registered_type = -1;
    info->sector0_signature = -1;
    info->sector0_byte0 = -1;
    info->sector0_byte1 = -1;
    info->sector0_byte2 = -1;
    info->sector0_byte3 = -1;
    info->sector0_sig0 = -1;
    info->sector0_sig1 = -1;
    info->partition_type = -1;
    info->partition_active = -1;
    info->partition_start = -1;
    info->partition_size = -1;
    info->volinfo_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->filesystem_type = -1;
    info->vol_startsector = -1;
    info->vol_secperclus = -1;
    info->vol_reservedsecs = -1;
    info->vol_secperfat = -1;
    info->vol_fat1 = -1;
    info->vol_rootdir = -1;
    info->vol_dataarea = -1;
    info->vol_numsecs = -1;
    info->vol_rootentries = -1;
    info->vol_numclusters = -1;
    info->vol_root_sector = -1;
    info->mount_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->resolve_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->root_open_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->root_first_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->root_first_byte = -1;
    info->root_first_attr = -1;
    info->path_read_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->path_dir_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->create_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->write_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->read_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->unlink_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    strncpy(info->cwd, p2_cwd, sizeof(info->cwd) - 1u);
}

#if BE_P2_ENABLE_SD_DIAGNOSTICS
static void p2_fs_info_copy_raw_dir_name(char *dst, size_t size, const DIRENT *entry)
{
    int i;
    int j = 0;

    if (!dst || size == 0) {
        return;
    }
    dst[0] = '\0';
    if (!entry) {
        return;
    }
    for (i = 0; i < 11 && j + 1 < (int)size; ++i) {
        uint8_t ch = (uint8_t)entry->name[i];
        if (ch >= 32 && ch <= 126) {
            dst[j++] = (char)ch;
        } else {
            dst[j++] = '.';
        }
    }
    dst[j] = '\0';
}

static void p2_fs_info_append_root_sample(berry_p2_fs_info *info,
    const DIRENT *entry,
    int scanned)
{
    char name[16];
    char item[32];
    size_t used;

    if (!info || !entry || scanned >= 10) {
        return;
    }
    p2_fs_info_copy_raw_dir_name(name, sizeof(name), entry);
    snprintf(item, sizeof(item), "%s%s:%02X:%02X",
        info->root_sample[0] ? ";" : "",
        name,
        (unsigned int)((uint8_t)entry->attr),
        (unsigned int)((uint8_t)entry->name[0]));
    used = strlen(info->root_sample);
    if (used + strlen(item) < sizeof(info->root_sample)) {
        strcat(info->root_sample, item);
    }
}
#endif

#if BE_P2_ENABLE_SD_DIAGNOSTICS
static void p2_fs_info_capture_volinfo(berry_p2_fs_info *info)
{
    if (!info || !p2_fs_mounted) {
        return;
    }
    info->vol_startsector = (int)__vi.startsector;
    info->vol_secperclus = (int)__vi.secperclus;
    info->vol_reservedsecs = (int)__vi.reservedsecs;
    info->vol_secperfat = (int)__vi.secperfat;
    info->vol_fat1 = (int)__vi.fat1;
    info->vol_rootdir = (int)__vi.rootdir;
    info->vol_dataarea = (int)__vi.dataarea;
    info->vol_numsecs = (int)__vi.numsecs;
    info->vol_rootentries = (int)__vi.rootentries;
    info->vol_numclusters = (int)__vi.numclusters;
    if (__vi.filesystem == FAT32) {
        info->vol_root_sector = (int)(__vi.dataarea + ((__vi.rootdir - 2u) * __vi.secperclus));
    } else {
        info->vol_root_sector = (int)__vi.rootdir;
    }
}
#endif

static int p2_fs_sector_signature(const uint8_t *scratch)
{
    return ((int)scratch[511] << 8) | (int)scratch[510];
}

static uint32_t p2_fs_le32(const uint8_t *p)
{
    return (uint32_t)p[0]
        | ((uint32_t)p[1] << 8)
        | ((uint32_t)p[2] << 16)
        | ((uint32_t)p[3] << 24);
}

static int p2_fs_partition_type_is_fat(uint8_t type)
{
    switch (type) {
    case 0x01: /* FAT12 */
    case 0x04: /* FAT16 < 32M */
    case 0x06: /* FAT16 */
    case 0x0B: /* FAT32 CHS */
    case 0x0C: /* FAT32 LBA */
    case 0x0E: /* FAT16 LBA */
        return 1;
    default:
        return 0;
    }
}

static int p2_fs_sector_looks_fat_boot(const uint8_t *sector)
{
    if (!sector) {
        return 0;
    }
    if (p2_fs_sector_signature(sector) != 0xAA55) {
        return 0;
    }
    if (sector[0] != 0xEB && sector[0] != 0xE9) {
        return 0;
    }
    if (!memcmp(sector + 54, "FAT", 3)) {
        return 1;
    }
    if (!memcmp(sector + 82, "FAT", 3)) {
        return 1;
    }
    return 0;
}

static int p2_fs_dfs_read_retry(uint8_t unit, uint8_t *buffer, uint32_t sector, uint32_t count)
{
    int result = -1;
    int tries;

    for (tries = 0; tries < 2; ++tries) {
        result = (int)DFS_ReadSector(unit, buffer, sector, count);
        if (result == 0) {
            return 0;
        }
        _waitms(2);
    }
    return result;
}

static int p2_fs_mount_start(uint32_t start, berry_p2_fs_info *info)
{
    uint8_t *scratch = p2_mount_scratch_get();
    int result;

    if (!scratch) {
        return -1;
    }

    memset(scratch, 0, SECTOR_SIZE);
    result = p2_fs_dfs_read_retry(0, scratch, start, 1);
    if (result != 0) {
        return P2_FS_MOUNT_IO_ERROR;
    }
    if (p2_fs_sector_signature(scratch) != 0xAA55) {
        return -1;
    }
    if (!p2_fs_sector_looks_fat_boot(scratch)) {
        return -1;
    }

    result = (int)DFS_GetVolInfo(0, scratch, start, &__vi);
    if (info) {
        info->partition_start = (int)start;
        info->volinfo_result = result;
        if (result == DFS_OK) {
            info->filesystem_type = (int)__vi.filesystem;
        }
    }
    if (result != DFS_OK) {
        return -1;
    }

    __pstart = start;
    p2_fs_mounted = 1;
    if (info) {
        info->mount_result = 0;
#if BE_P2_ENABLE_SD_DIAGNOSTICS
        p2_fs_info_capture_volinfo(info);
#endif
    }
    return 0;
}

static int p2_fs_mount_mbr(berry_p2_fs_info *info)
{
    uint8_t *scratch = p2_mount_scratch_get();
    int result;
    int i;
    int best = -1;
    uint32_t best_start = 0;
    uint32_t best_size = 0;
    uint8_t best_type = 0;
    uint8_t best_active = 0;

    if (!scratch) {
        return -1;
    }

    memset(scratch, 0, SECTOR_SIZE);
    result = p2_fs_dfs_read_retry(0, scratch, 0u, 1);
    if (info) {
        info->dfs_sector0_result = result;
    }
    if (result != 0) {
        return P2_FS_MOUNT_IO_ERROR;
    }
    if (p2_fs_sector_signature(scratch) != 0xAA55) {
        return -1;
    }

    /*
     * If sector 0 is a superfloppy FAT boot sector, use it directly.  If it is
     * an MBR, prefer the active FAT partition, otherwise the first FAT
     * partition.  This keeps freshly reformatted cards from accidentally
     * mounting a stale old FAT boot sector at a common offset like 2048.
     */
    if (p2_fs_sector_looks_fat_boot(scratch)) {
        if (info) {
            info->partition_type = 0;
            info->partition_active = 0;
            info->partition_start = 0;
            info->partition_size = -1;
        }
        return p2_fs_mount_start(0u, info);
    }

    for (i = 0; i < 4; ++i) {
        const uint8_t *entry = scratch + 446 + (i * 16);
        uint8_t active = entry[0];
        uint8_t type = entry[4];
        uint32_t start = p2_fs_le32(entry + 8);
        uint32_t size = p2_fs_le32(entry + 12);

        if (!p2_fs_partition_type_is_fat(type) || start == 0 || size == 0) {
            continue;
        }
        if (best < 0 || active == 0x80) {
            best = i;
            best_start = start;
            best_size = size;
            best_type = type;
            best_active = active;
            if (active == 0x80) {
                break;
            }
        }
    }

    if (best < 0) {
        return -1;
    }
    if (info) {
        info->partition_type = (int)best_type;
        info->partition_active = (int)best_active;
        info->partition_start = (int)best_start;
        info->partition_size = (int)best_size;
    }
    return p2_fs_mount_start(best_start, info);
}

static int p2_fs_mount_fallback(berry_p2_fs_info *info)
{
    static const uint32_t candidates[] = {
        0u,
        1u,
        32u,
        63u,
        128u,
        256u,
        512u,
        1024u,
        2048u,
        4096u,
        8192u,
        16384u,
        32768u,
        65536u
    };
    size_t i;

    for (i = 0; i < sizeof(candidates) / sizeof(candidates[0]); ++i) {
        if (p2_fs_mount_start(candidates[i], info) == 0) {
            return 0;
        }
    }

    __pstart = (uint32_t)-1;
    if (info) {
        info->mount_result = -1;
    }
    return -1;
}

static int p2_fs_mount_core(berry_p2_fs_info *info)
{
    if (p2_fs_mounted) {
        if (info) {
            info->mount_result = 0;
            info->filesystem_type = (int)__vi.filesystem;
#if BE_P2_ENABLE_SD_DIAGNOSTICS
            p2_fs_info_capture_volinfo(info);
#endif
        }
        return 0;
    }

    if (!p2_sd_bus_prepared) {
#if defined(__BERRY_P2_DIRECT_SD_IO)
        p2_sd_bus_prepared = 1;
#else
        p2_release_sd_bus_from_current_cog();
        p2_sd_bus_prepared = 1;
#endif
    }
    if (!p2_sd_initialized && p2_fs_init_sd() != 0) {
        if (info) {
            info->mount_result = -1;
        }
        return -1;
    }

    {
        int mbr_result = p2_fs_mount_mbr(info);
        if (mbr_result == 0) {
            return 0;
        }
        if (mbr_result == P2_FS_MOUNT_IO_ERROR) {
            if (info) {
                info->mount_result = -1;
            }
            return -1;
        }
    }

    if (info) {
        p2_fs_trace("fallback begin");
    }
    return p2_fs_mount_fallback(info);
}

static int p2_fs_mount_retry(berry_p2_fs_info *info)
{
    int result = -1;
    int tries;

    for (tries = 0; tries < 2; ++tries) {
        result = p2_fs_mount_core(info);
        if (result == 0) {
            return 0;
        }
        p2_fs_mounted = 0;
        __pstart = (uint32_t)-1;
        p2_sd_initialized = 0;
#if defined(__BERRY_P2_DIRECT_SD_IO)
        p2_sd_bus_prepared = 0;
#endif
        _waitms(50);
    }

    if (info) {
        info->mount_result = result;
    }
    return result;
}

static int p2_fs_ensure_mounted(void)
{
    if (!p2_fs_mounted) {
        /*
         * Keep the mount path off the already tight C stack. Catalina's _mount()
         * allocates another sector buffer; doing the same work with a static
         * scratch buffer avoids a silent overflow on the P2 Hub image.
         */
        if (p2_fs_mount_retry(NULL) != 0) {
            return -1;
        }
    }
    return 0;
}

void p2_fs_info(const char *path, int write_probe, berry_p2_fs_info *info)
{
    char fullpath[P2_FS_PATH_MAX];
    const char *probe_path = path && *path ? path : "/";
    FILEINFO fileinfo;
    DIRINFO dirinfo;
    DIRENT entry;
    uint8_t scratch[SECTOR_SIZE];
    uint32_t count;
    char readback[3];

    p2_fs_info_init(info);
    if (!info) {
        return;
    }
    info->available = 1;
    p2_fs_trace("begin");
    p2_decode_sd_service(info);
    p2_fs_trace("service decoded");
    info->fil_cog = _locate_plugin(LMM_FIL);
    p2_fs_trace("file plugin located");
    if (info->fil_cog >= 0) {
        info->fil_registered_type = (int)REGISTERED_TYPE(info->fil_cog);
    }

    if (write_probe && (!path || !*path || !strcmp(path, "/"))) {
        probe_path = "/P2FSPROB.TXT";
    }

    if (!p2_fs_mounted) {
        p2_fs_trace("mount retry begin");
        info->mount_result = p2_fs_mount_retry(info);
        p2_decode_sd_service(info);
        p2_fs_trace("mount retry done");
        if (info->mount_result == 0) {
            info->mounted = 1;
        }
    } else {
        info->sd_init_result = 0;
        info->mount_result = 0;
        info->filesystem_type = (int)__vi.filesystem;
    }
    info->mounted = p2_fs_mounted ? 1 : 0;
    if (info->mount_result != 0) {
        p2_fs_trace("mount failed");
        return;
    }

    p2_fs_trace("root open begin");
    memset(&dirinfo, 0, sizeof(dirinfo));
    dirinfo.scratch = scratch;
    info->root_open_result = (int)DFS_OpenDir(&__vi, (uint8_t *)"", &dirinfo);
    p2_fs_trace("root open done");
    if (info->root_open_result == DFS_OK) {
        int scanned = 0;
        p2_fs_trace("root scan begin");
        uint32_t result = DFS_GetNext(&__vi, &dirinfo, &entry);
        info->root_first_result = (int)result;
        while (result == DFS_OK && scanned < 64) {
            uint8_t first = (uint8_t)entry.name[0];
#if BE_P2_ENABLE_SD_DIAGNOSTICS
            if (scanned == 0) {
                info->root_first_byte = (int)first;
                info->root_first_attr = (int)entry.attr;
                p2_fs_info_copy_raw_dir_name(info->root_first_name, sizeof(info->root_first_name), &entry);
            }
            p2_fs_info_append_root_sample(info, &entry, scanned);
            if (first == 0) {
                ++info->root_zero_entry_count;
            }
            if (first == 0xE5) {
                ++info->root_deleted_entry_count;
            }
            if ((entry.attr & ATTR_LONG_NAME) == ATTR_LONG_NAME) {
                ++info->root_lfn_entry_count;
            }
            if (entry.attr & ATTR_HIDDEN) {
                ++info->root_hidden_entry_count;
            }
#endif
            if (first != 0 && first != 0xE5
                && (entry.attr & (ATTR_VOLUME_ID | ATTR_HIDDEN | 0xC0)) == 0) {
                ++info->root_entry_count;
            }
            result = DFS_GetNext(&__vi, &dirinfo, &entry);
            ++scanned;
        }
        p2_fs_trace("root scan done");
    }

    p2_fs_trace("resolve begin");
    info->resolve_result = p2_resolve_path(probe_path, fullpath, sizeof(fullpath));
    p2_fs_trace("resolve done");
    if (info->resolve_result != 0) {
        return;
    }
    strncpy(info->path, fullpath, sizeof(info->path) - 1u);
    strncpy(info->fs_path, p2_catalina_fs_path(fullpath), sizeof(info->fs_path) - 1u);

    p2_fs_trace("path read begin");
    info->path_read_result = (int)DFS_OpenFile(&__vi,
        (uint8_t *)info->fs_path, DFS_READ, scratch, &fileinfo);
    p2_fs_trace("path read done");

    p2_fs_trace("path dir begin");
    memset(&dirinfo, 0, sizeof(dirinfo));
    dirinfo.scratch = scratch;
    info->path_dir_result = (int)DFS_OpenDir(&__vi, (uint8_t *)info->fs_path, &dirinfo);
    p2_fs_trace("path dir done");

    if (!write_probe) {
        p2_fs_trace("done");
        return;
    }

    p2_fs_trace("create file begin");
    info->create_file_result = (int)DFS_OpenFile(&__vi,
        (uint8_t *)info->fs_path, DFS_WRITE, scratch, &fileinfo);
    p2_fs_trace("create file done");
    if (info->create_file_result != DFS_OK) {
        return;
    }

    count = 0;
    p2_fs_trace("write file begin");
    info->write_file_result = (int)DFS_WriteFile(&fileinfo, scratch,
        (uint8_t *)"ok", &count, 2);
    p2_fs_trace("write file done");
    info->write_count = (int)count;

    count = 0;
    memset(readback, 0, sizeof(readback));
    p2_fs_trace("readback open begin");
    info->read_file_result = (int)DFS_OpenFile(&__vi,
        (uint8_t *)info->fs_path, DFS_READ, scratch, &fileinfo);
    p2_fs_trace("readback open done");
    if (info->read_file_result == DFS_OK) {
        p2_fs_trace("readback read begin");
        info->read_file_result = (int)DFS_ReadFile(&fileinfo, scratch,
            (uint8_t *)readback, &count, 2);
        p2_fs_trace("readback read done");
        info->read_count = (int)count;
        strncpy(info->read_value, readback, sizeof(info->read_value) - 1u);
    }
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

#if !defined(__CATALINA__)
void p2_fs_info(const char *path, int write_probe, berry_p2_fs_info *info)
{
    (void)path;
    (void)write_probe;
    if (!info) {
        return;
    }
    memset(info, 0, sizeof(*info));
    info->mount_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->resolve_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->root_open_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->root_first_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->path_read_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->path_dir_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->create_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->write_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->read_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    info->unlink_file_result = BERRY_P2_FS_RESULT_NOT_RUN;
    strncpy(info->cwd, "/", sizeof(info->cwd) - 1u);
    strncpy(info->path, path && *path ? path : "/", sizeof(info->path) - 1u);
}
#endif

enum {
    BERRY_P2_BAUD = 115200,
    BERRY_P2_RX_PIN = 63,
    BERRY_P2_TX_PIN = 62
};

static int p2_exit_requested;
static int p2_swallow_newline;
static int p2_prompt_needs_cr;
static int p2_main_cog = -1;
static char p2_readline_history[3][256];
static int p2_readline_history_count;
static int p2_readline_history_next;

void p2_serial_init(void)
{
    p2_main_cog = _cogid();
    p2_smartserial_init(BERRY_P2_RX_PIN, BERRY_P2_TX_PIN, BERRY_P2_BAUD);
#if !defined(__CATALINA__)
    _waitms(100);
#endif
}

static int p2_is_main_cog(void)
{
    return p2_main_cog < 0 || _cogid() == p2_main_cog;
}

static int p2_interrupt_key_pressed(void)
{
    int ch;

    if (!p2_is_main_cog()) {
        return 0;
    }
    ch = p2_smartserial_rxcheck();
    return ch == 3 || ch == 4;
}

void p2_check_interrupt_now(bvm *vm)
{
    if (p2_interrupt_key_pressed()) {
        be_raise(vm, "keyboard_interrupt", "interrupted");
    }
}

void p2_check_interrupt(bvm *vm)
{
    static unsigned int poll_tick;

    if ((++poll_tick & 0x3ffu) == 0) {
        p2_check_interrupt_now(vm);
    }
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
        p2_prompt_needs_cr = 1;
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

static void serial_repaint_line(const char *prompt, const char *buffer, int pos, int cursor)
{
    int back = pos - cursor;

    serial_write_char('\r');
    if (prompt) {
        p2_serial_puts(prompt);
    }
    p2_serial_puts(buffer);
    p2_serial_puts("\033[K");
    while (back-- > 0) {
        p2_serial_puts("\033[D");
    }
}

static void serial_set_line(char *buffer, size_t size, int *pos, int *cursor, const char *text)
{
    size_t len = strlen(text);

    if (len >= size) {
        len = size - 1u;
    }
    memcpy(buffer, text, len);
    buffer[len] = '\0';
    *pos = (int)len;
    *cursor = (int)len;
}

static const char *serial_history_at_age(int age)
{
    int index = p2_readline_history_next - 1 - age;

    while (index < 0) {
        index += 3;
    }
    return p2_readline_history[index % 3];
}

static void serial_history_add(const char *line)
{
    if (!line || !*line) {
        return;
    }
    if (p2_readline_history_count > 0 && !strcmp(serial_history_at_age(0), line)) {
        return;
    }

    strncpy(p2_readline_history[p2_readline_history_next], line,
        sizeof(p2_readline_history[p2_readline_history_next]) - 1u);
    p2_readline_history[p2_readline_history_next]
        [sizeof(p2_readline_history[p2_readline_history_next]) - 1u] = '\0';
    p2_readline_history_next = (p2_readline_history_next + 1) % 3;
    if (p2_readline_history_count < 3) {
        ++p2_readline_history_count;
    }
}

static int serial_read_escape_key(void)
{
    int ch = p2_smartserial_rx();

    if (ch != '[' && ch != 'O') {
        return 0;
    }
    ch = p2_smartserial_rx();
    if (ch >= '0' && ch <= '9') {
        int suffix = p2_smartserial_rx();
        if (ch == '3' && suffix == '~') {
            return 'D' + 256;
        }
        return 0;
    }
    switch (ch) {
    case 'A':
        return 'U' + 256;
    case 'B':
        return 'N' + 256;
    case 'C':
        return 'R' + 256;
    case 'D':
        return 'L' + 256;
    case 'H':
        return 'H' + 256;
    case 'F':
        return 'E' + 256;
    default:
        return 0;
    }
}

static void p2_repl_idle_hook(int idle)
{
#if BE_P2_PROFILE != BE_P2_PROFILE_MINIMAL
    p2_closure_cog_repl_idle(idle);
#else
    (void)idle;
#endif
}

static char *serial_readline(char *buffer, size_t size, const char *prompt)
{
    int pos = 0;
    int cursor = 0;
    int limit = (int)size;
    const int echo_input = 1;
    int history_age = -1;
    int repl_vm_reclaimed = 0;
    char draft[256];

    if (!buffer || limit <= 0) {
        return NULL;
    }
    buffer[0] = '\0';
    draft[0] = '\0';

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

        if (prompt != NULL && !repl_vm_reclaimed) {
            p2_repl_idle_hook(0);
            repl_vm_reclaimed = 1;
        }

        if (ch == 27) {
            int key = serial_read_escape_key();

            switch (key) {
            case 'U' + 256:
                if (p2_readline_history_count > 0 && history_age < p2_readline_history_count - 1) {
                    if (history_age < 0) {
                        strncpy(draft, buffer, sizeof(draft) - 1u);
                        draft[sizeof(draft) - 1u] = '\0';
                    }
                    ++history_age;
                    serial_set_line(buffer, size, &pos, &cursor, serial_history_at_age(history_age));
                    serial_repaint_line(prompt, buffer, pos, cursor);
                }
                break;
            case 'N' + 256:
                if (history_age > 0) {
                    --history_age;
                    serial_set_line(buffer, size, &pos, &cursor, serial_history_at_age(history_age));
                    serial_repaint_line(prompt, buffer, pos, cursor);
                } else if (history_age == 0) {
                    history_age = -1;
                    serial_set_line(buffer, size, &pos, &cursor, draft);
                    serial_repaint_line(prompt, buffer, pos, cursor);
                }
                break;
            case 'L' + 256:
                if (cursor > 0) {
                    --cursor;
                    p2_serial_puts("\033[D");
                }
                break;
            case 'R' + 256:
                if (cursor < pos) {
                    ++cursor;
                    p2_serial_puts("\033[C");
                }
                break;
            case 'H' + 256:
                cursor = 0;
                serial_repaint_line(prompt, buffer, pos, cursor);
                break;
            case 'E' + 256:
                cursor = pos;
                serial_repaint_line(prompt, buffer, pos, cursor);
                break;
            case 'D' + 256:
                if (cursor < pos) {
                    memmove(buffer + cursor, buffer + cursor + 1, (size_t)(pos - cursor));
                    --pos;
                    serial_repaint_line(prompt, buffer, pos, cursor);
                }
                break;
            default:
                break;
            }
            continue;
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

        if ((ch == '\b' || ch == 127) && cursor > 0) {
            memmove(buffer + cursor - 1, buffer + cursor, (size_t)(pos - cursor + 1));
            pos--;
            cursor--;
            serial_repaint_line(prompt, buffer, pos, cursor);
            continue;
        }

        if (ch < 32 || ch > 126) {
            continue;
        }

        if (pos + 1 >= limit) {
            break;
        }

        if (cursor == pos) {
            buffer[pos++] = (char)ch;
            buffer[pos] = '\0';
            cursor = pos;
        } else {
            memmove(buffer + cursor + 1, buffer + cursor, (size_t)(pos - cursor + 1));
            buffer[cursor++] = (char)ch;
            ++pos;
        }
        if (echo_input && cursor == pos) {
            serial_write_char(ch);
        } else if (echo_input) {
            serial_repaint_line(prompt, buffer, pos, cursor);
        }
    }

    buffer[pos] = '\0';
    serial_history_add(buffer);
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
    return serial_readline(buffer, size, NULL);
}

char *p2_readline(const char *prompt)
{
    static char line[256];
    char *result;

    if (p2_prompt_needs_cr) {
        p2_smartserial_tx('\r');
        p2_prompt_needs_cr = 0;
    }
    p2_serial_puts(map_prompt(prompt));
    p2_repl_idle_hook(1);
    result = serial_readline(line, sizeof(line), map_prompt(prompt));
    p2_repl_idle_hook(0);
    return result;
}

void p2_freeline(char *line)
{
    (void)line;
}

void p2_clear_exit_request(void)
{
    p2_exit_requested = 0;
}

void p2_request_exit(void)
{
    p2_exit_requested = 1;
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

    p2_fs_trace("fopen begin");
    if (p2_fs_ensure_mounted() != 0
        || p2_resolve_path(filename, path, sizeof(path)) != 0
        || p2_open_mode(modes, &mode, &truncate_existing, &append) != 0) {
        p2_fs_trace("fopen preflight failed");
        return NULL;
    }
    fs_path = p2_catalina_fs_path(path);
    allow_write = p2_mode_allows_write(modes);

    handle = p2_file_alloc();
    if (!handle) {
        p2_fs_trace("fopen alloc failed");
        return NULL;
    }
    if (truncate_existing) {
        p2_fs_trace("fopen truncate lookup begin");
        if (DFS_OpenFile(&__vi, (uint8_t *)fs_path, DFS_READ, handle->scratch, &handle->info) == DFS_OK) {
            p2_fs_trace("fopen truncate unlink begin");
            DFS_UnlinkFile(&__vi, (uint8_t *)fs_path, handle->scratch);
            p2_fs_trace("fopen truncate unlink done");
        }
        p2_fs_trace("fopen truncate lookup done");
    }
    p2_fs_trace("fopen dfs open begin");
    if (p2_open_fileinfo(fs_path, mode, handle->scratch, &handle->info) != 0) {
        p2_fs_trace("fopen dfs open failed");
        if (allow_write && DFS_OpenFile(&__vi, (uint8_t *)fs_path, DFS_READ, handle->scratch, &handle->info) == DFS_OK) {
            /* accept the create as successful and reuse the handle */
            p2_fs_trace("fopen fallback read accepted");
        } else {
            p2_file_free(handle);
            p2_fs_trace("fopen failed");
            return NULL;
        }
    }
    p2_fs_trace("fopen dfs open done");
    if (append) {
        p2_fs_trace("fopen append seek begin");
        DFS_Seek(&handle->info, handle->info.filelen, handle->scratch);
        p2_fs_trace("fopen append seek done");
    } else if (truncate_existing && allow_write && handle->info.filelen > 0) {
        /*
         * If Catalina reported a false failure after recreating the file,
         * re-opening read-only can leave the old size cached in the handle.
         * Force the logical position back to the start for Berry semantics.
         */
        p2_fs_trace("fopen truncate seek begin");
        DFS_Seek(&handle->info, 0, handle->scratch);
        p2_fs_trace("fopen truncate seek done");
    }
    p2_fs_trace("fopen done");
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
    p2_file_free(handle);
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
    dir = p2_dir_alloc();
    if (!dir) {
        return -1;
    }
    dir->di.scratch = dir->scratch;
    if (DFS_OpenDir(&__vi, (uint8_t *)p2_catalina_fs_path(fullpath), &dir->di) != DFS_OK) {
        p2_dir_free(dir);
        return -1;
    }
    if (p2_dir_load_next(dir) != 0) {
        p2_dir_free(dir);
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
        p2_dir_free((p2_dir_handle *)info->dir);
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

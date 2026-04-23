/*
# * Destructive Catalina DOSFS probe for the P2 Edge path.
# *
# * This helper intentionally creates, renames, and deletes files/directories
# * on the mounted SD card while exercising Catalina's low-level filesystem
# * APIs. Do not run it against media you want to keep pristine.
# */
#include <stdio.h>
#include <fs.h>
#include <dirent.h>
#include <string.h>

extern VOLINFO __vi;
extern uint32_t DFS_GetFreeDirEnt(PVOLINFO volinfo, uint8_t *path, PDIRINFO di, PDIRENT de);
extern uint32_t DFS_GetFreeFAT(PVOLINFO volinfo, uint8_t *scratch);
extern uint32_t DFS_GetFAT(PVOLINFO volinfo, uint8_t *scratch, uint32_t *scratchcache, uint32_t cluster);

static void list_root(void)
{
    DIR *dir;
    struct dirent *entry;

    dir = opendir("");
    if (!dir) {
        printf("opendir root failed\n");
        return;
    }
    printf("root:");
    while ((entry = readdir(dir)) != NULL) {
        printf(" %s", entry->d_name);
    }
    printf("\n");
    closedir(dir);
}

static void dump_dir(const char *path)
{
    DIRINFO di;
    DIRENT de;
    uint8_t scratch[SECTOR_SIZE];
    uint32_t result;
    int index = 0;

    memset(&di, 0, sizeof(di));
    memset(&de, 0, sizeof(de));
    memset(scratch, 0, sizeof(scratch));
    di.scratch = scratch;
    result = DFS_OpenDir(&__vi, (uint8_t *)path, &di);
    printf("open dir '%s'=%lu cluster=%lu sector=%lu entry=%d\n",
        path,
        (unsigned long)result,
        (unsigned long)di.currentcluster,
        (unsigned long)di.currentsector,
        di.currententry);
    if (result != DFS_OK) {
        return;
    }
    while (index < 8 && DFS_GetNext(&__vi, &di, &de) == DFS_OK) {
        printf("  entry[%d] name0=%02X attr=%02X name='%.11s'\n",
            index,
            de.name[0],
            de.attr,
            de.name);
        index++;
    }
}

int main(void)
{
    FILE *fp;
    FILEINFO info;
    DIRINFO di;
    DIRENT de;
    uint8_t scratch[SECTOR_SIZE];
    uint32_t dfs_result;
    int fd;
    char buffer[64];
    int result;

    printf("mount=%d\n", _mount(0, 0));
    printf("fs=%lu secperclus=%lu dataarea=%lu rootdir=%lu numclusters=%lu\n",
        (unsigned long)__vi.filesystem,
        (unsigned long)__vi.secperclus,
        (unsigned long)__vi.dataarea,
        (unsigned long)__vi.rootdir,
        (unsigned long)__vi.numclusters);
    list_root();
    dump_dir("");
    dump_dir("TMPDIR");

    result = _mkdir("TMP4", 0);
    printf("mkdir TMP4=%d\n", result);
    result = _create_directory("TMP5");
    printf("create_directory TMP5=%d\n", result);
    printf("open TMP4.TXT for write...\n");
    fp = fopen("TMP4.TXT", "w");
    printf("fopen=%p\n", (void *)fp);
    if (fp) {
        int written = fwrite("abc", 1, 3, fp);
        printf("fwrite=%d\n", written);
        fclose(fp);
    }

    fp = fopen("TMP4.TXT", "r");
    printf("reopen=%p\n", (void *)fp);
    if (fp) {
        memset(buffer, 0, sizeof(buffer));
        fread(buffer, 1, sizeof(buffer) - 1, fp);
        fclose(fp);
        printf("read='%s'\n", buffer);
    }

    memset(&info, 0, sizeof(info));
    printf("open unmanaged TMP6.TXT for write...\n");
    fd = _open_unmanaged("TMP6.TXT", 1, &info);
    printf("open_unmanaged=%d\n", fd);
    if (fd != -1) {
        int written = _write(fd, "xyz", 3);
        printf("write_unmanaged=%d\n", written);
        _close_unmanaged(fd);
    }

    memset(&info, 0, sizeof(info));
    fd = _open_unmanaged("TMP6.TXT", 0, &info);
    printf("reopen_unmanaged=%d\n", fd);
    if (fd != -1) {
        memset(buffer, 0, sizeof(buffer));
        result = _read(fd, buffer, sizeof(buffer) - 1);
        printf("read_unmanaged=%d '%s'\n", result, buffer);
        _close_unmanaged(fd);
    }

    memset(&info, 0, sizeof(info));
    memset(scratch, 0, sizeof(scratch));
    dfs_result = DFS_OpenFile(&__vi, (uint8_t *)"TMP7.TXT", DFS_WRITE, scratch, &info);
    printf("DFS_OpenFile TMP7.TXT WRITE=%lu\n", (unsigned long)dfs_result);

    memset(&info, 0, sizeof(info));
    memset(scratch, 0, sizeof(scratch));
    dfs_result = DFS_OpenFile(&__vi, (uint8_t *)"TMP8", DFS_CREATEDIR, scratch, &info);
    printf("DFS_OpenFile TMP8 CREATEDIR=%lu\n", (unsigned long)dfs_result);

    memset(&info, 0, sizeof(info));
    memset(scratch, 0, sizeof(scratch));
    dfs_result = DFS_OpenFile(&__vi, (uint8_t *)"TMPDIR/NEW2.TXT", DFS_WRITE, scratch, &info);
    printf("DFS_OpenFile TMPDIR/NEW2.TXT WRITE=%lu\n", (unsigned long)dfs_result);

    memset(&info, 0, sizeof(info));
    memset(scratch, 0, sizeof(scratch));
    dfs_result = DFS_OpenFile(&__vi, (uint8_t *)"TMPDIR/NEW3", DFS_CREATEDIR, scratch, &info);
    printf("DFS_OpenFile TMPDIR/NEW3 CREATEDIR=%lu\n", (unsigned long)dfs_result);

    memset(&di, 0, sizeof(di));
    memset(&de, 0, sizeof(de));
    memset(scratch, 0, sizeof(scratch));
    di.scratch = scratch;
    dfs_result = DFS_GetFreeDirEnt(&__vi, (uint8_t *)"", &di, &de);
    printf("DFS_GetFreeDirEnt root=%lu entry=%d sector=%lu cluster=%lu\n",
        (unsigned long)dfs_result,
        di.currententry,
        (unsigned long)di.currentsector,
        (unsigned long)di.currentcluster);

    memset(&di, 0, sizeof(di));
    memset(&de, 0, sizeof(de));
    memset(scratch, 0, sizeof(scratch));
    di.scratch = scratch;
    dfs_result = DFS_GetFreeDirEnt(&__vi, (uint8_t *)"TMPDIR", &di, &de);
    printf("DFS_GetFreeDirEnt TMPDIR=%lu entry=%d sector=%lu cluster=%lu\n",
        (unsigned long)dfs_result,
        di.currententry,
        (unsigned long)di.currentsector,
        (unsigned long)di.currentcluster);

    memset(scratch, 0, sizeof(scratch));
    dfs_result = DFS_GetFreeFAT(&__vi, scratch);
    printf("DFS_GetFreeFAT=%lu\n", (unsigned long)dfs_result);
    {
        uint32_t fat_cache = 0;
        memset(scratch, 0, sizeof(scratch));
        printf("FAT[2]=%lu FAT[6]=%lu\n",
            (unsigned long)DFS_GetFAT(&__vi, scratch, &fat_cache, 2),
            (unsigned long)DFS_GetFAT(&__vi, scratch, &fat_cache, 6));
    }
    {
        uint32_t sector = __vi.dataarea + ((6 - 2) * __vi.secperclus);
        memset(scratch, 0x00, sizeof(scratch));
        dfs_result = DFS_WriteSector(__vi.unit, scratch, sector, 1);
        printf("DFS_WriteSector cluster6 sector%lu=%lu\n",
            (unsigned long)sector,
            (unsigned long)dfs_result);
        memset(scratch, 0, sizeof(scratch));
        dfs_result = DFS_ReadSector(__vi.unit, scratch, sector, 1);
        printf("DFS_ReadSector cluster6 sector%lu=%lu first=%02X\n",
            (unsigned long)sector,
            (unsigned long)dfs_result,
            scratch[0]);
    }

    result = _rename("HELLO.TXT", "HELLO2.TXT");
    printf("rename HELLO.TXT->HELLO2.TXT=%d\n", result);
    if (result == 0) {
        result = _rename("HELLO2.TXT", "HELLO.TXT");
        printf("rename HELLO2.TXT->HELLO.TXT=%d\n", result);
    }

    result = _unlink("BERRYTMP");
    printf("unlink BERRYTMP=%d\n", result);

    list_root();
    return 0;
}

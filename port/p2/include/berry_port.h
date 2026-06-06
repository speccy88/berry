#ifndef BERRY_PORT_P2_H
#define BERRY_PORT_P2_H

#include "berry.h"

#define BERRY_P2_FS_TEXT_MAX 256
#define BERRY_P2_FS_RESULT_NOT_RUN -9999
#define BERRY_P2_FS_RESULT_SD_TIMEOUT 0x101
#define BERRY_P2_FS_RESULT_SD_BUSY 0x102
#define BERRY_P2_FS_RESULT_SD_NO_SERVICE 0x103

typedef struct berry_p2_fs_info {
    int available;
    int mounted;
    int sd_init_result;
    int raw_sector0_result;
    int dfs_sector0_result;
    int sd_service_entry;
    int sd_service_cog;
    int sd_service_lock;
    int sd_service_code;
    int sd_request;
    int sd_response;
    int fil_cog;
    int fil_registered_type;
    int sector0_signature;
    int sector0_byte0;
    int sector0_byte1;
    int sector0_byte2;
    int sector0_byte3;
    int sector0_sig0;
    int sector0_sig1;
    int partition_type;
    int partition_active;
    int partition_start;
    int partition_size;
    int volinfo_result;
    int filesystem_type;
    int mount_result;
    int resolve_result;
    int root_open_result;
    int root_first_result;
    int root_entry_count;
    int path_read_result;
    int path_dir_result;
    int create_file_result;
    int write_file_result;
    int write_count;
    int read_file_result;
    int read_count;
    int unlink_file_result;
    char cwd[BERRY_P2_FS_TEXT_MAX];
    char path[BERRY_P2_FS_TEXT_MAX];
    char fs_path[BERRY_P2_FS_TEXT_MAX];
    char read_value[8];
} berry_p2_fs_info;

void p2_serial_init(void);
void p2_serial_puts(const char *s);
char *p2_readline(const char *prompt);
void p2_freeline(char *line);
void p2_clear_exit_request(void);
int p2_take_exit_request(void);
void p2_check_interrupt(bvm *vm);
void p2_check_interrupt_now(bvm *vm);
void p2_fs_info(const char *path, int write_probe, berry_p2_fs_info *info);

#endif

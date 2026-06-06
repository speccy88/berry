#ifndef BERRY_PORT_P2_H
#define BERRY_PORT_P2_H

#include "berry.h"

#define BERRY_P2_FS_TEXT_MAX 256
#define BERRY_P2_FS_RESULT_NOT_RUN -9999

typedef struct berry_p2_fs_info {
    int available;
    int mounted;
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

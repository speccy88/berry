#ifndef P2_HEAP_H
#define P2_HEAP_H

#include <stddef.h>

#ifndef BE_P2_HEAP_BYTES
#define BE_P2_HEAP_BYTES (8 * 1024)
#endif

#ifndef BE_P2_WORKER_HEAP_BYTES
#define BE_P2_WORKER_HEAP_BYTES (8 * 1024)
#endif

#ifndef BE_P2_VM_HEAP_PARTITION_BYTES
#define BE_P2_VM_HEAP_PARTITION_BYTES (2 * 1024 * 1024)
#endif

#ifndef BE_P2_VM_HEAP_MAX_PARTITIONS
#define BE_P2_VM_HEAP_MAX_PARTITIONS 4
#endif

void *p2_heap_malloc(size_t size);
void p2_heap_free(void *ptr);
void *p2_heap_realloc(void *ptr, size_t size);
size_t p2_heap_free_bytes(void);
size_t p2_heap_main_free_bytes(void);
size_t p2_heap_worker_free_bytes(void);
void p2_heap_set_worker_cog(int cog);
void *p2_heap_main_base(void);
size_t p2_heap_main_size(void);
size_t p2_heap_main_requested_size(void);
int p2_heap_main_segments(void);
size_t p2_heap_main_low_address(void);
size_t p2_heap_main_high_address(void);
int p2_heap_main_crosses_block_window(void);
int p2_heap_main_ready(void);
int p2_heap_main_alloc_failed(void);
size_t p2_heap_vm_partition_size(void);
int p2_heap_main_vm_partition_capacity(void);
int p2_heap_main_vm_partition_free_capacity(void);
size_t p2_heap_main_vm_partition_remainder(void);
size_t p2_heap_main_vm_partition_free_remainder(void);
int p2_heap_vm_partition_create(int slot, size_t bytes);
int p2_heap_vm_partition_release(int slot);
int p2_heap_vm_partition_select(int slot);
void p2_heap_vm_partition_clear_current(void);
int p2_heap_vm_partition_current(void);
size_t p2_heap_vm_partition_bytes(int slot);
size_t p2_heap_vm_partition_free_bytes(int slot);
int p2_heap_vm_partition_ready(int slot);
size_t p2_heap_vm_partition_low_address(int slot);
size_t p2_heap_vm_partition_high_address(int slot);
int p2_heap_vm_partition_created_count(void);
size_t p2_heap_vm_partition_total_bytes(void);
size_t p2_heap_wrong_free_count(void);
size_t p2_heap_wrong_realloc_count(void);
void *p2_heap_worker_base(void);
size_t p2_heap_worker_size(void);

#endif

#ifndef BERRY_P2_CONFIG_H
#define BERRY_P2_CONFIG_H

#define BE_P2_PROFILE_MINIMAL           1
#define BE_P2_PROFILE_FULL              2
#define BE_P2_PROFILE_XMM               3

#ifndef BE_P2_PROFILE
#define BE_P2_PROFILE                   BE_P2_PROFILE_FULL
#endif

#if BE_P2_PROFILE == BE_P2_PROFILE_MINIMAL
#define BE_P2_PROFILE_NAME              "minimal"

#define BE_USE_JSON                     0
#define BE_USE_MATH                     0
#define BE_USE_OS                       0
#define BE_USE_FILE                     0
#define BE_USE_INTROSPECT               0
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         0
#define BE_P2_USE_P2_MODULE             0
#define BE_P2_USE_I2C_MODULE            0
#define BE_P2_USE_SPI_MODULE            0
#define BE_P2_USE_THREADS_MODULE        0
#define BE_P2_USE_SPIN2_MODULE          0
#define BE_P2_USE_WORKER_MODULE         0
#define BE_P2_USE_XMM_PLACEHOLDER       0

#define BE_P2_HEAP_SIZE                 (192 * 1024)
#define BE_P2_WORKER_HEAP_SIZE          (4 * 1024)
#define BE_P2_STACK_SLOTS               512
#define BE_P2_BYTES_MAX                 2048

#elif BE_P2_PROFILE == BE_P2_PROFILE_XMM
#define BE_P2_PROFILE_NAME              "xmm"

#define BE_USE_JSON                     1
#define BE_USE_MATH                     1
#define BE_USE_OS                       1
#define BE_USE_FILE                     1
#define BE_USE_INTROSPECT               0
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         1
#define BE_P2_USE_P2_MODULE             1
#define BE_P2_USE_I2C_MODULE            1
#define BE_P2_USE_SPI_MODULE            1
#define BE_P2_USE_THREADS_MODULE        1
#define BE_P2_USE_SPIN2_MODULE          1
#define BE_P2_USE_WORKER_MODULE         1
#define BE_P2_USE_XMM_PLACEHOLDER       1

#define BE_P2_HEAP_SIZE                 (128 * 1024)
#define BE_P2_WORKER_HEAP_SIZE          (32 * 1024)
#define BE_P2_STACK_SLOTS               1024
#define BE_P2_BYTES_MAX                 (4 * 1024)

#elif BE_P2_PROFILE == BE_P2_PROFILE_FULL
#define BE_P2_PROFILE_NAME              "full"

#define BE_USE_JSON                     1
#define BE_USE_MATH                     1
#define BE_USE_OS                       1
#define BE_USE_FILE                     1
#define BE_USE_INTROSPECT               0
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         1
#define BE_P2_USE_P2_MODULE             1
#define BE_P2_USE_I2C_MODULE            1
#define BE_P2_USE_SPI_MODULE            1
#define BE_P2_USE_THREADS_MODULE        1
#define BE_P2_USE_SPIN2_MODULE          1
#define BE_P2_USE_WORKER_MODULE         1
#define BE_P2_USE_XMM_PLACEHOLDER       0

#define BE_P2_HEAP_SIZE                 (128 * 1024)
#define BE_P2_WORKER_HEAP_SIZE          (32 * 1024)
#define BE_P2_STACK_SLOTS               1024
#define BE_P2_BYTES_MAX                 (4 * 1024)

#else
#error Unsupported BE_P2_PROFILE
#endif

#endif

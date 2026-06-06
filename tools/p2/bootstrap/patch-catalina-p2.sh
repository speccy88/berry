#!/usr/bin/env bash
set -euo pipefail

CATALINA_DIR="${1:?usage: $0 <catalina-dir> [platform] [model] [clib]}"
CATALINA_PLATFORM="${2:-P2_EDGE}"
CATALINA_MODEL="${3:-COMPACT}"
CATALINA_CLIB="${4:-cix}"
PATCH_VERSION="berry-p2-patch-v24"
CATALINA_DIR="$(cd "${CATALINA_DIR}" && pwd -P)"
STAMP_FILE="${CATALINA_DIR}/.${PATCH_VERSION}-${CATALINA_CLIB}-${CATALINA_MODEL}"

if [ -f "${STAMP_FILE}" ]; then
    exit 0
fi

python3 - "${CATALINA_DIR}" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

def replace_one(path_str, old, new):
    path = root / path_str
    text = path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"patch pattern not found in {path}")
    path.write_text(text.replace(old, new))

replace_one(
    "source/lib/io/dwrite.c",
    "         if (result = sectwrite((char *)buffer, sector) == 0) {\n",
    "         if ((result = sectwrite((char *)buffer, sector)) == 0) {\n",
)

replace_one(
    "source/lib/io/dread.c",
    "#if defined(__CATALINA_PSRAM) || defined(__CATALINA_HYPER)\n",
    "#if (defined(__CATALINA_PSRAM) || defined(__CATALINA_HYPER)) && !defined(__BERRY_P2_DIRECT_SD_IO)\n",
)

replace_one(
    "source/lib/io/dwrite.c",
    "#if defined(__CATALINA_PSRAM) || defined(__CATALINA_HYPER)\n",
    "#if (defined(__CATALINA_PSRAM) || defined(__CATALINA_HYPER)) && !defined(__BERRY_P2_DIRECT_SD_IO)\n",
)

replace_one(
    "target/p2/plugsup.inc",
    "#if defined(libcx) || defined (libcix)\n#if !defined(SD)\n#define SD\n#endif\n#endif\n",
    "#if (defined(libcx) || defined (libcix)) && !defined(BERRY_P2_DIRECT_SD_IO)\n#if !defined(SD)\n#define SD\n#endif\n#endif\n",
)

replace_one(
    "source/lib/io/dread.c",
    "#define READ_RETRIES 10\n",
    "#if defined(__BERRY_P2_DIRECT_SD_IO)\n#define READ_RETRIES 1\n#else\n#define READ_RETRIES 10\n#endif\n",
)

replace_one(
    "source/lib/io/dwrite.c",
    "#define WRITE_RETRIES 10\n",
    "#if defined(__BERRY_P2_DIRECT_SD_IO)\n#define WRITE_RETRIES 1\n#else\n#define WRITE_RETRIES 10\n#endif\n",
)

replace_one(
    "source/lib/io/dgnext.c",
    """\t\telse {\n\t\t\tif (dirinfo->currentsector >= volinfo->secperclus) {\n\t\t\t\tdirinfo->currentsector = 0;\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((dirinfo->currentcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (dirinfo->currentcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (dirinfo->currentcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\n\t\t\t\t  \t// We are at the end of the directory chain. If this is a normal\n\t\t\t\t  \t// find operation, we should indicate that there is nothing more\n\t\t\t\t  \t// to see.\n\t\t\t\t  \tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\t\n\t\t\t\t\t// On the other hand, if this is a \"find free entry\" search,\n\t\t\t\t\t// we need to tell the caller to allocate a new cluster\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\t\t\t\tdirinfo->currentcluster = DFS_GetFAT(volinfo, dirinfo->scratch, &tempint, dirinfo->currentcluster);\n\t\t\t}\n\t\t\tif (DFS_ReadSector(volinfo->unit, dirinfo->scratch, volinfo->dataarea + ((dirinfo->currentcluster - 2) * volinfo->secperclus) + dirinfo->currentsector, 1))\n\t\t\t\treturn DFS_ERRMISC;\n\t\t}\n""",
    """\t\telse {\n\t\t\tif (dirinfo->currentsector >= volinfo->secperclus) {\n\t\t\t\tuint32_t nextcluster;\n\n\t\t\t\tdirinfo->currentsector = 0;\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((dirinfo->currentcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (dirinfo->currentcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (dirinfo->currentcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\n\t\t\t\t  \tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\n\t\t\t\tnextcluster = DFS_GetFAT(volinfo, dirinfo->scratch, &tempint, dirinfo->currentcluster);\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((nextcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (nextcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (nextcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\t\t\t\t\tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\t\t\t\tdirinfo->currentcluster = nextcluster;\n\t\t\t}\n\t\t\tif (DFS_ReadSector(volinfo->unit, dirinfo->scratch, volinfo->dataarea + ((dirinfo->currentcluster - 2) * volinfo->secperclus) + dirinfo->currentsector, 1))\n\t\t\t\treturn DFS_ERRMISC;\n\t\t}\n""",
)


secwrite = root / "source/lib/catalina/secwrite.c"
secwrite.write_text(
    """#include <plugin.h>
#include <prop2.h>
#include <sd.h>

#define BERRY_P2_SD_TIMEOUT_MS 3000
#define BERRY_P2_SD_SPIN_LIMIT 100000UL
#define BERRY_P2_FS_RESULT_SD_TIMEOUT 0x101
#define BERRY_P2_FS_RESULT_SD_BUSY 0x102
#define BERRY_P2_FS_RESULT_SD_NO_SERVICE 0x103

typedef struct berry_p2_sd_params {
   long par1;
   long par2;
} berry_p2_sd_params;

static volatile berry_p2_sd_params sd_params;
#if defined(__BERRY_P2_DIRECT_SD_IO)
static char sd_sector[__CATALINA_SECTOR_SIZE];

#define BERRY_P2_SD_DO 58
#define BERRY_P2_SD_DI 59
#define BERRY_P2_SD_CS 60
#define BERRY_P2_SD_CLK 61
#define BERRY_P2_FLASH_DO 58
#define BERRY_P2_FLASH_DI 59
#define BERRY_P2_FLASH_CLK 60
#define BERRY_P2_FLASH_CS 61
#define BERRY_P2_FLASH_RESET_ENABLE 0x66
#define BERRY_P2_FLASH_RESET_MEMORY 0x99
#define BERRY_P2_FLASH_DEEP_POWER_DOWN 0xb9

static int berry_p2_sd_ready;
static int berry_p2_sd_high_capacity;

static unsigned char berry_p2_transfer_pin(int do_pin, int di_pin, int clk_pin, unsigned char value) {
   unsigned char in = 0;
   int bit;

   for (bit = 0; bit < 8; bit++) {
      if (value & 0x80) {
         _pinh(di_pin);
      }
      else {
         _pinl(di_pin);
      }
      value <<= 1;
      _waitus(2);
      _pinh(clk_pin);
      _waitus(2);
      in = (unsigned char)((in << 1) | (_pinr(do_pin) ? 1 : 0));
      _pinl(clk_pin);
   }
   return in;
}

static unsigned char berry_p2_sd_transfer(unsigned char value) {
   return berry_p2_transfer_pin(BERRY_P2_SD_DO, BERRY_P2_SD_DI, BERRY_P2_SD_CLK, value);
}

static unsigned char berry_p2_flash_transfer(unsigned char value) {
   return berry_p2_transfer_pin(BERRY_P2_FLASH_DO, BERRY_P2_FLASH_DI, BERRY_P2_FLASH_CLK, value);
}

static void berry_p2_flash_command(unsigned char command) {
   _pinh(BERRY_P2_FLASH_CS);
   _pinl(BERRY_P2_FLASH_CLK);
   _pinl(BERRY_P2_FLASH_DI);
   _pinf(BERRY_P2_FLASH_DO);
   _waitus(2);
   _pinl(BERRY_P2_FLASH_CS);
   (void)berry_p2_flash_transfer(command);
   _pinh(BERRY_P2_FLASH_CS);
   _waitus(2);
}

static void berry_p2_flash_sleep(void) {
   berry_p2_flash_command(BERRY_P2_FLASH_RESET_ENABLE);
   berry_p2_flash_command(BERRY_P2_FLASH_RESET_MEMORY);
   _waitms(1);
   berry_p2_flash_command(BERRY_P2_FLASH_DEEP_POWER_DOWN);
   _waitus(10);
}

static void berry_p2_sd_deselect(void) {
   _pinh(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
}

static void berry_p2_sd_idle_clocks(void) {
   int i;

   berry_p2_flash_sleep();
   _pinh(BERRY_P2_SD_CS);
   _pinl(BERRY_P2_SD_CLK);
   _pinh(BERRY_P2_SD_DI);
   _pinf(BERRY_P2_SD_DO);
   _waitms(1);
   for (i = 0; i < 10; i++) {
      (void)berry_p2_sd_transfer(0xff);
   }
}

static unsigned char berry_p2_sd_command(
   unsigned char cmd,
   unsigned long arg,
   unsigned char crc,
   unsigned char *extra,
   int extra_len
) {
   unsigned char response = 0xff;
   int i;

   berry_p2_sd_deselect();
   _pinl(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer((unsigned char)(0x40 | cmd));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 24));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 16));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 8));
   (void)berry_p2_sd_transfer((unsigned char)arg);
   (void)berry_p2_sd_transfer(crc);

   for (i = 0; i < 16; i++) {
      response = berry_p2_sd_transfer(0xff);
      if ((response & 0x80) == 0) {
         break;
      }
   }
   for (i = 0; i < extra_len; i++) {
      extra[i] = berry_p2_sd_transfer(0xff);
   }
   berry_p2_sd_deselect();
   return response;
}

static int berry_p2_sd_init_direct(void) {
   unsigned char extra[4];
   unsigned char r;
   int tries;

   berry_p2_sd_ready = 0;
   berry_p2_sd_high_capacity = 0;
   berry_p2_sd_idle_clocks();

   r = berry_p2_sd_command(0, 0, 0x95, 0, 0);
   if (r != 0x01) {
      return -1;
   }

   r = berry_p2_sd_command(8, 0x1aa, 0x87, extra, 4);
   if (r != 0x01 || extra[2] != 0x01 || extra[3] != 0xaa) {
      return -1;
   }

   for (tries = 0; tries < 1000; tries++) {
      r = berry_p2_sd_command(55, 0, 0x01, 0, 0);
      if (r > 0x01) {
         return -1;
      }
      r = berry_p2_sd_command(41, 0x40000000, 0x01, 0, 0);
      if (r == 0x00) {
         break;
      }
      _waitms(1);
   }
   if (r != 0x00) {
      return -1;
   }

   r = berry_p2_sd_command(58, 0, 0x01, extra, 4);
   if (r != 0x00) {
      return -1;
   }
   berry_p2_sd_high_capacity = (extra[0] & 0x40) ? 1 : 0;

   r = berry_p2_sd_command(16, 512, 0x01, 0, 0);
   if (r != 0x00 && !berry_p2_sd_high_capacity) {
      return -1;
   }

   berry_p2_sd_ready = 1;
   return 0;
}

static int berry_p2_sd_write_direct(char *buffer, unsigned long sector) {
   unsigned long arg;
   unsigned char response = 0xff;
   int i;

   if (!berry_p2_sd_ready && berry_p2_sd_init_direct() != 0) {
      return -1;
   }

   arg = berry_p2_sd_high_capacity ? sector : (sector << 9);
   _pinl(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer(0x40 | 24);
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 24));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 16));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 8));
   (void)berry_p2_sd_transfer((unsigned char)arg);
   (void)berry_p2_sd_transfer(0x01);

   for (i = 0; i < 16; i++) {
      response = berry_p2_sd_transfer(0xff);
      if ((response & 0x80) == 0) {
         break;
      }
   }
   if (response != 0x00) {
      berry_p2_sd_deselect();
      berry_p2_sd_ready = 0;
      return -1;
   }

   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer(0xfe);
   for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
      (void)berry_p2_sd_transfer((unsigned char)buffer[i]);
   }
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer(0xff);

   response = berry_p2_sd_transfer(0xff);
   if ((response & 0x1f) != 0x05) {
      berry_p2_sd_deselect();
      berry_p2_sd_ready = 0;
      return -1;
   }
   for (i = 0; i < 200000; i++) {
      if (berry_p2_sd_transfer(0xff) == 0xff) {
         berry_p2_sd_deselect();
         return 0;
      }
   }
   berry_p2_sd_deselect();
   berry_p2_sd_ready = 0;
   return -1;
}
#endif

static unsigned long sd_service_2_timed(int svc, long par1, long par2) {
   int entry;
   int code;
   int cog;
   int lock;
   int have_lock;
   unsigned long spins;
   volatile request_t *request;

   entry = *((short *)SERVICE_POINTER(svc));
   code = entry & 0x7f;
   if (code == 0) {
      return BERRY_P2_FS_RESULT_SD_NO_SERVICE;
   }

   cog = (entry >> 12) & 0x0f;
   lock = (entry >> 7) & 0x1f;
   request = REQUEST_BLOCK(cog);
   if (request->request != 0) {
      return BERRY_P2_FS_RESULT_SD_BUSY;
   }

   have_lock = 0;
   if (lock < LOCK_MAX) {
      if (!_locktry(lock)) {
         return BERRY_P2_FS_RESULT_SD_BUSY;
      }
      have_lock = 1;
   }

   sd_params.par1 = par1;
   sd_params.par2 = par2;
   request->response = 0;
   request->request = ((unsigned int)code << 24) | ((unsigned int)&sd_params & 0x00ffffff);
   spins = BERRY_P2_SD_SPIN_LIMIT;
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
   return request->response;
}

/*
 * SD calls : write a sector
 */
unsigned long sd_sectwrite(char * buffer, long sector) {

   unsigned long retval;

#if defined(__BERRY_P2_DIRECT_SD_IO)
   int i;

   for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
      sd_sector[i] = buffer[i];
   }
   retval = berry_p2_sd_write_direct(sd_sector, (unsigned long)sector);
#else
   retval = _long_service_2(SVC_SD_WRITE, (long)buffer, sector);
#endif
   return retval == 3 ? 0 : retval;

}
"""
)

secread = root / "source/lib/catalina/secread.c"
secread.write_text(
    """#include <plugin.h>
#include <prop2.h>
#include <sd.h>

#define BERRY_P2_SD_TIMEOUT_MS 3000
#define BERRY_P2_SD_SPIN_LIMIT 100000UL
#define BERRY_P2_FS_RESULT_SD_TIMEOUT 0x101
#define BERRY_P2_FS_RESULT_SD_BUSY 0x102
#define BERRY_P2_FS_RESULT_SD_NO_SERVICE 0x103

#if defined(__BERRY_P2_DIRECT_SD_IO)
#define BERRY_P2_SD_DO 58
#define BERRY_P2_SD_DI 59
#define BERRY_P2_SD_CS 60
#define BERRY_P2_SD_CLK 61
#define BERRY_P2_FLASH_DO 58
#define BERRY_P2_FLASH_DI 59
#define BERRY_P2_FLASH_CLK 60
#define BERRY_P2_FLASH_CS 61
#define BERRY_P2_FLASH_RESET_ENABLE 0x66
#define BERRY_P2_FLASH_RESET_MEMORY 0x99
#define BERRY_P2_FLASH_DEEP_POWER_DOWN 0xb9

static int berry_p2_sd_ready;
static int berry_p2_sd_high_capacity;

static unsigned char berry_p2_flash_transfer(unsigned char value) {
   unsigned char in = 0;
   int bit;

   for (bit = 0; bit < 8; bit++) {
      if (value & 0x80) {
         _pinh(BERRY_P2_FLASH_DI);
      }
      else {
         _pinl(BERRY_P2_FLASH_DI);
      }
      value <<= 1;
      _waitus(1);
      _pinh(BERRY_P2_FLASH_CLK);
      _waitus(1);
      in = (unsigned char)((in << 1) | (_pinr(BERRY_P2_FLASH_DO) ? 1 : 0));
      _pinl(BERRY_P2_FLASH_CLK);
   }
   return in;
}

static void berry_p2_flash_command(unsigned char command) {
   _pinh(BERRY_P2_FLASH_CS);
   _pinl(BERRY_P2_FLASH_CLK);
   _pinl(BERRY_P2_FLASH_DI);
   _pinf(BERRY_P2_FLASH_DO);
   _waitus(2);
   _pinl(BERRY_P2_FLASH_CS);
   (void)berry_p2_flash_transfer(command);
   _pinh(BERRY_P2_FLASH_CS);
   _waitus(2);
}

static void berry_p2_flash_sleep(void) {
   berry_p2_flash_command(BERRY_P2_FLASH_RESET_ENABLE);
   berry_p2_flash_command(BERRY_P2_FLASH_RESET_MEMORY);
   _waitms(1);
   berry_p2_flash_command(BERRY_P2_FLASH_DEEP_POWER_DOWN);
   _waitus(10);
}

static unsigned char berry_p2_sd_transfer(unsigned char value) {
   unsigned char in = 0;
   int bit;

   for (bit = 0; bit < 8; bit++) {
      if (value & 0x80) {
         _pinh(BERRY_P2_SD_DI);
      }
      else {
         _pinl(BERRY_P2_SD_DI);
      }
      value <<= 1;
      _waitus(2);
      _pinh(BERRY_P2_SD_CLK);
      _waitus(2);
      in = (unsigned char)((in << 1) | (_pinr(BERRY_P2_SD_DO) ? 1 : 0));
      _pinl(BERRY_P2_SD_CLK);
   }
   return in;
}

static void berry_p2_sd_deselect(void) {
   _pinh(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
}

static void berry_p2_sd_idle_clocks(void) {
   int i;

   berry_p2_flash_sleep();
   _pinh(BERRY_P2_SD_CS);
   _pinl(BERRY_P2_SD_CLK);
   _pinh(BERRY_P2_SD_DI);
   _pinf(BERRY_P2_SD_DO);
   _waitms(1);
   for (i = 0; i < 10; i++) {
      (void)berry_p2_sd_transfer(0xff);
   }
}

static unsigned char berry_p2_sd_command(
   unsigned char cmd,
   unsigned long arg,
   unsigned char crc,
   unsigned char *extra,
   int extra_len
) {
   unsigned char response = 0xff;
   int i;

   berry_p2_sd_deselect();
   _pinl(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer((unsigned char)(0x40 | cmd));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 24));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 16));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 8));
   (void)berry_p2_sd_transfer((unsigned char)arg);
   (void)berry_p2_sd_transfer(crc);

   for (i = 0; i < 16; i++) {
      response = berry_p2_sd_transfer(0xff);
      if ((response & 0x80) == 0) {
         break;
      }
   }
   for (i = 0; i < extra_len; i++) {
      extra[i] = berry_p2_sd_transfer(0xff);
   }
   berry_p2_sd_deselect();
   return response;
}

static int berry_p2_sd_init_direct(void) {
   unsigned char extra[4];
   unsigned char r;
   int tries;

   berry_p2_sd_ready = 0;
   berry_p2_sd_high_capacity = 0;
   berry_p2_sd_idle_clocks();

   r = berry_p2_sd_command(0, 0, 0x95, 0, 0);
   if (r != 0x01) {
      return -1;
   }

   r = berry_p2_sd_command(8, 0x1aa, 0x87, extra, 4);
   if (r != 0x01 || extra[2] != 0x01 || extra[3] != 0xaa) {
      return -1;
   }

   for (tries = 0; tries < 1000; tries++) {
      r = berry_p2_sd_command(55, 0, 0x01, 0, 0);
      if (r > 0x01) {
         return -1;
      }
      r = berry_p2_sd_command(41, 0x40000000, 0x01, 0, 0);
      if (r == 0x00) {
         break;
      }
      _waitms(1);
   }
   if (r != 0x00) {
      return -1;
   }

   r = berry_p2_sd_command(58, 0, 0x01, extra, 4);
   if (r != 0x00) {
      return -1;
   }
   berry_p2_sd_high_capacity = (extra[0] & 0x40) ? 1 : 0;

   r = berry_p2_sd_command(16, 512, 0x01, 0, 0);
   if (r != 0x00 && !berry_p2_sd_high_capacity) {
      return -1;
   }

   berry_p2_sd_ready = 1;
   return 0;
}

static int berry_p2_sd_read_direct(char *buffer, unsigned long sector) {
   unsigned long arg;
   unsigned char token = 0xff;
   int i;

   if (!berry_p2_sd_ready && berry_p2_sd_init_direct() != 0) {
      return -1;
   }

   arg = berry_p2_sd_high_capacity ? sector : (sector << 9);
   _pinl(BERRY_P2_SD_CS);
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer(0x40 | 17);
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 24));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 16));
   (void)berry_p2_sd_transfer((unsigned char)(arg >> 8));
   (void)berry_p2_sd_transfer((unsigned char)arg);
   (void)berry_p2_sd_transfer(0x01);

   for (i = 0; i < 16; i++) {
      token = berry_p2_sd_transfer(0xff);
      if ((token & 0x80) == 0) {
         break;
      }
   }
   if (token != 0x00) {
      berry_p2_sd_deselect();
      berry_p2_sd_ready = 0;
      return -1;
   }

   for (i = 0; i < 20000; i++) {
      token = berry_p2_sd_transfer(0xff);
      if (token == 0xfe) {
         break;
      }
      if ((token & 0xf0) == 0) {
         berry_p2_sd_deselect();
         berry_p2_sd_ready = 0;
         return -1;
      }
   }
   if (token != 0xfe) {
      berry_p2_sd_deselect();
      berry_p2_sd_ready = 0;
      return -1;
   }

   for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
      buffer[i] = (char)berry_p2_sd_transfer(0xff);
   }
   (void)berry_p2_sd_transfer(0xff);
   (void)berry_p2_sd_transfer(0xff);
   berry_p2_sd_deselect();
   return 0;
}
#endif

typedef struct berry_p2_sd_params {
   long par1;
   long par2;
} berry_p2_sd_params;

static volatile berry_p2_sd_params sd_params;
#if defined(__BERRY_P2_DIRECT_SD_IO)
static char sd_sector[__CATALINA_SECTOR_SIZE];
#endif

static unsigned long sd_service_2_timed(int svc, long par1, long par2) {
   int entry;
   int code;
   int cog;
   int lock;
   int have_lock;
   unsigned long spins;
   volatile request_t *request;

   entry = *((short *)SERVICE_POINTER(svc));
   code = entry & 0x7f;
   if (code == 0) {
      return BERRY_P2_FS_RESULT_SD_NO_SERVICE;
   }

   cog = (entry >> 12) & 0x0f;
   lock = (entry >> 7) & 0x1f;
   request = REQUEST_BLOCK(cog);
   if (request->request != 0) {
      return BERRY_P2_FS_RESULT_SD_BUSY;
   }

   have_lock = 0;
   if (lock < LOCK_MAX) {
      if (!_locktry(lock)) {
         return BERRY_P2_FS_RESULT_SD_BUSY;
      }
      have_lock = 1;
   }

   sd_params.par1 = par1;
   sd_params.par2 = par2;
   request->response = 0;
   request->request = ((unsigned int)code << 24) | ((unsigned int)&sd_params & 0x00ffffff);
   spins = BERRY_P2_SD_SPIN_LIMIT;
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
   return request->response;
}

/*
 * SD calls : read a sector
 */
unsigned long sd_sectread(char * buffer, long sector) {

   unsigned long retval;

#if defined(__BERRY_P2_DIRECT_SD_IO)
   int i;

   retval = berry_p2_sd_read_direct(sd_sector, (unsigned long)sector);
   if (retval == 0) {
      for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
         buffer[i] = sd_sector[i];
      }
   }
#else
   retval = _long_service_2(SVC_SD_READ, (long)buffer, sector);
#endif
   return retval;

}
"""
)
PY

export LCCDIR="${CATALINA_DIR}"
source "${LCCDIR}/use_catalina" >/dev/null

model_compile_flags=(-C "${CATALINA_MODEL}" -C "${CATALINA_PLATFORM}")
if [ "${CATALINA_MODEL}" = "LARGE" ]; then
   model_compile_flags+=(-C PSRAM)
fi
io_compile_flags=(-p2 -W-w "${model_compile_flags[@]}" -D__CATALINA_SIMPLE_IO=0 -D__CATALINA_SDCARD_IO=1 -D__BERRY_P2_DIRECT_SD_IO -DNOFLOAT)
sector_compile_flags=(-p2 -W-w "${model_compile_flags[@]}" -D__CATALINA_SIMPLE_IO=0 -D__CATALINA_SDCARD_IO=1 -D__BERRY_P2_DIRECT_SD_IO)
io_src_dir="${CATALINA_DIR}/source/lib/io"
lib_src_dir="${CATALINA_DIR}/source/lib/catalina"
lib_dst_dir="${CATALINA_DIR}/lib/p2/cmm/${CATALINA_CLIB}"
build_tmp_dir="${CATALINA_DIR}/build/tmp"

mkdir -p "${build_tmp_dir}"

( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o cache_sd "${io_src_dir}/cache_sd.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dread "${io_src_dir}/dread.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dwrite "${io_src_dir}/dwrite.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dgnext "${io_src_dir}/dgnext.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${sector_compile_flags[@]}" -o secread "${lib_src_dir}/secread.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${sector_compile_flags[@]}" -o secwrite "${lib_src_dir}/secwrite.c" >/dev/null )

python3 - "${build_tmp_dir}/dgnext" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("cviu_m1 ' zero extend", "#$ff ' zero extend")
text = text.replace("cviu_m2 ' zero extend", "#$ffff ' zero extend")
path.write_text(text)
PY

cp "${build_tmp_dir}/cache_sd" "${lib_dst_dir}/cache_sd.s"
cp "${build_tmp_dir}/dread" "${lib_dst_dir}/dread.s"
cp "${build_tmp_dir}/dwrite" "${lib_dst_dir}/dwrite.s"
cp "${build_tmp_dir}/dgnext" "${lib_dst_dir}/dgnext.s"
cp "${build_tmp_dir}/secread" "${lib_dst_dir}/secread.s"
cp "${build_tmp_dir}/secwrite" "${lib_dst_dir}/secwrite.s"

( cd "${lib_dst_dir}" && catbind -i -e *.s >/dev/null )

printf '%s\n' "${PATCH_VERSION}" > "${STAMP_FILE}"

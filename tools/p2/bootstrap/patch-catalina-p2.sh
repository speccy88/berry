#!/usr/bin/env bash
set -euo pipefail

CATALINA_DIR="${1:?usage: $0 <catalina-dir> [platform] [model] [clib]}"
CATALINA_PLATFORM="${2:-P2_EDGE}"
CATALINA_MODEL="${3:-COMPACT}"
CATALINA_CLIB="${4:-cix}"
PATCH_VERSION="berry-p2-patch-v2"
CATALINA_DIR="$(cd "${CATALINA_DIR}" && pwd -P)"
STAMP_FILE="${CATALINA_DIR}/.${PATCH_VERSION}"

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
    "source/lib/io/dgnext.c",
    """\t\telse {\n\t\t\tif (dirinfo->currentsector >= volinfo->secperclus) {\n\t\t\t\tdirinfo->currentsector = 0;\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((dirinfo->currentcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (dirinfo->currentcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (dirinfo->currentcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\n\t\t\t\t  \t// We are at the end of the directory chain. If this is a normal\n\t\t\t\t  \t// find operation, we should indicate that there is nothing more\n\t\t\t\t  \t// to see.\n\t\t\t\t  \tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\t\n\t\t\t\t\t// On the other hand, if this is a \"find free entry\" search,\n\t\t\t\t\t// we need to tell the caller to allocate a new cluster\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\t\t\t\tdirinfo->currentcluster = DFS_GetFAT(volinfo, dirinfo->scratch, &tempint, dirinfo->currentcluster);\n\t\t\t}\n\t\t\tif (DFS_ReadSector(volinfo->unit, dirinfo->scratch, volinfo->dataarea + ((dirinfo->currentcluster - 2) * volinfo->secperclus) + dirinfo->currentsector, 1))\n\t\t\t\treturn DFS_ERRMISC;\n\t\t}\n""",
    """\t\telse {\n\t\t\tif (dirinfo->currentsector >= volinfo->secperclus) {\n\t\t\t\tuint32_t nextcluster;\n\n\t\t\t\tdirinfo->currentsector = 0;\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((dirinfo->currentcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (dirinfo->currentcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (dirinfo->currentcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\n\t\t\t\t  \tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\n\t\t\t\tnextcluster = DFS_GetFAT(volinfo, dirinfo->scratch, &tempint, dirinfo->currentcluster);\n#if __CATALINA_FAT12_SUPPORT            \n\t\t\t\tif ((nextcluster >= 0xff7 &&  volinfo->filesystem == FAT12) ||\n#else\n\t\t\t\tif (volinfo->filesystem == FAT12)\n               return DFS_NOSUPPORT;\n            else if (\n#endif                  \n\t\t\t\t  (nextcluster >= 0xfff7 &&  volinfo->filesystem == FAT16) ||\n\t\t\t\t  (nextcluster >= 0x0ffffff7 &&  volinfo->filesystem == FAT32)) {\n\t\t\t\t\tif (!(dirinfo->flags & DFS_DI_BLANKENT))\n\t\t\t\t\t\treturn DFS_EOF;\n\t\t\t\t\telse\n\t\t\t\t\t\treturn DFS_ALLOCNEW;\n\t\t\t\t}\n\t\t\t\tdirinfo->currentcluster = nextcluster;\n\t\t\t}\n\t\t\tif (DFS_ReadSector(volinfo->unit, dirinfo->scratch, volinfo->dataarea + ((dirinfo->currentcluster - 2) * volinfo->secperclus) + dirinfo->currentsector, 1))\n\t\t\t\treturn DFS_ERRMISC;\n\t\t}\n""",
)

secwrite = root / "source/lib/catalina/secwrite.c"
secwrite.write_text(
    """#include <sd.h>

/*
 * SD calls : write a sector
 */
unsigned long sd_sectwrite(char * buffer, long sector) {

#ifdef __CATALINA_LARGE

   int i;
   int retval;
   char local[__CATALINA_SECTOR_SIZE];

   for (i = 0; i < __CATALINA_SECTOR_SIZE; i++) {
      local[i] = buffer[i];;
   }
   retval = _long_service_2(SVC_SD_WRITE, (long)local, sector);
   return retval == 3 ? 0 : retval;

#else

   {
      unsigned long retval = _long_service_2(SVC_SD_WRITE, (long)buffer, sector);
      return retval == 3 ? 0 : retval;
   }

#endif

}
"""
)
PY

export LCCDIR="${CATALINA_DIR}"
source "${LCCDIR}/use_catalina" >/dev/null

docker_platform_flags=(-p2 -W-w -C "${CATALINA_MODEL}" -C "${CATALINA_PLATFORM}")
io_compile_flags=(-p2 -W-w -C "${CATALINA_MODEL}" -C "${CATALINA_PLATFORM}" -C PSRAM -D__CATALINA_SIMPLE_IO=0 -D__CATALINA_SDCARD_IO=1 -DNOFLOAT)
io_src_dir="${CATALINA_DIR}/source/lib/io"
lib_src_dir="${CATALINA_DIR}/source/lib/catalina"
lib_dst_dir="${CATALINA_DIR}/lib/p2/cmm/${CATALINA_CLIB}"
build_tmp_dir="${CATALINA_DIR}/build/tmp"

mkdir -p "${build_tmp_dir}"

( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o cache_sd "${io_src_dir}/cache_sd.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dread "${io_src_dir}/dread.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dwrite "${io_src_dir}/dwrite.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${io_compile_flags[@]}" -o dgnext "${io_src_dir}/dgnext.c" >/dev/null )
( cd "${build_tmp_dir}" && catalina -S "${docker_platform_flags[@]}" -o secwrite "${lib_src_dir}/secwrite.c" >/dev/null )

cp "${build_tmp_dir}/cache_sd" "${lib_dst_dir}/cache_sd.s"
cp "${build_tmp_dir}/dread" "${lib_dst_dir}/dread.s"
cp "${build_tmp_dir}/dwrite" "${lib_dst_dir}/dwrite.s"
cp "${build_tmp_dir}/dgnext" "${lib_dst_dir}/dgnext.s"
cp "${build_tmp_dir}/secwrite" "${lib_dst_dir}/secwrite.s"

( cd "${lib_dst_dir}" && catbind -i -e *.s >/dev/null )

printf '%s\n' "${PATCH_VERSION}" > "${STAMP_FILE}"

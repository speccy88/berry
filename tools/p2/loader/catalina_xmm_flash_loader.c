#include <stdint.h>
#include <string.h>

#include <cog.h>
#include <prop2.h>
#include <psram.h>

#ifndef BERRY_XMM_FLASH_ADDR
#define BERRY_XMM_FLASH_ADDR 0x40000UL
#endif

#define FLASH_DO 58
#define FLASH_DI 59
#define FLASH_CLK 60
#define FLASH_CS 61

#define SD_DO FLASH_DO
#define SD_DI FLASH_DI
#define SD_CS FLASH_CLK
#define SD_CLK FLASH_CS

#define FLASH_READ_DATA 0x03
#define FLASH_RESET_ENABLE 0x66
#define FLASH_RESET_MEMORY 0x99
#define FLASH_DEEP_POWER_DOWN 0xB9

#define SECTOR_SIZE 0x0200
#define FLASH_CHUNK_SIZE 0x2000
#define PROLOGUE_OFFS 0x1000
#define LAYOUT_OFFS 0x10

static uint8_t flash_sink;
static uint8_t flash_page[FLASH_CHUNK_SIZE];
static uint32_t boot_status_ticks;

#define FLASH_SLOT_FREE 0
#define FLASH_SLOT_READY 1
#define FLASH_SLOT_READING 2
#define FLASH_WORKER_DONE 1
#define FLASH_WORKER_STATE_ADDR 0x60000UL
#define FLASH_BUFFER0_ADDR 0x61000UL
#define FLASH_BUFFER1_ADDR (FLASH_BUFFER0_ADDR + FLASH_CHUNK_SIZE)
#define FLASH_WORKER_TIMEOUT_LOOPS 4000000UL
#define FLASH_APP_SPARSE_MAGIC 0x31505358UL
#define FLASH_SPARSE_FLAG_DATA 0
#define FLASH_SPARSE_FLAG_ZERO 1
#define BOOT_STATUS_TX_PIN 62
#define BOOT_STATUS_BAUD 230400UL
#define BOOT_STATUS_TX_MODE 0x7cUL

typedef struct flash_worker_state {
    volatile uint32_t slot_state[2];
    volatile uint32_t slot_count[2];
    volatile uint32_t worker_status;
    uint32_t image_base;
    uint32_t image_size;
    uint8_t *buffer[2];
} flash_worker_state;

static const uint32_t flash_worker_pasm[] = {
    0xf600f5f8u, 0xf601147au, 0xf1051414u, 0xfb00f68au,
    0xf601147au, 0xf1051418u, 0xfb00f88au, 0xf601147au,
    0xf105141cu, 0xfb00fa8au, 0xf601147au, 0xf1051420u,
    0xfb00fc8au, 0xf543fa77u, 0xf543fa76u, 0xf523fa74u,
    0xf543f677u, 0xf543f676u, 0xf543f674u, 0xf523f675u,
    0xf523fa77u, 0xf523fa76u, 0xf6050e03u, 0xfdb00118u,
    0xf6010e7bu, 0xf0450e10u, 0xfdb0010cu, 0xf6010e7bu,
    0xf0450e08u, 0xfdb00100u, 0xf6010e7bu, 0xfdb000f8u,
    0xf523fa74u, 0xf604fe00u, 0xf218fe7cu, 0x3d9000c4u,
    0xf601007fu, 0xf045000du, 0xf5050001u, 0xf21d0000u,
    0xa601027au, 0xa1050200u, 0x5601027au, 0x51050204u,
    0xa601047au, 0xa1050408u, 0x5601047au, 0x5105040cu,
    0xa601067du, 0x5601067eu, 0xfb011481u, 0xf21d1400u,
    0x5d64201fu, 0x5d9ffff0u, 0xf6051402u, 0xfc611481u,
    0xf601087cu, 0xf181087fu, 0xf2190878u, 0x16010878u,
    0xf6010a84u, 0xf1010a79u, 0xf5210a79u, 0xf6010c84u,
    0xf21d0c00u, 0xad900014u, 0xfdb00098u, 0xfc411083u,
    0xf1050601u, 0xf1850c01u, 0xfd9fffe4u, 0xf6010c85u,
    0xf1810c84u, 0xf21d0c00u, 0xad900014u, 0xf6051000u,
    0xfc411083u, 0xf1050601u, 0xf1850c01u, 0xfd9fffe4u,
    0xfc610a82u, 0xf6051401u, 0xfc611481u, 0xf100fe78u,
    0xfd9fff34u, 0xf543fa76u, 0xf543fa77u, 0xf601147au,
    0xf1051410u, 0xf6051601u, 0xfc61168au, 0xff855d4au,
    0xfd66001fu, 0xfd9ffff4u, 0xf6051208u, 0xf4150e07u,
    0xc543fa74u, 0x3523fa74u, 0xf0650e01u, 0xf543fa76u,
    0x00000000u, 0xf523fa76u, 0x00000000u, 0xfb6d13f7u,
    0xfd64002du, 0xf6051000u, 0xf6051208u, 0xf543fa76u,
    0x00000000u, 0x00000000u, 0xfd747440u, 0xf0a51001u,
    0xf523fa76u, 0x00000000u, 0xfb6d13f8u, 0xfd64002du,
    0x08000000u, 0x04000000u, 0x10000000u, 0x20000000u,
    0x00002000u, 0x000001ffu,
};

static void boot_status_puts(const char *s)
{
    while (*s) {
        uint32_t wait_count = 0;

        _wypin(BOOT_STATUS_TX_PIN, (unsigned char)*s++);
        while (_pinr(BOOT_STATUS_TX_PIN) == 0 && wait_count < FLASH_WORKER_TIMEOUT_LOOPS) {
            ++wait_count;
        }
    }
}

static void boot_status_start(void)
{
    uint32_t bitperiod = _clockfreq() / BOOT_STATUS_BAUD;
    uint32_t bit_mode = 7u + (bitperiod << 16);

    _pinf(BOOT_STATUS_TX_PIN);
    _wrpin(BOOT_STATUS_TX_PIN, BOOT_STATUS_TX_MODE);
    _wxpin(BOOT_STATUS_TX_PIN, bit_mode);
    _pinl(BOOT_STATUS_TX_PIN);
    _waitms(10);
    boot_status_ticks = 0;
    boot_status_puts("\rInitializing PSRAM |");
}

static void boot_status_step(void)
{
    static const char spin[] = "|/-\\";
    char text[24];

    ++boot_status_ticks;
    if ((boot_status_ticks & 3u) != 0u) {
        return;
    }
    text[0] = '\r';
    text[1] = 'I';
    text[2] = 'n';
    text[3] = 'i';
    text[4] = 't';
    text[5] = 'i';
    text[6] = 'a';
    text[7] = 'l';
    text[8] = 'i';
    text[9] = 'z';
    text[10] = 'i';
    text[11] = 'n';
    text[12] = 'g';
    text[13] = ' ';
    text[14] = 'P';
    text[15] = 'S';
    text[16] = 'R';
    text[17] = 'A';
    text[18] = 'M';
    text[19] = ' ';
    text[20] = spin[(boot_status_ticks >> 2) & 3u];
    text[21] = '\0';
    boot_status_puts(text);
}

static void boot_status_done(void)
{
    boot_status_puts("\r\033[K");
}

static void flash_init(void)
{
    _pinh(FLASH_CS);
    _pinh(FLASH_CLK);
    _pinl(FLASH_DI);
    _pinf(FLASH_DO);
}

static uint8_t flash_transfer(uint8_t out)
{
    uint8_t in = 0;
    int bit;

    for (bit = 0; bit < 8; bit++) {
        if (out & 0x80) {
            _pinh(FLASH_DI);
        } else {
            _pinl(FLASH_DI);
        }
        out <<= 1;
        _pinh(FLASH_CLK);
        in = (uint8_t)((in << 1) | (_pinr(FLASH_DO) & 1));
        _pinl(FLASH_CLK);
    }
    return in;
}

static void flash_send(uint8_t out)
{
    flash_sink ^= flash_transfer(out);
}

static void flash_start_read(uint32_t addr)
{
    _pinl(FLASH_CS);
    _pinl(FLASH_CLK);
    flash_send(FLASH_READ_DATA);
    flash_send((uint8_t)(addr >> 16));
    flash_send((uint8_t)(addr >> 8));
    flash_send((uint8_t)addr);
}

static void flash_stop(void)
{
    _pinh(FLASH_CLK);
    _pinh(FLASH_CS);
}

static void flash_float_bus(void)
{
    _pinf(FLASH_CS);
    _pinf(FLASH_CLK);
    _pinf(FLASH_DI);
    _pinf(FLASH_DO);
}

static void flash_read_into(uint8_t *dst, uint32_t count)
{
    uint32_t i;

    for (i = 0; i < count; i++) {
        uint8_t in = 0;
        int bit;

        for (bit = 0; bit < 8; bit++) {
            _pinh(FLASH_CLK);
            in = (uint8_t)((in << 1) | (_pinr(FLASH_DO) & 1));
            _pinl(FLASH_CLK);
        }
        dst[i] = in;
    }
}

static void flash_read(uint32_t addr, uint8_t *dst, uint32_t count)
{
    flash_start_read(addr);
    _pinl(FLASH_DI);
    flash_read_into(dst, count);
    flash_stop();
}

static void flash_command(uint8_t cmd)
{
    _pinl(FLASH_CS);
    _pinl(FLASH_CLK);
    flash_send(cmd);
    flash_stop();
}

static void flash_release_bus(void)
{
    /*
     * P2 Edge boot flash and microSD share pins 58..61, with flash CS/CLK
     * crossing the SD clock/select pins. Put flash in deep power-down before
     * Catalina starts its SD cog, otherwise SD clock pulses can also select
     * flash and leave MISO looking like an idle 0xff sector.
     */
    flash_command(FLASH_RESET_ENABLE);
    flash_command(FLASH_RESET_MEMORY);
    _waitms(100);
    flash_command(FLASH_DEEP_POWER_DOWN);
    _waitus(10);

    /*
     * Leave both shared devices explicitly deselected for Catalina:
     *
     *   SD_CS  == FLASH_CLK  high
     *   SD_CLK == FLASH_CS   high
     *
     * Floating these pins here lets the board/pullups decide the handoff
     * state, and driving FLASH_CLK low selects the SD card.
     */
    _pinh(SD_CS);
    _pinh(SD_CLK);
    _pinh(SD_DI);
    _pinf(SD_DO);
}

static void sd_idle_after_flash(void)
{
    int i;

    /*
     * Catalina's SD cog sends the SD power-up idle clocks during _SDcard_Init.
     * Standalone flash boot has just spent a long time exercising the shared
     * flash/SD pins, so provide the SD idle-clock pattern here too, but end
     * with both shared devices explicitly deselected.
     */
    _pinh(SD_CS);
    _pinh(SD_CLK);
    _pinh(SD_DI);
    _pinf(SD_DO);
    _waitms(1);
    for (i = 0; i < 96; ++i) {
        _pinl(SD_CLK);
        _waitus(5);
        _pinh(SD_CLK);
        _waitus(5);
    }
    _waitms(10);
    _pinh(SD_CS);
    _pinh(SD_CLK);
    _pinh(SD_DI);
    _pinf(SD_DO);
}

static uint32_t flash_read_u32(uint32_t addr)
{
    uint8_t b[4];

    flash_read(addr, b, sizeof(b));
    return (uint32_t)b[0]
        | ((uint32_t)b[1] << 8)
        | ((uint32_t)b[2] << 16)
        | ((uint32_t)b[3] << 24);
}


static void load_single_cog(uint32_t image_size, uint32_t image_base)
{
    uint32_t offset;
    uint32_t corr = 0;
    uint32_t layout = 0;

    flash_start_read(image_base);
    _pinl(FLASH_DI);

    for (offset = 0; offset < image_size; offset += FLASH_CHUNK_SIZE) {
        uint32_t padded_count;
        uint32_t consumed = 0;
        uint32_t remaining = image_size - offset;
        uint32_t count = remaining < FLASH_CHUNK_SIZE ? remaining : FLASH_CHUNK_SIZE;

        flash_read_into(flash_page, count);
        padded_count = (count + SECTOR_SIZE - 1) & ~(uint32_t)(SECTOR_SIZE - 1);
        if (padded_count > count) {
            memset(flash_page + count, 0, padded_count - count);
        }

        if (offset < P2_LOAD_SIZE) {
            uint32_t hub_count = P2_LOAD_SIZE - offset;
            if (hub_count > padded_count) {
                hub_count = padded_count;
            }
            memcpy((void *)offset, flash_page, hub_count);
            consumed = hub_count;
            boot_status_step();
        }

        if (consumed < padded_count) {
            uint32_t xmm_offset = offset + consumed;
            uint8_t *xmm_page = flash_page + consumed;
            uint32_t xmm_count = padded_count - consumed;

            if (xmm_offset == P2_LOAD_SIZE) {
                layout = (uint32_t)xmm_page[LAYOUT_OFFS + 0]
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 1] << 8)
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 2] << 16)
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 3] << 24);
            }
            if (psram_write(xmm_page, (void *)(xmm_offset + corr - P2_LOAD_SIZE), xmm_count) < 0) {
                while (1) {
                    _waitms(1000);
                }
            }
            boot_status_step();
            if (layout == 2) {
                corr = PROLOGUE_OFFS;
            }
        }
    }
    flash_stop();
}

static void worker_init(flash_worker_state *worker, uint32_t image_base, uint32_t image_size)
{
    worker->slot_state[0] = FLASH_SLOT_FREE;
    worker->slot_state[1] = FLASH_SLOT_FREE;
    worker->slot_count[0] = 0;
    worker->slot_count[1] = 0;
    worker->worker_status = 0;
    worker->image_base = image_base;
    worker->image_size = image_size;
    worker->buffer[0] = (uint8_t *)FLASH_BUFFER0_ADDR;
    worker->buffer[1] = (uint8_t *)FLASH_BUFFER1_ADDR;
}

static int worker_wait_slot(flash_worker_state *worker, uint32_t slot)
{
    uint32_t loops;

    for (loops = 0; loops < FLASH_WORKER_TIMEOUT_LOOPS; ++loops) {
        if (worker->slot_state[slot] == FLASH_SLOT_READY) {
            return 1;
        }
        _waitx(16);
    }
    return 0;
}

static int worker_wait_done(flash_worker_state *worker);

static int worker_wait_done(flash_worker_state *worker)
{
    uint32_t loops;

    for (loops = 0; loops < FLASH_WORKER_TIMEOUT_LOOPS; ++loops) {
        if (worker->worker_status == FLASH_WORKER_DONE) {
            return 1;
        }
        _waitx(16);
    }
    return 0;
}

static int write_loaded_range(uint32_t dst_offset, uint8_t *data, uint32_t count, int is_zero, uint32_t *layout)
{
    uint32_t pos = 0;

    while (pos < count) {
        uint32_t cur = dst_offset + pos;
        uint32_t remaining = count - pos;

        if (cur < P2_LOAD_SIZE) {
            uint32_t hub_count = P2_LOAD_SIZE - cur;
            if (hub_count > remaining) {
                hub_count = remaining;
            }
            if (is_zero) {
                memset((void *)cur, 0, hub_count);
            } else {
                memcpy((void *)cur, data + pos, hub_count);
            }
            pos += hub_count;
            boot_status_step();
            continue;
        }

        if (cur < P2_LOAD_SIZE + FLASH_CHUNK_SIZE && cur + remaining > P2_LOAD_SIZE + FLASH_CHUNK_SIZE) {
            remaining = P2_LOAD_SIZE + FLASH_CHUNK_SIZE - cur;
        }

        if (!is_zero && cur <= P2_LOAD_SIZE + LAYOUT_OFFS && cur + remaining >= P2_LOAD_SIZE + LAYOUT_OFFS + 4) {
            uint32_t idx = pos + (P2_LOAD_SIZE + LAYOUT_OFFS - cur);
            *layout = (uint32_t)data[idx + 0]
                | ((uint32_t)data[idx + 1] << 8)
                | ((uint32_t)data[idx + 2] << 16)
                | ((uint32_t)data[idx + 3] << 24);
        }

        {
            uint32_t corr = (*layout == 2 && cur >= P2_LOAD_SIZE + FLASH_CHUNK_SIZE) ? PROLOGUE_OFFS : 0;
            uint8_t *src = is_zero ? flash_page : (data + pos);

            if (is_zero) {
                uint32_t zero_count = remaining;
                while (zero_count > 0) {
                    uint32_t chunk = zero_count > FLASH_CHUNK_SIZE ? FLASH_CHUNK_SIZE : zero_count;
                    memset(flash_page, 0, chunk);
                    if (psram_write(flash_page, (void *)(cur + pos - pos + corr - P2_LOAD_SIZE), chunk) < 0) {
                        return 0;
                    }
                    cur += chunk;
                    pos += chunk;
                    zero_count -= chunk;
                    boot_status_step();
                }
            } else {
                if (psram_write(src, (void *)(cur + corr - P2_LOAD_SIZE), remaining) < 0) {
                    return 0;
                }
                pos += remaining;
                boot_status_step();
            }
        }
    }
    return 1;
}

static int load_data_single(uint32_t flash_addr, uint32_t dst_offset, uint32_t count, uint32_t *layout)
{
    uint32_t pos;

    for (pos = 0; pos < count; pos += FLASH_CHUNK_SIZE) {
        uint32_t chunk = count - pos;
        if (chunk > FLASH_CHUNK_SIZE) {
            chunk = FLASH_CHUNK_SIZE;
        }
        flash_read(flash_addr + pos, flash_page, chunk);
        if (!write_loaded_range(dst_offset + pos, flash_page, chunk, 0, layout)) {
            return 0;
        }
    }
    return 1;
}

static int load_zero_range(uint32_t dst_offset, uint32_t count, uint32_t *layout)
{
    return write_loaded_range(dst_offset, NULL, count, 1, layout);
}

static int load_data_worker(uint32_t flash_addr, uint32_t dst_offset, uint32_t count, uint32_t *layout)
{
    flash_worker_state *worker = (flash_worker_state *)FLASH_WORKER_STATE_ADDR;
    uint32_t pos;
    int cog;

    worker_init(worker, flash_addr, count);
    flash_float_bus();
    cog = _cogstart_PASM(ANY_COG, (void *)flash_worker_pasm, worker);
    if (cog < 0) {
        flash_init();
        return load_data_single(flash_addr, dst_offset, count, layout);
    }

    for (pos = 0; pos < count; pos += FLASH_CHUNK_SIZE) {
        uint32_t slot = (pos / FLASH_CHUNK_SIZE) & 1u;
        uint32_t chunk;

        if (!worker_wait_slot(worker, slot)) {
            if (_cogchk(cog)) {
                _cogstop(cog);
            }
            flash_init();
            return load_data_single(flash_addr, dst_offset, count, layout);
        }
        chunk = worker->slot_count[slot];
        if (chunk > count - pos) {
            chunk = count - pos;
        }
        if (!write_loaded_range(dst_offset + pos, worker->buffer[slot], chunk, 0, layout)) {
            if (_cogchk(cog)) {
                _cogstop(cog);
            }
            return 0;
        }
        worker->slot_state[slot] = FLASH_SLOT_FREE;
    }

    if (!worker_wait_done(worker)) {
        if (_cogchk(cog)) {
            _cogstop(cog);
        }
        return 0;
    }
    if (_cogchk(cog)) {
        _cogstop(cog);
    }
    return 1;
}

static int load_sparse_app(uint32_t record_addr, uint32_t record_count)
{
    uint32_t i;
    uint32_t cursor = record_addr;
    uint32_t layout = 0;

    for (i = 0; i < record_count; ++i) {
        uint8_t header[16];
        uint32_t dst_offset;
        uint32_t count;
        uint32_t flags;

        flash_read(cursor, header, sizeof(header));
        cursor += sizeof(header);
        dst_offset = (uint32_t)header[0]
            | ((uint32_t)header[1] << 8)
            | ((uint32_t)header[2] << 16)
            | ((uint32_t)header[3] << 24);
        count = (uint32_t)header[4]
            | ((uint32_t)header[5] << 8)
            | ((uint32_t)header[6] << 16)
            | ((uint32_t)header[7] << 24);
        flags = (uint32_t)header[8]
            | ((uint32_t)header[9] << 8)
            | ((uint32_t)header[10] << 16)
            | ((uint32_t)header[11] << 24);

        if (flags == FLASH_SPARSE_FLAG_ZERO) {
            if (!load_zero_range(dst_offset, count, &layout)) {
                return 0;
            }
        } else if (flags == FLASH_SPARSE_FLAG_DATA) {
            if (!load_data_worker(cursor, dst_offset, count, &layout)) {
                return 0;
            }
            cursor += count;
        } else {
            return 0;
        }
    }
    return 1;
}

static int load_worker_fast(uint32_t image_size, uint32_t image_base)
{
    flash_worker_state *worker = (flash_worker_state *)FLASH_WORKER_STATE_ADDR;
    uint32_t offset;
    uint32_t corr = 0;
    uint32_t layout = 0;
    int cog;

    worker_init(worker, image_base, image_size);
    flash_float_bus();
    cog = _cogstart_PASM(ANY_COG, (void *)flash_worker_pasm, worker);
    if (cog < 0) {
        return 0;
    }

    for (offset = 0; offset < image_size; offset += FLASH_CHUNK_SIZE) {
        uint32_t slot = (offset / FLASH_CHUNK_SIZE) & 1u;
        uint8_t *page = worker->buffer[slot];
        uint32_t padded_count;
        uint32_t consumed = 0;

        if (!worker_wait_slot(worker, slot)) {
            if (_cogchk(cog)) {
                _cogstop(cog);
            }
            return 0;
        }
        padded_count = worker->slot_count[slot];

        if (offset < P2_LOAD_SIZE) {
            uint32_t hub_count = P2_LOAD_SIZE - offset;
            if (hub_count > padded_count) {
                hub_count = padded_count;
            }
            memcpy((void *)offset, page, hub_count);
            consumed = hub_count;
            boot_status_step();
        }

        if (consumed < padded_count) {
            uint32_t xmm_offset = offset + consumed;
            uint8_t *xmm_page = page + consumed;
            uint32_t xmm_count = padded_count - consumed;

            if (xmm_offset == P2_LOAD_SIZE) {
                layout = (uint32_t)xmm_page[LAYOUT_OFFS + 0]
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 1] << 8)
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 2] << 16)
                    | ((uint32_t)xmm_page[LAYOUT_OFFS + 3] << 24);
            }
            if (psram_write(xmm_page, (void *)(xmm_offset + corr - P2_LOAD_SIZE), xmm_count) < 0) {
                if (_cogchk(cog)) {
                    _cogstop(cog);
                }
                return 0;
            }
            boot_status_step();
            if (layout == 2) {
                corr = PROLOGUE_OFFS;
            }
        }
        worker->slot_state[slot] = FLASH_SLOT_FREE;
    }

    if (!worker_wait_done(worker)) {
        if (_cogchk(cog)) {
            _cogstop(cog);
        }
        return 0;
    }
    if (_cogchk(cog)) {
        _cogstop(cog);
    }
    return 1;
}


void main(void)
{
    uint32_t first_word;

    flash_init();
    first_word = flash_read_u32(BERRY_XMM_FLASH_ADDR);
    boot_status_start();

    if (first_word == FLASH_APP_SPARSE_MAGIC) {
        uint32_t record_count = flash_read_u32(BERRY_XMM_FLASH_ADDR + 8);
        uint32_t record_addr = BERRY_XMM_FLASH_ADDR + 16;

        if (!load_sparse_app(record_addr, record_count)) {
            while (1) {
                _waitms(1000);
            }
        }
    } else {
        uint32_t image_size = first_word;
        uint32_t image_base = BERRY_XMM_FLASH_ADDR + 4;

        if (!load_worker_fast(image_size, image_base)) {
            flash_init();
            load_single_cog(image_size, image_base);
        }
    }
    boot_status_done();

    (void)psram_stop();
    flash_release_bus();
    sd_idle_after_flash();
    _coginit(0, 0, 0);
    _cogstop(_cogid());
}

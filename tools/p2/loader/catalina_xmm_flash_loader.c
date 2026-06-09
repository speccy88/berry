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
#define PROLOGUE_OFFS 0x1000
#define LAYOUT_OFFS 0x10

static uint8_t flash_sink;

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

static void flash_read(uint32_t addr, uint8_t *dst, uint32_t count)
{
    uint32_t i;

    flash_start_read(addr);
    for (i = 0; i < count; i++) {
        dst[i] = flash_transfer(0);
    }
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

void main(void)
{
    uint8_t page[SECTOR_SIZE];
    uint32_t image_size;
    uint32_t image_base;
    uint32_t offset;
    uint32_t corr = 0;
    uint32_t layout = 0;

    flash_init();
    image_size = flash_read_u32(BERRY_XMM_FLASH_ADDR);
    image_base = BERRY_XMM_FLASH_ADDR + 4;

    memset((void *)0, 0, P2_LOAD_SIZE);

    for (offset = 0; offset < image_size; offset += SECTOR_SIZE) {
        uint32_t remaining = image_size - offset;
        uint32_t count = remaining < SECTOR_SIZE ? remaining : SECTOR_SIZE;

        memset(page, 0, sizeof(page));
        flash_read(image_base + offset, page, count);

        if (offset < P2_LOAD_SIZE) {
            memcpy((void *)offset, page, SECTOR_SIZE);
        } else {
            if (offset == P2_LOAD_SIZE) {
                layout = (uint32_t)page[LAYOUT_OFFS + 0]
                    | ((uint32_t)page[LAYOUT_OFFS + 1] << 8)
                    | ((uint32_t)page[LAYOUT_OFFS + 2] << 16)
                    | ((uint32_t)page[LAYOUT_OFFS + 3] << 24);
            }
            if (psram_write(page, (void *)(offset + corr - P2_LOAD_SIZE), SECTOR_SIZE) < 0) {
                while (1) {
                    _waitms(1000);
                }
            }
            if (layout == 2) {
                corr = PROLOGUE_OFFS;
            }
        }
    }

    (void)psram_stop();
    flash_release_bus();
    sd_idle_after_flash();
    _coginit(0, 0, 0);
    _cogstop(_cogid());
}

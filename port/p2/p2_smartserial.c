#include <propeller2.h>

/*
 * P2 Smart Pin Serial Driver
 * Implements bidirectional serial I/O using P2 smart pins
 * Based on SimpleSerial.spin2 pattern
 */

enum {
    /* Smart pin modes for async serial */
    TX_MODE = 0b0000_0000_000_0000000000000_01_11110_0,  /* async tx mode */
    RX_MODE = 0b0000_0000_000_0000000000000_00_11111_0,  /* async rx mode */
    
    /* Default pins for P2-EVAL/similar boards */
    DEFAULT_RX_PIN = 63,
    DEFAULT_TX_PIN = 62,
    
    /* Baud rate */
    DEFAULT_BAUD = 115200,
    
    /* Max iterations to prevent infinite loops */
    MAX_WAIT_LOOPS = 100000000,
};

static int rx_pin = DEFAULT_RX_PIN;
static int tx_pin = DEFAULT_TX_PIN;

/*
 * Initialize smart pin serial driver
 * Configures RX and TX pins with smart pin modes for async serial
 */
void p2_smartserial_init(int rxpin, int txpin, int baud)
{
    unsigned long bitperiod;
    unsigned long bit_mode;
    
    rx_pin = rxpin;
    tx_pin = txpin;
    
    /* Calculate bit period: clkfreq / baud */
    bitperiod = _clockfreq() / baud;
    
    /* Smart pin mode encodes: 7 bits per char (async) + bit period */
    bit_mode = 7 + (bitperiod << 16);
    
    /* Configure TX pin (output) */
    _pinf(tx_pin);              /* disable the pin */
    _wrpin(tx_pin, TX_MODE);    /* set tx mode */
    _wxpin(tx_pin, bit_mode);   /* set bit period */
    _pinl(tx_pin);              /* enable smart pin */
    
    /* Configure RX pin (input) */
    _pinf(rx_pin);              /* disable the pin */
    _wrpin(rx_pin, RX_MODE);    /* set rx mode */
    _wxpin(rx_pin, bit_mode);   /* set bit period */
    _pinl(rx_pin);              /* enable smart pin */
    
    /* Wait for pins to stabilize */
    _waitms(10);
}

/*
 * Send a single character via TX smart pin
 * Blocks until the character is transmitted
 */
void p2_smartserial_tx(int ch)
{
    unsigned long z;
    unsigned long wait_count = 0;
    
    _wypin(tx_pin, ch);
    
    /* Match SimpleSerial.spin2: wait until pinr becomes nonzero. */
    do {
        z = _pinr(tx_pin);
        wait_count++;
    } while (z == 0 && wait_count < MAX_WAIT_LOOPS);
}

/*
 * Receive a single character via RX smart pin
 * Blocks until a character is available
 */
int p2_smartserial_rx(void)
{
    unsigned long z;
    unsigned long wait_count = 0;
    
    /* Wait for character to arrive (pinr returns nonzero when data available) */
    do {
        z = _pinr(rx_pin);
        wait_count++;
    } while (z == 0 && wait_count < MAX_WAIT_LOOPS);
    
    /* Consume the character (upper 8 bits contain the actual byte) */
    z = _rdpin(rx_pin);
    return (z >> 24) & 0xFF;
}

/*
 * Check if a character is available without blocking
 * Returns the character if available, or -1 if none
 */
int p2_smartserial_rxcheck(void)
{
    unsigned long z;
    
    z = _pinr(rx_pin);
    if (z) {
        z = _rdpin(rx_pin);
        return (z >> 24) & 0xFF;
    }
    return -1;
}

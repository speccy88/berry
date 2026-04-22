#ifndef P2_SMARTSERIAL_H
#define P2_SMARTSERIAL_H

/*
 * P2 Smart Pin Serial Driver - Header
 */

void p2_smartserial_init(int rxpin, int txpin, int baud);
void p2_smartserial_tx(int ch);
int p2_smartserial_rx(void);
int p2_smartserial_rxcheck(void);

#endif

#ifndef BERRY_PORT_P2_H
#define BERRY_PORT_P2_H

#include "berry.h"

void p2_serial_init(void);
void p2_serial_puts(const char *s);
char *p2_readline(const char *prompt);
void p2_freeline(char *line);
void p2_clear_exit_request(void);
int p2_take_exit_request(void);
void p2_check_interrupt(bvm *vm);
void p2_check_interrupt_now(bvm *vm);

#endif

#ifndef BERRY_PORT_P2_H
#define BERRY_PORT_P2_H

void p2_serial_init(void);
void p2_serial_puts(const char *s);
char *p2_readline(const char *prompt);
void p2_freeline(char *line);

#endif

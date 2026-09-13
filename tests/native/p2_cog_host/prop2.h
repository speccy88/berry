/* Host-only P2 registry-lock seam. Never used by target builds. */
#ifndef TEST_P2_COG_PROP2_H
#define TEST_P2_COG_PROP2_H
int _locknew(void);
int _locktry(int lock);
void _lockrel(int lock);
#endif

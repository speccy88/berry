/* Host-only lock intrinsic seam: assert correct intervals; no hardware proof. */
#include <assert.h>
#include "prop2.h"
int test_registry_locked;
int test_lock_failure;
int _locknew(void) { return test_lock_failure ? -1 : 7; }
int _locktry(int lock) { assert(lock == 7); assert(!test_registry_locked); test_registry_locked = 1; return 1; }
void _lockrel(int lock) { assert(lock == 7); assert(test_registry_locked); test_registry_locked = 0; }

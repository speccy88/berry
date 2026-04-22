/* Split from src/be_class.c to avoid a Windows FlexC crash near EOF. */
#include "be_class.h"
#include "be_map.h"
#include "be_string.h"
#include "be_gc.h"

bbool be_class_setmember(bvm *vm, bclass *o, bstring *name, bvalue *src)
{
    bvalue v;
    be_assert(name != NULL);
    if (!gc_isconst(o)) {
        bclass *obj = be_class_member(vm, o, name, &v);
        if (obj && !var_istype(&v, MT_VARIABLE)) {
            be_map_insertstr(vm, obj->members, name, src);
            return btrue;
        }
    }
    return bfalse;
}

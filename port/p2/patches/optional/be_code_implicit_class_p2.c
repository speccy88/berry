/* Split from src/be_code.c to avoid a Windows FlexC crash near EOF. */
#include "be_code.h"
#include "be_lexer.h"
#include "be_var.h"
#include "be_vector.h"

static int be_code_newconst_p2(bfuncinfo *finfo, bvalue *k)
{
    int idx = be_vector_count(&finfo->kvec);
    be_vector_push_c(finfo->lexer->vm, &finfo->kvec, k);
    finfo->proto->ktab = be_vector_data(&finfo->kvec);
    finfo->proto->nconst = be_vector_capacity(&finfo->kvec);
    if (k == NULL) {
        var_setnil(&finfo->proto->ktab[idx]);
    }
    return idx;
}

void be_code_implicit_class(bfuncinfo *finfo, bexpdesc *e, bclass *c)
{
    bvalue k = {0};
    k.type = BE_CLASS;
    k.v.p = c;
    e->type = ETCONST;
    e->v.idx = setK(be_code_newconst_p2(finfo, &k));
}

/*
 * z3_ffi.c — All FFI glue for lean-z3.
 *
 * Each opaque Lean type is backed by a lean_external_class with
 * a finalizer (and optional foreach for GC traversal).
 *
 * ABI note (Lean 4.28+):
 *   BaseIO α = ST IO.RealWorld α. The Void world token is optimized
 *   away by the compiler, so BaseIO functions do NOT receive or return
 *   a world token. They take their normal arguments and return the
 *   value directly — no lean_io_result_mk_ok wrapping.
 *
 *   Env α = BaseIO (Except Error α), so Env functions also have no
 *   world token. They return Except Error α via the Lean-exported
 *   z3_env_pure / z3_env_throw_string helpers (which also take no world).
 */

#include <lean/lean.h>
#include <stdlib.h>
#include "z3_lean.h"

/* ── External classes (one per opaque type) ─────────────────────────────── */

static lean_external_class *g_Context_class = NULL;
static lean_external_class *g_Srt_class     = NULL;
static lean_external_class *g_Ast_class     = NULL;
static lean_external_class *g_FuncDecl_class = NULL;
static lean_external_class *g_Params_class  = NULL;
static lean_external_class *g_Solver_class  = NULL;
static lean_external_class *g_Model_class   = NULL;
static lean_external_class *g_Constructor_class = NULL;
static lean_external_class *g_OnClauseHandle_class = NULL;

/* ── Finalizers ─────────────────────────────────────────────────────────── */

static void Context_finalize(void *p) {
  Z3Ctx *c = (Z3Ctx *)p;
  Z3_del_context(c->ctx);
  free(c);
}

static void Srt_finalize(void *p) {
  Z3SortWrapper *s = (Z3SortWrapper *)p;
  Z3_dec_ref(s->ctx, (Z3_ast)s->sort);
  lean_dec(s->ctx_obj);
  free(s);
}

static void Ast_finalize(void *p) {
  Z3AstWrapper *a = (Z3AstWrapper *)p;
  Z3_dec_ref(a->ctx, a->ast);
  lean_dec(a->ctx_obj);
  free(a);
}

static void FuncDecl_finalize(void *p) {
  Z3FuncDeclWrapper *f = (Z3FuncDeclWrapper *)p;
  Z3_dec_ref(f->ctx, (Z3_ast)f->func_decl);
  lean_dec(f->ctx_obj);
  free(f);
}

static void Params_finalize(void *p) {
  Z3ParamsWrapper *pw = (Z3ParamsWrapper *)p;
  Z3_params_dec_ref(pw->ctx, pw->params);
  lean_dec(pw->ctx_obj);
  free(pw);
}

static void Solver_finalize(void *p) {
  Z3SolverWrapper *s = (Z3SolverWrapper *)p;
  Z3_solver_dec_ref(s->ctx, s->solver);
  lean_dec(s->ctx_obj);
  free(s);
}

static void Model_finalize(void *p) {
  Z3ModelWrapper *m = (Z3ModelWrapper *)p;
  Z3_model_dec_ref(m->ctx, m->model);
  lean_dec(m->ctx_obj);
  free(m);
}

static void Constructor_finalize(void *p) {
  Z3ConstructorWrapper *c = (Z3ConstructorWrapper *)p;
  Z3_del_constructor(c->ctx, c->constructor);
  lean_dec(c->ctx_obj);
  free(c);
}

static void OnClauseHandle_finalize(void *p) {
  Z3OnClauseHandleData *h = (Z3OnClauseHandleData *)p;
  lean_dec(h->events);
  lean_dec(h->solver_obj);
  lean_dec(h->ctx_obj);
  free(h);
}

/* ── Foreach (GC traversal — noop, ctx_obj prevented from GC by lean_inc) ─ */

static void noop_foreach(void *p, b_lean_obj_arg fn) {
  (void)p; (void)fn;
}

/* ── Class initialization ──────────────────────────────────────────────── */

static lean_external_class *ensure_class(lean_external_class **cls,
                                          void (*fin)(void *),
                                          void (*fe)(void *, b_lean_obj_arg)) {
  if (*cls == NULL) {
    *cls = lean_register_external_class(fin, fe);
  }
  return *cls;
}

static inline lean_external_class *get_Context_class(void) {
  return ensure_class(&g_Context_class, Context_finalize, noop_foreach);
}
static inline lean_external_class *get_Srt_class(void) {
  return ensure_class(&g_Srt_class, Srt_finalize, noop_foreach);
}
static inline lean_external_class *get_Ast_class(void) {
  return ensure_class(&g_Ast_class, Ast_finalize, noop_foreach);
}
static inline lean_external_class *get_FuncDecl_class(void) {
  return ensure_class(&g_FuncDecl_class, FuncDecl_finalize, noop_foreach);
}
static inline lean_external_class *get_Params_class(void) {
  return ensure_class(&g_Params_class, Params_finalize, noop_foreach);
}
static inline lean_external_class *get_Solver_class(void) {
  return ensure_class(&g_Solver_class, Solver_finalize, noop_foreach);
}
static inline lean_external_class *get_Model_class(void) {
  return ensure_class(&g_Model_class, Model_finalize, noop_foreach);
}
static inline lean_external_class *get_Constructor_class(void) {
  return ensure_class(&g_Constructor_class, Constructor_finalize, noop_foreach);
}
static inline lean_external_class *get_OnClauseHandle_class(void) {
  return ensure_class(&g_OnClauseHandle_class, OnClauseHandle_finalize, noop_foreach);
}

/* ── Wrap / unwrap helpers ─────────────────────────────────────────────── */

static inline Z3Ctx *to_Context(b_lean_obj_arg o) {
  return (Z3Ctx *)lean_get_external_data(o);
}
static inline Z3SortWrapper *to_Srt(b_lean_obj_arg o) {
  return (Z3SortWrapper *)lean_get_external_data(o);
}
static inline Z3AstWrapper *to_Ast(b_lean_obj_arg o) {
  return (Z3AstWrapper *)lean_get_external_data(o);
}
static inline Z3FuncDeclWrapper *to_FuncDecl(b_lean_obj_arg o) {
  return (Z3FuncDeclWrapper *)lean_get_external_data(o);
}
static inline Z3ParamsWrapper *to_Params(b_lean_obj_arg o) {
  return (Z3ParamsWrapper *)lean_get_external_data(o);
}
static inline Z3SolverWrapper *to_Solver(b_lean_obj_arg o) {
  return (Z3SolverWrapper *)lean_get_external_data(o);
}
static inline Z3ModelWrapper *to_Model(b_lean_obj_arg o) {
  return (Z3ModelWrapper *)lean_get_external_data(o);
}
static inline Z3ConstructorWrapper *to_Constructor(b_lean_obj_arg o) {
  return (Z3ConstructorWrapper *)lean_get_external_data(o);
}
static inline Z3OnClauseHandleData *to_OnClauseHandle(b_lean_obj_arg o) {
  return (Z3OnClauseHandleData *)lean_get_external_data(o);
}

static inline lean_obj_res mk_Context(Z3Ctx *p) {
  return lean_alloc_external(get_Context_class(), p);
}
static inline lean_obj_res mk_Srt(Z3SortWrapper *p) {
  return lean_alloc_external(get_Srt_class(), p);
}
static inline lean_obj_res mk_Ast(Z3AstWrapper *p) {
  return lean_alloc_external(get_Ast_class(), p);
}
static inline lean_obj_res mk_FuncDecl(Z3FuncDeclWrapper *p) {
  return lean_alloc_external(get_FuncDecl_class(), p);
}
static inline lean_obj_res mk_Params(Z3ParamsWrapper *p) {
  return lean_alloc_external(get_Params_class(), p);
}
static inline lean_obj_res mk_Solver(Z3SolverWrapper *p) {
  return lean_alloc_external(get_Solver_class(), p);
}
static inline lean_obj_res mk_Model(Z3ModelWrapper *p) {
  return lean_alloc_external(get_Model_class(), p);
}
static inline lean_obj_res mk_Constructor(Z3ConstructorWrapper *p) {
  return lean_alloc_external(get_Constructor_class(), p);
}
static inline lean_obj_res mk_OnClauseHandle(Z3OnClauseHandleData *p) {
  return lean_alloc_external(get_OnClauseHandle_class(), p);
}

/* ── Common wrap patterns ──────────────────────────────────────────────── */

static inline lean_obj_res z3_wrap_ast(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_ast ast) {
  Z3_inc_ref(raw_ctx, ast);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->ast = ast;
  return mk_Ast(w);
}

static inline lean_obj_res z3_wrap_sort(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_sort sort) {
  Z3_inc_ref(raw_ctx, (Z3_ast)sort);
  Z3SortWrapper *w = (Z3SortWrapper *)malloc(sizeof(Z3SortWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->sort = sort;
  return mk_Srt(w);
}

static inline lean_obj_res z3_wrap_func_decl(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_func_decl fd) {
  Z3_inc_ref(raw_ctx, (Z3_ast)fd);
  Z3FuncDeclWrapper *w = (Z3FuncDeclWrapper *)malloc(sizeof(Z3FuncDeclWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->func_decl = fd;
  return mk_FuncDecl(w);
}

/* ══════════════════════════════════════════════════════════════════════════
 * Env-returning functions (Env α = BaseIO (Except Error α))
 *
 * No world token — return Except Error α via z3_env_val / z3_env_error.
 * ══════════════════════════════════════════════════════════════════════════ */

/* ── Context operations ────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Context_new(void) {
  Z3_config cfg = Z3_mk_config();
  Z3_context ctx = Z3_mk_context_rc(cfg);
  Z3_del_config(cfg);
  Z3Ctx *c = (Z3Ctx *)malloc(sizeof(Z3Ctx));
  c->ctx = ctx;
  return z3_env_val(mk_Context(c));
}

LEAN_EXPORT lean_obj_res lean_z3_Context_newWithProofs(void) {
  Z3_config cfg = Z3_mk_config();
  Z3_set_param_value(cfg, "proof", "true");
  Z3_context ctx = Z3_mk_context_rc(cfg);
  Z3_del_config(cfg);
  Z3Ctx *c = (Z3Ctx *)malloc(sizeof(Z3Ctx));
  c->ctx = ctx;
  return z3_env_val(mk_Context(c));
}

/* ── Sort constructors (pure — no world token) ─────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkBool(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_bool_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkInt(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_int_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkReal(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_real_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkBv(b_lean_obj_arg ctx, uint32_t size) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_bv_sort(c->ctx, size));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkUninterpreted(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_uninterpreted_sort(c->ctx, sym));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkArray(b_lean_obj_arg ctx, b_lean_obj_arg domain, b_lean_obj_arg range) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *d = to_Srt(domain);
  Z3SortWrapper *r = to_Srt(range);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_array_sort(c->ctx, d->sort, r->sort));
}

/* ── Sort inspection (pure) ────────────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_Srt_getKindRaw(b_lean_obj_arg s) {
  Z3SortWrapper *w = to_Srt(s);
  return (uint32_t)Z3_get_sort_kind(w->ctx, w->sort);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getName(b_lean_obj_arg s) {
  Z3SortWrapper *w = to_Srt(s);
  Z3_symbol sym = Z3_get_sort_name(w->ctx, w->sort);
  return lean_mk_string(Z3_get_symbol_string(w->ctx, sym));
}

LEAN_EXPORT uint32_t lean_z3_Srt_getBvSize(b_lean_obj_arg s) {
  Z3SortWrapper *w = to_Srt(s);
  return Z3_get_bv_sort_size(w->ctx, w->sort);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_toString(b_lean_obj_arg s) {
  Z3SortWrapper *w = to_Srt(s);
  return lean_mk_string(Z3_sort_to_string(w->ctx, w->sort));
}

/* ── Term constructors (pure) ──────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkBool(b_lean_obj_arg ctx, uint8_t val) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast a = val ? Z3_mk_true(c->ctx) : Z3_mk_false(c->ctx);
  return z3_wrap_ast(ctx, c->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkNumeral(b_lean_obj_arg ctx, b_lean_obj_arg val, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  Z3_ast a = Z3_mk_numeral(c->ctx, lean_string_cstr(val), s->sort);
  return z3_wrap_ast(ctx, c->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkIntConst(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_sort int_sort = Z3_mk_int_sort(c->ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, int_sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkBoolConst(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_sort bool_sort = Z3_mk_bool_sort(c->ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, bool_sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkConst(b_lean_obj_arg ctx, b_lean_obj_arg name, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, s->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkBvConst(b_lean_obj_arg ctx, b_lean_obj_arg name, uint32_t size) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_sort bv_sort = Z3_mk_bv_sort(c->ctx, size);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, bv_sort));
}

/* ── Boolean operations (pure) ─────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_not(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *aw = to_Ast(a);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_not(c->ctx, aw->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_and(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast args[2] = { to_Ast(a)->ast, to_Ast(b)->ast };
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_and(c->ctx, 2, args));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_or(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast args[2] = { to_Ast(a)->ast, to_Ast(b)->ast };
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_or(c->ctx, 2, args));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_implies(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_implies(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_eq(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_eq(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_ite(b_lean_obj_arg ctx, b_lean_obj_arg cond, b_lean_obj_arg t, b_lean_obj_arg e) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_ite(c->ctx, to_Ast(cond)->ast, to_Ast(t)->ast, to_Ast(e)->ast));
}

/* ── Arithmetic operations (pure) ──────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_add(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast args[2] = { to_Ast(a)->ast, to_Ast(b)->ast };
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_add(c->ctx, 2, args));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_sub(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast args[2] = { to_Ast(a)->ast, to_Ast(b)->ast };
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_sub(c->ctx, 2, args));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mul(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast args[2] = { to_Ast(a)->ast, to_Ast(b)->ast };
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_mul(c->ctx, 2, args));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_lt(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_lt(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_le(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_le(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_gt(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_gt(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_ge(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_ge(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_distinct(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast *arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
  for (unsigned i = 0; i < n; i++) {
    arr[i] = to_Ast(lean_array_get_core(args, i))->ast;
  }
  Z3_ast result = Z3_mk_distinct(c->ctx, n, arr);
  free(arr);
  return z3_wrap_ast(ctx, c->ctx, result);
}

/* ── Array operations (pure) ───────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_select(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg i) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_select(c->ctx, to_Ast(a)->ast, to_Ast(i)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_store(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg i, b_lean_obj_arg v) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_store(c->ctx, to_Ast(a)->ast, to_Ast(i)->ast, to_Ast(v)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_constArray(b_lean_obj_arg ctx, b_lean_obj_arg domain, b_lean_obj_arg v) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *d = to_Srt(domain);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_const_array(c->ctx, d->sort, to_Ast(v)->ast));
}

/* ── Term inspection (pure) ────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_getSort(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return z3_wrap_sort(aw->ctx_obj, aw->ctx, Z3_get_sort(aw->ctx, aw->ast));
}

LEAN_EXPORT uint32_t lean_z3_Ast_getAstKindRaw(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return (uint32_t)Z3_get_ast_kind(aw->ctx, aw->ast);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getNumArgs(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_app_num_args(aw->ctx, Z3_to_app(aw->ctx, aw->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getArg(b_lean_obj_arg a, uint32_t i) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_app app = Z3_to_app(aw->ctx, aw->ast);
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, Z3_get_app_arg(aw->ctx, app, i));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getFuncDecl(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_app app = Z3_to_app(aw->ctx, aw->ast);
  return z3_wrap_func_decl(aw->ctx_obj, aw->ctx, Z3_get_app_decl(aw->ctx, app));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralString(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return lean_mk_string(Z3_get_numeral_string(aw->ctx, aw->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_toString(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return lean_mk_string(Z3_ast_to_string(aw->ctx, aw->ast));
}

/* ── FuncDecl operations (pure) ────────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_FuncDecl_getDeclKindRaw(b_lean_obj_arg fd) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  return (uint32_t)Z3_get_decl_kind(w->ctx, w->func_decl);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_getName(b_lean_obj_arg fd) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  Z3_symbol sym = Z3_get_decl_name(w->ctx, w->func_decl);
  return lean_mk_string(Z3_get_symbol_string(w->ctx, sym));
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_toString(b_lean_obj_arg fd) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  return lean_mk_string(Z3_func_decl_to_string(w->ctx, w->func_decl));
}

/* ══════════════════════════════════════════════════════════════════════════
 * BaseIO-returning functions
 *
 * No world token in Lean 4.28+. Return the value directly.
 * ══════════════════════════════════════════════════════════════════════════ */

/* ── Params operations ─────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Params_new(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_params p = Z3_mk_params(c->ctx);
  Z3_params_inc_ref(c->ctx, p);
  Z3ParamsWrapper *w = (Z3ParamsWrapper *)malloc(sizeof(Z3ParamsWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = c->ctx;
  w->params = p;
  return mk_Params(w);
}

LEAN_EXPORT lean_obj_res lean_z3_Params_setBool(b_lean_obj_arg p, b_lean_obj_arg name, uint8_t val) {
  Z3ParamsWrapper *w = to_Params(p);
  Z3_symbol sym = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  Z3_params_set_bool(w->ctx, w->params, sym, val);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Params_setUInt(b_lean_obj_arg p, b_lean_obj_arg name, uint32_t val) {
  Z3ParamsWrapper *w = to_Params(p);
  Z3_symbol sym = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  Z3_params_set_uint(w->ctx, w->params, sym, val);
  return lean_box(0);
}

/* ── Solver operations ─────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Solver_new(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_solver s = Z3_mk_solver(c->ctx);
  Z3_solver_inc_ref(c->ctx, s);
  Z3SolverWrapper *w = (Z3SolverWrapper *)malloc(sizeof(Z3SolverWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = c->ctx;
  w->solver = s;
  return mk_Solver(w);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_setParams(b_lean_obj_arg s, b_lean_obj_arg p) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3ParamsWrapper *pw = to_Params(p);
  Z3_solver_set_params(sw->ctx, sw->solver, pw->params);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_assert(b_lean_obj_arg s, b_lean_obj_arg a) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3AstWrapper *aw = to_Ast(a);
  Z3_solver_assert(sw->ctx, sw->solver, aw->ast);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_push(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_push(sw->ctx, sw->solver);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_pop(b_lean_obj_arg s, uint32_t n) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_pop(sw->ctx, sw->solver, n);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_reset(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_reset(sw->ctx, sw->solver);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Solver_checkSatRaw(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  return (uint32_t)(Z3_solver_check(sw->ctx, sw->solver) + 1);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getReasonUnknown(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  return lean_mk_string(Z3_solver_get_reason_unknown(sw->ctx, sw->solver));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getProof(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_ast proof = Z3_solver_get_proof(sw->ctx, sw->solver);
  if (proof == NULL) {
    return z3_env_error("no proof available");
  }
  Z3_inc_ref(sw->ctx, proof);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  lean_inc(sw->ctx_obj);
  w->ctx_obj = sw->ctx_obj;
  w->ctx = sw->ctx;
  w->ast = proof;
  return z3_env_val(mk_Ast(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_toString(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  return lean_mk_string(Z3_solver_to_string(sw->ctx, sw->solver));
}

/* ── Model operations ──────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Solver_getModel(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_model m = Z3_solver_get_model(sw->ctx, sw->solver);
  if (m == NULL) {
    return z3_env_error("no model available");
  }
  Z3_model_inc_ref(sw->ctx, m);
  Z3ModelWrapper *w = (Z3ModelWrapper *)malloc(sizeof(Z3ModelWrapper));
  lean_inc(sw->ctx_obj);
  w->ctx_obj = sw->ctx_obj;
  w->ctx = sw->ctx;
  w->model = m;
  return z3_env_val(mk_Model(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Model_eval(b_lean_obj_arg m, b_lean_obj_arg a, uint8_t completion) {
  Z3ModelWrapper *mw = to_Model(m);
  Z3AstWrapper *aw = to_Ast(a);
  Z3_ast result;
  bool ok = Z3_model_eval(mw->ctx, mw->model, aw->ast, completion, &result);
  if (!ok) {
    return z3_env_error("model evaluation failed");
  }
  Z3_inc_ref(mw->ctx, result);
  Z3AstWrapper *rw = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  lean_inc(mw->ctx_obj);
  rw->ctx_obj = mw->ctx_obj;
  rw->ctx = mw->ctx;
  rw->ast = result;
  return z3_env_val(mk_Ast(rw));
}

LEAN_EXPORT uint32_t lean_z3_Model_getNumConsts(b_lean_obj_arg m) {
  Z3ModelWrapper *mw = to_Model(m);
  return Z3_model_get_num_consts(mw->ctx, mw->model);
}

LEAN_EXPORT lean_obj_res lean_z3_Model_getConstDecl(b_lean_obj_arg m, uint32_t i) {
  Z3ModelWrapper *mw = to_Model(m);
  return z3_wrap_func_decl(mw->ctx_obj, mw->ctx, Z3_model_get_const_decl(mw->ctx, mw->model, i));
}

LEAN_EXPORT lean_obj_res lean_z3_Model_getConstInterp(b_lean_obj_arg m, b_lean_obj_arg fd) {
  Z3ModelWrapper *mw = to_Model(m);
  Z3FuncDeclWrapper *fdw = to_FuncDecl(fd);
  Z3_ast a = Z3_model_get_const_interp(mw->ctx, mw->model, fdw->func_decl);
  if (a == NULL) {
    return z3_env_error("no interpretation for constant");
  }
  Z3_inc_ref(mw->ctx, a);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  lean_inc(mw->ctx_obj);
  w->ctx_obj = mw->ctx_obj;
  w->ctx = mw->ctx;
  w->ast = a;
  return z3_env_val(mk_Ast(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Model_toString(b_lean_obj_arg m) {
  Z3ModelWrapper *mw = to_Model(m);
  return lean_mk_string(Z3_model_to_string(mw->ctx, mw->model));
}

/* ── SMT-LIB parsing ──────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Context_parseSMTLIB2String(b_lean_obj_arg ctx, b_lean_obj_arg str) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast_vector vec = Z3_parse_smtlib2_string(c->ctx, lean_string_cstr(str), 0, NULL, NULL, 0, NULL, NULL);
  if (vec == NULL) {
    return z3_env_error("SMT-LIB2 parse failed");
  }
  unsigned n = Z3_ast_vector_size(c->ctx, vec);
  if (n == 0) {
    return z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_mk_true(c->ctx)));
  } else if (n == 1) {
    return z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_ast_vector_get(c->ctx, vec, 0)));
  } else {
    Z3_ast *args = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    for (unsigned i = 0; i < n; i++) {
      args[i] = Z3_ast_vector_get(c->ctx, vec, i);
    }
    Z3_ast conj = Z3_mk_and(c->ctx, n, args);
    free(args);
    return z3_env_val(z3_wrap_ast(ctx, c->ctx, conj));
  }
}

/* ── Quantifiers ───────────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkBound(b_lean_obj_arg ctx, uint32_t idx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *sw = to_Srt(s);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bound(c->ctx, idx, sw->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkForall(b_lean_obj_arg ctx, b_lean_obj_arg sorts,
    b_lean_obj_arg names, b_lean_obj_arg body, uint32_t weight) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned n = lean_array_size(sorts);
  if (n != lean_array_size(names)) {
    return z3_env_error("sorts and names must have the same length");
  }
  if (n == 0) {
    return z3_env_error("quantifier must bind at least one variable");
  }
  Z3_sort *z3_sorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
  Z3_symbol *z3_names = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  for (unsigned i = 0; i < n; i++) {
    Z3SortWrapper *si = to_Srt(lean_array_get_core(sorts, i));
    z3_sorts[i] = si->sort;
    z3_names[i] = Z3_mk_string_symbol(c->ctx,
      lean_string_cstr(lean_array_get_core(names, i)));
  }
  Z3_ast q = Z3_mk_forall(c->ctx, weight, 0, NULL, n, z3_sorts, z3_names, bw->ast);
  free(z3_sorts);
  free(z3_names);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, q));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkExists(b_lean_obj_arg ctx, b_lean_obj_arg sorts,
    b_lean_obj_arg names, b_lean_obj_arg body, uint32_t weight) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned n = lean_array_size(sorts);
  if (n != lean_array_size(names)) {
    return z3_env_error("sorts and names must have the same length");
  }
  if (n == 0) {
    return z3_env_error("quantifier must bind at least one variable");
  }
  Z3_sort *z3_sorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
  Z3_symbol *z3_names = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  for (unsigned i = 0; i < n; i++) {
    Z3SortWrapper *si = to_Srt(lean_array_get_core(sorts, i));
    z3_sorts[i] = si->sort;
    z3_names[i] = Z3_mk_string_symbol(c->ctx,
      lean_string_cstr(lean_array_get_core(names, i)));
  }
  Z3_ast q = Z3_mk_exists(c->ctx, weight, 0, NULL, n, z3_sorts, z3_names, bw->ast);
  free(z3_sorts);
  free(z3_names);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, q));
}

/* ── Datatype operations ───────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Constructor_mk(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg recognizer, b_lean_obj_arg fieldNames,
    b_lean_obj_arg fieldSorts, b_lean_obj_arg fieldSortRefs) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(fieldNames);
  if (n != lean_array_size(fieldSorts) || n != lean_array_size(fieldSortRefs)) {
    return z3_env_error("fieldNames, fieldSorts, fieldSortRefs must have same length");
  }
  Z3_symbol z3_name = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_symbol z3_rec = Z3_mk_string_symbol(c->ctx, lean_string_cstr(recognizer));
  Z3_symbol *z3_fnames = NULL;
  Z3_sort *z3_fsorts = NULL;
  unsigned *z3_frefs = NULL;
  if (n > 0) {
    z3_fnames = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
    z3_fsorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
    z3_frefs = (unsigned *)malloc(n * sizeof(unsigned));
    for (unsigned i = 0; i < n; i++) {
      z3_fnames[i] = Z3_mk_string_symbol(c->ctx,
        lean_string_cstr(lean_array_get_core(fieldNames, i)));
      Z3SortWrapper *si = to_Srt(lean_array_get_core(fieldSorts, i));
      z3_fsorts[i] = si->sort;
      z3_frefs[i] = lean_unbox(lean_array_get_core(fieldSortRefs, i));
    }
  }
  Z3_constructor con = Z3_mk_constructor(c->ctx, z3_name, z3_rec, n,
                                          z3_fnames, z3_fsorts, z3_frefs);
  free(z3_fnames); free(z3_fsorts); free(z3_frefs);
  Z3ConstructorWrapper *w = (Z3ConstructorWrapper *)malloc(sizeof(Z3ConstructorWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = c->ctx;
  w->constructor = con;
  return z3_env_val(mk_Constructor(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkDatatype(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg constructors) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(constructors);
  if (n == 0) {
    return z3_env_error("datatype must have at least one constructor");
  }
  Z3_constructor *z3_cons = (Z3_constructor *)malloc(n * sizeof(Z3_constructor));
  for (unsigned i = 0; i < n; i++) {
    Z3ConstructorWrapper *cw = to_Constructor(lean_array_get_core(constructors, i));
    z3_cons[i] = cw->constructor;
  }
  Z3_sort dt = Z3_mk_datatype(c->ctx, Z3_mk_string_symbol(c->ctx, lean_string_cstr(name)),
                                n, z3_cons);
  /* Z3_mk_datatype updates z3_cons[i] in place — write back to wrappers */
  for (unsigned i = 0; i < n; i++) {
    Z3ConstructorWrapper *cw = to_Constructor(lean_array_get_core(constructors, i));
    cw->constructor = z3_cons[i];
  }
  free(z3_cons);
  return z3_env_val(z3_wrap_sort(ctx, c->ctx, dt));
}

LEAN_EXPORT lean_obj_res lean_z3_Constructor_query(b_lean_obj_arg con, uint32_t numFields) {
  Z3ConstructorWrapper *cw = to_Constructor(con);
  Z3_func_decl con_decl, tester_decl;
  Z3_func_decl *accessors = NULL;
  unsigned n = numFields;
  if (n > 0) {
    accessors = (Z3_func_decl *)malloc(n * sizeof(Z3_func_decl));
  }
  Z3_query_constructor(cw->ctx, cw->constructor, n, &con_decl, &tester_decl, accessors);

  lean_object *con_lean = z3_wrap_func_decl(cw->ctx_obj, cw->ctx, con_decl);
  lean_object *tester_lean = z3_wrap_func_decl(cw->ctx_obj, cw->ctx, tester_decl);

  lean_object *acc_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    lean_object *acc = z3_wrap_func_decl(cw->ctx_obj, cw->ctx, accessors[i]);
    acc_arr = lean_array_push(acc_arr, acc);
  }
  free(accessors);

  /* Build the triple: (con_lean, tester_lean, acc_arr) */
  lean_object *inner = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(inner, 0, tester_lean);
  lean_ctor_set(inner, 1, acc_arr);
  lean_object *triple = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(triple, 0, con_lean);
  lean_ctor_set(triple, 1, inner);

  return z3_env_val(triple);
}

/* ══════════════════════════════════════════════════════════════════════════
 * On-clause callback
 * ══════════════════════════════════════════════════════════════════════════ */

/*
 * C callback invoked by Z3 when clauses are asserted, inferred, or deleted.
 * Wraps the Z3 objects into Lean objects and appends a ClauseEvent to the
 * handle's events array.
 */
static void on_clause_callback(void *user_ctx, Z3_ast proof_hint,
                                unsigned n, unsigned const *deps,
                                Z3_ast_vector literals) {
  Z3OnClauseHandleData *h = (Z3OnClauseHandleData *)user_ctx;

  /* Wrap proof_hint as Lean Ast */
  lean_object *proof_lean = z3_wrap_ast(h->ctx_obj, h->ctx, proof_hint);

  /* Build Array UInt32 from deps */
  lean_object *deps_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    deps_arr = lean_array_push(deps_arr, lean_box_uint32(deps[i]));
  }

  /* Build Array Ast from literals vector */
  unsigned lit_count = Z3_ast_vector_size(h->ctx, literals);
  lean_object *lits_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < lit_count; i++) {
    Z3_ast lit = Z3_ast_vector_get(h->ctx, literals, i);
    lits_arr = lean_array_push(lits_arr, z3_wrap_ast(h->ctx_obj, h->ctx, lit));
  }

  /* Build ClauseEvent structure: ⟨proofHint, deps, literals⟩ */
  lean_object *event = lean_alloc_ctor(0, 3, 0);
  lean_ctor_set(event, 0, proof_lean);
  lean_ctor_set(event, 1, deps_arr);
  lean_ctor_set(event, 2, lits_arr);

  /* Append to events array (mutates in place when refcount == 1) */
  h->events = lean_array_push(h->events, event);
}

/*
 * Register an on-clause collector on the solver.
 * Returns an OnClauseHandle that accumulates clause events during checkSat.
 */
LEAN_EXPORT lean_obj_res lean_z3_Solver_registerOnClause(b_lean_obj_arg solver_obj) {
  Z3SolverWrapper *sw = to_Solver(solver_obj);

  Z3OnClauseHandleData *h = (Z3OnClauseHandleData *)malloc(sizeof(Z3OnClauseHandleData));
  lean_inc(solver_obj);
  h->solver_obj = solver_obj;
  lean_inc(sw->ctx_obj);
  h->ctx_obj = sw->ctx_obj;
  h->ctx = sw->ctx;
  h->events = lean_mk_empty_array();

  Z3_solver_register_on_clause(sw->ctx, sw->solver, (void *)h, on_clause_callback);

  return mk_OnClauseHandle(h);
}

/*
 * Retrieve all collected clause events and clear the buffer.
 */
LEAN_EXPORT lean_obj_res lean_z3_OnClauseHandle_getClauses(b_lean_obj_arg handle_obj) {
  Z3OnClauseHandleData *h = to_OnClauseHandle(handle_obj);
  lean_object *result = h->events;
  lean_inc(result);
  return result;
}

/*
 * Clear the collected clause events.
 */
LEAN_EXPORT lean_obj_res lean_z3_OnClauseHandle_clear(b_lean_obj_arg handle_obj) {
  Z3OnClauseHandleData *h = to_OnClauseHandle(handle_obj);
  lean_dec(h->events);
  h->events = lean_mk_empty_array();
  return lean_box(0);
}

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
static lean_external_class *g_ParamDescrs_class = NULL;
static lean_external_class *g_Optimize_class = NULL;
static lean_external_class *g_Tactic_class = NULL;
static lean_external_class *g_Goal_class = NULL;
static lean_external_class *g_ApplyResult_class = NULL;
static lean_external_class *g_FuncInterp_class = NULL;
static lean_external_class *g_FuncEntry_class = NULL;
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

static void ParamDescrs_finalize(void *p) {
  Z3ParamDescrsWrapper *w = (Z3ParamDescrsWrapper *)p;
  Z3_param_descrs_dec_ref(w->ctx, w->param_descrs);
  lean_dec(w->ctx_obj);
  free(w);
}
static void Tactic_finalize(void *p) {
  Z3TacticWrapper *w = (Z3TacticWrapper *)p;
  Z3_tactic_dec_ref(w->ctx, w->tactic);
  lean_dec(w->ctx_obj);
  free(w);
}

static void Goal_finalize(void *p) {
  Z3GoalWrapper *w = (Z3GoalWrapper *)p;
  Z3_goal_dec_ref(w->ctx, w->goal);
  lean_dec(w->ctx_obj);
  free(w);
}

static void ApplyResult_finalize(void *p) {
  Z3ApplyResultWrapper *w = (Z3ApplyResultWrapper *)p;
  Z3_apply_result_dec_ref(w->ctx, w->apply_result);
  lean_dec(w->ctx_obj);
  free(w);
}

static void Optimize_finalize(void *p) {
  Z3OptimizeWrapper *w = (Z3OptimizeWrapper *)p;
  Z3_optimize_dec_ref(w->ctx, w->optimize);
  lean_dec(w->ctx_obj);
  free(w);
}

static void FuncInterp_finalize(void *p) {
  Z3FuncInterpWrapper *w = (Z3FuncInterpWrapper *)p;
  Z3_func_interp_dec_ref(w->ctx, w->func_interp);
  lean_dec(w->ctx_obj);
  free(w);
}

static void FuncEntry_finalize(void *p) {
  Z3FuncEntryWrapper *w = (Z3FuncEntryWrapper *)p;
  Z3_func_entry_dec_ref(w->ctx, w->func_entry);
  lean_dec(w->ctx_obj);
  free(w);
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
static inline lean_external_class *get_ParamDescrs_class(void) {
  return ensure_class(&g_ParamDescrs_class, ParamDescrs_finalize, noop_foreach);
}
static inline lean_external_class *get_Tactic_class(void) {
  return ensure_class(&g_Tactic_class, Tactic_finalize, noop_foreach);
}
static inline lean_external_class *get_Goal_class(void) {
  return ensure_class(&g_Goal_class, Goal_finalize, noop_foreach);
}
static inline lean_external_class *get_ApplyResult_class(void) {
  return ensure_class(&g_ApplyResult_class, ApplyResult_finalize, noop_foreach);
}
static inline lean_external_class *get_Optimize_class(void) {
  return ensure_class(&g_Optimize_class, Optimize_finalize, noop_foreach);
}
static inline lean_external_class *get_FuncInterp_class(void) {
  return ensure_class(&g_FuncInterp_class, FuncInterp_finalize, noop_foreach);
}
static inline lean_external_class *get_FuncEntry_class(void) {
  return ensure_class(&g_FuncEntry_class, FuncEntry_finalize, noop_foreach);
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
static inline Z3ParamDescrsWrapper *to_ParamDescrs(b_lean_obj_arg o) {
  return (Z3ParamDescrsWrapper *)lean_get_external_data(o);
}
static inline Z3TacticWrapper *to_Tactic(b_lean_obj_arg o) {
  return (Z3TacticWrapper *)lean_get_external_data(o);
}
static inline Z3GoalWrapper *to_Goal(b_lean_obj_arg o) {
  return (Z3GoalWrapper *)lean_get_external_data(o);
}
static inline Z3ApplyResultWrapper *to_ApplyResult(b_lean_obj_arg o) {
  return (Z3ApplyResultWrapper *)lean_get_external_data(o);
}
static inline Z3OptimizeWrapper *to_Optimize(b_lean_obj_arg o) {
  return (Z3OptimizeWrapper *)lean_get_external_data(o);
}
static inline Z3FuncInterpWrapper *to_FuncInterp(b_lean_obj_arg o) {
  return (Z3FuncInterpWrapper *)lean_get_external_data(o);
}
static inline Z3FuncEntryWrapper *to_FuncEntry(b_lean_obj_arg o) {
  return (Z3FuncEntryWrapper *)lean_get_external_data(o);
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
static inline lean_obj_res mk_ParamDescrs(Z3ParamDescrsWrapper *p) {
  return lean_alloc_external(get_ParamDescrs_class(), p);
}
static inline lean_obj_res mk_Tactic(Z3TacticWrapper *p) {
  return lean_alloc_external(get_Tactic_class(), p);
}
static inline lean_obj_res mk_Goal(Z3GoalWrapper *p) {
  return lean_alloc_external(get_Goal_class(), p);
}
static inline lean_obj_res mk_ApplyResult(Z3ApplyResultWrapper *p) {
  return lean_alloc_external(get_ApplyResult_class(), p);
}
static inline lean_obj_res mk_Optimize(Z3OptimizeWrapper *p) {
  return lean_alloc_external(get_Optimize_class(), p);
}
static inline lean_obj_res mk_FuncInterp(Z3FuncInterpWrapper *p) {
  return lean_alloc_external(get_FuncInterp_class(), p);
}
static inline lean_obj_res mk_FuncEntry(Z3FuncEntryWrapper *p) {
  return lean_alloc_external(get_FuncEntry_class(), p);
}
static inline lean_obj_res mk_OnClauseHandle(Z3OnClauseHandleData *p) {
  return lean_alloc_external(get_OnClauseHandle_class(), p);
}

/* ── Common wrap patterns ──────────────────────────────────────────────── */

static inline lean_obj_res z3_wrap_ast(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_ast ast) {
  Z3_inc_ref(raw_ctx, ast);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  if (w == NULL) { Z3_dec_ref(raw_ctx, ast); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->ast = ast;
  return mk_Ast(w);
}

static inline lean_obj_res z3_wrap_sort(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_sort sort) {
  Z3_inc_ref(raw_ctx, (Z3_ast)sort);
  Z3SortWrapper *w = (Z3SortWrapper *)malloc(sizeof(Z3SortWrapper));
  if (w == NULL) { Z3_dec_ref(raw_ctx, (Z3_ast)sort); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->sort = sort;
  return mk_Srt(w);
}

static inline lean_obj_res z3_wrap_func_decl(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_func_decl fd) {
  Z3_inc_ref(raw_ctx, (Z3_ast)fd);
  Z3FuncDeclWrapper *w = (Z3FuncDeclWrapper *)malloc(sizeof(Z3FuncDeclWrapper));
  if (w == NULL) { Z3_dec_ref(raw_ctx, (Z3_ast)fd); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->func_decl = fd;
  return mk_FuncDecl(w);
}

static inline lean_obj_res z3_wrap_param_descrs(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_param_descrs pd) {
  Z3_param_descrs_inc_ref(raw_ctx, pd);
  Z3ParamDescrsWrapper *w = (Z3ParamDescrsWrapper *)malloc(sizeof(Z3ParamDescrsWrapper));
  if (w == NULL) { Z3_param_descrs_dec_ref(raw_ctx, pd); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->param_descrs = pd;
  return mk_ParamDescrs(w);
}

static inline lean_obj_res z3_wrap_func_interp(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_func_interp fi) {
  Z3_func_interp_inc_ref(raw_ctx, fi);
  Z3FuncInterpWrapper *w = (Z3FuncInterpWrapper *)malloc(sizeof(Z3FuncInterpWrapper));
  if (w == NULL) { Z3_func_interp_dec_ref(raw_ctx, fi); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->func_interp = fi;
  return mk_FuncInterp(w);
}

static inline lean_obj_res z3_wrap_func_entry(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_func_entry fe) {
  Z3_func_entry_inc_ref(raw_ctx, fe);
  Z3FuncEntryWrapper *w = (Z3FuncEntryWrapper *)malloc(sizeof(Z3FuncEntryWrapper));
  if (w == NULL) { Z3_func_entry_dec_ref(raw_ctx, fe); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->func_entry = fe;
  return mk_FuncEntry(w);
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
  if (c == NULL) { Z3_del_context(ctx); return z3_env_error("out of memory"); }
  c->ctx = ctx;
  return z3_env_val(mk_Context(c));
}

LEAN_EXPORT lean_obj_res lean_z3_Context_newWithProofs(void) {
  Z3_config cfg = Z3_mk_config();
  Z3_set_param_value(cfg, "proof", "true");
  Z3_context ctx = Z3_mk_context_rc(cfg);
  Z3_del_config(cfg);
  Z3Ctx *c = (Z3Ctx *)malloc(sizeof(Z3Ctx));
  if (c == NULL) { Z3_del_context(ctx); return z3_env_error("out of memory"); }
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
  const char *str = Z3_sort_to_string(w->ctx, w->sort);
  if (str == NULL) { lean_internal_panic("Z3_sort_to_string returned NULL"); }
  return lean_mk_string(str);
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
  if (a == NULL) { lean_internal_panic("Z3_mk_numeral failed: invalid numeral string"); }
  return z3_wrap_ast(ctx, c->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkIntConst(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_sort int_sort = Z3_mk_int_sort(c->ctx);
  Z3_inc_ref(c->ctx, (Z3_ast)int_sort);
  lean_obj_res result = z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, int_sort));
  Z3_dec_ref(c->ctx, (Z3_ast)int_sort);
  return result;
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkBoolConst(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_sort bool_sort = Z3_mk_bool_sort(c->ctx);
  Z3_inc_ref(c->ctx, (Z3_ast)bool_sort);
  lean_obj_res result = z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, bool_sort));
  Z3_dec_ref(c->ctx, (Z3_ast)bool_sort);
  return result;
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
  Z3_inc_ref(c->ctx, (Z3_ast)bv_sort);
  lean_obj_res result = z3_wrap_ast(ctx, c->ctx, Z3_mk_const(c->ctx, sym, bv_sort));
  Z3_dec_ref(c->ctx, (Z3_ast)bv_sort);
  return result;
}

/* ── Numeral constructors (pure) ──────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkInt(b_lean_obj_arg ctx, int32_t v, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_int(c->ctx, (int)v, s->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReal(b_lean_obj_arg ctx, int32_t num, int32_t den) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_real(c->ctx, (int)num, (int)den));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkInt64(b_lean_obj_arg ctx, int64_t v, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_int64(c->ctx, v, s->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkUInt64(b_lean_obj_arg ctx, uint64_t v, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_unsigned_int64(c->ctx, v, s->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkRealVal(b_lean_obj_arg ctx, int64_t num, int64_t den) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_real_int64(c->ctx, num, den));
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

LEAN_EXPORT lean_obj_res lean_z3_Ast_xor(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_xor(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_iff(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_iff(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Z3_get_bool_value returns Z3_lbool: Z3_L_FALSE=-1, Z3_L_UNDEF=0, Z3_L_TRUE=1.
   We shift by +1 to get 0/1/2 matching LBool encoding. */
LEAN_EXPORT uint32_t lean_z3_Ast_getBoolValue(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return (uint32_t)(Z3_get_bool_value(aw->ctx, aw->ast) + 1);
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

LEAN_EXPORT lean_obj_res lean_z3_Ast_div(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_div(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mod(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_mod(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_rem(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_rem(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_power(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_power(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_abs(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_abs(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_unaryMinus(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_unary_minus(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_int2real(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_int2real(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_real2int(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_real2int(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_isInt(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_is_int(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_distinct(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  if (n == 0) { return z3_wrap_ast(ctx, c->ctx, Z3_mk_true(c->ctx)); }
  Z3_ast *arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
  if (arr == NULL) { lean_internal_panic("out of memory"); }
  for (unsigned i = 0; i < n; i++) {
    arr[i] = to_Ast(lean_array_get_core(args, i))->ast;
  }
  Z3_ast result = Z3_mk_distinct(c->ctx, n, arr);
  free(arr);
  return z3_wrap_ast(ctx, c->ctx, result);
}

/* ── Bitvector operations (pure) ────────────────────────────────────────── */

/* Arithmetic */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvneg(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvneg(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvadd(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvadd(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsub(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsub(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvmul(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvmul(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvudiv(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvudiv(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsdiv(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsdiv(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvurem(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvurem(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsrem(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsrem(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Bitwise */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvnot(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvnot(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvand(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvand(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvor(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvor(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvxor(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvxor(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Shifts */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvshl(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvshl(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvlshr(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvlshr(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvashr(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvashr(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Rotation */
LEAN_EXPORT lean_obj_res lean_z3_Ast_rotateLeft(b_lean_obj_arg ctx, b_lean_obj_arg a, uint32_t n) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_rotate_left(c->ctx, n, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_rotateRight(b_lean_obj_arg ctx, b_lean_obj_arg a, uint32_t n) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_rotate_right(c->ctx, n, to_Ast(a)->ast));
}

/* Unsigned comparisons */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvult(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvult(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvule(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvule(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvugt(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvugt(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvuge(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvuge(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Signed comparisons */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvslt(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvslt(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsle(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsle(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsgt(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsgt(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsge(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsge(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* Extract / concat / extend */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bvextract(b_lean_obj_arg ctx, uint32_t high, uint32_t low, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_extract(c->ctx, high, low, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvconcat(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_concat(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvzeroExt(b_lean_obj_arg ctx, uint32_t n, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_zero_ext(c->ctx, n, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsignExt(b_lean_obj_arg ctx, uint32_t n, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_sign_ext(c->ctx, n, to_Ast(a)->ast));
}

/* BV / Int conversion */
LEAN_EXPORT lean_obj_res lean_z3_Ast_bv2int(b_lean_obj_arg ctx, b_lean_obj_arg a, uint8_t isSigned) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bv2int(c->ctx, to_Ast(a)->ast, isSigned));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_int2bv(b_lean_obj_arg ctx, uint32_t n, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_int2bv(c->ctx, n, to_Ast(a)->ast));
}

/* ── Bitvector (remaining ops) ─────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvnand(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvnand(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvnor(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvnor(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvxnor(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvxnor(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsmod(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsmod(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvredand(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvredand(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvredor(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvredor(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvrepeat(b_lean_obj_arg ctx, uint32_t n, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_repeat(c->ctx, n, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvaddNoOverflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b, uint8_t isSigned) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvadd_no_overflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast, isSigned));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvaddNoUnderflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvadd_no_underflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsubNoOverflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsub_no_overflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsubNoUnderflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b, uint8_t isSigned) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsub_no_underflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast, isSigned));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvmulNoOverflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b, uint8_t isSigned) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvmul_no_overflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast, isSigned));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvmulNoUnderflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvmul_no_underflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvsdivNoOverflow(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvsdiv_no_overflow(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_bvnegNoOverflow(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_bvneg_no_overflow(c->ctx, to_Ast(a)->ast));
}

/* ── Pseudo-boolean constraints ────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkAtmost(b_lean_obj_arg ctx, b_lean_obj_arg args, uint32_t k) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_atmost(c->ctx, n, buf, k));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkAtleast(b_lean_obj_arg ctx, b_lean_obj_arg args, uint32_t k) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_atleast(c->ctx, n, buf, k));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkPble(b_lean_obj_arg ctx, b_lean_obj_arg args, b_lean_obj_arg coeffs, uint32_t k) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast abuf[n];
  int cbuf[n];
  for (unsigned i = 0; i < n; i++) {
    abuf[i] = to_Ast(lean_array_get_core(args, i))->ast;
    cbuf[i] = (int)lean_unbox_uint32(lean_array_get_core(coeffs, i));
  }
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_pble(c->ctx, n, abuf, cbuf, (int)k));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkPbge(b_lean_obj_arg ctx, b_lean_obj_arg args, b_lean_obj_arg coeffs, uint32_t k) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast abuf[n];
  int cbuf[n];
  for (unsigned i = 0; i < n; i++) {
    abuf[i] = to_Ast(lean_array_get_core(args, i))->ast;
    cbuf[i] = (int)lean_unbox_uint32(lean_array_get_core(coeffs, i));
  }
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_pbge(c->ctx, n, abuf, cbuf, (int)k));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkPbeq(b_lean_obj_arg ctx, b_lean_obj_arg args, b_lean_obj_arg coeffs, uint32_t k) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast abuf[n];
  int cbuf[n];
  for (unsigned i = 0; i < n; i++) {
    abuf[i] = to_Ast(lean_array_get_core(args, i))->ast;
    cbuf[i] = (int)lean_unbox_uint32(lean_array_get_core(coeffs, i));
  }
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_pbeq(c->ctx, n, abuf, cbuf, (int)k));
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
  unsigned n = Z3_get_app_num_args(aw->ctx, app);
  if (i >= n) { lean_internal_panic("Ast.getArg: index out of bounds"); }
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, Z3_get_app_arg(aw->ctx, app, i));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getFuncDecl(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_app app = Z3_to_app(aw->ctx, aw->ast);
  return z3_wrap_func_decl(aw->ctx_obj, aw->ctx, Z3_get_app_decl(aw->ctx, app));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralString(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  const char *s = Z3_get_numeral_string(aw->ctx, aw->ast);
  if (s == NULL) { lean_internal_panic("Z3_get_numeral_string failed: AST is not a numeral"); }
  return lean_mk_string(s);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralDecimalString(b_lean_obj_arg a, uint32_t precision) {
  Z3AstWrapper *aw = to_Ast(a);
  const char *s = Z3_get_numeral_decimal_string(aw->ctx, aw->ast, precision);
  if (s == NULL) { lean_internal_panic("Z3_get_numeral_decimal_string failed"); }
  return lean_mk_string(s);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralBinaryString(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  const char *s = Z3_get_numeral_binary_string(aw->ctx, aw->ast);
  if (s == NULL) { lean_internal_panic("Z3_get_numeral_binary_string failed"); }
  return lean_mk_string(s);
}

/* Returns Int64 via Env monad. Errors if the value doesn't fit in int64. */
LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralInt64(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  int64_t val = 0;
  bool ok = Z3_get_numeral_int64(aw->ctx, aw->ast, &val);
  if (!ok) { return z3_env_error("Z3_get_numeral_int64: value does not fit in Int64"); }
  return z3_env_val(lean_box_uint64((uint64_t)val));
}

/* Returns UInt64 via Env monad. Errors if the value doesn't fit in uint64. */
LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumeralUInt64(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  uint64_t val = 0;
  bool ok = Z3_get_numeral_uint64(aw->ctx, aw->ast, &val);
  if (!ok) { return z3_env_error("Z3_get_numeral_uint64: value does not fit in UInt64"); }
  return z3_env_val(lean_box_uint64(val));
}

LEAN_EXPORT double lean_z3_Ast_getNumeralDouble(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_numeral_double(aw->ctx, aw->ast);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getNumerator(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_ast num = Z3_get_numerator(aw->ctx, aw->ast);
  if (num == NULL) { lean_internal_panic("Z3_get_numerator failed: not a rational numeral"); }
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, num);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getDenominator(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_ast den = Z3_get_denominator(aw->ctx, aw->ast);
  if (den == NULL) { lean_internal_panic("Z3_get_denominator failed: not a rational numeral"); }
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, den);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_toString(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  const char *str = Z3_ast_to_string(aw->ctx, aw->ast);
  if (str == NULL) { lean_internal_panic("Z3_ast_to_string returned NULL"); }
  return lean_mk_string(str);
}

/* ── AST utilities ────────────────────────────────────────────────────── */

LEAN_EXPORT uint8_t lean_z3_Ast_isApp(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_app(aw->ctx, aw->ast);
}

LEAN_EXPORT uint8_t lean_z3_Ast_isNumeralAst(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_numeral_ast(aw->ctx, aw->ast);
}

LEAN_EXPORT uint8_t lean_z3_Ast_isWellSorted(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_well_sorted(aw->ctx, aw->ast);
}

LEAN_EXPORT uint8_t lean_z3_Ast_isEqAst(b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3AstWrapper *bw = to_Ast(b);
  return Z3_is_eq_ast(aw->ctx, aw->ast, bw->ast);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getId(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_ast_id(aw->ctx, aw->ast);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getHash(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_ast_hash(aw->ctx, aw->ast);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_translate(b_lean_obj_arg a, b_lean_obj_arg target) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3Ctx *tc = to_Context(target);
  Z3_ast result = Z3_translate(aw->ctx, aw->ast, tc->ctx);
  return z3_wrap_ast(target, tc->ctx, result);
}

/* ── Quantifier inspection (pure) ──────────────────────────────────────── */

LEAN_EXPORT uint8_t lean_z3_Ast_isQuantifierForall(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_quantifier_forall(aw->ctx, aw->ast) ? 1 : 0;
}

LEAN_EXPORT uint8_t lean_z3_Ast_isQuantifierExists(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_quantifier_exists(aw->ctx, aw->ast) ? 1 : 0;
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getQuantifierBody(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  Z3_ast body = Z3_get_quantifier_body(aw->ctx, aw->ast);
  if (body == NULL) { lean_internal_panic("Z3_get_quantifier_body: not a quantifier"); }
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, body);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getQuantifierNumBound(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_quantifier_num_bound(aw->ctx, aw->ast);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getQuantifierBoundName(b_lean_obj_arg a, uint32_t i) {
  Z3AstWrapper *aw = to_Ast(a);
  unsigned n = Z3_get_quantifier_num_bound(aw->ctx, aw->ast);
  if (i >= n) { lean_internal_panic("Ast.getQuantifierBoundName: index out of bounds"); }
  Z3_symbol sym = Z3_get_quantifier_bound_name(aw->ctx, aw->ast, i);
  return lean_mk_string(Z3_get_symbol_string(aw->ctx, sym));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getQuantifierBoundSort(b_lean_obj_arg a, uint32_t i) {
  Z3AstWrapper *aw = to_Ast(a);
  unsigned n = Z3_get_quantifier_num_bound(aw->ctx, aw->ast);
  if (i >= n) { lean_internal_panic("Ast.getQuantifierBoundSort: index out of bounds"); }
  Z3_sort s = Z3_get_quantifier_bound_sort(aw->ctx, aw->ast, i);
  if (s == NULL) { lean_internal_panic("Z3_get_quantifier_bound_sort returned NULL"); }
  return z3_wrap_sort(aw->ctx_obj, aw->ctx, s);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getQuantifierWeight(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_quantifier_weight(aw->ctx, aw->ast);
}

LEAN_EXPORT uint32_t lean_z3_Ast_getQuantifierNumPatterns(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_quantifier_num_patterns(aw->ctx, aw->ast);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getQuantifierPatternAst(b_lean_obj_arg a, uint32_t i) {
  Z3AstWrapper *aw = to_Ast(a);
  unsigned n = Z3_get_quantifier_num_patterns(aw->ctx, aw->ast);
  if (i >= n) { lean_internal_panic("Ast.getQuantifierPatternAst: index out of bounds"); }
  Z3_pattern p = Z3_get_quantifier_pattern_ast(aw->ctx, aw->ast, i);
  /* Z3_pattern is a Z3_ast — wrap it as Ast */
  Z3_ast pat_ast = Z3_pattern_to_ast(aw->ctx, p);
  return z3_wrap_ast(aw->ctx_obj, aw->ctx, pat_ast);
}

LEAN_EXPORT uint8_t lean_z3_Ast_isLambda(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_is_lambda(aw->ctx, aw->ast) ? 1 : 0;
}

/* ── Pattern construction ─────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkPattern(b_lean_obj_arg ctx, b_lean_obj_arg terms) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(terms);
  if (n == 0) { lean_internal_panic("Ast.mkPattern: need at least one term"); }
  Z3_ast *arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
  if (arr == NULL) { lean_internal_panic("out of memory"); }
  for (unsigned i = 0; i < n; i++) {
    arr[i] = to_Ast(lean_array_get_core(terms, i))->ast;
  }
  Z3_pattern p = Z3_mk_pattern(c->ctx, n, arr);
  free(arr);
  /* Z3_pattern is a Z3_ast — wrap via pattern_to_ast */
  Z3_ast pat_ast = Z3_pattern_to_ast(c->ctx, p);
  return z3_wrap_ast(ctx, c->ctx, pat_ast);
}

/* ── Variable inspection (pure) ───────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_Ast_getVarIndex(b_lean_obj_arg a) {
  Z3AstWrapper *aw = to_Ast(a);
  return Z3_get_index_value(aw->ctx, aw->ast);
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
  const char *str = Z3_func_decl_to_string(w->ctx, w->func_decl);
  if (str == NULL) { lean_internal_panic("Z3_func_decl_to_string returned NULL"); }
  return lean_mk_string(str);
}

LEAN_EXPORT uint32_t lean_z3_FuncDecl_getArity(b_lean_obj_arg fd) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  return Z3_get_arity(w->ctx, w->func_decl);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_getDomain(b_lean_obj_arg fd, uint32_t i) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  unsigned n = Z3_get_domain_size(w->ctx, w->func_decl);
  if (i >= n) { lean_internal_panic("FuncDecl.getDomain: index out of bounds"); }
  Z3_sort s = Z3_get_domain(w->ctx, w->func_decl, i);
  return z3_wrap_sort(w->ctx_obj, w->ctx, s);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_getRange(b_lean_obj_arg fd) {
  Z3FuncDeclWrapper *w = to_FuncDecl(fd);
  Z3_sort s = Z3_get_range(w->ctx, w->func_decl);
  return z3_wrap_sort(w->ctx_obj, w->ctx, s);
}

/* ── Uninterpreted functions ──────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_mk(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg domain, b_lean_obj_arg range) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *r = to_Srt(range);
  unsigned n = lean_array_size(domain);
  Z3_sort *dom = NULL;
  if (n > 0) {
    dom = (Z3_sort *)malloc(n * sizeof(Z3_sort));
    if (dom == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      dom[i] = to_Srt(lean_array_get_core(domain, i))->sort;
    }
  }
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_func_decl fd = Z3_mk_func_decl(c->ctx, sym, n, dom, r->sort);
  free(dom);
  return z3_wrap_func_decl(ctx, c->ctx, fd);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkApp(b_lean_obj_arg ctx, b_lean_obj_arg fd, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  Z3FuncDeclWrapper *fw = to_FuncDecl(fd);
  unsigned n = lean_array_size(args);
  Z3_ast *arr = NULL;
  if (n > 0) {
    arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    if (arr == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      arr[i] = to_Ast(lean_array_get_core(args, i))->ast;
    }
  }
  Z3_ast result = Z3_mk_app(c->ctx, fw->func_decl, n, arr);
  free(arr);
  return z3_wrap_ast(ctx, c->ctx, result);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFreshConst(b_lean_obj_arg ctx, b_lean_obj_arg prefix, b_lean_obj_arg sort) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *s = to_Srt(sort);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fresh_const(c->ctx, lean_string_cstr(prefix), s->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_mkFresh(b_lean_obj_arg ctx, b_lean_obj_arg prefix,
    b_lean_obj_arg domain, b_lean_obj_arg range) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *r = to_Srt(range);
  unsigned n = lean_array_size(domain);
  Z3_sort *dom = NULL;
  if (n > 0) {
    dom = (Z3_sort *)malloc(n * sizeof(Z3_sort));
    if (dom == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      dom[i] = to_Srt(lean_array_get_core(domain, i))->sort;
    }
  }
  Z3_func_decl fd = Z3_mk_fresh_func_decl(c->ctx, lean_string_cstr(prefix), n, dom, r->sort);
  free(dom);
  return z3_wrap_func_decl(ctx, c->ctx, fd);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_mkRec(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg domain, b_lean_obj_arg range) {
  Z3Ctx *c = to_Context(ctx);
  Z3SortWrapper *r = to_Srt(range);
  unsigned n = lean_array_size(domain);
  Z3_sort *dom = NULL;
  if (n > 0) {
    dom = (Z3_sort *)malloc(n * sizeof(Z3_sort));
    if (dom == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      dom[i] = to_Srt(lean_array_get_core(domain, i))->sort;
    }
  }
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_func_decl fd = Z3_mk_rec_func_decl(c->ctx, sym, n, dom, r->sort);
  free(dom);
  return z3_wrap_func_decl(ctx, c->ctx, fd);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncDecl_addRecDef(b_lean_obj_arg ctx,
    b_lean_obj_arg fd, b_lean_obj_arg args, b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3FuncDeclWrapper *fw = to_FuncDecl(fd);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned n = lean_array_size(args);
  Z3_ast *arr = NULL;
  if (n > 0) {
    arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    if (arr == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      arr[i] = to_Ast(lean_array_get_core(args, i))->ast;
    }
  }
  Z3_add_rec_def(c->ctx, fw->func_decl, n, arr, bw->ast);
  free(arr);
  return lean_box(0);
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
  if (w == NULL) { Z3_params_dec_ref(c->ctx, p); lean_internal_panic("out of memory"); }
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
  if (w == NULL) { Z3_solver_dec_ref(c->ctx, s); lean_internal_panic("out of memory"); }
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
  const char *str = Z3_solver_get_reason_unknown(sw->ctx, sw->solver);
  if (str == NULL) { lean_internal_panic("Z3_solver_get_reason_unknown returned NULL"); }
  return lean_mk_string(str);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getProof(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_ast proof = Z3_solver_get_proof(sw->ctx, sw->solver);
  if (proof == NULL) {
    return z3_env_error("no proof available");
  }
  Z3_inc_ref(sw->ctx, proof);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  if (w == NULL) { Z3_dec_ref(sw->ctx, proof); return z3_env_error("out of memory"); }
  lean_inc(sw->ctx_obj);
  w->ctx_obj = sw->ctx_obj;
  w->ctx = sw->ctx;
  w->ast = proof;
  return z3_env_val(mk_Ast(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_toString(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  const char *str = Z3_solver_to_string(sw->ctx, sw->solver);
  if (str == NULL) { lean_internal_panic("Z3_solver_to_string returned NULL"); }
  return lean_mk_string(str);
}

/* ── Stats external class ─────────────────────────────────────────────── */

static void Stats_finalize(void *p) {
  Z3StatsWrapper *w = (Z3StatsWrapper *)p;
  Z3_stats_dec_ref(w->ctx, w->stats);
  lean_dec(w->ctx_obj);
  free(w);
}

static lean_external_class *g_Stats_class = NULL;
static inline lean_external_class *get_Stats_class(void) {
  if (g_Stats_class == NULL)
    g_Stats_class = lean_register_external_class(Stats_finalize, noop_foreach);
  return g_Stats_class;
}

static inline lean_obj_res mk_Stats(Z3StatsWrapper *w) {
  return lean_alloc_external(get_Stats_class(), w);
}

static inline Z3StatsWrapper *to_Stats(b_lean_obj_arg o) {
  return (Z3StatsWrapper *)lean_get_external_data(o);
}

/* ── Solver (extended) ────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Solver_mkSimple(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_solver s = Z3_mk_simple_solver(c->ctx);
  Z3_solver_inc_ref(c->ctx, s);
  Z3SolverWrapper *w = (Z3SolverWrapper *)malloc(sizeof(Z3SolverWrapper));
  if (w == NULL) { Z3_solver_dec_ref(c->ctx, s); return z3_env_error("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx; w->ctx = c->ctx; w->solver = s;
  return z3_env_val(mk_Solver(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_mkForLogic(b_lean_obj_arg ctx, b_lean_obj_arg logic) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(logic));
  Z3_solver s = Z3_mk_solver_for_logic(c->ctx, sym);
  Z3_solver_inc_ref(c->ctx, s);
  Z3SolverWrapper *w = (Z3SolverWrapper *)malloc(sizeof(Z3SolverWrapper));
  if (w == NULL) { Z3_solver_dec_ref(c->ctx, s); return z3_env_error("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx; w->ctx = c->ctx; w->solver = s;
  return z3_env_val(mk_Solver(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_fromString(b_lean_obj_arg s, b_lean_obj_arg str) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_from_string(sw->ctx, sw->solver, lean_string_cstr(str));
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_fromFile(b_lean_obj_arg s, b_lean_obj_arg filename) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_from_file(sw->ctx, sw->solver, lean_string_cstr(filename));
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getNumScopes(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  return lean_box_uint32(Z3_solver_get_num_scopes(sw->ctx, sw->solver));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_interrupt(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_interrupt(sw->ctx, sw->solver);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_translate(b_lean_obj_arg s, b_lean_obj_arg target) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3Ctx *tc = to_Context(target);
  Z3_solver ts = Z3_solver_translate(sw->ctx, sw->solver, tc->ctx);
  Z3_solver_inc_ref(tc->ctx, ts);
  Z3SolverWrapper *w = (Z3SolverWrapper *)malloc(sizeof(Z3SolverWrapper));
  if (w == NULL) { Z3_solver_dec_ref(tc->ctx, ts); return z3_env_error("out of memory"); }
  lean_inc(target);
  w->ctx_obj = target; w->ctx = tc->ctx; w->solver = ts;
  return z3_env_val(mk_Solver(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getTrail(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_ast_vector trail = Z3_solver_get_trail(sw->ctx, sw->solver);
  Z3_ast_vector_inc_ref(sw->ctx, trail);
  unsigned n = Z3_ast_vector_size(sw->ctx, trail);
  lean_object *arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(sw->ctx, trail, i);
    arr = lean_array_push(arr, z3_wrap_ast(sw->ctx_obj, sw->ctx, a));
  }
  Z3_ast_vector_dec_ref(sw->ctx, trail);
  return arr;
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getConsequences(b_lean_obj_arg s,
    b_lean_obj_arg assumptions, b_lean_obj_arg variables) {
  Z3SolverWrapper *sw = to_Solver(s);

  /* Create assumption ast_vector */
  Z3_ast_vector av = Z3_mk_ast_vector(sw->ctx);
  Z3_ast_vector_inc_ref(sw->ctx, av);
  unsigned na = lean_array_size(assumptions);
  for (unsigned i = 0; i < na; i++)
    Z3_ast_vector_push(sw->ctx, av, to_Ast(lean_array_get_core(assumptions, i))->ast);

  /* Create variables ast_vector */
  Z3_ast_vector vv = Z3_mk_ast_vector(sw->ctx);
  Z3_ast_vector_inc_ref(sw->ctx, vv);
  unsigned nv = lean_array_size(variables);
  for (unsigned i = 0; i < nv; i++)
    Z3_ast_vector_push(sw->ctx, vv, to_Ast(lean_array_get_core(variables, i))->ast);

  /* Create consequence ast_vector (output) */
  Z3_ast_vector cv = Z3_mk_ast_vector(sw->ctx);
  Z3_ast_vector_inc_ref(sw->ctx, cv);

  Z3_lbool r = Z3_solver_get_consequences(sw->ctx, sw->solver, av, vv, cv);

  /* Convert consequences to Lean array */
  unsigned nc = Z3_ast_vector_size(sw->ctx, cv);
  lean_object *conseq_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < nc; i++) {
    Z3_ast a = Z3_ast_vector_get(sw->ctx, cv, i);
    conseq_arr = lean_array_push(conseq_arr, z3_wrap_ast(sw->ctx_obj, sw->ctx, a));
  }

  Z3_ast_vector_dec_ref(sw->ctx, av);
  Z3_ast_vector_dec_ref(sw->ctx, vv);
  Z3_ast_vector_dec_ref(sw->ctx, cv);

  /* Map Z3_lbool {-1,0,1} to LBool {0,1,2} */
  lean_object *lbool = lean_box((uint8_t)(r + 1));

  /* Build (LBool × Array Ast) */
  lean_object *pair = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(pair, 0, lbool);
  lean_ctor_set(pair, 1, conseq_arr);
  return pair;
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getStatistics(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_stats st = Z3_solver_get_statistics(sw->ctx, sw->solver);
  Z3_stats_inc_ref(sw->ctx, st);
  Z3StatsWrapper *w = (Z3StatsWrapper *)malloc(sizeof(Z3StatsWrapper));
  if (w == NULL) { Z3_stats_dec_ref(sw->ctx, st); lean_internal_panic("out of memory"); }
  lean_inc(sw->ctx_obj);
  w->ctx_obj = sw->ctx_obj; w->ctx = sw->ctx; w->stats = st;
  return mk_Stats(w);
}

/* ── Statistics ───────────────────────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_Stats_size(b_lean_obj_arg s) {
  Z3StatsWrapper *sw = to_Stats(s);
  return Z3_stats_size(sw->ctx, sw->stats);
}

LEAN_EXPORT lean_obj_res lean_z3_Stats_getKey(b_lean_obj_arg s, uint32_t i) {
  Z3StatsWrapper *sw = to_Stats(s);
  return lean_mk_string(Z3_stats_get_key(sw->ctx, sw->stats, i));
}

LEAN_EXPORT uint8_t lean_z3_Stats_isUInt(b_lean_obj_arg s, uint32_t i) {
  Z3StatsWrapper *sw = to_Stats(s);
  return Z3_stats_is_uint(sw->ctx, sw->stats, i) ? 1 : 0;
}

LEAN_EXPORT uint8_t lean_z3_Stats_isDouble(b_lean_obj_arg s, uint32_t i) {
  Z3StatsWrapper *sw = to_Stats(s);
  return Z3_stats_is_double(sw->ctx, sw->stats, i) ? 1 : 0;
}

LEAN_EXPORT uint32_t lean_z3_Stats_getUIntValue(b_lean_obj_arg s, uint32_t i) {
  Z3StatsWrapper *sw = to_Stats(s);
  return Z3_stats_get_uint_value(sw->ctx, sw->stats, i);
}

LEAN_EXPORT double lean_z3_Stats_getDoubleValue(b_lean_obj_arg s, uint32_t i) {
  Z3StatsWrapper *sw = to_Stats(s);
  return Z3_stats_get_double_value(sw->ctx, sw->stats, i);
}

LEAN_EXPORT lean_obj_res lean_z3_Stats_toString(b_lean_obj_arg s) {
  Z3StatsWrapper *sw = to_Stats(s);
  const char *str = Z3_stats_to_string(sw->ctx, sw->stats);
  if (str == NULL) { lean_internal_panic("Z3_stats_to_string returned NULL"); }
  return lean_mk_string(str);
}

/* ── Fixedpoint (Datalog/CHC) ─────────────────────────────────────────── */

static void Fixedpoint_finalize(void *p) {
  Z3FixedpointWrapper *w = (Z3FixedpointWrapper *)p;
  Z3_fixedpoint_dec_ref(w->ctx, w->fixedpoint);
  lean_dec(w->ctx_obj);
  free(w);
}

static lean_external_class *g_Fixedpoint_class = NULL;
static inline lean_external_class *get_Fixedpoint_class(void) {
  if (g_Fixedpoint_class == NULL)
    g_Fixedpoint_class = lean_register_external_class(Fixedpoint_finalize, noop_foreach);
  return g_Fixedpoint_class;
}

static inline lean_obj_res mk_Fixedpoint(Z3FixedpointWrapper *w) {
  return lean_alloc_external(get_Fixedpoint_class(), w);
}

static inline Z3FixedpointWrapper *to_Fixedpoint(b_lean_obj_arg o) {
  return (Z3FixedpointWrapper *)lean_get_external_data(o);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_new(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_fixedpoint fp = Z3_mk_fixedpoint(c->ctx);
  Z3_fixedpoint_inc_ref(c->ctx, fp);
  Z3FixedpointWrapper *w = (Z3FixedpointWrapper *)malloc(sizeof(Z3FixedpointWrapper));
  if (w == NULL) { Z3_fixedpoint_dec_ref(c->ctx, fp); return z3_env_error("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx; w->ctx = c->ctx; w->fixedpoint = fp;
  return z3_env_val(mk_Fixedpoint(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_registerRelation(b_lean_obj_arg fp, b_lean_obj_arg f) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_fixedpoint_register_relation(fpw->ctx, fpw->fixedpoint, to_FuncDecl(f)->func_decl);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_addRule(b_lean_obj_arg fp, b_lean_obj_arg rule, b_lean_obj_arg name) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_symbol sym = Z3_mk_string_symbol(fpw->ctx, lean_string_cstr(name));
  Z3_fixedpoint_add_rule(fpw->ctx, fpw->fixedpoint, to_Ast(rule)->ast, sym);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_assert(b_lean_obj_arg fp, b_lean_obj_arg a) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_fixedpoint_assert(fpw->ctx, fpw->fixedpoint, to_Ast(a)->ast);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_query(b_lean_obj_arg fp, b_lean_obj_arg query) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_lbool r = Z3_fixedpoint_query(fpw->ctx, fpw->fixedpoint, to_Ast(query)->ast);
  /* Map Z3_lbool {-1,0,1} to LBool {0,1,2} */
  return lean_box((uint8_t)(r + 1));
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getAnswer(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast a = Z3_fixedpoint_get_answer(fpw->ctx, fpw->fixedpoint);
  return z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getReasonUnknown(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  return lean_mk_string(Z3_fixedpoint_get_reason_unknown(fpw->ctx, fpw->fixedpoint));
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_setParams(b_lean_obj_arg fp, b_lean_obj_arg p) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_fixedpoint_set_params(fpw->ctx, fpw->fixedpoint, to_Params(p)->params);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_toString(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  const char *str = Z3_fixedpoint_to_string(fpw->ctx, fpw->fixedpoint, 0, NULL);
  if (str == NULL) { lean_internal_panic("Z3_fixedpoint_to_string returned NULL"); }
  return lean_mk_string(str);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_addFact(b_lean_obj_arg fp, b_lean_obj_arg r, b_lean_obj_arg args) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  unsigned n = lean_array_size(args);
  unsigned *vals = (unsigned *)malloc(n * sizeof(unsigned));
  if (vals == NULL && n > 0) lean_internal_panic("out of memory");
  for (unsigned i = 0; i < n; i++)
    vals[i] = lean_unbox_uint32(lean_array_uget(args, i));
  Z3_fixedpoint_add_fact(fpw->ctx, fpw->fixedpoint, to_FuncDecl(r)->func_decl, n, vals);
  free(vals);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Fixedpoint_queryRelations(b_lean_obj_arg fp, b_lean_obj_arg relations) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  unsigned n = lean_array_size(relations);
  Z3_func_decl *rels = (Z3_func_decl *)malloc(n * sizeof(Z3_func_decl));
  if (rels == NULL && n > 0) lean_internal_panic("out of memory");
  for (unsigned i = 0; i < n; i++)
    rels[i] = to_FuncDecl(lean_array_uget(relations, i))->func_decl;
  Z3_lbool result = Z3_fixedpoint_query_relations(fpw->ctx, fpw->fixedpoint, n, rels);
  free(rels);
  return (uint32_t)result + 1; /* Z3_L_FALSE=-1 -> 0, Z3_L_UNDEF=0 -> 1, Z3_L_TRUE=1 -> 2 */
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_updateRule(b_lean_obj_arg fp, b_lean_obj_arg rule, b_lean_obj_arg name) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_symbol sym = Z3_mk_string_symbol(fpw->ctx, lean_string_cstr(name));
  Z3_fixedpoint_update_rule(fpw->ctx, fpw->fixedpoint, to_Ast(rule)->ast, sym);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Fixedpoint_getNumLevels(b_lean_obj_arg fp, b_lean_obj_arg pred) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  return Z3_fixedpoint_get_num_levels(fpw->ctx, fpw->fixedpoint, to_FuncDecl(pred)->func_decl);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getCoverDelta(b_lean_obj_arg fp, int32_t level, b_lean_obj_arg pred) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast a = Z3_fixedpoint_get_cover_delta(fpw->ctx, fpw->fixedpoint, (int)level, to_FuncDecl(pred)->func_decl);
  return z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_addCover(b_lean_obj_arg fp, int32_t level, b_lean_obj_arg pred, b_lean_obj_arg property) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_fixedpoint_add_cover(fpw->ctx, fpw->fixedpoint, (int)level, to_FuncDecl(pred)->func_decl, to_Ast(property)->ast);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getStatistics(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_stats s = Z3_fixedpoint_get_statistics(fpw->ctx, fpw->fixedpoint);
  Z3_stats_inc_ref(fpw->ctx, s);
  Z3StatsWrapper *w = (Z3StatsWrapper *)malloc(sizeof(Z3StatsWrapper));
  if (w == NULL) { Z3_stats_dec_ref(fpw->ctx, s); lean_internal_panic("out of memory"); }
  lean_inc(fpw->ctx_obj);
  w->ctx_obj = fpw->ctx_obj;
  w->ctx = fpw->ctx;
  w->stats = s;
  return mk_Stats(w);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getRules(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast_vector v = Z3_fixedpoint_get_rules(fpw->ctx, fpw->fixedpoint);
  Z3_ast_vector_inc_ref(fpw->ctx, v);
  unsigned n = Z3_ast_vector_size(fpw->ctx, v);
  lean_obj_res arr = lean_alloc_array(n, n);
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(fpw->ctx, v, i);
    lean_array_set_core(arr, i, z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a));
  }
  Z3_ast_vector_dec_ref(fpw->ctx, v);
  return arr;
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getAssertions(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast_vector v = Z3_fixedpoint_get_assertions(fpw->ctx, fpw->fixedpoint);
  Z3_ast_vector_inc_ref(fpw->ctx, v);
  unsigned n = Z3_ast_vector_size(fpw->ctx, v);
  lean_obj_res arr = lean_alloc_array(n, n);
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(fpw->ctx, v, i);
    lean_array_set_core(arr, i, z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a));
  }
  Z3_ast_vector_dec_ref(fpw->ctx, v);
  return arr;
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getHelp(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  const char *s = Z3_fixedpoint_get_help(fpw->ctx, fpw->fixedpoint);
  return lean_mk_string(s ? s : "");
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_getParamDescrs(b_lean_obj_arg fp) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_param_descrs pd = Z3_fixedpoint_get_param_descrs(fpw->ctx, fpw->fixedpoint);
  Z3_param_descrs_inc_ref(fpw->ctx, pd);
  Z3ParamDescrsWrapper *w = (Z3ParamDescrsWrapper *)malloc(sizeof(Z3ParamDescrsWrapper));
  if (w == NULL) { Z3_param_descrs_dec_ref(fpw->ctx, pd); lean_internal_panic("out of memory"); }
  lean_inc(fpw->ctx_obj);
  w->ctx_obj = fpw->ctx_obj;
  w->ctx = fpw->ctx;
  w->param_descrs = pd;
  return mk_ParamDescrs(w);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_fromString(b_lean_obj_arg fp, b_lean_obj_arg s) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast_vector v = Z3_fixedpoint_from_string(fpw->ctx, fpw->fixedpoint, lean_string_cstr(s));
  Z3_ast_vector_inc_ref(fpw->ctx, v);
  unsigned n = Z3_ast_vector_size(fpw->ctx, v);
  lean_obj_res arr = lean_alloc_array(n, n);
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(fpw->ctx, v, i);
    lean_array_set_core(arr, i, z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a));
  }
  Z3_ast_vector_dec_ref(fpw->ctx, v);
  return arr;
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_fromFile(b_lean_obj_arg fp, b_lean_obj_arg path) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_ast_vector v = Z3_fixedpoint_from_file(fpw->ctx, fpw->fixedpoint, lean_string_cstr(path));
  Z3_ast_vector_inc_ref(fpw->ctx, v);
  unsigned n = Z3_ast_vector_size(fpw->ctx, v);
  lean_obj_res arr = lean_alloc_array(n, n);
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(fpw->ctx, v, i);
    lean_array_set_core(arr, i, z3_wrap_ast(fpw->ctx_obj, fpw->ctx, a));
  }
  Z3_ast_vector_dec_ref(fpw->ctx, v);
  return arr;
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_setPredicateRepresentation(b_lean_obj_arg fp, b_lean_obj_arg f, b_lean_obj_arg kinds) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  unsigned n = lean_array_size(kinds);
  Z3_symbol *syms = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  if (syms == NULL && n > 0) lean_internal_panic("out of memory");
  for (unsigned i = 0; i < n; i++)
    syms[i] = Z3_mk_string_symbol(fpw->ctx, lean_string_cstr(lean_array_uget(kinds, i)));
  Z3_fixedpoint_set_predicate_representation(fpw->ctx, fpw->fixedpoint, to_FuncDecl(f)->func_decl, n, syms);
  free(syms);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Fixedpoint_addConstraint(b_lean_obj_arg fp, b_lean_obj_arg e, uint32_t lvl) {
  Z3FixedpointWrapper *fpw = to_Fixedpoint(fp);
  Z3_fixedpoint_add_constraint(fpw->ctx, fpw->fixedpoint, to_Ast(e)->ast, lvl);
  return lean_box(0);
}

/* ── Probe API ─────────────────────────────────────────────────────────── */

static void Probe_finalize(void *p) {
  Z3ProbeWrapper *w = (Z3ProbeWrapper *)p;
  Z3_probe_dec_ref(w->ctx, w->probe);
  lean_dec(w->ctx_obj);
  free(w);
}

static lean_external_class *g_Probe_class = NULL;
static inline lean_external_class *get_Probe_class(void) {
  if (g_Probe_class == NULL)
    g_Probe_class = lean_register_external_class(Probe_finalize, noop_foreach);
  return g_Probe_class;
}

static inline lean_obj_res mk_Probe(Z3ProbeWrapper *w) {
  return lean_alloc_external(get_Probe_class(), w);
}

static inline Z3ProbeWrapper *to_Probe(b_lean_obj_arg o) {
  return (Z3ProbeWrapper *)lean_get_external_data(o);
}

static inline lean_obj_res z3_wrap_probe(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_probe p) {
  Z3_probe_inc_ref(raw_ctx, p);
  Z3ProbeWrapper *w = (Z3ProbeWrapper *)malloc(sizeof(Z3ProbeWrapper));
  if (w == NULL) { Z3_probe_dec_ref(raw_ctx, p); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->probe = p;
  return mk_Probe(w);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_mk(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe p = Z3_mk_probe(c->ctx, lean_string_cstr(name));
  return z3_wrap_probe(ctx, c->ctx, p);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_const(b_lean_obj_arg ctx, double val) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe p = Z3_probe_const(c->ctx, val);
  return z3_wrap_probe(ctx, c->ctx, p);
}

LEAN_EXPORT double lean_z3_Probe_apply(b_lean_obj_arg ctx, b_lean_obj_arg probe, b_lean_obj_arg goal) {
  Z3Ctx *c = to_Context(ctx);
  return Z3_probe_apply(c->ctx, to_Probe(probe)->probe, to_Goal(goal)->goal);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_lt(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_lt(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_gt(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_gt(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_le(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_le(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_ge(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_ge(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_eq(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_eq(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_and(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_and(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_or(b_lean_obj_arg ctx, b_lean_obj_arg p1, b_lean_obj_arg p2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_or(c->ctx, to_Probe(p1)->probe, to_Probe(p2)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_not(b_lean_obj_arg ctx, b_lean_obj_arg p) {
  Z3Ctx *c = to_Context(ctx);
  Z3_probe r = Z3_probe_not(c->ctx, to_Probe(p)->probe);
  return z3_wrap_probe(ctx, c->ctx, r);
}

LEAN_EXPORT uint32_t lean_z3_Context_getNumProbes(b_lean_obj_arg ctx) {
  return Z3_get_num_probes(to_Context(ctx)->ctx);
}

LEAN_EXPORT lean_obj_res lean_z3_Context_getProbeName(b_lean_obj_arg ctx, uint32_t i) {
  return lean_mk_string(Z3_get_probe_name(to_Context(ctx)->ctx, i));
}

LEAN_EXPORT lean_obj_res lean_z3_Probe_getDescr(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  const char *s = Z3_probe_get_descr(to_Context(ctx)->ctx, lean_string_cstr(name));
  return lean_mk_string(s ? s : "");
}

/* ── Unsat core / assumptions ──────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Solver_assertAndTrack(b_lean_obj_arg s, b_lean_obj_arg a, b_lean_obj_arg track) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_solver_assert_and_track(sw->ctx, sw->solver, to_Ast(a)->ast, to_Ast(track)->ast);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Solver_checkAssumptionsRaw(b_lean_obj_arg s, b_lean_obj_arg assumptions) {
  Z3SolverWrapper *sw = to_Solver(s);
  unsigned n = lean_array_size(assumptions);
  Z3_ast *arr = NULL;
  if (n > 0) {
    arr = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    if (arr == NULL) { lean_internal_panic("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      arr[i] = to_Ast(lean_array_get_core(assumptions, i))->ast;
    }
  }
  Z3_lbool result = Z3_solver_check_assumptions(sw->ctx, sw->solver, n, arr);
  free(arr);
  return (uint32_t)(result + 1);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getUnsatCore(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_ast_vector core = Z3_solver_get_unsat_core(sw->ctx, sw->solver);
  if (core == NULL) {
    return z3_env_error("no unsat core available");
  }
  Z3_ast_vector_inc_ref(sw->ctx, core);
  unsigned n = Z3_ast_vector_size(sw->ctx, core);
  lean_object *arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(sw->ctx, core, i);
    arr = lean_array_push(arr, z3_wrap_ast(sw->ctx_obj, sw->ctx, a));
  }
  Z3_ast_vector_dec_ref(sw->ctx, core);
  return z3_env_val(arr);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getAssertions(b_lean_obj_arg s) {
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_ast_vector assertions = Z3_solver_get_assertions(sw->ctx, sw->solver);
  if (assertions == NULL) { lean_internal_panic("Z3_solver_get_assertions returned NULL"); }
  Z3_ast_vector_inc_ref(sw->ctx, assertions);
  unsigned n = Z3_ast_vector_size(sw->ctx, assertions);
  lean_object *arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(sw->ctx, assertions, i);
    arr = lean_array_push(arr, z3_wrap_ast(sw->ctx_obj, sw->ctx, a));
  }
  Z3_ast_vector_dec_ref(sw->ctx, assertions);
  return arr;
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
  if (w == NULL) { Z3_model_dec_ref(sw->ctx, m); return z3_env_error("out of memory"); }
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
  if (rw == NULL) { Z3_dec_ref(mw->ctx, result); return z3_env_error("out of memory"); }
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
  unsigned n = Z3_model_get_num_consts(mw->ctx, mw->model);
  if (i >= n) { lean_internal_panic("Model.getConstDecl: index out of bounds"); }
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
  if (w == NULL) { Z3_dec_ref(mw->ctx, a); return z3_env_error("out of memory"); }
  lean_inc(mw->ctx_obj);
  w->ctx_obj = mw->ctx_obj;
  w->ctx = mw->ctx;
  w->ast = a;
  return z3_env_val(mk_Ast(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Model_toString(b_lean_obj_arg m) {
  Z3ModelWrapper *mw = to_Model(m);
  const char *str = Z3_model_to_string(mw->ctx, mw->model);
  if (str == NULL) { lean_internal_panic("Z3_model_to_string returned NULL"); }
  return lean_mk_string(str);
}

/* ── Model (extended) ─────────────────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_Model_getNumFuncs(b_lean_obj_arg m) {
  Z3ModelWrapper *mw = to_Model(m);
  return Z3_model_get_num_funcs(mw->ctx, mw->model);
}

LEAN_EXPORT lean_obj_res lean_z3_Model_getFuncDecl(b_lean_obj_arg m, uint32_t i) {
  Z3ModelWrapper *mw = to_Model(m);
  unsigned n = Z3_model_get_num_funcs(mw->ctx, mw->model);
  if (i >= n) { lean_internal_panic("Model.getFuncDecl: index out of bounds"); }
  return z3_wrap_func_decl(mw->ctx_obj, mw->ctx, Z3_model_get_func_decl(mw->ctx, mw->model, i));
}

LEAN_EXPORT lean_obj_res lean_z3_Model_getFuncInterp(b_lean_obj_arg m, b_lean_obj_arg fd) {
  Z3ModelWrapper *mw = to_Model(m);
  Z3FuncDeclWrapper *fdw = to_FuncDecl(fd);
  Z3_func_interp fi = Z3_model_get_func_interp(mw->ctx, mw->model, fdw->func_decl);
  if (fi == NULL) {
    return z3_env_error("no function interpretation available");
  }
  return z3_env_val(z3_wrap_func_interp(mw->ctx_obj, mw->ctx, fi));
}

LEAN_EXPORT uint8_t lean_z3_Model_hasInterp(b_lean_obj_arg m, b_lean_obj_arg fd) {
  Z3ModelWrapper *mw = to_Model(m);
  Z3FuncDeclWrapper *fdw = to_FuncDecl(fd);
  return Z3_model_has_interp(mw->ctx, mw->model, fdw->func_decl);
}

LEAN_EXPORT lean_obj_res lean_z3_Model_getSortUniverse(b_lean_obj_arg m, b_lean_obj_arg s) {
  Z3ModelWrapper *mw = to_Model(m);
  Z3SortWrapper *sw = to_Srt(s);
  Z3_ast_vector vec = Z3_model_get_sort_universe(mw->ctx, mw->model, sw->sort);
  if (vec == NULL) {
    return z3_env_error("failed to get sort universe");
  }
  Z3_ast_vector_inc_ref(mw->ctx, vec);
  unsigned n = Z3_ast_vector_size(mw->ctx, vec);
  lean_obj_res arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    Z3_ast a = Z3_ast_vector_get(mw->ctx, vec, i);
    arr = lean_array_push(arr, z3_wrap_ast(mw->ctx_obj, mw->ctx, a));
  }
  Z3_ast_vector_dec_ref(mw->ctx, vec);
  return z3_env_val(arr);
}

/* ── FuncInterp operations ────────────────────────────────────────────── */

LEAN_EXPORT uint32_t lean_z3_FuncInterp_getNumEntries(b_lean_obj_arg fi) {
  Z3FuncInterpWrapper *w = to_FuncInterp(fi);
  return Z3_func_interp_get_num_entries(w->ctx, w->func_interp);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncInterp_getEntry(b_lean_obj_arg fi, uint32_t i) {
  Z3FuncInterpWrapper *w = to_FuncInterp(fi);
  unsigned n = Z3_func_interp_get_num_entries(w->ctx, w->func_interp);
  if (i >= n) { lean_internal_panic("FuncInterp.getEntry: index out of bounds"); }
  Z3_func_entry fe = Z3_func_interp_get_entry(w->ctx, w->func_interp, i);
  return z3_wrap_func_entry(w->ctx_obj, w->ctx, fe);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncInterp_getElse(b_lean_obj_arg fi) {
  Z3FuncInterpWrapper *w = to_FuncInterp(fi);
  Z3_ast a = Z3_func_interp_get_else(w->ctx, w->func_interp);
  return z3_wrap_ast(w->ctx_obj, w->ctx, a);
}

LEAN_EXPORT uint32_t lean_z3_FuncInterp_getArity(b_lean_obj_arg fi) {
  Z3FuncInterpWrapper *w = to_FuncInterp(fi);
  return Z3_func_interp_get_arity(w->ctx, w->func_interp);
}

/* ── FuncEntry operations ─────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_FuncEntry_getValue(b_lean_obj_arg fe) {
  Z3FuncEntryWrapper *w = to_FuncEntry(fe);
  Z3_ast a = Z3_func_entry_get_value(w->ctx, w->func_entry);
  return z3_wrap_ast(w->ctx_obj, w->ctx, a);
}

LEAN_EXPORT uint32_t lean_z3_FuncEntry_getNumArgs(b_lean_obj_arg fe) {
  Z3FuncEntryWrapper *w = to_FuncEntry(fe);
  return Z3_func_entry_get_num_args(w->ctx, w->func_entry);
}

LEAN_EXPORT lean_obj_res lean_z3_FuncEntry_getArg(b_lean_obj_arg fe, uint32_t i) {
  Z3FuncEntryWrapper *w = to_FuncEntry(fe);
  unsigned n = Z3_func_entry_get_num_args(w->ctx, w->func_entry);
  if (i >= n) { lean_internal_panic("FuncEntry.getArg: index out of bounds"); }
  Z3_ast a = Z3_func_entry_get_arg(w->ctx, w->func_entry, i);
  return z3_wrap_ast(w->ctx_obj, w->ctx, a);
}

/* ── Tactic / Goal API ────────────────────────────────────────────────── */

static inline lean_obj_res z3_wrap_tactic(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_tactic t) {
  Z3_tactic_inc_ref(raw_ctx, t);
  Z3TacticWrapper *w = (Z3TacticWrapper *)malloc(sizeof(Z3TacticWrapper));
  if (w == NULL) { Z3_tactic_dec_ref(raw_ctx, t); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->tactic = t;
  return mk_Tactic(w);
}

static inline lean_obj_res z3_wrap_goal(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_goal g) {
  Z3_goal_inc_ref(raw_ctx, g);
  Z3GoalWrapper *w = (Z3GoalWrapper *)malloc(sizeof(Z3GoalWrapper));
  if (w == NULL) { Z3_goal_dec_ref(raw_ctx, g); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->goal = g;
  return mk_Goal(w);
}

static inline lean_obj_res z3_wrap_apply_result(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_apply_result r) {
  Z3_apply_result_inc_ref(raw_ctx, r);
  Z3ApplyResultWrapper *w = (Z3ApplyResultWrapper *)malloc(sizeof(Z3ApplyResultWrapper));
  if (w == NULL) { Z3_apply_result_dec_ref(raw_ctx, r); lean_internal_panic("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = raw_ctx;
  w->apply_result = r;
  return mk_ApplyResult(w);
}

/* Tactic creation */

LEAN_EXPORT lean_obj_res lean_z3_Tactic_mk(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic t = Z3_mk_tactic(c->ctx, lean_string_cstr(name));
  return z3_wrap_tactic(ctx, c->ctx, t);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_andThen(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_and_then(c->ctx, to_Tactic(t1)->tactic, to_Tactic(t2)->tactic);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_orElse(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_or_else(c->ctx, to_Tactic(t1)->tactic, to_Tactic(t2)->tactic);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_tryFor(b_lean_obj_arg ctx, b_lean_obj_arg t, uint32_t ms) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_try_for(c->ctx, to_Tactic(t)->tactic, ms);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_repeat(b_lean_obj_arg ctx, b_lean_obj_arg t, uint32_t max) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_repeat(c->ctx, to_Tactic(t)->tactic, max);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_skip(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_tactic(ctx, c->ctx, Z3_tactic_skip(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_fail(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_tactic(ctx, c->ctx, Z3_tactic_fail(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_usingParams(b_lean_obj_arg ctx, b_lean_obj_arg t, b_lean_obj_arg p) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_using_params(c->ctx, to_Tactic(t)->tactic, to_Params(p)->params);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_getHelp(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  const char *s = Z3_tactic_get_help(c->ctx, to_Tactic(t)->tactic);
  return lean_mk_string(s ? s : "");
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_getDescr(b_lean_obj_arg ctx, b_lean_obj_arg name) {
  Z3Ctx *c = to_Context(ctx);
  const char *s = Z3_tactic_get_descr(c->ctx, lean_string_cstr(name));
  return lean_mk_string(s ? s : "");
}

LEAN_EXPORT uint32_t lean_z3_Context_getNumTactics(b_lean_obj_arg ctx) {
  return Z3_get_num_tactics(to_Context(ctx)->ctx);
}

LEAN_EXPORT lean_obj_res lean_z3_Context_getTacticName(b_lean_obj_arg ctx, uint32_t i) {
  Z3Ctx *c = to_Context(ctx);
  const char *s = Z3_get_tactic_name(c->ctx, i);
  return lean_mk_string(s ? s : "");
}

/* Goal */

LEAN_EXPORT lean_obj_res lean_z3_Goal_mk(b_lean_obj_arg ctx, uint8_t models, uint8_t unsat_cores, uint8_t proofs) {
  Z3Ctx *c = to_Context(ctx);
  Z3_goal g = Z3_mk_goal(c->ctx, models, unsat_cores, proofs);
  return z3_wrap_goal(ctx, c->ctx, g);
}

LEAN_EXPORT lean_obj_res lean_z3_Goal_assert(b_lean_obj_arg g, b_lean_obj_arg a) {
  Z3GoalWrapper *gw = to_Goal(g);
  Z3_goal_assert(gw->ctx, gw->goal, to_Ast(a)->ast);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Goal_size(b_lean_obj_arg g) {
  Z3GoalWrapper *gw = to_Goal(g);
  return Z3_goal_size(gw->ctx, gw->goal);
}

LEAN_EXPORT lean_obj_res lean_z3_Goal_formula(b_lean_obj_arg g, uint32_t i) {
  Z3GoalWrapper *gw = to_Goal(g);
  return z3_wrap_ast(gw->ctx_obj, gw->ctx, Z3_goal_formula(gw->ctx, gw->goal, i));
}

LEAN_EXPORT uint32_t lean_z3_Goal_depth(b_lean_obj_arg g) {
  return Z3_goal_depth(to_Goal(g)->ctx, to_Goal(g)->goal);
}

LEAN_EXPORT uint8_t lean_z3_Goal_inconsistent(b_lean_obj_arg g) {
  return Z3_goal_inconsistent(to_Goal(g)->ctx, to_Goal(g)->goal);
}

LEAN_EXPORT uint8_t lean_z3_Goal_isDecidedSat(b_lean_obj_arg g) {
  return Z3_goal_is_decided_sat(to_Goal(g)->ctx, to_Goal(g)->goal);
}

LEAN_EXPORT uint8_t lean_z3_Goal_isDecidedUnsat(b_lean_obj_arg g) {
  return Z3_goal_is_decided_unsat(to_Goal(g)->ctx, to_Goal(g)->goal);
}

LEAN_EXPORT lean_obj_res lean_z3_Goal_reset(b_lean_obj_arg g) {
  Z3GoalWrapper *gw = to_Goal(g);
  Z3_goal_reset(gw->ctx, gw->goal);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Goal_toString(b_lean_obj_arg g) {
  Z3GoalWrapper *gw = to_Goal(g);
  const char *s = Z3_goal_to_string(gw->ctx, gw->goal);
  return lean_mk_string(s ? s : "");
}

/* Tactic application */

LEAN_EXPORT lean_obj_res lean_z3_Tactic_apply(b_lean_obj_arg ctx, b_lean_obj_arg t, b_lean_obj_arg g) {
  Z3Ctx *c = to_Context(ctx);
  Z3_apply_result r = Z3_tactic_apply(c->ctx, to_Tactic(t)->tactic, to_Goal(g)->goal);
  return z3_wrap_apply_result(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_applyEx(b_lean_obj_arg ctx, b_lean_obj_arg t, b_lean_obj_arg g, b_lean_obj_arg p) {
  Z3Ctx *c = to_Context(ctx);
  Z3_apply_result r = Z3_tactic_apply_ex(c->ctx, to_Tactic(t)->tactic, to_Goal(g)->goal, to_Params(p)->params);
  return z3_wrap_apply_result(ctx, c->ctx, r);
}

/* ApplyResult */

LEAN_EXPORT uint32_t lean_z3_ApplyResult_getNumSubgoals(b_lean_obj_arg r) {
  Z3ApplyResultWrapper *rw = to_ApplyResult(r);
  return Z3_apply_result_get_num_subgoals(rw->ctx, rw->apply_result);
}

LEAN_EXPORT lean_obj_res lean_z3_ApplyResult_getSubgoal(b_lean_obj_arg r, uint32_t i) {
  Z3ApplyResultWrapper *rw = to_ApplyResult(r);
  Z3_goal g = Z3_apply_result_get_subgoal(rw->ctx, rw->apply_result, i);
  return z3_wrap_goal(rw->ctx_obj, rw->ctx, g);
}

LEAN_EXPORT lean_obj_res lean_z3_ApplyResult_toString(b_lean_obj_arg r) {
  Z3ApplyResultWrapper *rw = to_ApplyResult(r);
  const char *s = Z3_apply_result_to_string(rw->ctx, rw->apply_result);
  return lean_mk_string(s ? s : "");
}

/* Solver from tactic */

LEAN_EXPORT lean_obj_res lean_z3_Solver_fromTactic(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  Z3_solver s = Z3_mk_solver_from_tactic(c->ctx, to_Tactic(t)->tactic);
  Z3_solver_inc_ref(c->ctx, s);
  Z3SolverWrapper *w = (Z3SolverWrapper *)malloc(sizeof(Z3SolverWrapper));
  if (w == NULL) { Z3_solver_dec_ref(c->ctx, s); return z3_env_error("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = c->ctx;
  w->solver = s;
  return z3_env_val(mk_Solver(w));
}

/* Tactic-probe combinators */

LEAN_EXPORT lean_obj_res lean_z3_Tactic_when(b_lean_obj_arg ctx, b_lean_obj_arg probe, b_lean_obj_arg tactic) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_when(c->ctx, to_Probe(probe)->probe, to_Tactic(tactic)->tactic);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_cond(b_lean_obj_arg ctx, b_lean_obj_arg probe, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_cond(c->ctx, to_Probe(probe)->probe, to_Tactic(t1)->tactic, to_Tactic(t2)->tactic);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_failIf(b_lean_obj_arg ctx, b_lean_obj_arg probe) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_fail_if(c->ctx, to_Probe(probe)->probe);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

LEAN_EXPORT lean_obj_res lean_z3_Tactic_failIfNotDecided(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_tactic r = Z3_tactic_fail_if_not_decided(c->ctx);
  return z3_wrap_tactic(ctx, c->ctx, r);
}

/* ── Floating point theory ────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpa(b_lean_obj_arg ctx, uint32_t ebits, uint32_t sbits) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_sort(c->ctx, ebits, sbits));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpa32(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_sort_32(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpa64(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_sort_64(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpa16(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_sort_16(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpa128(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_sort_128(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFpaRoundingMode(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_fpa_rounding_mode_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRne(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rne(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRna(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rna(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRtp(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rtp(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRtn(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rtn(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRtz(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rtz(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaNan(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_nan(c->ctx, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaInf(b_lean_obj_arg ctx, b_lean_obj_arg s, uint8_t negative) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_inf(c->ctx, to_Srt(s)->sort, negative));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaZero(b_lean_obj_arg ctx, b_lean_obj_arg s, uint8_t negative) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_zero(c->ctx, to_Srt(s)->sort, negative));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaNumeralDouble(b_lean_obj_arg ctx, double v, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_numeral_double(c->ctx, v, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaNumeralInt(b_lean_obj_arg ctx, uint32_t v, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_numeral_int(c->ctx, (signed)v, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaAdd(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_add(c->ctx, to_Ast(rm)->ast, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaSub(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_sub(c->ctx, to_Ast(rm)->ast, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaMul(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_mul(c->ctx, to_Ast(rm)->ast, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaDiv(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_div(c->ctx, to_Ast(rm)->ast, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaFma(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t1, b_lean_obj_arg t2, b_lean_obj_arg t3) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_fma(c->ctx, to_Ast(rm)->ast, to_Ast(t1)->ast, to_Ast(t2)->ast, to_Ast(t3)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaSqrt(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_sqrt(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRem(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_rem(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaAbs(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_abs(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaNeg(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_neg(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaMin(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_min(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaMax(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_max(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaRoundToIntegral(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_round_to_integral(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaLt(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_lt(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaLeq(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_leq(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaGt(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_gt(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaGeq(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_geq(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaEq(b_lean_obj_arg ctx, b_lean_obj_arg t1, b_lean_obj_arg t2) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_eq(c->ctx, to_Ast(t1)->ast, to_Ast(t2)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsNan(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_nan(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsInf(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_infinite(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsZero(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_zero(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsNormal(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_normal(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsSubnormal(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_subnormal(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsNegative(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_negative(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaIsPositive(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_is_positive(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToFpBv(b_lean_obj_arg ctx, b_lean_obj_arg bv, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_fp_bv(c->ctx, to_Ast(bv)->ast, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToFpFloat(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_fp_float(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToFpReal(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_fp_real(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToFpSigned(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_fp_signed(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToFpUnsigned(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_fp_unsigned(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToUbv(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, uint32_t sz) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_ubv(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, sz));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToSbv(b_lean_obj_arg ctx, b_lean_obj_arg rm, b_lean_obj_arg t, uint32_t sz) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_sbv(c->ctx, to_Ast(rm)->ast, to_Ast(t)->ast, sz));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToReal(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_real(c->ctx, to_Ast(t)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFpaToIeeeBv(b_lean_obj_arg ctx, b_lean_obj_arg t) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_fpa_to_ieee_bv(c->ctx, to_Ast(t)->ast));
}

/* ── Additional sorts ─────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkFiniteDomain(b_lean_obj_arg ctx, b_lean_obj_arg name, uint64_t size) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol sym = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_finite_domain_sort(c->ctx, sym, size));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkChar(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_char_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkEnumeration(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg enumNames) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(enumNames);
  Z3_symbol z3_name = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_symbol *z3_names = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  Z3_func_decl *consts = (Z3_func_decl *)malloc(n * sizeof(Z3_func_decl));
  Z3_func_decl *testers = (Z3_func_decl *)malloc(n * sizeof(Z3_func_decl));
  if ((n > 0) && (z3_names == NULL || consts == NULL || testers == NULL)) {
    free(z3_names); free(consts); free(testers);
    return z3_env_error("out of memory");
  }
  for (unsigned i = 0; i < n; i++) {
    z3_names[i] = Z3_mk_string_symbol(c->ctx, lean_string_cstr(lean_array_get_core(enumNames, i)));
  }
  Z3_sort s = Z3_mk_enumeration_sort(c->ctx, z3_name, n, z3_names, consts, testers);

  lean_object *sort_lean = z3_wrap_sort(ctx, c->ctx, s);
  lean_object *consts_arr = lean_mk_empty_array();
  lean_object *testers_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    consts_arr = lean_array_push(consts_arr, z3_wrap_func_decl(ctx, c->ctx, consts[i]));
    testers_arr = lean_array_push(testers_arr, z3_wrap_func_decl(ctx, c->ctx, testers[i]));
  }
  free(z3_names); free(consts); free(testers);

  /* Build (Srt × Array FuncDecl × Array FuncDecl) */
  lean_object *inner = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(inner, 0, consts_arr);
  lean_ctor_set(inner, 1, testers_arr);
  lean_object *triple = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(triple, 0, sort_lean);
  lean_ctor_set(triple, 1, inner);

  return z3_env_val(triple);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkList(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg elemSort) {
  Z3Ctx *c = to_Context(ctx);
  Z3_symbol z3_name = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_func_decl nil_decl, is_nil_decl, cons_decl, is_cons_decl, head_decl, tail_decl;
  Z3_sort s = Z3_mk_list_sort(c->ctx, z3_name, to_Srt(elemSort)->sort,
    &nil_decl, &is_nil_decl, &cons_decl, &is_cons_decl, &head_decl, &tail_decl);

  lean_object *sort_lean = z3_wrap_sort(ctx, c->ctx, s);
  lean_object *nil_lean = z3_wrap_func_decl(ctx, c->ctx, nil_decl);
  lean_object *is_nil_lean = z3_wrap_func_decl(ctx, c->ctx, is_nil_decl);
  lean_object *cons_lean = z3_wrap_func_decl(ctx, c->ctx, cons_decl);
  lean_object *is_cons_lean = z3_wrap_func_decl(ctx, c->ctx, is_cons_decl);
  lean_object *head_lean = z3_wrap_func_decl(ctx, c->ctx, head_decl);
  lean_object *tail_lean = z3_wrap_func_decl(ctx, c->ctx, tail_decl);

  /* Build (Srt × FuncDecl × FuncDecl × FuncDecl × FuncDecl × FuncDecl × FuncDecl)
     as nested Prod: (s, (nil, (is_nil, (cons, (is_cons, (head, tail)))))) */
  lean_object *p5 = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(p5, 0, head_lean);
  lean_ctor_set(p5, 1, tail_lean);
  lean_object *p4 = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(p4, 0, is_cons_lean);
  lean_ctor_set(p4, 1, p5);
  lean_object *p3 = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(p3, 0, cons_lean);
  lean_ctor_set(p3, 1, p4);
  lean_object *p2 = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(p2, 0, is_nil_lean);
  lean_ctor_set(p2, 1, p3);
  lean_object *p1 = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(p1, 0, nil_lean);
  lean_ctor_set(p1, 1, p2);
  lean_object *result = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(result, 0, sort_lean);
  lean_ctor_set(result, 1, p1);

  return z3_env_val(result);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkTuple(b_lean_obj_arg ctx, b_lean_obj_arg name,
    b_lean_obj_arg fieldNames, b_lean_obj_arg fieldSorts) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(fieldNames);
  if (n != lean_array_size(fieldSorts)) {
    return z3_env_error("fieldNames and fieldSorts must have same length");
  }
  Z3_symbol z3_name = Z3_mk_string_symbol(c->ctx, lean_string_cstr(name));
  Z3_symbol *z3_fnames = NULL;
  Z3_sort *z3_fsorts = NULL;
  Z3_func_decl mk_tuple_decl;
  Z3_func_decl *proj_decls = NULL;
  if (n > 0) {
    z3_fnames = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
    z3_fsorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
    proj_decls = (Z3_func_decl *)malloc(n * sizeof(Z3_func_decl));
    if (z3_fnames == NULL || z3_fsorts == NULL || proj_decls == NULL) {
      free(z3_fnames); free(z3_fsorts); free(proj_decls);
      return z3_env_error("out of memory");
    }
    for (unsigned i = 0; i < n; i++) {
      z3_fnames[i] = Z3_mk_string_symbol(c->ctx, lean_string_cstr(lean_array_get_core(fieldNames, i)));
      z3_fsorts[i] = to_Srt(lean_array_get_core(fieldSorts, i))->sort;
    }
  }
  Z3_sort s = Z3_mk_tuple_sort(c->ctx, z3_name, n, z3_fnames, z3_fsorts, &mk_tuple_decl, proj_decls);

  lean_object *sort_lean = z3_wrap_sort(ctx, c->ctx, s);
  lean_object *mk_lean = z3_wrap_func_decl(ctx, c->ctx, mk_tuple_decl);
  lean_object *projs_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < n; i++) {
    projs_arr = lean_array_push(projs_arr, z3_wrap_func_decl(ctx, c->ctx, proj_decls[i]));
  }
  free(z3_fnames); free(z3_fsorts); free(proj_decls);

  /* Build (Srt × FuncDecl × Array FuncDecl) */
  lean_object *inner = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(inner, 0, mk_lean);
  lean_ctor_set(inner, 1, projs_arr);
  lean_object *triple = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(triple, 0, sort_lean);
  lean_ctor_set(triple, 1, inner);

  return z3_env_val(triple);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkDatatypes(b_lean_obj_arg ctx,
    b_lean_obj_arg names, b_lean_obj_arg constructorGroups) {
  Z3Ctx *c = to_Context(ctx);
  unsigned num_sorts = lean_array_size(names);
  if (num_sorts != lean_array_size(constructorGroups)) {
    return z3_env_error("names and constructorGroups must have same length");
  }
  if (num_sorts == 0) {
    return z3_env_error("must have at least one sort");
  }

  Z3_symbol *z3_names = (Z3_symbol *)malloc(num_sorts * sizeof(Z3_symbol));
  Z3_sort *z3_sorts = (Z3_sort *)malloc(num_sorts * sizeof(Z3_sort));
  Z3_constructor_list *z3_clists = (Z3_constructor_list *)malloc(num_sorts * sizeof(Z3_constructor_list));
  if (z3_names == NULL || z3_sorts == NULL || z3_clists == NULL) {
    free(z3_names); free(z3_sorts); free(z3_clists);
    return z3_env_error("out of memory");
  }

  for (unsigned i = 0; i < num_sorts; i++) {
    z3_names[i] = Z3_mk_string_symbol(c->ctx, lean_string_cstr(lean_array_get_core(names, i)));
    lean_object *group = lean_array_get_core(constructorGroups, i);
    unsigned nc = lean_array_size(group);
    Z3_constructor *cons = (Z3_constructor *)malloc(nc * sizeof(Z3_constructor));
    if (cons == NULL) {
      /* Clean up already-created lists */
      for (unsigned j = 0; j < i; j++) Z3_del_constructor_list(c->ctx, z3_clists[j]);
      free(z3_names); free(z3_sorts); free(z3_clists);
      return z3_env_error("out of memory");
    }
    for (unsigned j = 0; j < nc; j++) {
      cons[j] = to_Constructor(lean_array_get_core(group, j))->constructor;
    }
    z3_clists[i] = Z3_mk_constructor_list(c->ctx, nc, cons);
    free(cons);
  }

  Z3_mk_datatypes(c->ctx, num_sorts, z3_names, z3_sorts, z3_clists);

  /* Build result array of sorts */
  lean_object *result_arr = lean_mk_empty_array();
  for (unsigned i = 0; i < num_sorts; i++) {
    result_arr = lean_array_push(result_arr, z3_wrap_sort(ctx, c->ctx, z3_sorts[i]));
  }

  /* Update constructor wrappers in-place (like mkDatatype) and clean up */
  for (unsigned i = 0; i < num_sorts; i++) {
    Z3_del_constructor_list(c->ctx, z3_clists[i]);
  }
  free(z3_names); free(z3_sorts); free(z3_clists);

  return z3_env_val(result_arr);
}

/* ── Sort inspection (extended) ───────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_getArraySortDomain(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_get_array_sort_domain(c->ctx, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getArraySortDomainN(b_lean_obj_arg ctx, b_lean_obj_arg s, uint32_t idx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_get_array_sort_domain_n(c->ctx, to_Srt(s)->sort, idx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getArraySortRange(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_get_array_sort_range(c->ctx, to_Srt(s)->sort));
}

LEAN_EXPORT uint32_t lean_z3_Srt_getDatatypeSortNumConstructors(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return Z3_get_datatype_sort_num_constructors(c->ctx, to_Srt(s)->sort);
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getDatatypeSortConstructor(b_lean_obj_arg ctx, b_lean_obj_arg s, uint32_t idx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_func_decl(ctx, c->ctx, Z3_get_datatype_sort_constructor(c->ctx, to_Srt(s)->sort, idx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getDatatypeSortRecognizer(b_lean_obj_arg ctx, b_lean_obj_arg s, uint32_t idx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_func_decl(ctx, c->ctx, Z3_get_datatype_sort_recognizer(c->ctx, to_Srt(s)->sort, idx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_getDatatypeSortConstructorAccessor(b_lean_obj_arg ctx, b_lean_obj_arg s, uint32_t idxC, uint32_t idxA) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_func_decl(ctx, c->ctx, Z3_get_datatype_sort_constructor_accessor(c->ctx, to_Srt(s)->sort, idxC, idxA));
}

/* ── Sets ─────────────────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkSet(b_lean_obj_arg ctx, b_lean_obj_arg ty) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_set_sort(c->ctx, to_Srt(ty)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkEmptySet(b_lean_obj_arg ctx, b_lean_obj_arg domain) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_empty_set(c->ctx, to_Srt(domain)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkFullSet(b_lean_obj_arg ctx, b_lean_obj_arg domain) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_full_set(c->ctx, to_Srt(domain)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetAdd(b_lean_obj_arg ctx, b_lean_obj_arg set, b_lean_obj_arg elem) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_add(c->ctx, to_Ast(set)->ast, to_Ast(elem)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetDel(b_lean_obj_arg ctx, b_lean_obj_arg set, b_lean_obj_arg elem) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_del(c->ctx, to_Ast(set)->ast, to_Ast(elem)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetUnion(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_union(c->ctx, n, buf));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetIntersect(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_intersect(c->ctx, n, buf));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetDifference(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_difference(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetComplement(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_complement(c->ctx, to_Ast(a)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetMember(b_lean_obj_arg ctx, b_lean_obj_arg elem, b_lean_obj_arg set) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_member(c->ctx, to_Ast(elem)->ast, to_Ast(set)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSetSubset(b_lean_obj_arg ctx, b_lean_obj_arg a, b_lean_obj_arg b) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_set_subset(c->ctx, to_Ast(a)->ast, to_Ast(b)->ast));
}

/* ── String / Sequence theory ─────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkString(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_string_sort(c->ctx));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkSeq(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_seq_sort(c->ctx, to_Srt(s)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Srt_mkRe(b_lean_obj_arg ctx, b_lean_obj_arg seq) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_sort(ctx, c->ctx, Z3_mk_re_sort(c->ctx, to_Srt(seq)->sort));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkString(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  const char *str = lean_string_cstr(s);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_string(c->ctx, str));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_getString(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  Z3_string str = Z3_get_string(c->ctx, to_Ast(a)->ast);
  return lean_mk_string(str);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqConcat(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_concat(c->ctx, n, buf));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqLength(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_length(c->ctx, to_Ast(s)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqContains(b_lean_obj_arg ctx, b_lean_obj_arg container, b_lean_obj_arg containee) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_contains(c->ctx, to_Ast(container)->ast, to_Ast(containee)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqPrefix(b_lean_obj_arg ctx, b_lean_obj_arg pfx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_prefix(c->ctx, to_Ast(pfx)->ast, to_Ast(s)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqSuffix(b_lean_obj_arg ctx, b_lean_obj_arg sfx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_suffix(c->ctx, to_Ast(sfx)->ast, to_Ast(s)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqExtract(b_lean_obj_arg ctx, b_lean_obj_arg s, b_lean_obj_arg offset, b_lean_obj_arg length) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_extract(c->ctx, to_Ast(s)->ast, to_Ast(offset)->ast, to_Ast(length)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqAt(b_lean_obj_arg ctx, b_lean_obj_arg s, b_lean_obj_arg index) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_at(c->ctx, to_Ast(s)->ast, to_Ast(index)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqIndex(b_lean_obj_arg ctx, b_lean_obj_arg s, b_lean_obj_arg substr, b_lean_obj_arg offset) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_index(c->ctx, to_Ast(s)->ast, to_Ast(substr)->ast, to_Ast(offset)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkStrToInt(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_str_to_int(c->ctx, to_Ast(s)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkIntToStr(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_int_to_str(c->ctx, to_Ast(s)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqToRe(b_lean_obj_arg ctx, b_lean_obj_arg seq) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_to_re(c->ctx, to_Ast(seq)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkSeqInRe(b_lean_obj_arg ctx, b_lean_obj_arg seq, b_lean_obj_arg re) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_seq_in_re(c->ctx, to_Ast(seq)->ast, to_Ast(re)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReStar(b_lean_obj_arg ctx, b_lean_obj_arg re) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_star(c->ctx, to_Ast(re)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkRePlus(b_lean_obj_arg ctx, b_lean_obj_arg re) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_plus(c->ctx, to_Ast(re)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReOption(b_lean_obj_arg ctx, b_lean_obj_arg re) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_option(c->ctx, to_Ast(re)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReUnion(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_union(c->ctx, n, buf));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReConcat(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_concat(c->ctx, n, buf));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReRange(b_lean_obj_arg ctx, b_lean_obj_arg lo, b_lean_obj_arg hi) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_range(c->ctx, to_Ast(lo)->ast, to_Ast(hi)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReComplement(b_lean_obj_arg ctx, b_lean_obj_arg re) {
  Z3Ctx *c = to_Context(ctx);
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_complement(c->ctx, to_Ast(re)->ast));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkReIntersect(b_lean_obj_arg ctx, b_lean_obj_arg args) {
  Z3Ctx *c = to_Context(ctx);
  unsigned n = lean_array_size(args);
  Z3_ast buf[n];
  for (unsigned i = 0; i < n; i++) buf[i] = to_Ast(lean_array_get_core(args, i))->ast;
  return z3_wrap_ast(ctx, c->ctx, Z3_mk_re_intersect(c->ctx, n, buf));
}

/* ── Optimization API ─────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Optimize_new(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_optimize o = Z3_mk_optimize(c->ctx);
  Z3_optimize_inc_ref(c->ctx, o);
  Z3OptimizeWrapper *w = (Z3OptimizeWrapper *)malloc(sizeof(Z3OptimizeWrapper));
  if (w == NULL) { Z3_optimize_dec_ref(c->ctx, o); return z3_env_error("out of memory"); }
  lean_inc(ctx);
  w->ctx_obj = ctx;
  w->ctx = c->ctx;
  w->optimize = o;
  return z3_env_val(mk_Optimize(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_assert(b_lean_obj_arg o, b_lean_obj_arg a) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_optimize_assert(ow->ctx, ow->optimize, to_Ast(a)->ast);
  return lean_box(0);
}

LEAN_EXPORT uint32_t lean_z3_Optimize_assertSoft(b_lean_obj_arg o, b_lean_obj_arg a, b_lean_obj_arg weight, b_lean_obj_arg id) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_symbol sym = Z3_mk_string_symbol(ow->ctx, lean_string_cstr(id));
  return Z3_optimize_assert_soft(ow->ctx, ow->optimize, to_Ast(a)->ast, lean_string_cstr(weight), sym);
}

LEAN_EXPORT uint32_t lean_z3_Optimize_maximize(b_lean_obj_arg o, b_lean_obj_arg a) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  return Z3_optimize_maximize(ow->ctx, ow->optimize, to_Ast(a)->ast);
}

LEAN_EXPORT uint32_t lean_z3_Optimize_minimize(b_lean_obj_arg o, b_lean_obj_arg a) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  return Z3_optimize_minimize(ow->ctx, ow->optimize, to_Ast(a)->ast);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_check(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_lbool r = Z3_optimize_check(ow->ctx, ow->optimize, 0, NULL);
  /* Map: Z3_L_FALSE=-1 → 0, Z3_L_UNDEF=0 → 1, Z3_L_TRUE=1 → 2 */
  return lean_box((uint8_t)(r + 1));
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_getModel(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_model m = Z3_optimize_get_model(ow->ctx, ow->optimize);
  if (m == NULL) {
    return z3_env_error("no model available");
  }
  Z3_model_inc_ref(ow->ctx, m);
  Z3ModelWrapper *w = (Z3ModelWrapper *)malloc(sizeof(Z3ModelWrapper));
  if (w == NULL) { Z3_model_dec_ref(ow->ctx, m); return z3_env_error("out of memory"); }
  lean_inc(ow->ctx_obj);
  w->ctx_obj = ow->ctx_obj;
  w->ctx = ow->ctx;
  w->model = m;
  return z3_env_val(mk_Model(w));
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_getLower(b_lean_obj_arg o, uint32_t idx) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_ast a = Z3_optimize_get_lower(ow->ctx, ow->optimize, idx);
  return z3_wrap_ast(ow->ctx_obj, ow->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_getUpper(b_lean_obj_arg o, uint32_t idx) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_ast a = Z3_optimize_get_upper(ow->ctx, ow->optimize, idx);
  return z3_wrap_ast(ow->ctx_obj, ow->ctx, a);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_push(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_optimize_push(ow->ctx, ow->optimize);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_pop(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3_optimize_pop(ow->ctx, ow->optimize);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_toString(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  const char *str = Z3_optimize_to_string(ow->ctx, ow->optimize);
  if (str == NULL) { lean_internal_panic("Z3_optimize_to_string returned NULL"); }
  return lean_mk_string(str);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_setParams(b_lean_obj_arg o, b_lean_obj_arg p) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  Z3ParamsWrapper *pw = to_Params(p);
  Z3_optimize_set_params(ow->ctx, ow->optimize, pw->params);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Optimize_getReasonUnknown(b_lean_obj_arg o) {
  Z3OptimizeWrapper *ow = to_Optimize(o);
  const char *str = Z3_optimize_get_reason_unknown(ow->ctx, ow->optimize);
  if (str == NULL) return lean_mk_string("unknown");
  return lean_mk_string(str);
}

/* ── SMT-LIB parsing ──────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Context_parseSMTLIB2String(b_lean_obj_arg ctx, b_lean_obj_arg str) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast_vector vec = Z3_parse_smtlib2_string(c->ctx, lean_string_cstr(str), 0, NULL, NULL, 0, NULL, NULL);
  if (vec == NULL) {
    return z3_env_error("SMT-LIB2 parse failed");
  }
  Z3_ast_vector_inc_ref(c->ctx, vec);
  unsigned n = Z3_ast_vector_size(c->ctx, vec);
  lean_obj_res result;
  if (n == 0) {
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_mk_true(c->ctx)));
  } else if (n == 1) {
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_ast_vector_get(c->ctx, vec, 0)));
  } else {
    Z3_ast *args = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    if (args == NULL) { Z3_ast_vector_dec_ref(c->ctx, vec); return z3_env_error("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      args[i] = Z3_ast_vector_get(c->ctx, vec, i);
    }
    Z3_ast conj = Z3_mk_and(c->ctx, n, args);
    free(args);
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, conj));
  }
  Z3_ast_vector_dec_ref(c->ctx, vec);
  return result;
}

LEAN_EXPORT lean_obj_res lean_z3_Context_parseSMTLIB2File(b_lean_obj_arg ctx, b_lean_obj_arg filename) {
  Z3Ctx *c = to_Context(ctx);
  Z3_ast_vector vec = Z3_parse_smtlib2_file(c->ctx, lean_string_cstr(filename), 0, NULL, NULL, 0, NULL, NULL);
  if (vec == NULL) {
    return z3_env_error("SMT-LIB2 file parse failed");
  }
  Z3_ast_vector_inc_ref(c->ctx, vec);
  unsigned n = Z3_ast_vector_size(c->ctx, vec);
  lean_obj_res result;
  if (n == 0) {
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_mk_true(c->ctx)));
  } else if (n == 1) {
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, Z3_ast_vector_get(c->ctx, vec, 0)));
  } else {
    Z3_ast *args = (Z3_ast *)malloc(n * sizeof(Z3_ast));
    if (args == NULL) { Z3_ast_vector_dec_ref(c->ctx, vec); return z3_env_error("out of memory"); }
    for (unsigned i = 0; i < n; i++) {
      args[i] = Z3_ast_vector_get(c->ctx, vec, i);
    }
    Z3_ast conj = Z3_mk_and(c->ctx, n, args);
    free(args);
    result = z3_env_val(z3_wrap_ast(ctx, c->ctx, conj));
  }
  Z3_ast_vector_dec_ref(c->ctx, vec);
  return result;
}

LEAN_EXPORT lean_obj_res lean_z3_Context_evalSMTLIB2String(b_lean_obj_arg ctx, b_lean_obj_arg str) {
  Z3Ctx *c = to_Context(ctx);
  Z3_string result = Z3_eval_smtlib2_string(c->ctx, lean_string_cstr(str));
  if (result == NULL) { lean_internal_panic("Z3_eval_smtlib2_string returned NULL"); }
  return lean_mk_string(result);
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
  if (z3_sorts == NULL || z3_names == NULL) { free(z3_sorts); free(z3_names); return z3_env_error("out of memory"); }
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
  if (z3_sorts == NULL || z3_names == NULL) { free(z3_sorts); free(z3_names); return z3_env_error("out of memory"); }
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

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkQuantifierEx(b_lean_obj_arg ctx,
    uint8_t is_forall, uint32_t weight,
    b_lean_obj_arg quantifier_id, b_lean_obj_arg skolem_id,
    b_lean_obj_arg patterns, b_lean_obj_arg no_patterns,
    b_lean_obj_arg sorts, b_lean_obj_arg names,
    b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned n = lean_array_size(sorts);
  if (n != lean_array_size(names)) {
    return z3_env_error("sorts and names must have the same length");
  }
  if (n == 0) {
    return z3_env_error("quantifier must bind at least one variable");
  }
  unsigned np = lean_array_size(patterns);
  unsigned nnp = lean_array_size(no_patterns);

  Z3_sort *z3_sorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
  Z3_symbol *z3_names = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  Z3_pattern *z3_pats = np > 0 ? (Z3_pattern *)malloc(np * sizeof(Z3_pattern)) : NULL;
  Z3_ast *z3_nopats = nnp > 0 ? (Z3_ast *)malloc(nnp * sizeof(Z3_ast)) : NULL;
  if (z3_sorts == NULL || z3_names == NULL ||
      (np > 0 && z3_pats == NULL) || (nnp > 0 && z3_nopats == NULL)) {
    free(z3_sorts); free(z3_names); free(z3_pats); free(z3_nopats);
    return z3_env_error("out of memory");
  }

  for (unsigned i = 0; i < n; i++) {
    z3_sorts[i] = to_Srt(lean_array_get_core(sorts, i))->sort;
    z3_names[i] = Z3_mk_string_symbol(c->ctx,
      lean_string_cstr(lean_array_get_core(names, i)));
  }
  for (unsigned i = 0; i < np; i++) {
    z3_pats[i] = (Z3_pattern)to_Ast(lean_array_get_core(patterns, i))->ast;
  }
  for (unsigned i = 0; i < nnp; i++) {
    z3_nopats[i] = to_Ast(lean_array_get_core(no_patterns, i))->ast;
  }

  Z3_symbol qid = Z3_mk_string_symbol(c->ctx, lean_string_cstr(quantifier_id));
  Z3_symbol sid = Z3_mk_string_symbol(c->ctx, lean_string_cstr(skolem_id));

  Z3_ast q = Z3_mk_quantifier_ex(c->ctx, is_forall, weight, qid, sid,
    np, z3_pats, nnp, z3_nopats, n, z3_sorts, z3_names, bw->ast);
  free(z3_sorts); free(z3_names); free(z3_pats); free(z3_nopats);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, q));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkForallConst(b_lean_obj_arg ctx,
    uint32_t weight, b_lean_obj_arg bound, b_lean_obj_arg patterns,
    b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned nb = lean_array_size(bound);
  unsigned np = lean_array_size(patterns);
  if (nb == 0) {
    return z3_env_error("quantifier must bind at least one variable");
  }

  Z3_app *z3_bound = (Z3_app *)malloc(nb * sizeof(Z3_app));
  Z3_pattern *z3_pats = np > 0 ? (Z3_pattern *)malloc(np * sizeof(Z3_pattern)) : NULL;
  if (z3_bound == NULL || (np > 0 && z3_pats == NULL)) {
    free(z3_bound); free(z3_pats);
    return z3_env_error("out of memory");
  }

  for (unsigned i = 0; i < nb; i++) {
    z3_bound[i] = (Z3_app)to_Ast(lean_array_get_core(bound, i))->ast;
  }
  for (unsigned i = 0; i < np; i++) {
    z3_pats[i] = (Z3_pattern)to_Ast(lean_array_get_core(patterns, i))->ast;
  }

  Z3_ast q = Z3_mk_forall_const(c->ctx, weight, nb, z3_bound, np, z3_pats, bw->ast);
  free(z3_bound); free(z3_pats);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, q));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkExistsConst(b_lean_obj_arg ctx,
    uint32_t weight, b_lean_obj_arg bound, b_lean_obj_arg patterns,
    b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned nb = lean_array_size(bound);
  unsigned np = lean_array_size(patterns);
  if (nb == 0) {
    return z3_env_error("quantifier must bind at least one variable");
  }

  Z3_app *z3_bound = (Z3_app *)malloc(nb * sizeof(Z3_app));
  Z3_pattern *z3_pats = np > 0 ? (Z3_pattern *)malloc(np * sizeof(Z3_pattern)) : NULL;
  if (z3_bound == NULL || (np > 0 && z3_pats == NULL)) {
    free(z3_bound); free(z3_pats);
    return z3_env_error("out of memory");
  }

  for (unsigned i = 0; i < nb; i++) {
    z3_bound[i] = (Z3_app)to_Ast(lean_array_get_core(bound, i))->ast;
  }
  for (unsigned i = 0; i < np; i++) {
    z3_pats[i] = (Z3_pattern)to_Ast(lean_array_get_core(patterns, i))->ast;
  }

  Z3_ast q = Z3_mk_exists_const(c->ctx, weight, nb, z3_bound, np, z3_pats, bw->ast);
  free(z3_bound); free(z3_pats);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, q));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkLambda(b_lean_obj_arg ctx,
    b_lean_obj_arg sorts, b_lean_obj_arg names, b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned n = lean_array_size(sorts);
  if (n != lean_array_size(names)) {
    return z3_env_error("sorts and names must have the same length");
  }
  if (n == 0) {
    return z3_env_error("lambda must bind at least one variable");
  }
  Z3_sort *z3_sorts = (Z3_sort *)malloc(n * sizeof(Z3_sort));
  Z3_symbol *z3_names = (Z3_symbol *)malloc(n * sizeof(Z3_symbol));
  if (z3_sorts == NULL || z3_names == NULL) {
    free(z3_sorts); free(z3_names);
    return z3_env_error("out of memory");
  }
  for (unsigned i = 0; i < n; i++) {
    z3_sorts[i] = to_Srt(lean_array_get_core(sorts, i))->sort;
    z3_names[i] = Z3_mk_string_symbol(c->ctx,
      lean_string_cstr(lean_array_get_core(names, i)));
  }
  Z3_ast lam = Z3_mk_lambda(c->ctx, n, z3_sorts, z3_names, bw->ast);
  free(z3_sorts); free(z3_names);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, lam));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_mkLambdaConst(b_lean_obj_arg ctx,
    b_lean_obj_arg bound, b_lean_obj_arg body) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *bw = to_Ast(body);
  unsigned nb = lean_array_size(bound);
  if (nb == 0) {
    return z3_env_error("lambda must bind at least one variable");
  }
  Z3_app *z3_bound = (Z3_app *)malloc(nb * sizeof(Z3_app));
  if (z3_bound == NULL) { return z3_env_error("out of memory"); }
  for (unsigned i = 0; i < nb; i++) {
    z3_bound[i] = (Z3_app)to_Ast(lean_array_get_core(bound, i))->ast;
  }
  Z3_ast lam = Z3_mk_lambda_const(c->ctx, nb, z3_bound, bw->ast);
  free(z3_bound);
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, lam));
}

/* ── Params (extended) ─────────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Params_setDouble(b_lean_obj_arg p, b_lean_obj_arg name, double val) {
  Z3ParamsWrapper *w = to_Params(p);
  Z3_symbol sym = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  Z3_params_set_double(w->ctx, w->params, sym, val);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Params_setSymbol(b_lean_obj_arg p, b_lean_obj_arg name, b_lean_obj_arg val) {
  Z3ParamsWrapper *w = to_Params(p);
  Z3_symbol key = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  Z3_symbol value = Z3_mk_string_symbol(w->ctx, lean_string_cstr(val));
  Z3_params_set_symbol(w->ctx, w->params, key, value);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Params_toString(b_lean_obj_arg p) {
  Z3ParamsWrapper *w = to_Params(p);
  const char *s = Z3_params_to_string(w->ctx, w->params);
  if (s == NULL) { lean_internal_panic("Z3_params_to_string returned NULL"); }
  return lean_mk_string(s);
}

/* ── Substitution & simplification ─────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Ast_substitute(b_lean_obj_arg ctx,
    b_lean_obj_arg a, b_lean_obj_arg from_arr, b_lean_obj_arg to_arr) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *aw = to_Ast(a);
  unsigned n = lean_array_size(from_arr);
  if (n != lean_array_size(to_arr)) {
    return z3_env_error("substitute: from and to arrays must have the same length");
  }
  Z3_ast *from_asts = (Z3_ast *)malloc(n * sizeof(Z3_ast));
  Z3_ast *to_asts = (Z3_ast *)malloc(n * sizeof(Z3_ast));
  if ((n > 0 && from_asts == NULL) || (n > 0 && to_asts == NULL)) {
    free(from_asts); free(to_asts);
    return z3_env_error("out of memory");
  }
  for (unsigned i = 0; i < n; i++) {
    from_asts[i] = to_Ast(lean_array_get_core(from_arr, i))->ast;
    to_asts[i] = to_Ast(lean_array_get_core(to_arr, i))->ast;
  }
  Z3_ast result = Z3_substitute(c->ctx, aw->ast, n, from_asts, to_asts);
  free(from_asts); free(to_asts);
  if (result == NULL) { return z3_env_error("Z3_substitute failed"); }
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, result));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_substituteVars(b_lean_obj_arg ctx,
    b_lean_obj_arg a, b_lean_obj_arg to_arr) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *aw = to_Ast(a);
  unsigned n = lean_array_size(to_arr);
  Z3_ast *to_asts = n > 0 ? (Z3_ast *)malloc(n * sizeof(Z3_ast)) : NULL;
  if (n > 0 && to_asts == NULL) { return z3_env_error("out of memory"); }
  for (unsigned i = 0; i < n; i++) {
    to_asts[i] = to_Ast(lean_array_get_core(to_arr, i))->ast;
  }
  Z3_ast result = Z3_substitute_vars(c->ctx, aw->ast, n, to_asts);
  free(to_asts);
  if (result == NULL) { return z3_env_error("Z3_substitute_vars failed"); }
  return z3_env_val(z3_wrap_ast(ctx, c->ctx, result));
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_simplify(b_lean_obj_arg ctx, b_lean_obj_arg a) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *aw = to_Ast(a);
  Z3_ast result = Z3_simplify(c->ctx, aw->ast);
  if (result == NULL) { lean_internal_panic("Z3_simplify returned NULL"); }
  return z3_wrap_ast(ctx, c->ctx, result);
}

LEAN_EXPORT lean_obj_res lean_z3_Ast_simplifyEx(b_lean_obj_arg ctx,
    b_lean_obj_arg a, b_lean_obj_arg p) {
  Z3Ctx *c = to_Context(ctx);
  Z3AstWrapper *aw = to_Ast(a);
  Z3ParamsWrapper *pw = to_Params(p);
  Z3_ast result = Z3_simplify_ex(c->ctx, aw->ast, pw->params);
  if (result == NULL) { lean_internal_panic("Z3_simplify_ex returned NULL"); }
  return z3_wrap_ast(ctx, c->ctx, result);
}

LEAN_EXPORT lean_obj_res lean_z3_Context_simplifyGetParamDescrs(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_param_descrs pd = Z3_simplify_get_param_descrs(c->ctx);
  return z3_wrap_param_descrs(ctx, c->ctx, pd);
}

/* ── ParamDescrs operations ────────────────────────────────────────────── */

LEAN_EXPORT lean_obj_res lean_z3_Params_validate(b_lean_obj_arg p, b_lean_obj_arg d) {
  Z3ParamsWrapper *pw = to_Params(p);
  Z3ParamDescrsWrapper *dw = to_ParamDescrs(d);
  Z3_params_validate(pw->ctx, pw->params, dw->param_descrs);
  return lean_box(0);
}

LEAN_EXPORT lean_obj_res lean_z3_Solver_getParamDescrs(b_lean_obj_arg ctx, b_lean_obj_arg s) {
  Z3Ctx *c = to_Context(ctx);
  Z3SolverWrapper *sw = to_Solver(s);
  Z3_param_descrs pd = Z3_solver_get_param_descrs(c->ctx, sw->solver);
  return z3_wrap_param_descrs(ctx, c->ctx, pd);
}

LEAN_EXPORT lean_obj_res lean_z3_Context_getGlobalParamDescrs(b_lean_obj_arg ctx) {
  Z3Ctx *c = to_Context(ctx);
  Z3_param_descrs pd = Z3_get_global_param_descrs(c->ctx);
  return z3_wrap_param_descrs(ctx, c->ctx, pd);
}

LEAN_EXPORT uint32_t lean_z3_ParamDescrs_size(b_lean_obj_arg d) {
  Z3ParamDescrsWrapper *w = to_ParamDescrs(d);
  return Z3_param_descrs_size(w->ctx, w->param_descrs);
}

LEAN_EXPORT lean_obj_res lean_z3_ParamDescrs_getName(b_lean_obj_arg d, uint32_t i) {
  Z3ParamDescrsWrapper *w = to_ParamDescrs(d);
  unsigned sz = Z3_param_descrs_size(w->ctx, w->param_descrs);
  if (i >= sz) { lean_internal_panic("ParamDescrs.getName: index out of bounds"); }
  Z3_symbol sym = Z3_param_descrs_get_name(w->ctx, w->param_descrs, i);
  const char *s = Z3_get_symbol_string(w->ctx, sym);
  if (s == NULL) { lean_internal_panic("Z3_get_symbol_string returned NULL"); }
  return lean_mk_string(s);
}

LEAN_EXPORT uint32_t lean_z3_ParamDescrs_getKind(b_lean_obj_arg d, b_lean_obj_arg name) {
  Z3ParamDescrsWrapper *w = to_ParamDescrs(d);
  Z3_symbol sym = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  return (uint32_t)Z3_param_descrs_get_kind(w->ctx, w->param_descrs, sym);
}

LEAN_EXPORT lean_obj_res lean_z3_ParamDescrs_getDocumentation(b_lean_obj_arg d, b_lean_obj_arg name) {
  Z3ParamDescrsWrapper *w = to_ParamDescrs(d);
  Z3_symbol sym = Z3_mk_string_symbol(w->ctx, lean_string_cstr(name));
  const char *s = Z3_param_descrs_get_documentation(w->ctx, w->param_descrs, sym);
  if (s == NULL) { return lean_mk_string(""); }
  return lean_mk_string(s);
}

LEAN_EXPORT lean_obj_res lean_z3_ParamDescrs_toString(b_lean_obj_arg d) {
  Z3ParamDescrsWrapper *w = to_ParamDescrs(d);
  const char *s = Z3_param_descrs_to_string(w->ctx, w->param_descrs);
  if (s == NULL) { lean_internal_panic("Z3_param_descrs_to_string returned NULL"); }
  return lean_mk_string(s);
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
    if (z3_fnames == NULL || z3_fsorts == NULL || z3_frefs == NULL) {
      free(z3_fnames); free(z3_fsorts); free(z3_frefs);
      return z3_env_error("out of memory");
    }
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
  if (w == NULL) { Z3_del_constructor(c->ctx, con); return z3_env_error("out of memory"); }
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
  if (z3_cons == NULL) { return z3_env_error("out of memory"); }
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
    if (accessors == NULL) { return z3_env_error("out of memory"); }
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
  if (h == NULL) { lean_internal_panic("out of memory"); }
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
 * DeclKind validation: return the actual Z3 C enum value for each DeclKind variant.
 * Index matches the order in Z3/Types.lean DeclKind inductive.
 * Returns 0xFFFFFFFF for out-of-range indices.
 */
LEAN_EXPORT uint32_t lean_z3_DeclKind_expectedRaw(uint32_t idx) {
  static const uint32_t table[] = {
    Z3_OP_TRUE, Z3_OP_FALSE, Z3_OP_EQ, Z3_OP_DISTINCT, Z3_OP_ITE,
    Z3_OP_AND, Z3_OP_OR, Z3_OP_IFF, Z3_OP_XOR, Z3_OP_NOT, Z3_OP_IMPLIES,
    Z3_OP_ANUM, Z3_OP_AGNUM,
    Z3_OP_LE, Z3_OP_GE, Z3_OP_LT, Z3_OP_GT,
    Z3_OP_ADD, Z3_OP_SUB, Z3_OP_UMINUS, Z3_OP_MUL,
    Z3_OP_DIV, Z3_OP_IDIV, Z3_OP_REM, Z3_OP_MOD,
    Z3_OP_TO_REAL, Z3_OP_TO_INT, Z3_OP_IS_INT, Z3_OP_POWER,
    Z3_OP_STORE, Z3_OP_SELECT, Z3_OP_CONST_ARRAY,
    Z3_OP_ARRAY_MAP, Z3_OP_ARRAY_DEFAULT,
    Z3_OP_SET_UNION, Z3_OP_SET_INTERSECT, Z3_OP_SET_DIFFERENCE,
    Z3_OP_SET_COMPLEMENT, Z3_OP_SET_SUBSET, Z3_OP_AS_ARRAY,
    Z3_OP_BNUM, Z3_OP_BNEG, Z3_OP_BADD, Z3_OP_BSUB, Z3_OP_BMUL,
    Z3_OP_BSDIV, Z3_OP_BUDIV, Z3_OP_BSREM, Z3_OP_BUREM, Z3_OP_BSMOD,
    Z3_OP_BNOT, Z3_OP_BAND, Z3_OP_BOR, Z3_OP_BXOR,
    Z3_OP_BNAND, Z3_OP_BNOR, Z3_OP_BXNOR,
    Z3_OP_CONCAT, Z3_OP_SIGN_EXT, Z3_OP_ZERO_EXT,
    Z3_OP_EXTRACT, Z3_OP_REPEAT, Z3_OP_BREDAND, Z3_OP_BREDOR,
    Z3_OP_BSHL, Z3_OP_BLSHR, Z3_OP_BASHR,
    Z3_OP_ROTATE_LEFT, Z3_OP_ROTATE_RIGHT,
    Z3_OP_ULEQ, Z3_OP_SLEQ, Z3_OP_UGEQ, Z3_OP_SGEQ,
    Z3_OP_ULT, Z3_OP_SLT, Z3_OP_UGT, Z3_OP_SGT,
    Z3_OP_BV2INT, Z3_OP_INT2BV,
    Z3_OP_UNINTERPRETED,
  };
  if (idx >= sizeof(table) / sizeof(table[0])) return 0xFFFFFFFF;
  return table[idx];
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

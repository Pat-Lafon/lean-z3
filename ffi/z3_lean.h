/*
 * z3_lean.h — Shared wrapper structs for lean-z3 FFI.
 *
 * Each Z3 object that needs ref-counting stores:
 *   - The raw Z3 pointer
 *   - A reference to the Lean Context object (to prevent GC ordering issues)
 *   - The raw Z3_context pointer (for calling Z3_dec_ref in the finalizer)
 *
 * The Context itself only stores the raw Z3_context pointer.
 */

#ifndef Z3_LEAN_H
#define Z3_LEAN_H

#include <z3.h>
#include <lean/lean.h>
#include <stdlib.h>

/* ── Context ─────────────────────────────────────────────────────────────── */

typedef struct {
  Z3_context ctx;
} Z3Ctx;

/* ── Objects that reference a context ────────────────────────────────────── */

typedef struct {
  lean_object *ctx_obj; /* Lean reference to Context — prevents premature GC */
  Z3_context   ctx;     /* raw context pointer for Z3_dec_ref calls          */
  Z3_solver    solver;
} Z3SolverWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_ast       ast;
} Z3AstWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_sort      sort;
} Z3SortWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_model     model;
} Z3ModelWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_func_decl func_decl;
} Z3FuncDeclWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_params    params;
} Z3ParamsWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_constructor constructor;
} Z3ConstructorWrapper;

typedef struct {
  lean_object *ctx_obj;
  Z3_context   ctx;
  Z3_param_descrs param_descrs;
} Z3ParamDescrsWrapper;

/* ── On-clause collector ─────────────────────────────────────────────────── */

typedef struct {
  lean_object *solver_obj; /* Lean reference to Solver — prevents premature GC */
  lean_object *ctx_obj;    /* Lean reference to Context — for wrapping ASTs   */
  Z3_context   ctx;        /* raw context pointer for Z3_inc_ref              */
  lean_object *events;     /* Lean Array ClauseEvent — grows during solving   */
} Z3OnClauseHandleData;

/* ── FFI helpers ─────────────────────────────────────────────────────────── */

/*
 * Env monad constructors (exported from Lean).
 *
 * In Lean 4.28+, BaseIO = ST IO.RealWorld, and the Void world token
 * is optimized away. Env α = BaseIO (Except Error α), so these
 * functions take only (alpha, value) — no world token.
 */
lean_obj_res z3_env_pure(lean_obj_arg alpha, lean_obj_arg a);
lean_obj_res z3_env_throw_string(lean_obj_arg alpha, lean_obj_arg msg);

static inline lean_obj_res z3_env_val(lean_obj_arg val) {
  return z3_env_pure(lean_box(0), val);
}

static inline lean_obj_res z3_env_error(const char *msg) {
  return z3_env_throw_string(lean_box(0), lean_mk_string(msg));
}

#endif /* Z3_LEAN_H */

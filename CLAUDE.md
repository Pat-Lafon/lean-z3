# lean-z3

Lean 4 FFI bindings to Z3 4.16.0 using raw `@[extern]` C FFI (no alloy dependency).

## Build

```bash
lake build           # library
lake build z3test && .lake/build/bin/z3test   # smoke test
```

Lean toolchain: `v4.28.0`.

## Architecture

### File layout

- `Z3/Types.lean` — Pure types: `LBool`, `SortKind`, `AstKind`, `ProofRule`, `Error`
- `Z3/Env.lean` — `Env α = ExceptT Error BaseIO α` monad, `Env.run` helper, FFI-exported helpers (`z3_env_pure`, `z3_env_throw_string`, etc.)
- `Z3/FFI.lean` — Opaque type declarations (`opaque Foo.Pointed : NonemptyType`), `@[extern]` function signatures, and pure Lean helpers (proof tree navigation, `AstKind`/`ProofRule` inspection)
- `ffi/z3_ffi.c` — All C FFI implementation (external class registration, wrap/unwrap helpers, all extern functions)
- `ffi/z3_lean.h` — Shared C wrapper structs (`Z3AstWrapper`, `Z3SortWrapper`, etc.) and Env monad C helpers
- `Z3Test/Harness.lean` — Test infrastructure (`TestResult`, `runTest`, `check`, `runTests`)
- `Z3Test/Basic.lean` — Core binding tests (14 tests)
- `Z3Test/Z3Rs.lean` — Tests translated from z3-rs (18 tests)
- `Z3Test/Arrays.lean` — Array and distinct operation tests (8 tests)
- `Z3Test/Proofs.lean` — Proof API and AST kind tests (7 tests)
- `Z3Test/Main.lean` — Test runner entry point

### Critical constraints

1. **Allocating FFI functions must return `BaseIO T`, not pure `T`.** Otherwise Lean's compiler may CSE/share results across call sites. This applies to `Solver.new`, `Params.new`, `Context.new` (via `Env`), and any future constructor that allocates.

2. **State-mutating FFI functions must return `BaseIO PUnit`, not `Unit`.** Returning `Unit` lets the compiler optimize away side effects.

2b. **State-dependent query functions must return `BaseIO T`, not pure `T`.** This includes `Solver.checkSat` — if pure, the compiler may cache/CSE results across push/pop/reset boundaries. The C function still returns the raw scalar (e.g., `uint32_t`); the Lean-generated wrapper handles boxing.

3. **Sort is named `Srt`** — `Sort` conflicts with Lean's built-in keyword.

4. **Z3 reference counting** — We use `Z3_mk_context_rc` mode. Every Z3 object needs `Z3_inc_ref` on creation and `Z3_dec_ref` in its finalizer. Exception: `Z3_constructor` uses `Z3_del_constructor`.

5. **GC ordering** — Every wrapper struct holds `lean_object *ctx_obj` (a Lean ref to the Context) to prevent the context from being GC'd before its children.

6. **BaseIO ABI (Lean 4.28+)** — `BaseIO α = ST IO.RealWorld α`. The `Void` world token is optimized away by the compiler. BaseIO and Env extern functions do **not** receive or return a world token. They take only their declared arguments and return the value directly (no `lean_io_result_mk_ok` wrapping). For `BaseIO PUnit`, return `lean_box(0)`.

7. **`toString'` naming convention** — All opaque types use `Foo.toString' : Foo → String` as the extern name, with a separate `instance : ToString Foo := ⟨fun x => Foo.toString' x⟩`. The apostrophe avoids conflicting with `ToString.toString`.

8. **Env namespace pitfall** — Inside `namespace Env`, a bare `.run` call (e.g., `action.run`) resolves to `Env.run` (self-recursion), **not** `ExceptT.run`. Always use `ExceptT.run action` explicitly when inside the `Env` namespace.

### FFI patterns

New opaque type (Lean side):
```lean
opaque Foo.Pointed : NonemptyType
def Foo : Type := Foo.Pointed.type
instance : Nonempty Foo := Foo.Pointed.property
```

New opaque type (C side — register external class):
```c
static void Foo_finalize(void *p) {
  FooWrapper *w = (FooWrapper *)p;
  Z3_dec_ref(w->ctx, (Z3_ast)w->foo);
  lean_dec(w->ctx_obj);
  free(w);
}
// In get_Foo_class:
lean_register_external_class(Foo_finalize, noop_foreach);
```

Wrapping a Z3 object (inc_ref + allocate wrapper + wrap as external):
```c
static inline lean_obj_res z3_wrap_ast(b_lean_obj_arg ctx, Z3_context raw_ctx, Z3_ast ast) {
  Z3_inc_ref(raw_ctx, ast);
  Z3AstWrapper *w = (Z3AstWrapper *)malloc(sizeof(Z3AstWrapper));
  lean_inc(ctx);
  w->ctx_obj = ctx; w->ctx = raw_ctx; w->ast = ast;
  return mk_Ast(w);  // lean_alloc_external(get_Ast_class(), w)
}
```

Returning success from C into the Env monad (no world token):
```c
return z3_env_val(mk_Foo(w));
```

Returning an error:
```c
return z3_env_error("message");
```

BaseIO PUnit return:
```c
return lean_box(0);
```

### Proof API

Z3 proofs are regular `Z3_ast` nodes where the function declaration's `decl_kind` is one of the `Z3_OP_PR_*` constants (base `0x500`). Navigation:

- `Ast.getProofRule? : Ast → Option ProofRule` — checks if an app node is a proof step
- `Ast.getArgs : Ast → Array Ast` — children/antecedents of a proof node
- `Ast.collectProofRules : Ast → Array ProofRule` — DFS over the proof tree collecting all unique rules
- `ProofRule` inductive in `Z3/Types.lean` maps all 42 `Z3_OP_PR_*` variants with `ofRaw?`/`toRaw` conversion

Proof extraction requires `Context.newWithProofs` (enables `Z3_mk_context_rc` with proof mode). After `Solver.checkSat` returns `.false`, call `Solver.getProof` to get the proof AST root.

### Build specifics

- Z3 4.16.0 removed `Z3_bool`; use C99 `bool` instead
- `ffi/z3_ffi.c` is compiled via `extern_lib` in lakefile.lean using `buildO` + `buildStaticLib`
- No external Lean dependencies (alloy removed)

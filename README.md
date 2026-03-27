# lean-z3

Lean 4 FFI bindings to the [Z3](https://github.com/Z3Prover/z3) SMT solver using raw `@[extern]` C FFI.

- **Z3 version:** 4.16.0
- **Lean toolchain:** 4.28.0
- **No external Lean dependencies** (alloy removed)

## Status

### Done

- [x] **Project scaffolding** — lakefile, Z3 binary download (macOS/Linux/Windows)
- [x] **Memory management** — wrapper structs hold Z3 pointer + Lean Context ref to prevent GC ordering issues; proper `Z3_inc_ref`/`Z3_dec_ref` in finalizers
- [x] **Opaque types** — `Context`, `Srt`, `Ast`, `FuncDecl`, `Params`, `Solver`, `Model`, `Constructor` via `NonemptyType` pattern
- [x] **Env monad** — `ExceptT Error BaseIO` with FFI helpers for C-to-Lean error propagation
- [x] **Context** — `new`, `newWithProofs`
- [x] **Sorts** — Bool, Int, Real, BV, Uninterpreted + inspection (`getKindRaw`, `getName`, `getBvSize`)
- [x] **Term constructors** — `mkBool`, `mkNumeral`, `mkIntConst`, `mkBoolConst`, `mkConst`, `mkBvConst`
- [x] **Boolean ops** — `not`, `and`, `or`, `implies`, `eq`, `ite`
- [x] **Arithmetic ops** — `add`, `sub`, `mul`, `lt`, `le`, `gt`, `ge`
- [x] **Term inspection** — `getSort`, `getNumArgs`, `getArg`, `getFuncDecl`, `getNumeralString`, `toString`
- [x] **FuncDecl** — `getDeclKindRaw`, `getName`, `toString`
- [x] **Params** — `new`, `setBool`, `setUInt`
- [x] **Solver** — `new`, `setParams`, `assert`, `push`, `pop`, `reset`, `checkSat`, `getReasonUnknown`, `getProof`, `toString`
- [x] **Model** — `eval`, `getNumConsts`, `getConstDecl`, `getConstInterp`, `toString`
- [x] **SMT-LIB parsing** — `parseSMTLIB2String`
- [x] **Quantifiers** — `mkBound`, `mkForall`, `mkExists`
- [x] **Datatypes** — `Constructor.mk`, `Srt.mkDatatype`, `Constructor.query`
- [x] **Arrays** — `Srt.mkArray`, `Ast.select`, `Ast.store`, `Ast.constArray`
- [x] **Distinct** — `Ast.distinct`
- [x] **Proof API** — `ProofRule` inductive (42 rules), `Ast.getProofRule?`, `Ast.collectProofRules`, proof tree navigation
- [x] **AST kind inspection** — `Ast.getAstKind`, `AstKind.ofRaw`
- [x] **Test suite** — 47 tests: core bindings, z3-rs translations, arrays, proofs

### TODO — Core Bindings

- [ ] **Enum mappings**
  - [ ] `Z3_sort_kind` → `SortKind` (convert `getKindRaw` to typed Lean enum)
  - [ ] `Z3_decl_kind` → `DeclKind` (~300 variants: AND, OR, NOT, EQ, ADD, MUL, BV ops, proof rules, etc.)
  - [ ] `Z3_ast_kind` → `AstKind` (convert raw to typed)
- [ ] **More term constructors**
  - [x] `distinct`
  - [ ] `mkIntVal` / `mkRealVal` (numeric convenience)
  - [x] Array: `mkSelect`, `mkStore`, `mkConstArray`, `mkArraySort`
  - [ ] Bitvector: `mkBvAnd`, `mkBvOr`, `mkBvAdd`, `mkBvMul`, `mkBvShl`, `mkBvLshr`, `mkBvExtract`, `mkBvConcat`, `mkBvNot`, `mkBvNeg`, etc.
  - [x] Quantifiers: `mkForall`, `mkExists`, `mkBound`
  - [x] Datatypes: `mkDatatype`, `Constructor.mk`, `Constructor.query` (constructor/tester/accessor decls)
- [ ] **More term inspection**
  - [x] `getAstKind` (typed)
  - [ ] `getBoolValue`
  - [ ] `isApp`, `isNumeral`, `isQuantifier`
  - [ ] `getDeclKind` (typed, requires DeclKind enum)
- [ ] **More sort constructors**
  - [x] `mkArraySort`
  - [ ] `mkSetSort`
  - [ ] `mkSeqSort` / `mkReSort`
- [ ] **Model operations**
  - [ ] `getSortUniverse`
  - [ ] `getNumFuncs` / `getFuncDecl` / `getFuncInterp`
- [ ] **Solver variants**
  - [ ] `mkSimpleSolver`
  - [ ] `mkSolverForLogic`
  - [ ] `checkSatAssumptions`
  - [ ] `getUnsatCore`
  - [ ] `getAssertions`

### TODO — Proof API

- [x] `Solver.getProof` — tested with `Context.newWithProofs`
- [x] `ProofRule` inductive type mapping Z3's 42 proof rule decl kinds (`Z3_OP_PR_*`)
- [x] Proof tree navigation: `Ast.getProofRule?`, `Ast.getArgs`, `Ast.collectProofRules`
- [x] Test harness: parse SMT-LIB, check unsat, extract proof, walk the tree

### TODO — Build & CI

- [ ] Cross-platform CI (GitHub Actions matrix: Linux x86_64/arm64, macOS x86_64/arm64, Windows x64)
- [ ] Dynamic linking option (for dev builds where static libz3.a is too slow to link)

### TODO — Ergonomics

- [x] ~~`Env.run` helper in the library~~ (moved from test harness to `Z3/Env.lean`)
- [ ] `SortKind` / `AstKind` conversion from raw `UInt32` → typed enum
- [ ] Nicer API wrappers that thread Context implicitly (ReaderT-style)
- [ ] `Solver.checkSatAndGetModel` convenience
- [ ] `ToString` / `Repr` for all types

### Future — lean-smt Integration

- [ ] Solver abstraction (typeclass or sum type) over `cvc5.Solver` / `Z3.Solver`
- [ ] Parallel Reconstruct registries — `Z3.ProofRule` handlers alongside `cvc5.ProofRule`
- [ ] Sort/Term reconstruction adapters mapping `Z3.Srt` / `Z3.Ast` to Lean `Expr`

## Building

```bash
# Fetches Lean toolchain and Z3 4.16.0 binaries automatically
lake build

# Run the smoke test
lake build z3test && .lake/build/bin/z3test
```

## Architecture Notes

- **Lean declarations in `Z3/FFI.lean`** — opaque types via `NonemptyType` pattern, functions via `@[extern "c_name"] opaque`
- **C implementation in `ffi/z3_ffi.c`** — external class registration, wrap/unwrap helpers, all extern function bodies
- **Wrapper structs** (`ffi/z3_lean.h`) — each Z3 object stores `{ lean_object* ctx_obj; Z3_context ctx; Z3_xxx obj; }`. The `ctx_obj` ref prevents the Context from being GC'd before its children.
- **State-mutating functions return `BaseIO PUnit`** — not `Unit`, to prevent the Lean compiler from optimizing away side-effectful calls.
- **Sort is named `Srt`** — `Sort` conflicts with Lean's built-in `Sort` keyword.
- **BaseIO ABI (Lean 4.28+)** — `BaseIO = ST IO.RealWorld`, the Void world token is optimized away. Extern functions for BaseIO/Env take no world token and return values directly.

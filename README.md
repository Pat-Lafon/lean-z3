# lean-z3

Lean 4 FFI bindings to the [Z3](https://github.com/Z3Prover/z3) SMT solver using raw `@[extern]` C FFI.

- **Z3 version:** 4.16.0
- **Lean toolchain:** 4.28.0
- **No external Lean dependencies** (alloy removed)

## Status

### Coverage

466 `@[extern]` bindings covering ~65% of the Z3 C API (508 of 787 functions). Run `./scripts/check-ffi-sync.sh` to verify Lean/C declarations stay in sync, or `--coverage /path/to/z3/include` for a full coverage report.

### Bound

- **Context** — `new`, `newWithProofs`
- **Sorts** — Bool, Int, Real, BV, Uninterpreted, Array, String, Seq, Re, FPA, Set, FiniteDomain, Char, Enumeration, List, Tuple + inspection (`getKindRaw`, `getSortKind`, `getName`, `getBvSize`, `getArraySortDomain/Range`, datatype sort inspection)
- **Term constructors** — `mkBool`, `mkNumeral`, `mkInt`, `mkInt64`, `mkUInt64`, `mkReal`, `mkRealVal`, `mkIntConst`, `mkBoolConst`, `mkConst`, `mkBvConst`, `mkFreshConst`
- **Boolean ops** — `not`, `and`, `or`, `xor`, `implies`, `iff`, `eq`, `ite`, `getBoolValue`, `distinct`
- **Arithmetic ops** — `add`, `sub`, `mul`, `div`, `mod`, `rem`, `power`, `abs`, `unaryMinus`, `lt`, `le`, `gt`, `ge`, `int2real`, `real2int`, `isInt`
- **Bitvector ops** — arithmetic, bitwise, reduction, shifts, rotations, comparisons (signed + unsigned), extract/concat/extend/repeat, bv2int/int2bv, overflow checks
- **Array ops** — `select`, `store`, `constArray`, `mkArray` sort
- **Quantifiers** — `mkBound`, `mkForall`, `mkExists`, `mkForallConst`, `mkExistsConst`, `mkQuantifierEx`, `mkPattern`, `mkLambda`, `mkLambdaConst`, inspection (body, bound names/sorts)
- **Datatypes** — `Constructor.mk`, `Srt.mkDatatype`, `mkDatatypes` (mutually recursive), `Constructor.query`
- **Term inspection** — sort, AST kind, args, func decl, numeral extraction (string, decimal, binary, int64, uint64, double, numerator/denominator), var index, toString
- **Substitution & simplification** — `substitute`, `substituteVars`, `simplify`, `simplifyEx`, `simplifyGetParamDescrs`
- **Uninterpreted functions** — `FuncDecl.mk`, `mkApp`, `mkFreshConst`, `FuncDecl.mkFresh`, `FuncDecl.mkRec`, `FuncDecl.addRecDef`
- **FuncDecl** — `getDeclKindRaw`, `getDeclKind`, `getName`, `getArity`, `getDomain`, `getRange`, `toString`
- **Params** — `new`, `setBool`, `setUInt`, `setDouble`, `setSymbol`, `validate`, `toString`
- **ParamDescrs** — `size`, `getName`, `getKindRaw`, `getDocumentation`, `toString`
- **Solver** — `new`, `mkSimple`, `mkForLogic`, `fromTactic`, `setParams`, `assert`, `assertAndTrack`, `push`, `pop`, `reset`, `checkSat`, `checkAssumptions`, `getReasonUnknown`, `getProof`, `getUnsatCore`, `getAssertions`, `getModel`, `registerOnClause`, `getNumScopes`, `interrupt`, `translate`, `getTrail`, `getConsequences`, `getStatistics`, `fromString`, `fromFile`, `addSimplifier`, `toString`
- **Pseudo-boolean** — `mkAtmost`, `mkAtleast`, `mkPble`, `mkPbge`, `mkPbeq`
- **Model** — `eval`, `getNumConsts`, `getConstDecl`, `getConstInterp`, `getNumFuncs`, `getFuncDecl`, `getFuncInterp`, `hasInterp`, `getSortUniverse`, `toString`
- **FuncInterp** — `getNumEntries`, `getEntry`, `getElse`, `getArity`
- **FuncEntry** — `getValue`, `getNumArgs`, `getArg`
- **SMT-LIB parsing** — `parseSMTLIB2String`, `parseSMTLIB2File`, `evalSMTLIB2String`
- **Proof API** — `ProofRule` inductive (42 rules), `getProofRule?`, `collectProofRules`, proof tree navigation
- **DeclKind** — enum (~80 variants), `FuncDecl.getDeclKind`, C-validated enum values
- **SortKind** — typed enum with `ofRaw`/`toRaw`, `Srt.getSortKind`
- **AST utilities** — `isApp`, `isNumeralAst`, `isWellSorted`, `isEqAst`, `getId`, `getHash`, `translate`
- **Optimize** — `new`, `assert`, `assertAndTrack`, `assertSoft`, `maximize`, `minimize`, `check`, `checkAssumptions`, `getModel`, `getUnsatCore`, `getLower`, `getUpper`, `push`, `pop`, `setParams`, `getParamDescrs`, `getReasonUnknown`, `getHelp`, `getStatistics`, `getAssertions`, `getObjectives`, `setInitialValue`, `fromString`, `fromFile`, `toString`
- **Tactic / Goal** — `Tactic.mk`, `andThen`, `orElse`, `repeat`, `skip`, `fail`, `getHelp`, `Goal.mk`, `assert`, `formula`, `size`, `reset`, `toString`, `apply`, `ApplyResult` inspection, `Solver.fromTactic`, tactic enumeration
- **String / Sequence** — sort constructors, `mkString`, `getString`, concat, length, contains, prefix, suffix, extract, at, index, str/int conversion, regex ops (star, plus, option, union, concat, range, complement, intersect)
- **Floating point** — sort constructors (16/32/64/128-bit), rounding modes, special values (NaN/Inf/Zero), numerals (double/int), arithmetic, comparisons, classification, rounding, conversions (BV/float/real/signed/unsigned), numeral inspection (sign/significand/exponent as string, uint64, int64, BV)
- **Sets** — `mkEmptySet`, `mkFullSet`, `mkSetAdd/Del/Union/Intersect/Difference/Complement/Member/Subset`
- **Additional sorts** — `mkFiniteDomain`, `mkChar`, `mkEnumeration`, `mkList`, `mkTuple`, `mkDatatypes`
- **Fixedpoint (Datalog/CHC)** — `new`, `registerRelation`, `addRule`, `addFact`, `assert`, `query`, `queryRelations`, `getAnswer`, `getReasonUnknown`, `updateRule`, `getNumLevels`, `getCoverDelta`, `addCover`, `getStatistics`, `getRules`, `getAssertions`, `getHelp`, `getParamDescrs`, `fromString`, `fromFile`, `setPredicateRepresentation`, `addConstraint`, `setParams`, `toString`
- **Probes** — `mk`, `const`, `apply`, comparisons, combinators (`and`, `or`, `not`), `getDescr`, enumeration, tactic integration (`when`, `cond`, `failIf`, `failIfNotDecided`)
- **Solver user propagation** — `Propagator` + `SolverCallback`, `propagateInit`, `setFixed/Final/Eq/Diseq/Created/Decide`, `propagateRegister/Consequence/Declare`, `nextSplit`
- **Simplifier API** — `mk`, `andThen`, `usingParams`, `getHelp`, `getParamDescrs`, `getDescr`, enumeration, `Solver.addSimplifier`
- **Quantifier elimination** — `qeLite`, `qeModelProject`, `modelExtrapolate`
- **Statistics** — `size`, `getKey`, `isUInt`, `isDouble`, `getUIntValue`, `getDoubleValue`, `toString`

### High-level API (`Z3.Api`)

A `ReaderT`-style API layer that threads `Context` implicitly via the `Z3M` monad (`ReaderT Context Env`).

```lean
import Z3

open Z3 Z3.Api

-- Solve 2x + 3 = 11
#eval Api.run do
  let x ← intConst "x"
  let lhs ← add (← mul (← intVal 2) x) (← intVal 3)
  withSolver fun s => do
    Api.assert s (← eq lhs (← intVal 11))
    let some m ← solve s | return "unsat"
    return Ast.getNumeralString (← Api.eval m x)
-- "4"
```

Entry points: `Api.run` (default config), `Api.runWith` (e.g. `{ proofs := true }`). Lifted operations for sorts, terms, solver, and model access. `withSolver` creates and manages a solver; `scope` handles push/pop with automatic cleanup.

### Test suite — 329 tests

## Building

```bash
# Fetches Lean toolchain and Z3 4.16.0 binaries automatically
lake build

# Run the test suite
lake build z3test && .lake/build/bin/z3test
```

## Architecture Notes

- **Lean declarations in `Z3/FFI.lean`** — opaque types via `NonemptyType` pattern, functions via `@[extern "c_name"] opaque`
- **C implementation in `ffi/z3_ffi.c`** — external class registration, wrap/unwrap helpers, all extern function bodies
- **Wrapper structs** (`ffi/z3_lean.h`) — each Z3 object stores `{ lean_object* ctx_obj; Z3_context ctx; Z3_xxx obj; }`. The `ctx_obj` ref prevents the Context from being GC'd before its children.
- **State-mutating functions return `BaseIO PUnit`** — not `Unit`, to prevent the Lean compiler from optimizing away side-effectful calls. State-dependent queries also return `BaseIO T` to avoid CSE.
- **Sort is named `Srt`** — `Sort` conflicts with Lean's built-in `Sort` keyword.
- **BaseIO ABI (Lean 4.28+)** — `BaseIO = ST IO.RealWorld`, the Void world token is optimized away. Extern functions for BaseIO/Env take no world token and return values directly.
- **High-level API** (`Z3/Api/`) — `Z3M = ReaderT Context Env` monad. Submodules: `Monad.lean` (monad + runners), `Sort.lean` (sort constructors), `Expr.lean` (term constructors + operations), `Solver.lean` (solver management), `Model.lean` (model evaluation).

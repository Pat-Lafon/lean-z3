# lean-z3

Lean 4 FFI bindings to the [Z3](https://github.com/Z3Prover/z3) SMT solver using raw `@[extern]` C FFI.

- **Z3 version:** 4.16.0
- **Lean toolchain:** 4.28.0
- **No external Lean dependencies** (alloy removed)

## Status

### Bound

- **Context** — `new`, `newWithProofs`
- **Sorts** — Bool, Int, Real, BV, Uninterpreted, Array + inspection (`getKindRaw`, `getName`, `getBvSize`)
- **Term constructors** — `mkBool`, `mkNumeral`, `mkInt`, `mkInt64`, `mkUInt64`, `mkReal`, `mkRealVal`, `mkIntConst`, `mkBoolConst`, `mkConst`, `mkBvConst`
- **Boolean ops** — `not`, `and`, `or`, `xor`, `implies`, `iff`, `eq`, `ite`, `getBoolValue`
- **Arithmetic ops** — `add`, `sub`, `mul`, `div`, `mod`, `rem`, `power`, `abs`, `unaryMinus`, `lt`, `le`, `gt`, `ge`, `int2real`, `real2int`, `isInt`
- **Bitvector ops** — arithmetic (`bvadd`, `bvsub`, `bvmul`, `bvudiv`, `bvsdiv`, `bvurem`, `bvsrem`, `bvsmod`, `bvneg`), bitwise (`bvand`, `bvor`, `bvxor`, `bvnot`, `bvnand`, `bvnor`, `bvxnor`), reduction (`bvredand`, `bvredor`), shifts (`bvshl`, `bvlshr`, `bvashr`), rotations, comparisons (signed + unsigned), extract/concat/extend/repeat, bv2int/int2bv, overflow checks (`bvaddNoOverflow`, `bvaddNoUnderflow`, `bvsubNoOverflow`, `bvsubNoUnderflow`, `bvmulNoOverflow`, `bvmulNoUnderflow`, `bvsdivNoOverflow`, `bvnegNoOverflow`)
- **Array ops** — `select`, `store`, `constArray`, `mkArray` sort
- **Distinct** — `distinct`
- **Quantifiers** — `mkBound`, `mkForall`, `mkExists`, `mkForallConst`, `mkExistsConst`, `mkQuantifierEx`, `mkPattern`, `mkLambda`, `mkLambdaConst`
- **Datatypes** — `Constructor.mk`, `Srt.mkDatatype`, `Constructor.query`
- **Term inspection** — `getSort`, `getAstKind`, `getNumArgs`, `getArg`, `getFuncDecl`, `getNumeralString`, `getNumeralDecimalString`, `getNumeralBinaryString`, `getNumeralInt64`, `getNumeralUInt64`, `getNumeralDouble`, `getNumerator`, `getDenominator`, `getVarIndex`, `toString`
- **Quantifier inspection** — `isQuantifierForall`, `isQuantifierExists`, `getQuantifierBody`, `getQuantifierNumBound`, `getQuantifierBoundName`, `getQuantifierBoundSort`
- **Substitution & simplification** — `substitute`, `substituteVars`, `simplify`, `simplifyEx`, `simplifyGetParamDescrs`
- **Uninterpreted functions** — `FuncDecl.mk`, `Ast.mkApp`, `Ast.mkFreshConst`, `FuncDecl.mkFresh`, `FuncDecl.mkRec`, `FuncDecl.addRecDef`
- **FuncDecl** — `getDeclKindRaw`, `getName`, `getArity`, `getDomain`, `getRange`, `toString`
- **Params** — `new`, `setBool`, `setUInt`, `setDouble`, `setSymbol`, `validate`, `toString`
- **ParamDescrs** — `size`, `getName`, `getKindRaw`, `getDocumentation`, `toString`; obtained via `Solver.getParamDescrs`, `Context.getGlobalParamDescrs`
- **Solver** — `new`, `setParams`, `assert`, `assertAndTrack`, `push`, `pop`, `reset`, `checkSat`, `checkAssumptions`, `getReasonUnknown`, `getProof`, `getUnsatCore`, `getAssertions`, `registerOnClause`, `toString`
- **Pseudo-boolean** — `mkAtmost`, `mkAtleast`, `mkPble`, `mkPbge`, `mkPbeq`
- **Model** — `eval`, `getNumConsts`, `getConstDecl`, `getConstInterp`, `getNumFuncs`, `getFuncDecl`, `getFuncInterp`, `hasInterp`, `getSortUniverse`, `toString`
- **FuncInterp** — `getNumEntries`, `getEntry`, `getElse`, `getArity`
- **FuncEntry** — `getValue`, `getNumArgs`, `getArg`
- **SMT-LIB parsing** — `parseSMTLIB2String`, `parseSMTLIB2File`, `evalSMTLIB2String`
- **Proof API** — `ProofRule` inductive (42 rules), `Ast.getProofRule?`, `Ast.collectProofRules`, proof tree navigation
- **AST kind inspection** — `Ast.getAstKind`, `AstKind.ofRaw`
- **DeclKind** — `DeclKind` enum (~80 variants), `FuncDecl.getDeclKind`, C-validated enum values
- **AST utilities** — `isApp`, `isNumeralAst`, `isWellSorted`, `isEqAst`, `getId`, `getHash`, `translate`
- **Optimize** — `new`, `assert`, `assertSoft`, `maximize`, `minimize`, `check`, `getModel`, `getLower`, `getUpper`, `push`, `pop`, `setParams`, `getReasonUnknown`, `toString`
- **Tactic / Goal** — `Tactic.mk`, `andThen`, `orElse`, `repeat`, `skip`, `fail`, `getHelp`, `Goal.mk`, `assert`, `formula`, `size`, `reset`, `toString`, `Tactic.apply`, `ApplyResult.getNumSubgoals`, `getSubgoal`, `toString`, `Solver.fromTactic`, `Context.getNumTactics`, `getTacticName`, `getTacticDescription`
- **String / Sequence** — `Srt.mkString`, `Srt.mkSeq`, `Srt.mkRe`, `Ast.mkString`, `getString`, `mkSeqConcat`, `mkSeqLength`, `mkSeqContains`, `mkSeqPrefix`, `mkSeqSuffix`, `mkSeqExtract`, `mkSeqAt`, `mkSeqIndex`, `mkStrToInt`, `mkIntToStr`, `mkSeqToRe`, `mkSeqInRe`, `mkReStar`, `mkRePlus`, `mkReOption`, `mkReUnion`, `mkReConcat`, `mkReRange`, `mkReComplement`, `mkReIntersect`
- **Floating point** — `Srt.mkFpa`, `mkFpa32`, `mkFpa64`, `mkFpa16`, `mkFpa128`, `mkFpaRoundingMode`, rounding modes (`mkFpaRne/Rna/Rtp/Rtn/Rtz`), special values (`mkFpaNan/Inf/Zero`), numerals (`mkFpaNumeralDouble/Int`), arithmetic (`mkFpaAdd/Sub/Mul/Div/Fma/Sqrt/Rem/Abs/Neg/Min/Max`), comparisons (`mkFpaLt/Leq/Gt/Geq/Eq`), classification (`mkFpaIsNan/Inf/Zero/Normal/Subnormal/Negative/Positive`), rounding (`mkFpaRoundToIntegral`), conversions (`mkFpaToFpBv/Float/Real/Signed/Unsigned`, `mkFpaToUbv/Sbv/Real/IeeeBv`), numeral inspection (`fpaIsNumeralNan/Inf/Zero/Normal/Subnormal/Positive/Negative`, `fpaGetNumeralSign/SignificandString/SignificandUInt64/ExponentString/ExponentInt64/SignBv/SignificandBv/ExponentBv`)
- **Sets** — `Srt.mkSet`, `mkEmptySet`, `mkFullSet`, `mkSetAdd`, `mkSetDel`, `mkSetUnion`, `mkSetIntersect`, `mkSetDifference`, `mkSetComplement`, `mkSetMember`, `mkSetSubset`
- **Additional sorts** — `Srt.mkFiniteDomain`, `mkChar`, `mkEnumeration`, `mkList`, `mkTuple`, `mkDatatypes` (mutually recursive)
- **Sort inspection (extended)** — `getArraySortDomain`, `getArraySortDomainN`, `getArraySortRange`, `getDatatypeSortNumConstructors`, `getDatatypeSortConstructor`, `getDatatypeSortRecognizer`, `getDatatypeSortConstructorAccessor`
- **Solver (extended)** — `mkSimple`, `mkForLogic`, `fromString`, `fromFile`, `getNumScopes`, `interrupt`, `translate`, `getTrail`, `getConsequences`, `getStatistics`
- **Statistics** — `Stats` opaque type, `size`, `getKey`, `isUInt`, `isDouble`, `getUIntValue`, `getDoubleValue`, `toString`
- **Fixedpoint (Datalog/CHC)** — `Fixedpoint` opaque type, `new`, `registerRelation`, `addRule`, `addFact`, `assert`, `query`, `queryRelations`, `getAnswer`, `getReasonUnknown`, `updateRule`, `getNumLevels`, `getCoverDelta`, `addCover`, `getStatistics`, `getRules`, `getAssertions`, `getHelp`, `getParamDescrs`, `fromString`, `fromFile`, `setPredicateRepresentation`, `addConstraint`, `setParams`, `toString`
- **Probes** — `Probe` opaque type, `mk`, `const`, `apply`, comparisons (`lt`, `gt`, `le`, `ge`, `eq`), combinators (`and`, `or`, `not`), `getDescr`, `Context.getNumProbes`, `getProbeName`, tactic integration (`Tactic.when`, `cond`, `failIf`, `failIfNotDecided`)
- **Solver user propagation** — `Propagator` + `SolverCallback` opaque types, `propagateInit`, `setFixed`, `setFinal`, `setEq`, `setDiseq`, `setCreated`, `setDecide`, `propagateRegister`, `propagateConsequence`, `nextSplit`, `propagateDeclare`
- **Simplifier API** — `Simplifier` opaque type, `mk`, `andThen`, `usingParams`, `getHelp`, `getParamDescrs`, `getDescr`, `Context.getNumSimplifiers`, `getSimplifierName`, `Solver.addSimplifier`
- **Test suite** — 303 tests

### Coverage

452 `@[extern]` bindings covering ~62% of the Z3 C API (484 of 766 functions). Run `./scripts/check-ffi-sync.sh` to verify Lean/C declarations stay in sync, or `--coverage /path/to/z3/include` for a full coverage report.

### TODO

#### Binding gaps (exposed by other major Z3 bindings)

- [x] **Probes** (~13 functions) — tactic guards: `Z3_mk_probe`, `probe_apply`, `probe_const`, comparisons, combinators. Exposed by Python, Rust, C++, OCaml, .NET.
- [x] **Solver user propagation** (~26 functions) — custom theory solvers via `Z3_solver_propagate_*` callbacks (`fixed`, `eq`, `diseq`, `final`, `decide`, `created`). Exposed by Python, C++, .NET; actively requested in z3-rs.
- [x] **FPA numeral inspection** (~15 functions) — extract sign/significand/exponent from FP numerals (`Z3_fpa_get_numeral_sign`, `_significand_string`, `_exponent_int64`, etc.). Exposed by all major bindings.
- [x] **Simplifier API** (~7 functions) — new simplifier framework replacing `Z3_simplify`: `Z3_mk_simplifier`, `simplifier_and_then`, `using_params`. Exposed by Python, C++, OCaml, .NET.
- [ ] **Quantifier elimination** (~4 functions) — `Z3_qe_lite`, `Z3_qe_model_project`. Exposed by z3-rs, C++.
- [x] **Fixedpoint extended** (~25 functions) — fill remaining methods on existing `Fixedpoint` type: `from_string`, `from_file`, `get_rules`, `get_statistics`, `get_cover_delta`, `add_cover`, etc.
- [ ] **Optimize extended** (~13 functions) — fill remaining methods on existing `Optimize` type: `from_string`, `from_file`, `get_objectives`, `get_statistics`, `assert_and_track`, etc.

#### Ergonomics

- [ ] `SortKind` typed enum from raw `UInt32` (same pattern as `DeclKind`)
- [ ] ReaderT-style API layer that threads `Context` implicitly

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

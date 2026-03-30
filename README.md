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
- **Floating point** — `Srt.mkFpa`, `mkFpa32`, `mkFpa64`, `mkFpa16`, `mkFpa128`, `mkFpaRoundingMode`, rounding modes (`mkFpaRne/Rna/Rtp/Rtn/Rtz`), special values (`mkFpaNan/Inf/Zero`), numerals (`mkFpaNumeralDouble/Int`), arithmetic (`mkFpaAdd/Sub/Mul/Div/Fma/Sqrt/Rem/Abs/Neg/Min/Max`), comparisons (`mkFpaLt/Leq/Gt/Geq/Eq`), classification (`mkFpaIsNan/Inf/Zero/Normal/Subnormal/Negative/Positive`), rounding (`mkFpaRoundToIntegral`), conversions (`mkFpaToFpBv/Float/Real/Signed/Unsigned`, `mkFpaToUbv/Sbv/Real/IeeeBv`)
- **Sets** — `Srt.mkSet`, `mkEmptySet`, `mkFullSet`, `mkSetAdd`, `mkSetDel`, `mkSetUnion`, `mkSetIntersect`, `mkSetDifference`, `mkSetComplement`, `mkSetMember`, `mkSetSubset`
- **Additional sorts** — `Srt.mkFiniteDomain`, `mkChar`, `mkEnumeration`, `mkList`, `mkTuple`, `mkDatatypes` (mutually recursive)
- **Sort inspection (extended)** — `getArraySortDomain`, `getArraySortDomainN`, `getArraySortRange`, `getDatatypeSortNumConstructors`, `getDatatypeSortConstructor`, `getDatatypeSortRecognizer`, `getDatatypeSortConstructorAccessor`
- **Solver (extended)** — `mkSimple`, `mkForLogic`, `fromString`, `fromFile`, `getNumScopes`, `interrupt`, `translate`, `getTrail`, `getConsequences`, `getStatistics`
- **Statistics** — `Stats` opaque type, `size`, `getKey`, `isUInt`, `isDouble`, `getUIntValue`, `getDoubleValue`, `toString`
- **Fixedpoint (Datalog/CHC)** — `Fixedpoint` opaque type, `new`, `registerRelation`, `addRule`, `assert`, `query`, `getAnswer`, `getReasonUnknown`, `setParams`, `toString`
- **Test suite** — 261 tests

### Unbound — Coverage Gaps

#### Core arithmetic
- [x] `Z3_mk_div` — integer/real division
- [x] `Z3_mk_mod` — integer modulus
- [x] `Z3_mk_rem` — integer remainder
- [x] `Z3_mk_power` — exponentiation
- [x] `Z3_mk_abs` — absolute value
- [x] `Z3_mk_unary_minus` — unary negation
- [x] `Z3_mk_int2real` — integer to real coercion
- [x] `Z3_mk_real2int` — real to integer (floor)
- [x] `Z3_mk_is_int` — test if real value is an integer

#### Uninterpreted functions
- [x] `Z3_mk_func_decl` — declare uninterpreted function
- [x] `Z3_mk_app` — apply function declaration to arguments
- [x] `Z3_mk_fresh_const` — fresh constant with prefix
- [x] `Z3_mk_fresh_func_decl` — fresh function decl with prefix
- [x] `Z3_mk_rec_func_decl` / `Z3_add_rec_def` — recursive functions

#### Bool / propositional
- [x] `Z3_mk_xor` — exclusive or
- [x] `Z3_mk_iff` — biconditional
- [x] `Z3_get_bool_value` — extract bool from model AST

#### Numeral constructors & extraction
- [x] `Z3_mk_int` / `Z3_mk_int64` / `Z3_mk_unsigned_int64` — numeric convenience constructors
- [x] `Z3_mk_real` / `Z3_mk_real_int64` — rational from numerator/denominator
- [x] `Z3_get_numeral_int64` / `Z3_get_numeral_uint64` / `Z3_get_numeral_double` — extract as native types
- [x] `Z3_get_numeral_decimal_string` / `Z3_get_numeral_binary_string` — alternative string reprs
- [x] `Z3_get_numerator` / `Z3_get_denominator` — rational decomposition

#### Substitution & simplification
- [x] `Z3_substitute` — substitute ASTs in an expression
- [x] `Z3_substitute_vars` — substitute bound variables
- [x] `Z3_simplify` / `Z3_simplify_ex` — simplify expression
- [x] `Z3_simplify_get_param_descrs` — simplifier parameter descriptions

#### AST utilities
- [x] `Z3_is_app` / `Z3_is_numeral_ast` / `Z3_is_well_sorted` — AST predicates
- [x] `Z3_is_eq_ast` — AST equality
- [x] `Z3_get_ast_id` / `Z3_get_ast_hash` — identity and hashing
- [x] `Z3_translate` — translate AST across contexts

#### Function declaration inspection
- [x] `Z3_get_arity` / `Z3_get_domain_size` / `Z3_get_domain` / `Z3_get_range` — signature inspection

#### Pseudo-boolean constraints
- [x] `Z3_mk_atmost` / `Z3_mk_atleast` — cardinality constraints
- [x] `Z3_mk_pble` / `Z3_mk_pbge` / `Z3_mk_pbeq` — weighted pseudo-boolean

#### Optimization API
- [x] `Z3_mk_optimize` — create optimizer
- [x] `Z3_optimize_assert` / `Z3_optimize_assert_soft` — hard and soft constraints
- [x] `Z3_optimize_maximize` / `Z3_optimize_minimize` — objectives
- [x] `Z3_optimize_check` / `Z3_optimize_get_model` — solve and extract
- [x] `Z3_optimize_get_lower` / `Z3_optimize_get_upper` — objective bounds
- [x] `Z3_optimize_push` / `Z3_optimize_pop` — scope management

#### Tactic / Goal API
- [x] `Z3_mk_tactic` / `Z3_tactic_and_then` / `Z3_tactic_or_else` — tactic creation and combinators
- [x] `Z3_mk_goal` / `Z3_goal_assert` / `Z3_goal_formula` — goal management
- [x] `Z3_tactic_apply` / `Z3_tactic_apply_ex` — apply tactic to goal
- [x] `Z3_apply_result_*` — result access
- [x] `Z3_mk_solver_from_tactic` — solver from tactic

#### String / Sequence theory
- [x] `Z3_mk_string_sort` / `Z3_mk_seq_sort` — string and sequence sorts
- [x] `Z3_mk_string` — string literal
- [x] `Z3_mk_seq_concat` / `Z3_mk_seq_length` / `Z3_mk_seq_contains` — sequence ops
- [x] `Z3_mk_seq_prefix` / `Z3_mk_seq_suffix` / `Z3_mk_seq_extract` / `Z3_mk_seq_at` / `Z3_mk_seq_index`
- [x] `Z3_mk_str_to_int` / `Z3_mk_int_to_str` — conversions
- [x] `Z3_mk_seq_in_re` — regex membership

#### Regular expressions
- [x] `Z3_mk_re_sort` / `Z3_mk_re_star` / `Z3_mk_re_plus` / `Z3_mk_re_option` — regex constructors
- [x] `Z3_mk_re_union` / `Z3_mk_re_intersect` / `Z3_mk_re_concat` / `Z3_mk_re_complement`
- [x] `Z3_mk_re_range` / `Z3_mk_seq_to_re`

#### Floating point theory
- [x] `Z3_mk_fpa_sort` / `Z3_mk_fpa_sort_32` / `Z3_mk_fpa_sort_64` — FP sorts
- [x] `Z3_mk_fpa_rne` / `Z3_mk_fpa_rna` / `Z3_mk_fpa_rtp` / `Z3_mk_fpa_rtn` / `Z3_mk_fpa_rtz` — rounding modes
- [x] `Z3_mk_fpa_add` / `Z3_mk_fpa_sub` / `Z3_mk_fpa_mul` / `Z3_mk_fpa_div` — arithmetic
- [x] `Z3_mk_fpa_sqrt` / `Z3_mk_fpa_rem` / `Z3_mk_fpa_abs` / `Z3_mk_fpa_neg` / `Z3_mk_fpa_fma`
- [x] `Z3_mk_fpa_lt` / `Z3_mk_fpa_leq` / `Z3_mk_fpa_gt` / `Z3_mk_fpa_geq` / `Z3_mk_fpa_eq` — comparisons
- [x] `Z3_mk_fpa_is_nan` / `Z3_mk_fpa_is_inf` / `Z3_mk_fpa_is_zero` — classification predicates
- [x] `Z3_mk_fpa_to_fp_*` / `Z3_mk_fpa_to_ubv` / `Z3_mk_fpa_to_sbv` — conversions

#### Sets
- [x] `Z3_mk_set_sort` / `Z3_mk_empty_set` / `Z3_mk_full_set`
- [x] `Z3_mk_set_add` / `Z3_mk_set_del` / `Z3_mk_set_union` / `Z3_mk_set_intersect` / `Z3_mk_set_difference`
- [x] `Z3_mk_set_complement` / `Z3_mk_set_member` / `Z3_mk_set_subset`

#### Additional sorts
- [x] `Z3_mk_enumeration_sort` / `Z3_mk_list_sort` / `Z3_mk_tuple_sort`
- [x] `Z3_mk_finite_domain_sort` / `Z3_mk_char_sort`
- [x] `Z3_mk_datatypes` — mutually recursive datatypes

#### Sort inspection (extended)
- [x] `Z3_get_array_sort_domain` / `Z3_get_array_sort_range`
- [x] `Z3_get_datatype_sort_*` — datatype sort inspection

#### Model (extended)
- [x] `Z3_model_get_num_funcs` / `Z3_model_get_func_decl` / `Z3_model_get_func_interp`
- [x] `Z3_model_has_interp` / `Z3_model_get_sort_universe`
- [x] `Z3_func_interp_*` / `Z3_func_entry_*` — function interpretation API

#### Solver (extended)
- [x] `Z3_mk_simple_solver` / `Z3_mk_solver_for_logic`
- [x] `Z3_solver_from_string` / `Z3_solver_from_file`
- [x] `Z3_solver_get_statistics` / `Z3_solver_get_num_scopes`
- [x] `Z3_solver_interrupt` / `Z3_solver_translate`
- [x] `Z3_solver_get_consequences` / `Z3_solver_get_trail`

#### Quantifiers (extended)
- [x] `Z3_is_quantifier_forall` / `Z3_is_quantifier_exists` — quantifier kind checks
- [x] `Z3_get_quantifier_body` — get quantifier body
- [x] `Z3_get_quantifier_num_bound` / `Z3_get_quantifier_bound_name` / `Z3_get_quantifier_bound_sort` — bound variable info
- [x] `Z3_get_index_value` — de Bruijn index for variable ASTs
- [x] `Z3_mk_pattern` — quantifier triggers/patterns
- [x] `Z3_mk_quantifier_ex` — quantifier with patterns/weight/id
- [x] `Z3_mk_forall_const` / `Z3_mk_exists_const` — quantifier over constants
- [x] `Z3_mk_lambda` / `Z3_mk_lambda_const` — lambda expressions

#### Params (extended)
- [x] `Z3_params_set_double` / `Z3_params_set_symbol`
- [x] `Z3_params_to_string` — string representation
- [x] `Z3_params_validate` — validate params against param descriptors
- [x] `Z3_param_descrs_*` — full param descriptors API (`size`, `get_name`, `get_kind`, `get_documentation`, `to_string`)
- [x] `Z3_solver_get_param_descrs` / `Z3_get_global_param_descrs` — obtain param descriptors

#### Fixedpoint (Datalog/CHC)
- [x] `Z3_mk_fixedpoint` / `Z3_fixedpoint_add_rule` / `Z3_fixedpoint_query`
- [x] `Z3_fixedpoint_assert` / `Z3_fixedpoint_get_answer`

#### Bitvector (remaining ops)
- [x] `Z3_mk_bvnand` / `Z3_mk_bvnor` / `Z3_mk_bvxnor` / `Z3_mk_bvsmod`
- [x] `Z3_mk_bvredand` / `Z3_mk_bvredor` / `Z3_mk_repeat`
- [x] `Z3_mk_bvadd_no_overflow` / `Z3_mk_bvadd_no_underflow` / `Z3_mk_bvsub_no_overflow` / `Z3_mk_bvsub_no_underflow` / `Z3_mk_bvmul_no_overflow` / `Z3_mk_bvmul_no_underflow` / `Z3_mk_bvsdiv_no_overflow` / `Z3_mk_bvneg_no_overflow` — overflow checks

#### Statistics
- [x] `Z3_stats_to_string` / `Z3_stats_size` / `Z3_stats_get_key`
- [x] `Z3_stats_get_uint_value` / `Z3_stats_get_double_value`

#### Parser (extended)
- [x] `Z3_parse_smtlib2_file`
- [x] `Z3_eval_smtlib2_string` — evaluate SMT-LIB2 command string

### TODO — Build & CI

- [ ] Cross-platform CI (GitHub Actions matrix: Linux x86_64/arm64, macOS x86_64/arm64, Windows x64)
- [ ] Dynamic linking option (for dev builds where static libz3.a is too slow to link)

### TODO — Ergonomics

- [x] `DeclKind` typed enum from raw `UInt32` (with C-validated values)
- [ ] `SortKind` typed enum from raw `UInt32`
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

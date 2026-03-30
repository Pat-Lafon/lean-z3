import Z3.Env

namespace Z3

/-! ## Opaque types -/

/-- A Z3 context (`Z3_context`). Uses reference-counted mode. -/
opaque Context.Pointed : NonemptyType
def Context : Type := Context.Pointed.type
instance : Nonempty Context := Context.Pointed.property

/-- A Z3 sort (`Z3_sort`). Holds a reference to its parent Context. -/
opaque Srt.Pointed : NonemptyType
def Srt : Type := Srt.Pointed.type
instance : Nonempty Srt := Srt.Pointed.property

/-- A Z3 AST node (`Z3_ast`). Holds a reference to its parent Context. -/
opaque Ast.Pointed : NonemptyType
def Ast : Type := Ast.Pointed.type
instance : Nonempty Ast := Ast.Pointed.property

/-- A Z3 function declaration (`Z3_func_decl`). -/
opaque FuncDecl.Pointed : NonemptyType
def FuncDecl : Type := FuncDecl.Pointed.type
instance : Nonempty FuncDecl := FuncDecl.Pointed.property

/-- Z3 parameters (`Z3_params`). -/
opaque Params.Pointed : NonemptyType
def Params : Type := Params.Pointed.type
instance : Nonempty Params := Params.Pointed.property

/-- A Z3 solver (`Z3_solver`). -/
opaque Solver.Pointed : NonemptyType
def Solver : Type := Solver.Pointed.type
instance : Nonempty Solver := Solver.Pointed.property

/-- A Z3 model (`Z3_model`). -/
opaque Model.Pointed : NonemptyType
def Model : Type := Model.Pointed.type
instance : Nonempty Model := Model.Pointed.property

/-- A Z3 datatype constructor declaration (`Z3_constructor`).
Uses `Z3_del_constructor` instead of ref counting. -/
opaque Constructor.Pointed : NonemptyType
def Constructor : Type := Constructor.Pointed.type
instance : Nonempty Constructor := Constructor.Pointed.property

/-! ## Context operations -/

/-- Create a new Z3 context with default configuration. -/
@[extern "lean_z3_Context_new"]
opaque Context.new : Env Context

/-- Create a new Z3 context with proof production enabled. -/
@[extern "lean_z3_Context_newWithProofs"]
opaque Context.newWithProofs : Env Context

/-! ## Sort constructors -/

/-- Create the Boolean sort. -/
@[extern "lean_z3_Srt_mkBool"]
opaque Srt.mkBool (ctx : @& Context) : Srt

/-- Create the integer sort. -/
@[extern "lean_z3_Srt_mkInt"]
opaque Srt.mkInt (ctx : @& Context) : Srt

/-- Create the real sort. -/
@[extern "lean_z3_Srt_mkReal"]
opaque Srt.mkReal (ctx : @& Context) : Srt

/-- Create a bitvector sort of the given size. -/
@[extern "lean_z3_Srt_mkBv"]
opaque Srt.mkBv (ctx : @& Context) (size : UInt32) : Srt

/-- Create an uninterpreted sort with the given name. -/
@[extern "lean_z3_Srt_mkUninterpreted"]
opaque Srt.mkUninterpreted (ctx : @& Context) (name : @& String) : Srt

/-- Create an array sort with the given domain and range sorts. -/
@[extern "lean_z3_Srt_mkArray"]
opaque Srt.mkArray (ctx : @& Context) (domain : @& Srt) (range : @& Srt) : Srt

/-! ## Sort inspection -/

/-- Get the sort kind as a raw `UInt32`. -/
@[extern "lean_z3_Srt_getKindRaw"]
opaque Srt.getKindRaw (s : @& Srt) : UInt32

/-- Get the name of this sort. -/
@[extern "lean_z3_Srt_getName"]
opaque Srt.getName (s : @& Srt) : String

/-- Get the size of a bitvector sort. -/
@[extern "lean_z3_Srt_getBvSize"]
opaque Srt.getBvSize (s : @& Srt) : UInt32

/-- Get a string representation of this sort. -/
@[extern "lean_z3_Srt_toString"]
opaque Srt.toString' (s : @& Srt) : String

instance : ToString Srt := ⟨fun s => Srt.toString' s⟩

/-! ## Term constructors -/

/-- Create a Boolean constant (true or false). -/
@[extern "lean_z3_Ast_mkBool"]
opaque Ast.mkBool (ctx : @& Context) (val : Bool) : Ast

/-- Create a numeral from a string and sort. -/
@[extern "lean_z3_Ast_mkNumeral"]
opaque Ast.mkNumeral (ctx : @& Context) (val : @& String) (sort : @& Srt) : Ast

/-- Create an integer constant with the given name. -/
@[extern "lean_z3_Ast_mkIntConst"]
opaque Ast.mkIntConst (ctx : @& Context) (name : @& String) : Ast

/-- Create a Boolean constant with the given name. -/
@[extern "lean_z3_Ast_mkBoolConst"]
opaque Ast.mkBoolConst (ctx : @& Context) (name : @& String) : Ast

/-- Create a constant of the given sort. -/
@[extern "lean_z3_Ast_mkConst"]
opaque Ast.mkConst (ctx : @& Context) (name : @& String) (sort : @& Srt) : Ast

/-- Create a bitvector constant of the given size. -/
@[extern "lean_z3_Ast_mkBvConst"]
opaque Ast.mkBvConst (ctx : @& Context) (name : @& String) (size : UInt32) : Ast

/-! ## Boolean operations -/

/-- Logical negation. -/
@[extern "lean_z3_Ast_not"]
opaque Ast.not (ctx : @& Context) (a : @& Ast) : Ast

/-- Logical conjunction. -/
@[extern "lean_z3_Ast_and"]
opaque Ast.and (ctx : @& Context) (a b : @& Ast) : Ast

/-- Logical disjunction. -/
@[extern "lean_z3_Ast_or"]
opaque Ast.or (ctx : @& Context) (a b : @& Ast) : Ast

/-- Logical implication. -/
@[extern "lean_z3_Ast_implies"]
opaque Ast.implies (ctx : @& Context) (a b : @& Ast) : Ast

/-- Equality. -/
@[extern "lean_z3_Ast_eq"]
opaque Ast.eq (ctx : @& Context) (a b : @& Ast) : Ast

/-- If-then-else. -/
@[extern "lean_z3_Ast_ite"]
opaque Ast.ite (ctx : @& Context) (cond t e : @& Ast) : Ast

/-! ## Arithmetic operations -/

/-- Addition. -/
@[extern "lean_z3_Ast_add"]
opaque Ast.add (ctx : @& Context) (a b : @& Ast) : Ast

/-- Subtraction. -/
@[extern "lean_z3_Ast_sub"]
opaque Ast.sub (ctx : @& Context) (a b : @& Ast) : Ast

/-- Multiplication. -/
@[extern "lean_z3_Ast_mul"]
opaque Ast.mul (ctx : @& Context) (a b : @& Ast) : Ast

/-- Less than. -/
@[extern "lean_z3_Ast_lt"]
opaque Ast.lt (ctx : @& Context) (a b : @& Ast) : Ast

/-- Less than or equal. -/
@[extern "lean_z3_Ast_le"]
opaque Ast.le (ctx : @& Context) (a b : @& Ast) : Ast

/-- Greater than. -/
@[extern "lean_z3_Ast_gt"]
opaque Ast.gt (ctx : @& Context) (a b : @& Ast) : Ast

/-- Greater than or equal. -/
@[extern "lean_z3_Ast_ge"]
opaque Ast.ge (ctx : @& Context) (a b : @& Ast) : Ast

/-- Distinct — all arguments are pairwise different. -/
@[extern "lean_z3_Ast_distinct"]
opaque Ast.distinct (ctx : @& Context) (args : @& Array Ast) : Ast

/-! ## Bitvector arithmetic -/

/-- Bitvector negation (two's complement). -/
@[extern "lean_z3_Ast_bvneg"]
opaque Ast.bvneg (ctx : @& Context) (a : @& Ast) : Ast

/-- Bitvector addition. -/
@[extern "lean_z3_Ast_bvadd"]
opaque Ast.bvadd (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitvector subtraction. -/
@[extern "lean_z3_Ast_bvsub"]
opaque Ast.bvsub (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitvector multiplication. -/
@[extern "lean_z3_Ast_bvmul"]
opaque Ast.bvmul (ctx : @& Context) (a b : @& Ast) : Ast

/-- Unsigned bitvector division. -/
@[extern "lean_z3_Ast_bvudiv"]
opaque Ast.bvudiv (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed bitvector division. -/
@[extern "lean_z3_Ast_bvsdiv"]
opaque Ast.bvsdiv (ctx : @& Context) (a b : @& Ast) : Ast

/-- Unsigned bitvector remainder. -/
@[extern "lean_z3_Ast_bvurem"]
opaque Ast.bvurem (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed bitvector remainder. -/
@[extern "lean_z3_Ast_bvsrem"]
opaque Ast.bvsrem (ctx : @& Context) (a b : @& Ast) : Ast

/-! ## Bitvector bitwise -/

/-- Bitwise NOT. -/
@[extern "lean_z3_Ast_bvnot"]
opaque Ast.bvnot (ctx : @& Context) (a : @& Ast) : Ast

/-- Bitwise AND. -/
@[extern "lean_z3_Ast_bvand"]
opaque Ast.bvand (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitwise OR. -/
@[extern "lean_z3_Ast_bvor"]
opaque Ast.bvor (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitwise XOR. -/
@[extern "lean_z3_Ast_bvxor"]
opaque Ast.bvxor (ctx : @& Context) (a b : @& Ast) : Ast

/-! ## Bitvector shifts and rotation -/

/-- Shift left. -/
@[extern "lean_z3_Ast_bvshl"]
opaque Ast.bvshl (ctx : @& Context) (a b : @& Ast) : Ast

/-- Logical shift right. -/
@[extern "lean_z3_Ast_bvlshr"]
opaque Ast.bvlshr (ctx : @& Context) (a b : @& Ast) : Ast

/-- Arithmetic shift right. -/
@[extern "lean_z3_Ast_bvashr"]
opaque Ast.bvashr (ctx : @& Context) (a b : @& Ast) : Ast

/-- Rotate left by `n` bits. -/
@[extern "lean_z3_Ast_rotateLeft"]
opaque Ast.rotateLeft (ctx : @& Context) (a : @& Ast) (n : UInt32) : Ast

/-- Rotate right by `n` bits. -/
@[extern "lean_z3_Ast_rotateRight"]
opaque Ast.rotateRight (ctx : @& Context) (a : @& Ast) (n : UInt32) : Ast

/-! ## Bitvector comparisons (unsigned) -/

/-- Unsigned less than. -/
@[extern "lean_z3_Ast_bvult"]
opaque Ast.bvult (ctx : @& Context) (a b : @& Ast) : Ast

/-- Unsigned less than or equal. -/
@[extern "lean_z3_Ast_bvule"]
opaque Ast.bvule (ctx : @& Context) (a b : @& Ast) : Ast

/-- Unsigned greater than. -/
@[extern "lean_z3_Ast_bvugt"]
opaque Ast.bvugt (ctx : @& Context) (a b : @& Ast) : Ast

/-- Unsigned greater than or equal. -/
@[extern "lean_z3_Ast_bvuge"]
opaque Ast.bvuge (ctx : @& Context) (a b : @& Ast) : Ast

/-! ## Bitvector comparisons (signed) -/

/-- Signed less than. -/
@[extern "lean_z3_Ast_bvslt"]
opaque Ast.bvslt (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed less than or equal. -/
@[extern "lean_z3_Ast_bvsle"]
opaque Ast.bvsle (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed greater than. -/
@[extern "lean_z3_Ast_bvsgt"]
opaque Ast.bvsgt (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed greater than or equal. -/
@[extern "lean_z3_Ast_bvsge"]
opaque Ast.bvsge (ctx : @& Context) (a b : @& Ast) : Ast

/-! ## Bitvector extract / concat / extend -/

/-- Extract bits `[high:low]` from a bitvector. -/
@[extern "lean_z3_Ast_bvextract"]
opaque Ast.bvextract (ctx : @& Context) (high low : UInt32) (a : @& Ast) : Ast

/-- Concatenate two bitvectors. -/
@[extern "lean_z3_Ast_bvconcat"]
opaque Ast.bvconcat (ctx : @& Context) (a b : @& Ast) : Ast

/-- Zero-extend by `n` bits. -/
@[extern "lean_z3_Ast_bvzeroExt"]
opaque Ast.bvzeroExt (ctx : @& Context) (n : UInt32) (a : @& Ast) : Ast

/-- Sign-extend by `n` bits. -/
@[extern "lean_z3_Ast_bvsignExt"]
opaque Ast.bvsignExt (ctx : @& Context) (n : UInt32) (a : @& Ast) : Ast

/-! ## Bitvector / integer conversion -/

/-- Convert a bitvector to an integer. If `isSigned`, treat as signed. -/
@[extern "lean_z3_Ast_bv2int"]
opaque Ast.bv2int (ctx : @& Context) (a : @& Ast) (isSigned : Bool) : Ast

/-- Convert an integer to a bitvector of width `n`. -/
@[extern "lean_z3_Ast_int2bv"]
opaque Ast.int2bv (ctx : @& Context) (n : UInt32) (a : @& Ast) : Ast

/-! ## Array operations -/

/-- Select (read) from an array: `a[i]`. -/
@[extern "lean_z3_Ast_select"]
opaque Ast.select (ctx : @& Context) (a i : @& Ast) : Ast

/-- Store (write) into an array: `a[i] := v`. -/
@[extern "lean_z3_Ast_store"]
opaque Ast.store (ctx : @& Context) (a i v : @& Ast) : Ast

/-- Create a constant array where every index maps to `v`. -/
@[extern "lean_z3_Ast_constArray"]
opaque Ast.constArray (ctx : @& Context) (domain : @& Srt) (v : @& Ast) : Ast

/-! ## Term inspection -/

/-- Get the sort of an AST node. -/
@[extern "lean_z3_Ast_getSort"]
opaque Ast.getSort (a : @& Ast) : Srt

/-- Get the AST kind as a raw `UInt32`. -/
@[extern "lean_z3_Ast_getAstKindRaw"]
opaque Ast.getAstKindRaw (a : @& Ast) : UInt32

/-- Get the AST kind. -/
def Ast.getAstKind (a : @& Ast) : AstKind :=
  AstKind.ofRaw (Ast.getAstKindRaw a)

/-- Get the number of arguments of an application node. -/
@[extern "lean_z3_Ast_getNumArgs"]
opaque Ast.getNumArgs (a : @& Ast) : UInt32

/-- Get the i-th argument of an application node. -/
@[extern "lean_z3_Ast_getArg"]
opaque Ast.getArg (a : @& Ast) (i : UInt32) : Ast

/-- Get the function declaration of an application node. -/
@[extern "lean_z3_Ast_getFuncDecl"]
opaque Ast.getFuncDecl (a : @& Ast) : FuncDecl

/-- Get the numeral value as a string. -/
@[extern "lean_z3_Ast_getNumeralString"]
opaque Ast.getNumeralString (a : @& Ast) : String

/-- Get a string representation. -/
@[extern "lean_z3_Ast_toString"]
opaque Ast.toString' (a : @& Ast) : String

instance : ToString Ast := ⟨fun a => Ast.toString' a⟩

/-! ## FuncDecl operations -/

/-- Get the decl kind as a raw `UInt32`. -/
@[extern "lean_z3_FuncDecl_getDeclKindRaw"]
opaque FuncDecl.getDeclKindRaw (fd : @& FuncDecl) : UInt32

/-- Get the name of a function declaration. -/
@[extern "lean_z3_FuncDecl_getName"]
opaque FuncDecl.getName (fd : @& FuncDecl) : String

/-- String representation. -/
@[extern "lean_z3_FuncDecl_toString"]
opaque FuncDecl.toString' (fd : @& FuncDecl) : String

instance : ToString FuncDecl := ⟨fun fd => FuncDecl.toString' fd⟩

/-! ## Params operations -/

/-- Create a new empty parameter set. -/
@[extern "lean_z3_Params_new"]
opaque Params.new (ctx : @& Context) : BaseIO Params

/-- Set a Boolean parameter. -/
@[extern "lean_z3_Params_setBool"]
opaque Params.setBool (p : @& Params) (name : @& String) (val : Bool) : BaseIO PUnit

/-- Set a UInt32 parameter. -/
@[extern "lean_z3_Params_setUInt"]
opaque Params.setUInt (p : @& Params) (name : @& String) (val : UInt32) : BaseIO PUnit

/-! ## Solver operations -/

/-- Create a new solver. -/
@[extern "lean_z3_Solver_new"]
opaque Solver.new (ctx : @& Context) : BaseIO Solver

/-- Set parameters on the solver. -/
@[extern "lean_z3_Solver_setParams"]
opaque Solver.setParams (s : @& Solver) (p : @& Params) : BaseIO PUnit

/-- Assert a constraint. -/
@[extern "lean_z3_Solver_assert"]
opaque Solver.assert (s : @& Solver) (a : @& Ast) : BaseIO PUnit

/-- Push a new scope. -/
@[extern "lean_z3_Solver_push"]
opaque Solver.push (s : @& Solver) : BaseIO PUnit

/-- Pop a scope. -/
@[extern "lean_z3_Solver_pop"]
opaque Solver.pop (s : @& Solver) (n : UInt32) : BaseIO PUnit

/-- Reset the solver. -/
@[extern "lean_z3_Solver_reset"]
opaque Solver.reset (s : @& Solver) : BaseIO PUnit

/-- Check satisfiability. Returns encoded `Z3_lbool` shifted by +1:
  0=unsat, 1=unknown, 2=sat. -/
@[extern "lean_z3_Solver_checkSatRaw"]
opaque Solver.checkSatRaw (s : @& Solver) : BaseIO UInt32

/-- Check satisfiability and return an `LBool`. -/
def Solver.checkSat (s : @& Solver) : BaseIO LBool := do
  let raw ← Solver.checkSatRaw s
  return match raw with
  | 0 => .false
  | 2 => .true
  | _ => .undef

/-- Get reason for unknown result. -/
@[extern "lean_z3_Solver_getReasonUnknown"]
opaque Solver.getReasonUnknown (s : @& Solver) : BaseIO String

/-- Get the proof from an unsatisfiable check.
Requires a context created with `Context.newWithProofs`. -/
@[extern "lean_z3_Solver_getProof"]
opaque Solver.getProof (s : @& Solver) : Env Ast

/-- String representation of solver assertions. -/
@[extern "lean_z3_Solver_toString"]
opaque Solver.toString' (s : @& Solver) : String

instance : ToString Solver := ⟨fun s => Solver.toString' s⟩

/-! ## Unsat cores and assumptions -/

/-- Assert a constraint tracked by a Boolean literal.
After an unsat check, the tracking literal appears in the unsat core
if the constraint contributed to unsatisfiability. -/
@[extern "lean_z3_Solver_assertAndTrack"]
opaque Solver.assertAndTrack (s : @& Solver) (a : @& Ast) (track : @& Ast) : BaseIO PUnit

/-- Check satisfiability under the given assumptions. Returns encoded `Z3_lbool` shifted by +1. -/
@[extern "lean_z3_Solver_checkAssumptionsRaw"]
opaque Solver.checkAssumptionsRaw (s : @& Solver) (assumptions : @& Array Ast) : BaseIO UInt32

/-- Check satisfiability under the given assumptions. -/
def Solver.checkAssumptions (s : @& Solver) (assumptions : @& Array Ast) : BaseIO LBool := do
  let raw ← Solver.checkAssumptionsRaw s assumptions
  return match raw with
  | 0 => .false
  | 2 => .true
  | _ => .undef

/-- Get the unsat core after an unsatisfiable `checkSat` or `checkAssumptions`.
Returns the tracking literals / assumptions that contributed to unsatisfiability. -/
@[extern "lean_z3_Solver_getUnsatCore"]
opaque Solver.getUnsatCore (s : @& Solver) : Env (Array Ast)

/-- Get all assertions in the solver. -/
@[extern "lean_z3_Solver_getAssertions"]
opaque Solver.getAssertions (s : @& Solver) : BaseIO (Array Ast)

/-! ## Model operations -/

/-- Get the model after a satisfiable check. -/
@[extern "lean_z3_Solver_getModel"]
opaque Solver.getModel (s : @& Solver) : Env Model

/-- Evaluate an AST in the model. -/
@[extern "lean_z3_Model_eval"]
opaque Model.eval (m : @& Model) (a : @& Ast) (completion : Bool) : Env Ast

/-- Get the number of constant declarations in the model. -/
@[extern "lean_z3_Model_getNumConsts"]
opaque Model.getNumConsts (m : @& Model) : UInt32

/-- Get the i-th constant declaration. -/
@[extern "lean_z3_Model_getConstDecl"]
opaque Model.getConstDecl (m : @& Model) (i : UInt32) : FuncDecl

/-- Get the interpretation of a constant. -/
@[extern "lean_z3_Model_getConstInterp"]
opaque Model.getConstInterp (m : @& Model) (fd : @& FuncDecl) : Env Ast

/-- String representation. -/
@[extern "lean_z3_Model_toString"]
opaque Model.toString' (m : @& Model) : String

instance : ToString Model := ⟨fun m => Model.toString' m⟩

/-! ## SMT-LIB parsing -/

/-- Parse an SMT-LIB2 string and return the resulting assertions as an AST. -/
@[extern "lean_z3_Context_parseSMTLIB2String"]
opaque Context.parseSMTLIB2String (ctx : @& Context) (str : @& String) : Env Ast

/-! ## Quantifiers -/

/-- Create a bound variable with de Bruijn index `idx` and sort `s`. -/
@[extern "lean_z3_Ast_mkBound"]
opaque Ast.mkBound (ctx : @& Context) (idx : UInt32) (s : @& Srt) : Ast

/-- Create a universal quantifier.
  `names` and `sorts` specify the bound variables (index 0 = innermost).
  `body` is the quantified formula (using `mkBound` for bound variable references).
  `weight` is an optional hint for the solver (default 0). -/
@[extern "lean_z3_Ast_mkForall"]
opaque Ast.mkForall (ctx : @& Context) (sorts : @& Array Srt)
    (names : @& Array String) (body : @& Ast) (weight : UInt32) : Env Ast

/-- Create an existential quantifier.
  `names` and `sorts` specify the bound variables (index 0 = innermost).
  `body` is the quantified formula (using `mkBound` for bound variable references).
  `weight` is an optional hint for the solver (default 0). -/
@[extern "lean_z3_Ast_mkExists"]
opaque Ast.mkExists (ctx : @& Context) (sorts : @& Array Srt)
    (names : @& Array String) (body : @& Ast) (weight : UInt32) : Env Ast

/-! ## Datatype operations -/

/-- Create a datatype constructor declaration.
  `name` — constructor name, `recognizer` — "is-Name" tester name,
  `fieldNames` — field/accessor names, `fieldSorts` — field sorts,
  `fieldSortRefs` — sort references for recursive sorts (0 = use fieldSorts entry). -/
@[extern "lean_z3_Constructor_mk"]
opaque Constructor.mk (ctx : @& Context) (name : @& String)
    (recognizer : @& String) (fieldNames : @& Array String)
    (fieldSorts : @& Array Srt) (fieldSortRefs : @& Array UInt32) : Env Constructor

/-- Create a datatype sort from a name and array of constructor declarations.
  **Warning:** The constructors are consumed by Z3 — do not reuse them after this call. -/
@[extern "lean_z3_Srt_mkDatatype"]
opaque Srt.mkDatatype (ctx : @& Context) (name : @& String)
    (constructors : @& Array Constructor) : Env Srt

/-- Query a constructor for its function declaration, tester, and accessor declarations.
  Returns `(constructor_decl, tester_decl, #[accessor_decls...])`.
  `numFields` must match the number of fields used when creating the constructor. -/
@[extern "lean_z3_Constructor_query"]
opaque Constructor.query (c : @& Constructor) (numFields : UInt32)
    : Env (FuncDecl × FuncDecl × Array FuncDecl)

/-! ## On-clause callback -/

/-- An opaque handle for collecting clause events during solving.
Created by `Solver.registerOnClause`, accumulates events when `checkSat` runs. -/
opaque OnClauseHandle.Pointed : NonemptyType
def OnClauseHandle : Type := OnClauseHandle.Pointed.type
instance : Nonempty OnClauseHandle := OnClauseHandle.Pointed.property

/-- A single clause event from the CDCL engine.
- `proofHint`: a proof AST describing how the clause was derived
- `deps`: indices of previously seen clauses this clause depends on
- `literals`: the clause literals (disjuncts) -/
structure ClauseEvent where
  proofHint : Ast
  deps : Array UInt32
  literals : Array Ast

/-- Register a clause event collector on the solver.
The returned handle accumulates clause events (asserted, inferred, deleted)
during subsequent `checkSat` calls. Use `OnClauseHandle.getClauses` to retrieve them. -/
@[extern "lean_z3_Solver_registerOnClause"]
opaque Solver.registerOnClause (s : @& Solver) : BaseIO OnClauseHandle

/-- Retrieve all collected clause events. -/
@[extern "lean_z3_OnClauseHandle_getClauses"]
opaque OnClauseHandle.getClauses (h : @& OnClauseHandle) : BaseIO (Array ClauseEvent)

/-- Clear the collected clause events buffer. -/
@[extern "lean_z3_OnClauseHandle_clear"]
opaque OnClauseHandle.clear (h : @& OnClauseHandle) : BaseIO PUnit

/-! ## Proof navigation -/

/-- Get the proof rule of an application AST, or `none` if not a proof step.
    Only valid for `AstKind.app` nodes whose decl kind is in the `Z3_OP_PR_*` range. -/
def Ast.getProofRule? (a : @& Ast) : Option ProofRule :=
  if Ast.getAstKind a != .app then none
  else ProofRule.ofRaw? (FuncDecl.getDeclKindRaw (Ast.getFuncDecl a))

/-- Get the children (antecedents) of a proof step. -/
def Ast.getArgs (a : @& Ast) : Array Ast := Id.run do
  let n := Ast.getNumArgs a
  let mut result := #[]
  for i in List.range n.toNat do
    result := result.push (Ast.getArg a i.toUInt32)
  return result

/-- Collect all unique proof rules used in a proof tree (DFS). -/
partial def Ast.collectProofRules (a : Ast) : Array ProofRule := Id.run do
  let mut visited : Array ProofRule := #[]
  let mut stack : Array Ast := #[a]
  while h : stack.size > 0 do
    let node := stack[stack.size - 1]
    stack := stack.pop
    if node.getAstKind != .app then continue
    match node.getProofRule? with
    | none => continue
    | some rule =>
      unless visited.contains rule do
        visited := visited.push rule
      let n := node.getNumArgs
      for i in List.range n.toNat do
        stack := stack.push (node.getArg i.toUInt32)
  return visited

end Z3

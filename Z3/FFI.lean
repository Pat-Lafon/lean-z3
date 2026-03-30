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

/-- Z3 parameter descriptions (`Z3_param_descrs`). -/
opaque ParamDescrs.Pointed : NonemptyType
def ParamDescrs : Type := ParamDescrs.Pointed.type
instance : Nonempty ParamDescrs := ParamDescrs.Pointed.property

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

/-- A Z3 function interpretation (`Z3_func_interp`). -/
opaque FuncInterp.Pointed : NonemptyType
def FuncInterp : Type := FuncInterp.Pointed.type
instance : Nonempty FuncInterp := FuncInterp.Pointed.property

/-- A Z3 function entry (`Z3_func_entry`). -/
opaque FuncEntry.Pointed : NonemptyType
def FuncEntry : Type := FuncEntry.Pointed.type
instance : Nonempty FuncEntry := FuncEntry.Pointed.property

/-- A Z3 tactic (`Z3_tactic`). -/
opaque Tactic.Pointed : NonemptyType
def Tactic : Type := Tactic.Pointed.type
instance : Nonempty Tactic := Tactic.Pointed.property

/-- A Z3 goal (`Z3_goal`). -/
opaque Goal.Pointed : NonemptyType
def Goal : Type := Goal.Pointed.type
instance : Nonempty Goal := Goal.Pointed.property

/-- A Z3 apply result (`Z3_apply_result`). -/
opaque ApplyResult.Pointed : NonemptyType
def ApplyResult : Type := ApplyResult.Pointed.type
instance : Nonempty ApplyResult := ApplyResult.Pointed.property

/-- A Z3 optimizer (`Z3_optimize`). -/
opaque Optimize.Pointed : NonemptyType
def Optimize : Type := Optimize.Pointed.type
instance : Nonempty Optimize := Optimize.Pointed.property

/-- Z3 statistics (`Z3_stats`). -/
opaque Stats.Pointed : NonemptyType
def Stats : Type := Stats.Pointed.type
instance : Nonempty Stats := Stats.Pointed.property

/-- Z3 fixedpoint engine (`Z3_fixedpoint`). -/
opaque Fixedpoint.Pointed : NonemptyType
def Fixedpoint : Type := Fixedpoint.Pointed.type
instance : Nonempty Fixedpoint := Fixedpoint.Pointed.property

/-- A Z3 probe (`Z3_probe`). Probes measure properties of goals (e.g., number of variables). -/
opaque Probe.Pointed : NonemptyType
def Probe : Type := Probe.Pointed.type
instance : Nonempty Probe := Probe.Pointed.property

/-- A user propagator handle. Holds registered callbacks for the solver. -/
opaque Propagator.Pointed : NonemptyType
def Propagator : Type := Propagator.Pointed.type
instance : Nonempty Propagator := Propagator.Pointed.property

/-- An ephemeral solver callback handle, only valid within a propagator callback. -/
opaque SolverCallback.Pointed : NonemptyType
def SolverCallback : Type := SolverCallback.Pointed.type
instance : Nonempty SolverCallback := SolverCallback.Pointed.property

/-- A Z3 simplifier (`Z3_simplifier`). Building block for custom pre-processing pipelines. -/
opaque Simplifier.Pointed : NonemptyType
def Simplifier : Type := Simplifier.Pointed.type
instance : Nonempty Simplifier := Simplifier.Pointed.property

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

/-! ## Numeral constructors -/

/-- Create a numeral from an `Int32` and a sort. -/
@[extern "lean_z3_Ast_mkInt"]
opaque Ast.mkInt (ctx : @& Context) (v : Int32) (sort : @& Srt) : Ast

/-- Create a real numeral from numerator and denominator (as `Int32`). -/
@[extern "lean_z3_Ast_mkReal"]
opaque Ast.mkReal (ctx : @& Context) (num den : Int32) : Ast

/-- Create a numeral from an `Int64` and a sort. -/
@[extern "lean_z3_Ast_mkInt64"]
opaque Ast.mkInt64 (ctx : @& Context) (v : Int64) (sort : @& Srt) : Ast

/-- Create a numeral from a `UInt64` and a sort. -/
@[extern "lean_z3_Ast_mkUInt64"]
opaque Ast.mkUInt64 (ctx : @& Context) (v : UInt64) (sort : @& Srt) : Ast

/-- Create a real numeral from numerator and denominator (as `Int64`). -/
@[extern "lean_z3_Ast_mkRealVal"]
opaque Ast.mkRealVal (ctx : @& Context) (num den : Int64) : Ast

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

/-- Exclusive or. -/
@[extern "lean_z3_Ast_xor"]
opaque Ast.xor (ctx : @& Context) (a b : @& Ast) : Ast

/-- Biconditional (if and only if). -/
@[extern "lean_z3_Ast_iff"]
opaque Ast.iff (ctx : @& Context) (a b : @& Ast) : Ast

/-- Extract the Boolean value of a constant AST.
Returns `.true`, `.false`, or `.undef` if the value cannot be determined. -/
@[extern "lean_z3_Ast_getBoolValue"]
private opaque Ast.getBoolValueRaw (a : @& Ast) : UInt32

/-- Extract the Boolean value of a constant AST. -/
def Ast.getBoolValue (a : @& Ast) : LBool :=
  match Ast.getBoolValueRaw a with
  | 0 => .false
  | 2 => .true
  | _ => .undef

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

/-- Integer/real division. -/
@[extern "lean_z3_Ast_div"]
opaque Ast.div (ctx : @& Context) (a b : @& Ast) : Ast

/-- Integer modulus (Euclidean). -/
@[extern "lean_z3_Ast_mod"]
opaque Ast.mod (ctx : @& Context) (a b : @& Ast) : Ast

/-- Integer remainder (Euclidean, always non-negative). -/
@[extern "lean_z3_Ast_rem"]
opaque Ast.rem (ctx : @& Context) (a b : @& Ast) : Ast

/-- Exponentiation. -/
@[extern "lean_z3_Ast_power"]
opaque Ast.power (ctx : @& Context) (a b : @& Ast) : Ast

/-- Absolute value. -/
@[extern "lean_z3_Ast_abs"]
opaque Ast.abs (ctx : @& Context) (a : @& Ast) : Ast

/-- Unary negation. -/
@[extern "lean_z3_Ast_unaryMinus"]
opaque Ast.unaryMinus (ctx : @& Context) (a : @& Ast) : Ast

/-- Coerce an integer to a real. -/
@[extern "lean_z3_Ast_int2real"]
opaque Ast.int2real (ctx : @& Context) (a : @& Ast) : Ast

/-- Floor: coerce a real to an integer (rounds toward negative infinity). -/
@[extern "lean_z3_Ast_real2int"]
opaque Ast.real2int (ctx : @& Context) (a : @& Ast) : Ast

/-- Test whether a real value is an integer. -/
@[extern "lean_z3_Ast_isInt"]
opaque Ast.isInt (ctx : @& Context) (a : @& Ast) : Ast

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

/-- Bitwise NAND. -/
@[extern "lean_z3_Ast_bvnand"]
opaque Ast.bvnand (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitwise NOR. -/
@[extern "lean_z3_Ast_bvnor"]
opaque Ast.bvnor (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitwise XNOR. -/
@[extern "lean_z3_Ast_bvxnor"]
opaque Ast.bvxnor (ctx : @& Context) (a b : @& Ast) : Ast

/-- Signed modulus (two's complement). -/
@[extern "lean_z3_Ast_bvsmod"]
opaque Ast.bvsmod (ctx : @& Context) (a b : @& Ast) : Ast

/-- Bitwise AND reduction (1-bit result: 1 iff all bits are 1). -/
@[extern "lean_z3_Ast_bvredand"]
opaque Ast.bvredand (ctx : @& Context) (a : @& Ast) : Ast

/-- Bitwise OR reduction (1-bit result: 1 iff any bit is 1). -/
@[extern "lean_z3_Ast_bvredor"]
opaque Ast.bvredor (ctx : @& Context) (a : @& Ast) : Ast

/-- Repeat bitvector `n` times. -/
@[extern "lean_z3_Ast_bvrepeat"]
opaque Ast.bvrepeat (ctx : @& Context) (n : UInt32) (a : @& Ast) : Ast

/-- Check that addition does not overflow. -/
@[extern "lean_z3_Ast_bvaddNoOverflow"]
opaque Ast.bvaddNoOverflow (ctx : @& Context) (a b : @& Ast) (isSigned : Bool) : Ast

/-- Check that signed addition does not underflow. -/
@[extern "lean_z3_Ast_bvaddNoUnderflow"]
opaque Ast.bvaddNoUnderflow (ctx : @& Context) (a b : @& Ast) : Ast

/-- Check that signed subtraction does not overflow. -/
@[extern "lean_z3_Ast_bvsubNoOverflow"]
opaque Ast.bvsubNoOverflow (ctx : @& Context) (a b : @& Ast) : Ast

/-- Check that subtraction does not underflow. -/
@[extern "lean_z3_Ast_bvsubNoUnderflow"]
opaque Ast.bvsubNoUnderflow (ctx : @& Context) (a b : @& Ast) (isSigned : Bool) : Ast

/-- Check that multiplication does not overflow. -/
@[extern "lean_z3_Ast_bvmulNoOverflow"]
opaque Ast.bvmulNoOverflow (ctx : @& Context) (a b : @& Ast) (isSigned : Bool) : Ast

/-- Check that signed multiplication does not underflow. -/
@[extern "lean_z3_Ast_bvmulNoUnderflow"]
opaque Ast.bvmulNoUnderflow (ctx : @& Context) (a b : @& Ast) : Ast

/-- Check that signed division does not overflow. -/
@[extern "lean_z3_Ast_bvsdivNoOverflow"]
opaque Ast.bvsdivNoOverflow (ctx : @& Context) (a b : @& Ast) : Ast

/-- Check that negation does not overflow. -/
@[extern "lean_z3_Ast_bvnegNoOverflow"]
opaque Ast.bvnegNoOverflow (ctx : @& Context) (a : @& Ast) : Ast

/-! ## Pseudo-boolean constraints -/

/-- At-most-k constraint: at most `k` of the Boolean arguments are true. -/
@[extern "lean_z3_Ast_mkAtmost"]
opaque Ast.mkAtmost (ctx : @& Context) (args : @& Array Ast) (k : UInt32) : Ast

/-- At-least-k constraint: at least `k` of the Boolean arguments are true. -/
@[extern "lean_z3_Ast_mkAtleast"]
opaque Ast.mkAtleast (ctx : @& Context) (args : @& Array Ast) (k : UInt32) : Ast

/-- Weighted pseudo-boolean ≤: `coeffs[0]*args[0] + ... + coeffs[n-1]*args[n-1] ≤ k`. -/
@[extern "lean_z3_Ast_mkPble"]
opaque Ast.mkPble (ctx : @& Context) (args : @& Array Ast) (coeffs : @& Array Int32) (k : Int32) : Ast

/-- Weighted pseudo-boolean ≥: `coeffs[0]*args[0] + ... + coeffs[n-1]*args[n-1] ≥ k`. -/
@[extern "lean_z3_Ast_mkPbge"]
opaque Ast.mkPbge (ctx : @& Context) (args : @& Array Ast) (coeffs : @& Array Int32) (k : Int32) : Ast

/-- Weighted pseudo-boolean =: `coeffs[0]*args[0] + ... + coeffs[n-1]*args[n-1] = k`. -/
@[extern "lean_z3_Ast_mkPbeq"]
opaque Ast.mkPbeq (ctx : @& Context) (args : @& Array Ast) (coeffs : @& Array Int32) (k : Int32) : Ast

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

/-- Get the numeral value as a decimal string with given precision. -/
@[extern "lean_z3_Ast_getNumeralDecimalString"]
opaque Ast.getNumeralDecimalString (a : @& Ast) (precision : UInt32) : String

/-- Get the numeral value as a binary string. -/
@[extern "lean_z3_Ast_getNumeralBinaryString"]
opaque Ast.getNumeralBinaryString (a : @& Ast) : String

/-- Get the numeral value as an Int64. Fails if the value doesn't fit. -/
@[extern "lean_z3_Ast_getNumeralInt64"]
opaque Ast.getNumeralInt64 (a : @& Ast) : Env Int64

/-- Get the numeral value as a UInt64. Fails if the value doesn't fit. -/
@[extern "lean_z3_Ast_getNumeralUInt64"]
opaque Ast.getNumeralUInt64 (a : @& Ast) : Env UInt64

/-- Get the numeral value as a Float (double). -/
@[extern "lean_z3_Ast_getNumeralDouble"]
opaque Ast.getNumeralDouble (a : @& Ast) : Float

/-- Get the numerator of a rational numeral. -/
@[extern "lean_z3_Ast_getNumerator"]
opaque Ast.getNumerator (a : @& Ast) : Ast

/-- Get the denominator of a rational numeral. -/
@[extern "lean_z3_Ast_getDenominator"]
opaque Ast.getDenominator (a : @& Ast) : Ast

/-- Get a string representation. -/
@[extern "lean_z3_Ast_toString"]
opaque Ast.toString' (a : @& Ast) : String

instance : ToString Ast := ⟨fun a => Ast.toString' a⟩

/-! ## AST utilities -/

/-- Check if an AST is an application node. -/
@[extern "lean_z3_Ast_isApp"]
opaque Ast.isApp (a : @& Ast) : Bool

/-- Check if an AST is a numeral. -/
@[extern "lean_z3_Ast_isNumeralAst"]
opaque Ast.isNumeralAst (a : @& Ast) : Bool

/-- Check if an AST is well-sorted. -/
@[extern "lean_z3_Ast_isWellSorted"]
opaque Ast.isWellSorted (a : @& Ast) : Bool

/-- Check structural equality of two ASTs. -/
@[extern "lean_z3_Ast_isEqAst"]
opaque Ast.isEqAst (a b : @& Ast) : Bool

/-- Get a unique identifier for an AST (unique within its context). -/
@[extern "lean_z3_Ast_getId"]
opaque Ast.getId (a : @& Ast) : UInt32

/-- Get a hash value for an AST. -/
@[extern "lean_z3_Ast_getHash"]
opaque Ast.getHash (a : @& Ast) : UInt32

/-- Translate an AST from one context to another. -/
@[extern "lean_z3_Ast_translate"]
opaque Ast.translate (a : @& Ast) (target : @& Context) : Ast

/-! ## Quantifier inspection -/

/-- Check if a quantifier AST is a universal (forall). -/
@[extern "lean_z3_Ast_isQuantifierForall"]
opaque Ast.isQuantifierForall (a : @& Ast) : Bool

/-- Check if a quantifier AST is existential. -/
@[extern "lean_z3_Ast_isQuantifierExists"]
opaque Ast.isQuantifierExists (a : @& Ast) : Bool

/-- Get the body of a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierBody"]
opaque Ast.getQuantifierBody (a : @& Ast) : Ast

/-- Get the number of bound variables in a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierNumBound"]
opaque Ast.getQuantifierNumBound (a : @& Ast) : UInt32

/-- Get the name of the i-th bound variable in a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierBoundName"]
opaque Ast.getQuantifierBoundName (a : @& Ast) (i : UInt32) : String

/-- Get the sort of the i-th bound variable in a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierBoundSort"]
opaque Ast.getQuantifierBoundSort (a : @& Ast) (i : UInt32) : Srt

/-- Get the weight of a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierWeight"]
opaque Ast.getQuantifierWeight (a : @& Ast) : UInt32

/-- Get the number of patterns in a quantifier. -/
@[extern "lean_z3_Ast_getQuantifierNumPatterns"]
opaque Ast.getQuantifierNumPatterns (a : @& Ast) : UInt32

/-- Get the i-th pattern of a quantifier (returned as an Ast). -/
@[extern "lean_z3_Ast_getQuantifierPatternAst"]
opaque Ast.getQuantifierPatternAst (a : @& Ast) (i : UInt32) : Ast

/-- Check if a quantifier AST is a lambda. -/
@[extern "lean_z3_Ast_isLambda"]
opaque Ast.isLambda (a : @& Ast) : Bool

/-- Create a pattern (trigger) from one or more terms.
Used with `mkQuantifierEx` or the extended quantifier API. -/
@[extern "lean_z3_Ast_mkPattern"]
opaque Ast.mkPattern (ctx : @& Context) (terms : @& Array Ast) : Ast

/-! ## Variable inspection -/

/-- Get the de Bruijn index of a bound variable AST (`Z3_VAR_AST`). -/
@[extern "lean_z3_Ast_getVarIndex"]
opaque Ast.getVarIndex (a : @& Ast) : UInt32

/-! ## Substitution & simplification -/

/-- Substitute `from[i]` with `to[i]` in expression `a`. -/
@[extern "lean_z3_Ast_substitute"]
opaque Ast.substitute (ctx : @& Context) (a : @& Ast)
    (from_ : @& Array Ast) (to : @& Array Ast) : Env Ast

/-- Substitute bound variables (de Bruijn index `i`) with `to[i]` in expression `a`. -/
@[extern "lean_z3_Ast_substituteVars"]
opaque Ast.substituteVars (ctx : @& Context) (a : @& Ast)
    (to : @& Array Ast) : Env Ast

/-- Simplify an expression using Z3's built-in simplifier. -/
@[extern "lean_z3_Ast_simplify"]
opaque Ast.simplify (ctx : @& Context) (a : @& Ast) : Ast

/-- Simplify an expression with custom parameters. -/
@[extern "lean_z3_Ast_simplifyEx"]
opaque Ast.simplifyEx (ctx : @& Context) (a : @& Ast) (p : @& Params) : Ast

/-- Get parameter descriptions for the simplifier. -/
@[extern "lean_z3_Context_simplifyGetParamDescrs"]
opaque Context.simplifyGetParamDescrs (ctx : @& Context) : BaseIO ParamDescrs

/-! ## FuncDecl operations -/

/-- Get the decl kind as a raw `UInt32`. -/
@[extern "lean_z3_FuncDecl_getDeclKindRaw"]
opaque FuncDecl.getDeclKindRaw (fd : @& FuncDecl) : UInt32

/-- Get the declaration kind as a typed `DeclKind`. -/
def FuncDecl.getDeclKind (fd : @& FuncDecl) : DeclKind :=
  DeclKind.ofRaw (FuncDecl.getDeclKindRaw fd)

/-- Return the actual Z3 C enum value for DeclKind variant at the given index.
    Used by tests to validate that our Lean `toRaw` values match the Z3 header. -/
@[extern "lean_z3_DeclKind_expectedRaw"]
opaque DeclKind.expectedRaw (idx : UInt32) : UInt32

/-- Get the name of a function declaration. -/
@[extern "lean_z3_FuncDecl_getName"]
opaque FuncDecl.getName (fd : @& FuncDecl) : String

/-- String representation. -/
@[extern "lean_z3_FuncDecl_toString"]
opaque FuncDecl.toString' (fd : @& FuncDecl) : String

instance : ToString FuncDecl := ⟨fun fd => FuncDecl.toString' fd⟩

/-! ## FuncDecl inspection -/

/-- Get the arity (number of domain sorts) of a function declaration. -/
@[extern "lean_z3_FuncDecl_getArity"]
opaque FuncDecl.getArity (fd : @& FuncDecl) : UInt32

/-- Get the i-th domain sort of a function declaration. -/
@[extern "lean_z3_FuncDecl_getDomain"]
opaque FuncDecl.getDomain (fd : @& FuncDecl) (i : UInt32) : Srt

/-- Get the range (return) sort of a function declaration. -/
@[extern "lean_z3_FuncDecl_getRange"]
opaque FuncDecl.getRange (fd : @& FuncDecl) : Srt

/-! ## Uninterpreted functions -/

/-- Declare an uninterpreted function with the given name, domain sorts, and range sort.
For constants (arity 0), pass an empty domain array. -/
@[extern "lean_z3_FuncDecl_mk"]
opaque FuncDecl.mk (ctx : @& Context) (name : @& String)
    (domain : @& Array Srt) (range : @& Srt) : FuncDecl

/-- Apply a function declaration to arguments. For constants (arity 0), pass an empty array. -/
@[extern "lean_z3_Ast_mkApp"]
opaque Ast.mkApp (ctx : @& Context) (fd : @& FuncDecl) (args : @& Array Ast) : Ast

/-- Create a fresh constant with a unique name based on the given prefix. -/
@[extern "lean_z3_Ast_mkFreshConst"]
opaque Ast.mkFreshConst (ctx : @& Context) (pfx : @& String) (sort : @& Srt) : BaseIO Ast

/-- Declare a fresh uninterpreted function with a unique name based on the given prefix. -/
@[extern "lean_z3_FuncDecl_mkFresh"]
opaque FuncDecl.mkFresh (ctx : @& Context) (pfx : @& String)
    (domain : @& Array Srt) (range : @& Srt) : BaseIO FuncDecl

/-- Declare a recursive function. Must be followed by `FuncDecl.addRecDef` to provide the body. -/
@[extern "lean_z3_FuncDecl_mkRec"]
opaque FuncDecl.mkRec (ctx : @& Context) (name : @& String)
    (domain : @& Array Srt) (range : @& Srt) : FuncDecl

/-- Add the recursive definition for a function declared with `FuncDecl.mkRec`.
  `args` — the formal parameters (constants matching the domain sorts).
  `body` — the function body in terms of those parameters. -/
@[extern "lean_z3_FuncDecl_addRecDef"]
opaque FuncDecl.addRecDef (ctx : @& Context) (f : @& FuncDecl)
    (args : @& Array Ast) (body : @& Ast) : BaseIO PUnit

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

/-- Set a double/float parameter. -/
@[extern "lean_z3_Params_setDouble"]
opaque Params.setDouble (p : @& Params) (name : @& String) (val : Float) : BaseIO PUnit

/-- Set a symbol parameter. -/
@[extern "lean_z3_Params_setSymbol"]
opaque Params.setSymbol (p : @& Params) (name : @& String) (val : @& String) : BaseIO PUnit

/-- Get a string representation of the parameter set. -/
@[extern "lean_z3_Params_toString"]
opaque Params.toString' (p : @& Params) : String

instance : ToString Params := ⟨fun p => Params.toString' p⟩

/-- Validate params against a parameter description set. -/
@[extern "lean_z3_Params_validate"]
opaque Params.validate (p : @& Params) (d : @& ParamDescrs) : BaseIO PUnit

/-! ## ParamDescrs operations -/

/-- Get the solver's parameter descriptions. -/
@[extern "lean_z3_Solver_getParamDescrs"]
opaque Solver.getParamDescrs (ctx : @& Context) (s : @& Solver) : BaseIO ParamDescrs

/-- Get global parameter descriptions. -/
@[extern "lean_z3_Context_getGlobalParamDescrs"]
opaque Context.getGlobalParamDescrs (ctx : @& Context) : BaseIO ParamDescrs

/-- Get the number of parameters in the description set. -/
@[extern "lean_z3_ParamDescrs_size"]
opaque ParamDescrs.size (d : @& ParamDescrs) : UInt32

/-- Get the name of the parameter at index `i`. -/
@[extern "lean_z3_ParamDescrs_getName"]
opaque ParamDescrs.getName (d : @& ParamDescrs) (i : UInt32) : String

/-- Get the kind of a named parameter as a raw `UInt32`.
  Values: 0=uint, 1=bool, 2=double, 3=symbol, 4=string, 5=other, 6=invalid. -/
@[extern "lean_z3_ParamDescrs_getKind"]
opaque ParamDescrs.getKindRaw (d : @& ParamDescrs) (name : @& String) : UInt32

/-- Get the documentation string for a named parameter. -/
@[extern "lean_z3_ParamDescrs_getDocumentation"]
opaque ParamDescrs.getDocumentation (d : @& ParamDescrs) (name : @& String) : String

/-- Get a string representation of the parameter description set. -/
@[extern "lean_z3_ParamDescrs_toString"]
opaque ParamDescrs.toString' (d : @& ParamDescrs) : String

instance : ToString ParamDescrs := ⟨fun d => ParamDescrs.toString' d⟩

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

/-! ## Solver (extended) -/

/-- Create a simple solver (no tactics, basic features). -/
@[extern "lean_z3_Solver_mkSimple"]
opaque Solver.mkSimple (ctx : @& Context) : Env Solver

/-- Create a solver for a specific logic (e.g., "QF_LIA", "QF_BV"). -/
@[extern "lean_z3_Solver_mkForLogic"]
opaque Solver.mkForLogic (ctx : @& Context) (logic : @& String) : Env Solver

/-- Load solver assertions from a string (SMT-LIB2 format). -/
@[extern "lean_z3_Solver_fromString"]
opaque Solver.fromString (s : @& Solver) (str : @& String) : BaseIO PUnit

/-- Load solver assertions from a file (SMT-LIB2 format). -/
@[extern "lean_z3_Solver_fromFile"]
opaque Solver.fromFile (s : @& Solver) (filename : @& String) : BaseIO PUnit

/-- Get the number of backtracking scopes. -/
@[extern "lean_z3_Solver_getNumScopes"]
opaque Solver.getNumScopes (s : @& Solver) : BaseIO UInt32

/-- Interrupt the solver (can be called from another thread). -/
@[extern "lean_z3_Solver_interrupt"]
opaque Solver.interrupt (s : @& Solver) : BaseIO PUnit

/-- Translate a solver to another context. -/
@[extern "lean_z3_Solver_translate"]
opaque Solver.translate (s : @& Solver) (target : @& Context) : Env Solver

/-- Get the trail (assigned literals after solving). -/
@[extern "lean_z3_Solver_getTrail"]
opaque Solver.getTrail (s : @& Solver) : BaseIO (Array Ast)

/-- Get consequences: given assumptions and variables, compute implied equalities.
  Returns `(result, consequences)` where result is the satisfiability check. -/
@[extern "lean_z3_Solver_getConsequences"]
opaque Solver.getConsequences (s : @& Solver) (assumptions variables : @& Array Ast)
    : BaseIO (LBool × Array Ast)

/-- Get solver statistics. -/
@[extern "lean_z3_Solver_getStatistics"]
opaque Solver.getStatistics (s : @& Solver) : BaseIO Stats

/-! ## User Propagation -/

/-- Initialize a user propagator on the solver with push/pop callbacks.
Returns a `Propagator` handle for registering additional callbacks. -/
@[extern "lean_z3_Solver_propagateInit"]
opaque Solver.propagateInit (s : @& Solver)
    (push : SolverCallback → BaseIO PUnit)
    (pop : SolverCallback → UInt32 → BaseIO PUnit)
    : BaseIO Propagator

/-- Register a callback for when a registered expression is assigned a value. -/
@[extern "lean_z3_Propagator_setFixed"]
opaque Propagator.setFixed (p : @& Propagator)
    (f : SolverCallback → Ast → Ast → BaseIO PUnit) : BaseIO PUnit

/-- Register a callback invoked when the solver needs to finalize (check for conflicts). -/
@[extern "lean_z3_Propagator_setFinal"]
opaque Propagator.setFinal (p : @& Propagator)
    (f : SolverCallback → BaseIO PUnit) : BaseIO PUnit

/-- Register a callback for when two registered expressions become equal. -/
@[extern "lean_z3_Propagator_setEq"]
opaque Propagator.setEq (p : @& Propagator)
    (f : SolverCallback → Ast → Ast → BaseIO PUnit) : BaseIO PUnit

/-- Register a callback for when two registered expressions become disequal. -/
@[extern "lean_z3_Propagator_setDiseq"]
opaque Propagator.setDiseq (p : @& Propagator)
    (f : SolverCallback → Ast → Ast → BaseIO PUnit) : BaseIO PUnit

/-- Register a callback for when a new expression is created by the solver. -/
@[extern "lean_z3_Propagator_setCreated"]
opaque Propagator.setCreated (p : @& Propagator)
    (f : SolverCallback → Ast → BaseIO PUnit) : BaseIO PUnit

/-- Register a callback for when the solver is about to make a decision. -/
@[extern "lean_z3_Propagator_setDecide"]
opaque Propagator.setDecide (p : @& Propagator)
    (f : SolverCallback → Ast → UInt32 → Bool → BaseIO PUnit) : BaseIO PUnit

/-- Register an expression for tracking by the user propagator. -/
@[extern "lean_z3_Solver_propagateRegister"]
opaque Solver.propagateRegister (s : @& Solver) (e : @& Ast) : BaseIO PUnit

/-- Register an expression within a callback (e.g., inside a created callback). -/
@[extern "lean_z3_SolverCallback_propagateRegister"]
opaque SolverCallback.propagateRegister (cb : @& SolverCallback) (e : @& Ast) : BaseIO PUnit

/-- Propagate a consequence from within a callback.
`fixed` are assigned literals, `eqLhs`/`eqRhs` are equality pairs, `conseq` is the consequence. -/
@[extern "lean_z3_SolverCallback_propagateConsequence"]
opaque SolverCallback.propagateConsequence (cb : @& SolverCallback)
    (fixed : @& Array Ast) (eqLhs eqRhs : @& Array Ast) (conseq : @& Ast)
    : BaseIO Bool

/-- Suggest a next split decision from within a decide callback. -/
@[extern "lean_z3_SolverCallback_nextSplit"]
opaque SolverCallback.nextSplit (cb : @& SolverCallback)
    (t : @& Ast) (idx : UInt32) (phase : LBool) : BaseIO Bool

/-- Declare a function for use with the user propagator. -/
@[extern "lean_z3_Context_propagateDeclare"]
opaque Context.propagateDeclare (ctx : @& Context) (name : @& String)
    (domain : @& Array Srt) (range : @& Srt) : FuncDecl

/-! ## Simplifier API -/

/-- Create a simplifier by name. -/
@[extern "lean_z3_Simplifier_mk"]
opaque Simplifier.mk (ctx : @& Context) (name : @& String) : Env Simplifier

/-- Compose two simplifiers sequentially (`and_then`). -/
@[extern "lean_z3_Simplifier_andThen"]
opaque Simplifier.andThen (ctx : @& Context) (s1 : @& Simplifier) (s2 : @& Simplifier) : Env Simplifier

/-- Apply parameters to a simplifier. -/
@[extern "lean_z3_Simplifier_usingParams"]
opaque Simplifier.usingParams (ctx : @& Context) (s : @& Simplifier) (p : @& Params) : Env Simplifier

/-- Get the help string for a simplifier. -/
@[extern "lean_z3_Simplifier_getHelp"]
opaque Simplifier.getHelp (ctx : @& Context) (s : @& Simplifier) : String

/-- Get parameter descriptions for a simplifier. -/
@[extern "lean_z3_Simplifier_getParamDescrs"]
opaque Simplifier.getParamDescrs (ctx : @& Context) (s : @& Simplifier) : BaseIO ParamDescrs

/-- Get the description of a simplifier by name. -/
@[extern "lean_z3_Simplifier_getDescr"]
opaque Simplifier.getDescr (ctx : @& Context) (name : @& String) : String

/-- Get the number of available simplifiers. -/
@[extern "lean_z3_Context_getNumSimplifiers"]
opaque Context.getNumSimplifiers (ctx : @& Context) : UInt32

/-- Get the name of the `i`-th simplifier. -/
@[extern "lean_z3_Context_getSimplifierName"]
opaque Context.getSimplifierName (ctx : @& Context) (i : UInt32) : String

/-- Add a simplifier to a solver. Returns a new solver with the simplifier applied. -/
@[extern "lean_z3_Solver_addSimplifier"]
opaque Solver.addSimplifier (ctx : @& Context) (s : @& Solver) (simp : @& Simplifier) : Env Solver

/-! ## Statistics -/

/-- Number of statistical data entries. -/
@[extern "lean_z3_Stats_size"]
opaque Stats.size (s : @& Stats) : UInt32

/-- Key name at index `i`. -/
@[extern "lean_z3_Stats_getKey"]
opaque Stats.getKey (s : @& Stats) (i : UInt32) : String

/-- Is the value at index `i` a UInt? -/
@[extern "lean_z3_Stats_isUInt"]
opaque Stats.isUInt (s : @& Stats) (i : UInt32) : Bool

/-- Is the value at index `i` a Double? -/
@[extern "lean_z3_Stats_isDouble"]
opaque Stats.isDouble (s : @& Stats) (i : UInt32) : Bool

/-- Get the UInt value at index `i`. -/
@[extern "lean_z3_Stats_getUIntValue"]
opaque Stats.getUIntValue (s : @& Stats) (i : UInt32) : UInt32

/-- Get the Double value at index `i`. -/
@[extern "lean_z3_Stats_getDoubleValue"]
opaque Stats.getDoubleValue (s : @& Stats) (i : UInt32) : Float

/-- String representation. -/
@[extern "lean_z3_Stats_toString"]
opaque Stats.toString' (s : @& Stats) : String

instance : ToString Stats := ⟨fun s => Stats.toString' s⟩

/-! ## Fixedpoint (Datalog/CHC) -/

/-- Create a new fixedpoint engine. -/
@[extern "lean_z3_Fixedpoint_new"]
opaque Fixedpoint.new (ctx : @& Context) : Env Fixedpoint

/-- Register a relation (predicate) with the fixedpoint engine. -/
@[extern "lean_z3_Fixedpoint_registerRelation"]
opaque Fixedpoint.registerRelation (fp : @& Fixedpoint) (f : @& FuncDecl) : BaseIO PUnit

/-- Add a rule (Horn clause). `name` is an optional label. -/
@[extern "lean_z3_Fixedpoint_addRule"]
opaque Fixedpoint.addRule (fp : @& Fixedpoint) (rule : @& Ast) (name : @& String) : BaseIO PUnit

/-- Assert a background axiom. -/
@[extern "lean_z3_Fixedpoint_assert"]
opaque Fixedpoint.assert (fp : @& Fixedpoint) (a : @& Ast) : BaseIO PUnit

/-- Query the fixedpoint engine. Returns satisfiability of the query. -/
@[extern "lean_z3_Fixedpoint_query"]
opaque Fixedpoint.query (fp : @& Fixedpoint) (query : @& Ast) : BaseIO LBool

/-- Get the answer (derivation/proof) after a successful query. -/
@[extern "lean_z3_Fixedpoint_getAnswer"]
opaque Fixedpoint.getAnswer (fp : @& Fixedpoint) : Ast

/-- Get reason for unknown result. -/
@[extern "lean_z3_Fixedpoint_getReasonUnknown"]
opaque Fixedpoint.getReasonUnknown (fp : @& Fixedpoint) : String

/-- Set parameters. -/
@[extern "lean_z3_Fixedpoint_setParams"]
opaque Fixedpoint.setParams (fp : @& Fixedpoint) (p : @& Params) : BaseIO PUnit

/-- String representation. -/
@[extern "lean_z3_Fixedpoint_toString"]
opaque Fixedpoint.toString' (fp : @& Fixedpoint) : String

instance : ToString Fixedpoint := ⟨fun fp => Fixedpoint.toString' fp⟩

/-- Add a ground fact (tuple of unsigned integers) to a relation. -/
@[extern "lean_z3_Fixedpoint_addFact"]
opaque Fixedpoint.addFact (fp : @& Fixedpoint) (r : @& FuncDecl) (args : @& Array UInt32) : BaseIO PUnit

/-- Query multiple relations simultaneously. -/
@[extern "lean_z3_Fixedpoint_queryRelations"]
opaque Fixedpoint.queryRelations (fp : @& Fixedpoint) (relations : @& Array FuncDecl) : BaseIO LBool

/-- Update a named rule. -/
@[extern "lean_z3_Fixedpoint_updateRule"]
opaque Fixedpoint.updateRule (fp : @& Fixedpoint) (rule : @& Ast) (name : @& String) : BaseIO PUnit

/-- Get the number of levels explored for a predicate. -/
@[extern "lean_z3_Fixedpoint_getNumLevels"]
opaque Fixedpoint.getNumLevels (fp : @& Fixedpoint) (pred : @& FuncDecl) : UInt32

/-- Get the covering property at a given level for a predicate. Returns `none` for level -1. -/
@[extern "lean_z3_Fixedpoint_getCoverDelta"]
opaque Fixedpoint.getCoverDelta (fp : @& Fixedpoint) (level : Int32) (pred : @& FuncDecl) : Ast

/-- Add a covering property at a given level for a predicate. -/
@[extern "lean_z3_Fixedpoint_addCover"]
opaque Fixedpoint.addCover (fp : @& Fixedpoint) (level : Int32) (pred : @& FuncDecl) (property : @& Ast) : BaseIO PUnit

/-- Get statistics for the last query. -/
@[extern "lean_z3_Fixedpoint_getStatistics"]
opaque Fixedpoint.getStatistics (fp : @& Fixedpoint) : Stats

/-- Get all rules that have been added. -/
@[extern "lean_z3_Fixedpoint_getRules"]
opaque Fixedpoint.getRules (fp : @& Fixedpoint) : Array Ast

/-- Get all assertions (background axioms). -/
@[extern "lean_z3_Fixedpoint_getAssertions"]
opaque Fixedpoint.getAssertions (fp : @& Fixedpoint) : Array Ast

/-- Get a help string describing available parameters. -/
@[extern "lean_z3_Fixedpoint_getHelp"]
opaque Fixedpoint.getHelp (fp : @& Fixedpoint) : String

/-- Get parameter descriptors. -/
@[extern "lean_z3_Fixedpoint_getParamDescrs"]
opaque Fixedpoint.getParamDescrs (fp : @& Fixedpoint) : ParamDescrs

/-- Load fixedpoint rules from an SMT-LIB2 string. Returns parsed queries. -/
@[extern "lean_z3_Fixedpoint_fromString"]
opaque Fixedpoint.fromString (fp : @& Fixedpoint) (s : @& String) : Array Ast

/-- Load fixedpoint rules from an SMT-LIB2 file. Returns parsed queries. -/
@[extern "lean_z3_Fixedpoint_fromFile"]
opaque Fixedpoint.fromFile (fp : @& Fixedpoint) (path : @& String) : Array Ast

/-- Set the predicate representation (e.g., "doc", "bdd"). -/
@[extern "lean_z3_Fixedpoint_setPredicateRepresentation"]
opaque Fixedpoint.setPredicateRepresentation (fp : @& Fixedpoint) (f : @& FuncDecl) (kinds : @& Array String) : BaseIO PUnit

/-- Add a constraint at a given level (Spacer engine). -/
@[extern "lean_z3_Fixedpoint_addConstraint"]
opaque Fixedpoint.addConstraint (fp : @& Fixedpoint) (e : @& Ast) (lvl : UInt32) : BaseIO PUnit

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

/-! ## Model (extended) -/

/-- Get the number of function interpretations in the model. -/
@[extern "lean_z3_Model_getNumFuncs"]
opaque Model.getNumFuncs (m : @& Model) : UInt32

/-- Get the i-th function declaration in the model. -/
@[extern "lean_z3_Model_getFuncDecl"]
opaque Model.getFuncDecl (m : @& Model) (i : UInt32) : FuncDecl

/-- Get the function interpretation for a function declaration. -/
@[extern "lean_z3_Model_getFuncInterp"]
opaque Model.getFuncInterp (m : @& Model) (fd : @& FuncDecl) : Env FuncInterp

/-- Check whether the model has an interpretation for a given function declaration. -/
@[extern "lean_z3_Model_hasInterp"]
opaque Model.hasInterp (m : @& Model) (fd : @& FuncDecl) : Bool

/-- Get the universe of an uninterpreted sort in the model. -/
@[extern "lean_z3_Model_getSortUniverse"]
opaque Model.getSortUniverse (m : @& Model) (s : @& Srt) : Env (Array Ast)

/-! ## FuncInterp operations -/

/-- Get the number of entries in a function interpretation. -/
@[extern "lean_z3_FuncInterp_getNumEntries"]
opaque FuncInterp.getNumEntries (fi : @& FuncInterp) : UInt32

/-- Get the i-th entry in a function interpretation. -/
@[extern "lean_z3_FuncInterp_getEntry"]
opaque FuncInterp.getEntry (fi : @& FuncInterp) (i : UInt32) : FuncEntry

/-- Get the else value of a function interpretation. -/
@[extern "lean_z3_FuncInterp_getElse"]
opaque FuncInterp.getElse (fi : @& FuncInterp) : Ast

/-- Get the arity of a function interpretation. -/
@[extern "lean_z3_FuncInterp_getArity"]
opaque FuncInterp.getArity (fi : @& FuncInterp) : UInt32

/-! ## FuncEntry operations -/

/-- Get the value of a function entry. -/
@[extern "lean_z3_FuncEntry_getValue"]
opaque FuncEntry.getValue (fe : @& FuncEntry) : Ast

/-- Get the number of arguments of a function entry. -/
@[extern "lean_z3_FuncEntry_getNumArgs"]
opaque FuncEntry.getNumArgs (fe : @& FuncEntry) : UInt32

/-- Get the i-th argument of a function entry. -/
@[extern "lean_z3_FuncEntry_getArg"]
opaque FuncEntry.getArg (fe : @& FuncEntry) (i : UInt32) : Ast

/-! ## SMT-LIB parsing -/

/-- Parse an SMT-LIB2 string and return the resulting assertions as an AST. -/
@[extern "lean_z3_Context_parseSMTLIB2String"]
opaque Context.parseSMTLIB2String (ctx : @& Context) (str : @& String) : Env Ast

/-- Parse an SMT-LIB2 file and return the resulting assertions as an AST. -/
@[extern "lean_z3_Context_parseSMTLIB2File"]
opaque Context.parseSMTLIB2File (ctx : @& Context) (filename : @& String) : Env Ast

/-- Evaluate an SMT-LIB2 command string and return the result as a string. -/
@[extern "lean_z3_Context_evalSMTLIB2String"]
opaque Context.evalSMTLIB2String (ctx : @& Context) (str : @& String) : BaseIO String

/-! ## Optimization API -/

/-- Create a new optimizer. -/
@[extern "lean_z3_Optimize_new"]
opaque Optimize.new (ctx : @& Context) : Env Optimize

/-- Assert a hard constraint in the optimizer. -/
@[extern "lean_z3_Optimize_assert"]
opaque Optimize.assert (o : @& Optimize) (a : @& Ast) : BaseIO PUnit

/-- Assert a soft constraint with a weight string and group id.
    Returns an index that can be used to query the constraint status. -/
@[extern "lean_z3_Optimize_assertSoft"]
opaque Optimize.assertSoft (o : @& Optimize) (a : @& Ast)
    (weight : @& String) (id : @& String) : BaseIO UInt32

/-- Add a maximization objective. Returns the objective index. -/
@[extern "lean_z3_Optimize_maximize"]
opaque Optimize.maximize (o : @& Optimize) (a : @& Ast) : BaseIO UInt32

/-- Add a minimization objective. Returns the objective index. -/
@[extern "lean_z3_Optimize_minimize"]
opaque Optimize.minimize (o : @& Optimize) (a : @& Ast) : BaseIO UInt32

/-- Check satisfiability of the optimization problem. -/
@[extern "lean_z3_Optimize_check"]
opaque Optimize.check (o : @& Optimize) : BaseIO LBool

/-- Get the model after a satisfiable optimization check. -/
@[extern "lean_z3_Optimize_getModel"]
opaque Optimize.getModel (o : @& Optimize) : Env Model

/-- Get the lower bound for objective at the given index. -/
@[extern "lean_z3_Optimize_getLower"]
opaque Optimize.getLower (o : @& Optimize) (idx : UInt32) : Ast

/-- Get the upper bound for objective at the given index. -/
@[extern "lean_z3_Optimize_getUpper"]
opaque Optimize.getUpper (o : @& Optimize) (idx : UInt32) : Ast

/-- Push a scope in the optimizer. -/
@[extern "lean_z3_Optimize_push"]
opaque Optimize.push (o : @& Optimize) : BaseIO PUnit

/-- Pop a scope in the optimizer. -/
@[extern "lean_z3_Optimize_pop"]
opaque Optimize.pop (o : @& Optimize) : BaseIO PUnit

/-- Set parameters on the optimizer. -/
@[extern "lean_z3_Optimize_setParams"]
opaque Optimize.setParams (o : @& Optimize) (p : @& Params) : BaseIO PUnit

/-- Get the reason for an unknown result. -/
@[extern "lean_z3_Optimize_getReasonUnknown"]
opaque Optimize.getReasonUnknown (o : @& Optimize) : String

/-- String representation. -/
@[extern "lean_z3_Optimize_toString"]
opaque Optimize.toString' (o : @& Optimize) : String

instance : ToString Optimize := ⟨fun o => Optimize.toString' o⟩

/-! ## Tactic / Goal API -/

/-- Create a tactic by name. -/
@[extern "lean_z3_Tactic_mk"]
opaque Tactic.mk (ctx : @& Context) (name : @& String) : Tactic

/-- Combine two tactics sequentially: apply `t1`, then `t2` to each subgoal. -/
@[extern "lean_z3_Tactic_andThen"]
opaque Tactic.andThen (ctx : @& Context) (t1 t2 : @& Tactic) : Tactic

/-- Try `t1`; if it fails, apply `t2`. -/
@[extern "lean_z3_Tactic_orElse"]
opaque Tactic.orElse (ctx : @& Context) (t1 t2 : @& Tactic) : Tactic

/-- Apply tactic with a timeout in milliseconds. -/
@[extern "lean_z3_Tactic_tryFor"]
opaque Tactic.tryFor (ctx : @& Context) (t : @& Tactic) (ms : UInt32) : Tactic

/-- Repeat tactic up to `max` times. -/
@[extern "lean_z3_Tactic_repeat"]
opaque Tactic.repeat (ctx : @& Context) (t : @& Tactic) (max : UInt32) : Tactic

/-- No-op tactic. -/
@[extern "lean_z3_Tactic_skip"]
opaque Tactic.skip (ctx : @& Context) : Tactic

/-- Always-failing tactic. -/
@[extern "lean_z3_Tactic_fail"]
opaque Tactic.fail (ctx : @& Context) : Tactic

/-- Apply tactic with parameters. -/
@[extern "lean_z3_Tactic_usingParams"]
opaque Tactic.usingParams (ctx : @& Context) (t : @& Tactic) (p : @& Params) : Tactic

/-- Get help string for a tactic. -/
@[extern "lean_z3_Tactic_getHelp"]
opaque Tactic.getHelp (ctx : @& Context) (t : @& Tactic) : String

/-- Get description of a tactic by name. -/
@[extern "lean_z3_Tactic_getDescr"]
opaque Tactic.getDescr (ctx : @& Context) (name : @& String) : String

/-- Get the number of available tactics. -/
@[extern "lean_z3_Context_getNumTactics"]
opaque Context.getNumTactics (ctx : @& Context) : UInt32

/-- Get the name of the i-th available tactic. -/
@[extern "lean_z3_Context_getTacticName"]
opaque Context.getTacticName (ctx : @& Context) (i : UInt32) : String

/-! ## Probe API -/

/-- Create a probe by name (e.g., "num-consts", "is-qfbv"). -/
@[extern "lean_z3_Probe_mk"]
opaque Probe.mk (ctx : @& Context) (name : @& String) : Probe

/-- Create a constant probe that always returns the given value. -/
@[extern "lean_z3_Probe_const"]
opaque Probe.const (ctx : @& Context) (val : Float) : Probe

/-- Apply a probe to a goal, returning the probe value. -/
@[extern "lean_z3_Probe_apply"]
opaque Probe.apply (ctx : @& Context) (p : @& Probe) (g : @& Goal) : BaseIO Float

/-- Create a probe that evaluates to true when p1 < p2. -/
@[extern "lean_z3_Probe_lt"]
opaque Probe.lt (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when p1 > p2. -/
@[extern "lean_z3_Probe_gt"]
opaque Probe.gt (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when p1 ≤ p2. -/
@[extern "lean_z3_Probe_le"]
opaque Probe.le (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when p1 ≥ p2. -/
@[extern "lean_z3_Probe_ge"]
opaque Probe.ge (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when p1 = p2. -/
@[extern "lean_z3_Probe_eq"]
opaque Probe.eq (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when both p1 and p2 are true. -/
@[extern "lean_z3_Probe_and"]
opaque Probe.and (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that evaluates to true when either p1 or p2 is true. -/
@[extern "lean_z3_Probe_or"]
opaque Probe.or (ctx : @& Context) (p1 p2 : @& Probe) : Probe

/-- Create a probe that negates another probe. -/
@[extern "lean_z3_Probe_not"]
opaque Probe.not (ctx : @& Context) (p : @& Probe) : Probe

/-- Get the number of available probes. -/
@[extern "lean_z3_Context_getNumProbes"]
opaque Context.getNumProbes (ctx : @& Context) : UInt32

/-- Get the name of the i-th available probe. -/
@[extern "lean_z3_Context_getProbeName"]
opaque Context.getProbeName (ctx : @& Context) (i : UInt32) : String

/-- Get a description of a probe by name. -/
@[extern "lean_z3_Probe_getDescr"]
opaque Probe.getDescr (ctx : @& Context) (name : @& String) : String

/-- Create a tactic that applies `t` only when probe `p` evaluates to true. -/
@[extern "lean_z3_Tactic_when"]
opaque Tactic.when (ctx : @& Context) (p : @& Probe) (t : @& Tactic) : Tactic

/-- Create a tactic that applies `t1` when probe `p` is true, `t2` otherwise. -/
@[extern "lean_z3_Tactic_cond"]
opaque Tactic.cond (ctx : @& Context) (p : @& Probe) (t1 t2 : @& Tactic) : Tactic

/-- Create a tactic that fails when probe `p` evaluates to true. -/
@[extern "lean_z3_Tactic_failIf"]
opaque Tactic.failIf (ctx : @& Context) (p : @& Probe) : Tactic

/-- Create a tactic that fails if the goal is not already decided. -/
@[extern "lean_z3_Tactic_failIfNotDecided"]
opaque Tactic.failIfNotDecided (ctx : @& Context) : Tactic

/-- Create a goal. -/
@[extern "lean_z3_Goal_mk"]
opaque Goal.mk (ctx : @& Context) (models : Bool) (unsatCores : Bool) (proofs : Bool) : Goal

/-- Assert a formula into a goal. -/
@[extern "lean_z3_Goal_assert"]
opaque Goal.assert (g : @& Goal) (a : @& Ast) : BaseIO PUnit

/-- Get the number of formulas in a goal. -/
@[extern "lean_z3_Goal_size"]
opaque Goal.size (g : @& Goal) : UInt32

/-- Get the i-th formula in a goal. -/
@[extern "lean_z3_Goal_formula"]
opaque Goal.formula (g : @& Goal) (i : UInt32) : Ast

/-- Get the depth of a goal. -/
@[extern "lean_z3_Goal_depth"]
opaque Goal.depth (g : @& Goal) : UInt32

/-- Check if a goal is inconsistent. -/
@[extern "lean_z3_Goal_inconsistent"]
opaque Goal.inconsistent (g : @& Goal) : Bool

/-- Check if a goal is decided sat. -/
@[extern "lean_z3_Goal_isDecidedSat"]
opaque Goal.isDecidedSat (g : @& Goal) : Bool

/-- Check if a goal is decided unsat. -/
@[extern "lean_z3_Goal_isDecidedUnsat"]
opaque Goal.isDecidedUnsat (g : @& Goal) : Bool

/-- Reset a goal, removing all formulas. -/
@[extern "lean_z3_Goal_reset"]
opaque Goal.reset (g : @& Goal) : BaseIO PUnit

/-- String representation. -/
@[extern "lean_z3_Goal_toString"]
opaque Goal.toString' (g : @& Goal) : String

instance : ToString Goal := ⟨fun g => Goal.toString' g⟩

/-- Apply a tactic to a goal. -/
@[extern "lean_z3_Tactic_apply"]
opaque Tactic.apply (ctx : @& Context) (t : @& Tactic) (g : @& Goal) : ApplyResult

/-- Apply a tactic to a goal with parameters. -/
@[extern "lean_z3_Tactic_applyEx"]
opaque Tactic.applyEx (ctx : @& Context) (t : @& Tactic) (g : @& Goal) (p : @& Params) : ApplyResult

/-- Get the number of subgoals in an apply result. -/
@[extern "lean_z3_ApplyResult_getNumSubgoals"]
opaque ApplyResult.getNumSubgoals (r : @& ApplyResult) : UInt32

/-- Get the i-th subgoal from an apply result. -/
@[extern "lean_z3_ApplyResult_getSubgoal"]
opaque ApplyResult.getSubgoal (r : @& ApplyResult) (i : UInt32) : Goal

/-- String representation. -/
@[extern "lean_z3_ApplyResult_toString"]
opaque ApplyResult.toString' (r : @& ApplyResult) : String

instance : ToString ApplyResult := ⟨fun r => ApplyResult.toString' r⟩

/-- Create a solver from a tactic. -/
@[extern "lean_z3_Solver_fromTactic"]
opaque Solver.fromTactic (ctx : @& Context) (t : @& Tactic) : Env Solver

/-! ## Floating point theory -/

/-- Create a floating point sort with `ebits` exponent bits and `sbits` significand bits. -/
@[extern "lean_z3_Srt_mkFpa"]
opaque Srt.mkFpa (ctx : @& Context) (ebits sbits : UInt32) : Srt

/-- Create a 32-bit (single precision) floating point sort. -/
@[extern "lean_z3_Srt_mkFpa32"]
opaque Srt.mkFpa32 (ctx : @& Context) : Srt

/-- Create a 64-bit (double precision) floating point sort. -/
@[extern "lean_z3_Srt_mkFpa64"]
opaque Srt.mkFpa64 (ctx : @& Context) : Srt

/-- Create a 16-bit (half precision) floating point sort. -/
@[extern "lean_z3_Srt_mkFpa16"]
opaque Srt.mkFpa16 (ctx : @& Context) : Srt

/-- Create a 128-bit (quadruple precision) floating point sort. -/
@[extern "lean_z3_Srt_mkFpa128"]
opaque Srt.mkFpa128 (ctx : @& Context) : Srt

/-- Create the rounding mode sort. -/
@[extern "lean_z3_Srt_mkFpaRoundingMode"]
opaque Srt.mkFpaRoundingMode (ctx : @& Context) : Srt

/-- Rounding mode: round nearest ties to even. -/
@[extern "lean_z3_Ast_mkFpaRne"]
opaque Ast.mkFpaRne (ctx : @& Context) : Ast

/-- Rounding mode: round nearest ties to away. -/
@[extern "lean_z3_Ast_mkFpaRna"]
opaque Ast.mkFpaRna (ctx : @& Context) : Ast

/-- Rounding mode: round toward positive. -/
@[extern "lean_z3_Ast_mkFpaRtp"]
opaque Ast.mkFpaRtp (ctx : @& Context) : Ast

/-- Rounding mode: round toward negative. -/
@[extern "lean_z3_Ast_mkFpaRtn"]
opaque Ast.mkFpaRtn (ctx : @& Context) : Ast

/-- Rounding mode: round toward zero. -/
@[extern "lean_z3_Ast_mkFpaRtz"]
opaque Ast.mkFpaRtz (ctx : @& Context) : Ast

/-- Create a FP NaN of given sort. -/
@[extern "lean_z3_Ast_mkFpaNan"]
opaque Ast.mkFpaNan (ctx : @& Context) (s : @& Srt) : Ast

/-- Create a FP infinity of given sort. `negative` controls sign. -/
@[extern "lean_z3_Ast_mkFpaInf"]
opaque Ast.mkFpaInf (ctx : @& Context) (s : @& Srt) (negative : Bool) : Ast

/-- Create a FP zero of given sort. `negative` controls sign. -/
@[extern "lean_z3_Ast_mkFpaZero"]
opaque Ast.mkFpaZero (ctx : @& Context) (s : @& Srt) (negative : Bool) : Ast

/-- Create a FP numeral from a double value. -/
@[extern "lean_z3_Ast_mkFpaNumeralDouble"]
opaque Ast.mkFpaNumeralDouble (ctx : @& Context) (v : Float) (s : @& Srt) : Ast

/-- Create a FP numeral from an integer value. -/
@[extern "lean_z3_Ast_mkFpaNumeralInt"]
opaque Ast.mkFpaNumeralInt (ctx : @& Context) (v : Int32) (s : @& Srt) : Ast

/-- FP addition with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaAdd"]
opaque Ast.mkFpaAdd (ctx : @& Context) (rm t1 t2 : @& Ast) : Ast

/-- FP subtraction with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaSub"]
opaque Ast.mkFpaSub (ctx : @& Context) (rm t1 t2 : @& Ast) : Ast

/-- FP multiplication with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaMul"]
opaque Ast.mkFpaMul (ctx : @& Context) (rm t1 t2 : @& Ast) : Ast

/-- FP division with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaDiv"]
opaque Ast.mkFpaDiv (ctx : @& Context) (rm t1 t2 : @& Ast) : Ast

/-- FP fused multiply-add: `t1 * t2 + t3` with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaFma"]
opaque Ast.mkFpaFma (ctx : @& Context) (rm t1 t2 t3 : @& Ast) : Ast

/-- FP square root with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaSqrt"]
opaque Ast.mkFpaSqrt (ctx : @& Context) (rm t : @& Ast) : Ast

/-- FP remainder. -/
@[extern "lean_z3_Ast_mkFpaRem"]
opaque Ast.mkFpaRem (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP absolute value. -/
@[extern "lean_z3_Ast_mkFpaAbs"]
opaque Ast.mkFpaAbs (ctx : @& Context) (t : @& Ast) : Ast

/-- FP negation. -/
@[extern "lean_z3_Ast_mkFpaNeg"]
opaque Ast.mkFpaNeg (ctx : @& Context) (t : @& Ast) : Ast

/-- FP min. -/
@[extern "lean_z3_Ast_mkFpaMin"]
opaque Ast.mkFpaMin (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP max. -/
@[extern "lean_z3_Ast_mkFpaMax"]
opaque Ast.mkFpaMax (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP round to integral with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaRoundToIntegral"]
opaque Ast.mkFpaRoundToIntegral (ctx : @& Context) (rm t : @& Ast) : Ast

/-- FP less than. -/
@[extern "lean_z3_Ast_mkFpaLt"]
opaque Ast.mkFpaLt (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP less than or equal. -/
@[extern "lean_z3_Ast_mkFpaLeq"]
opaque Ast.mkFpaLeq (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP greater than. -/
@[extern "lean_z3_Ast_mkFpaGt"]
opaque Ast.mkFpaGt (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP greater than or equal. -/
@[extern "lean_z3_Ast_mkFpaGeq"]
opaque Ast.mkFpaGeq (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- FP equality (IEEE semantics: NaN ≠ NaN). -/
@[extern "lean_z3_Ast_mkFpaEq"]
opaque Ast.mkFpaEq (ctx : @& Context) (t1 t2 : @& Ast) : Ast

/-- Check if FP value is NaN. -/
@[extern "lean_z3_Ast_mkFpaIsNan"]
opaque Ast.mkFpaIsNan (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is infinite. -/
@[extern "lean_z3_Ast_mkFpaIsInf"]
opaque Ast.mkFpaIsInf (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is zero. -/
@[extern "lean_z3_Ast_mkFpaIsZero"]
opaque Ast.mkFpaIsZero (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is normal. -/
@[extern "lean_z3_Ast_mkFpaIsNormal"]
opaque Ast.mkFpaIsNormal (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is subnormal. -/
@[extern "lean_z3_Ast_mkFpaIsSubnormal"]
opaque Ast.mkFpaIsSubnormal (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is negative. -/
@[extern "lean_z3_Ast_mkFpaIsNegative"]
opaque Ast.mkFpaIsNegative (ctx : @& Context) (t : @& Ast) : Ast

/-- Check if FP value is positive. -/
@[extern "lean_z3_Ast_mkFpaIsPositive"]
opaque Ast.mkFpaIsPositive (ctx : @& Context) (t : @& Ast) : Ast

/-- Convert bitvector to FP. -/
@[extern "lean_z3_Ast_mkFpaToFpBv"]
opaque Ast.mkFpaToFpBv (ctx : @& Context) (bv : @& Ast) (s : @& Srt) : Ast

/-- Convert FP to FP with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToFpFloat"]
opaque Ast.mkFpaToFpFloat (ctx : @& Context) (rm t : @& Ast) (s : @& Srt) : Ast

/-- Convert real to FP with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToFpReal"]
opaque Ast.mkFpaToFpReal (ctx : @& Context) (rm t : @& Ast) (s : @& Srt) : Ast

/-- Convert signed bitvector to FP with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToFpSigned"]
opaque Ast.mkFpaToFpSigned (ctx : @& Context) (rm t : @& Ast) (s : @& Srt) : Ast

/-- Convert unsigned bitvector to FP with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToFpUnsigned"]
opaque Ast.mkFpaToFpUnsigned (ctx : @& Context) (rm t : @& Ast) (s : @& Srt) : Ast

/-- Convert FP to unsigned bitvector with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToUbv"]
opaque Ast.mkFpaToUbv (ctx : @& Context) (rm t : @& Ast) (sz : UInt32) : Ast

/-- Convert FP to signed bitvector with rounding mode. -/
@[extern "lean_z3_Ast_mkFpaToSbv"]
opaque Ast.mkFpaToSbv (ctx : @& Context) (rm t : @& Ast) (sz : UInt32) : Ast

/-- Convert FP to real. -/
@[extern "lean_z3_Ast_mkFpaToReal"]
opaque Ast.mkFpaToReal (ctx : @& Context) (t : @& Ast) : Ast

/-- Convert FP to IEEE bitvector. -/
@[extern "lean_z3_Ast_mkFpaToIeeeBv"]
opaque Ast.mkFpaToIeeeBv (ctx : @& Context) (t : @& Ast) : Ast

/-! ### FPA numeral inspection -/

/-- Check if `t` is a FP NaN numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralNan"]
opaque Ast.fpaIsNumeralNan (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a FP infinity numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralInf"]
opaque Ast.fpaIsNumeralInf (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a FP zero numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralZero"]
opaque Ast.fpaIsNumeralZero (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a normal FP numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralNormal"]
opaque Ast.fpaIsNumeralNormal (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a subnormal FP numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralSubnormal"]
opaque Ast.fpaIsNumeralSubnormal (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a positive FP numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralPositive"]
opaque Ast.fpaIsNumeralPositive (ctx : @& Context) (t : @& Ast) : Bool

/-- Check if `t` is a negative FP numeral. -/
@[extern "lean_z3_Ast_fpaIsNumeralNegative"]
opaque Ast.fpaIsNumeralNegative (ctx : @& Context) (t : @& Ast) : Bool

/-- Raw: returns 0 for positive, 1 for negative, `UInt32.max` on failure. -/
@[extern "lean_z3_Ast_fpaGetNumeralSign_raw"]
private opaque Ast.fpaGetNumeralSignRaw (ctx : @& Context) (t : @& Ast) : BaseIO UInt32

/-- Get the sign of a FP numeral. Returns `some true` for negative, `some false` for positive, `none` on failure. -/
def Ast.fpaGetNumeralSign (ctx : Context) (t : Ast) : BaseIO (Option Bool) := do
  let v ← Ast.fpaGetNumeralSignRaw ctx t
  return if v == 4294967295 then none else some (v != 0)

/-- Get the significand of a FP numeral as a string. -/
@[extern "lean_z3_Ast_fpaGetNumeralSignificandString"]
opaque Ast.fpaGetNumeralSignificandString (ctx : @& Context) (t : @& Ast) : String

/-- Raw: returns significand or sets ok flag. Returns 0 with `ok=false` on failure. -/
@[extern "lean_z3_Ast_fpaGetNumeralSignificandUInt64_raw"]
private opaque Ast.fpaGetNumeralSignificandUInt64Raw (ctx : @& Context) (t : @& Ast) : BaseIO UInt64

/-- Get the significand of a FP numeral as a UInt64. -/
def Ast.fpaGetNumeralSignificandUInt64 (ctx : Context) (t : Ast) : BaseIO UInt64 :=
  Ast.fpaGetNumeralSignificandUInt64Raw ctx t

/-- Get the exponent of a FP numeral as a string. If `biased` is true, return the biased exponent. -/
@[extern "lean_z3_Ast_fpaGetNumeralExponentString"]
opaque Ast.fpaGetNumeralExponentString (ctx : @& Context) (t : @& Ast) (biased : Bool) : String

/-- Raw: returns exponent as UInt64 (interpret as signed Int64), or 0 on failure. -/
@[extern "lean_z3_Ast_fpaGetNumeralExponentInt64_raw"]
private opaque Ast.fpaGetNumeralExponentInt64Raw (ctx : @& Context) (t : @& Ast) (biased : Bool) : BaseIO UInt64

/-- Get the exponent of a FP numeral as a UInt64 (interpret as signed Int64). If `biased` is true, return the biased exponent. -/
def Ast.fpaGetNumeralExponentInt64 (ctx : Context) (t : Ast) (biased : Bool) : BaseIO UInt64 :=
  Ast.fpaGetNumeralExponentInt64Raw ctx t biased

/-- Get the sign bitvector of a FP numeral. -/
@[extern "lean_z3_Ast_fpaGetNumeralSignBv"]
opaque Ast.fpaGetNumeralSignBv (ctx : @& Context) (t : @& Ast) : Ast

/-- Get the significand bitvector of a FP numeral. -/
@[extern "lean_z3_Ast_fpaGetNumeralSignificandBv"]
opaque Ast.fpaGetNumeralSignificandBv (ctx : @& Context) (t : @& Ast) : Ast

/-- Get the exponent bitvector of a FP numeral. If `biased` is true, return the biased exponent. -/
@[extern "lean_z3_Ast_fpaGetNumeralExponentBv"]
opaque Ast.fpaGetNumeralExponentBv (ctx : @& Context) (t : @& Ast) (biased : Bool) : Ast

/-! ## Additional sorts -/

/-- Create a finite domain sort with the given name and size. -/
@[extern "lean_z3_Srt_mkFiniteDomain"]
opaque Srt.mkFiniteDomain (ctx : @& Context) (name : @& String) (size : UInt64) : Srt

/-- Create the character sort (Unicode). -/
@[extern "lean_z3_Srt_mkChar"]
opaque Srt.mkChar (ctx : @& Context) : Srt

/-- Create an enumeration sort.
  Returns `(sort, enumConstants, enumTesters)`. -/
@[extern "lean_z3_Srt_mkEnumeration"]
opaque Srt.mkEnumeration (ctx : @& Context) (name : @& String)
    (enumNames : @& Array String) : Env (Srt × Array FuncDecl × Array FuncDecl)

/-- Create a list sort.
  Returns `(sort, nilDecl, isNilDecl, consDecl, isConsDecl, headDecl, tailDecl)`. -/
@[extern "lean_z3_Srt_mkList"]
opaque Srt.mkList (ctx : @& Context) (name : @& String) (elemSort : @& Srt)
    : Env (Srt × FuncDecl × FuncDecl × FuncDecl × FuncDecl × FuncDecl × FuncDecl)

/-- Create a tuple sort.
  Returns `(sort, mkTupleDecl, projectionDecls)`. -/
@[extern "lean_z3_Srt_mkTuple"]
opaque Srt.mkTuple (ctx : @& Context) (name : @& String)
    (fieldNames : @& Array String) (fieldSorts : @& Array Srt)
    : Env (Srt × FuncDecl × Array FuncDecl)

/-- Create mutually recursive datatypes.
  Takes an array of `(sortName, constructors)` pairs.
  Returns the array of created sorts.
  Note: constructors are modified in-place (like `mkDatatype`). -/
@[extern "lean_z3_Srt_mkDatatypes"]
opaque Srt.mkDatatypes (ctx : @& Context)
    (names : @& Array String)
    (constructorGroups : @& Array (Array Constructor))
    : Env (Array Srt)

/-! ## Sort inspection (extended) -/

/-- Get the domain sort of an array sort. -/
@[extern "lean_z3_Srt_getArraySortDomain"]
opaque Srt.getArraySortDomain (ctx : @& Context) (s : @& Srt) : Srt

/-- Get the domain sort at index `idx` for a multi-dimensional array sort. -/
@[extern "lean_z3_Srt_getArraySortDomainN"]
opaque Srt.getArraySortDomainN (ctx : @& Context) (s : @& Srt) (idx : UInt32) : Srt

/-- Get the range sort of an array sort. -/
@[extern "lean_z3_Srt_getArraySortRange"]
opaque Srt.getArraySortRange (ctx : @& Context) (s : @& Srt) : Srt

/-- Get the number of constructors of a datatype sort. -/
@[extern "lean_z3_Srt_getDatatypeSortNumConstructors"]
opaque Srt.getDatatypeSortNumConstructors (ctx : @& Context) (s : @& Srt) : UInt32

/-- Get the constructor at index `idx` of a datatype sort. -/
@[extern "lean_z3_Srt_getDatatypeSortConstructor"]
opaque Srt.getDatatypeSortConstructor (ctx : @& Context) (s : @& Srt) (idx : UInt32) : FuncDecl

/-- Get the recognizer (tester) at index `idx` of a datatype sort. -/
@[extern "lean_z3_Srt_getDatatypeSortRecognizer"]
opaque Srt.getDatatypeSortRecognizer (ctx : @& Context) (s : @& Srt) (idx : UInt32) : FuncDecl

/-- Get the accessor at constructor index `idxC`, accessor index `idxA` of a datatype sort. -/
@[extern "lean_z3_Srt_getDatatypeSortConstructorAccessor"]
opaque Srt.getDatatypeSortConstructorAccessor (ctx : @& Context) (s : @& Srt)
    (idxC idxA : UInt32) : FuncDecl

/-! ## Sets -/

/-- Create a set sort over element sort `ty`. -/
@[extern "lean_z3_Srt_mkSet"]
opaque Srt.mkSet (ctx : @& Context) (ty : @& Srt) : Srt

/-- Create an empty set of the given `domain` sort. -/
@[extern "lean_z3_Ast_mkEmptySet"]
opaque Ast.mkEmptySet (ctx : @& Context) (domain : @& Srt) : Ast

/-- Create a full (universal) set of the given `domain` sort. -/
@[extern "lean_z3_Ast_mkFullSet"]
opaque Ast.mkFullSet (ctx : @& Context) (domain : @& Srt) : Ast

/-- Add an element to a set. -/
@[extern "lean_z3_Ast_mkSetAdd"]
opaque Ast.mkSetAdd (ctx : @& Context) (set elem : @& Ast) : Ast

/-- Remove an element from a set. -/
@[extern "lean_z3_Ast_mkSetDel"]
opaque Ast.mkSetDel (ctx : @& Context) (set elem : @& Ast) : Ast

/-- Union of sets. -/
@[extern "lean_z3_Ast_mkSetUnion"]
opaque Ast.mkSetUnion (ctx : @& Context) (args : @& Array Ast) : Ast

/-- Intersection of sets. -/
@[extern "lean_z3_Ast_mkSetIntersect"]
opaque Ast.mkSetIntersect (ctx : @& Context) (args : @& Array Ast) : Ast

/-- Set difference. -/
@[extern "lean_z3_Ast_mkSetDifference"]
opaque Ast.mkSetDifference (ctx : @& Context) (a b : @& Ast) : Ast

/-- Set complement. -/
@[extern "lean_z3_Ast_mkSetComplement"]
opaque Ast.mkSetComplement (ctx : @& Context) (a : @& Ast) : Ast

/-- Set membership test. -/
@[extern "lean_z3_Ast_mkSetMember"]
opaque Ast.mkSetMember (ctx : @& Context) (elem set : @& Ast) : Ast

/-- Subset test. -/
@[extern "lean_z3_Ast_mkSetSubset"]
opaque Ast.mkSetSubset (ctx : @& Context) (a b : @& Ast) : Ast

/-! ## String / Sequence theory -/

/-- Create the string sort. -/
@[extern "lean_z3_Srt_mkString"]
opaque Srt.mkString (ctx : @& Context) : Srt

/-- Create a sequence sort over element sort `s`. -/
@[extern "lean_z3_Srt_mkSeq"]
opaque Srt.mkSeq (ctx : @& Context) (s : @& Srt) : Srt

/-- Create a regular expression sort over sequence sort `seq`. -/
@[extern "lean_z3_Srt_mkRe"]
opaque Srt.mkRe (ctx : @& Context) (seq : @& Srt) : Srt

/-- Create a string literal. -/
@[extern "lean_z3_Ast_mkString"]
opaque Ast.mkString (ctx : @& Context) (s : @& String) : Ast

/-- Get the string value of a string literal AST. -/
@[extern "lean_z3_Ast_getString"]
opaque Ast.getString (ctx : @& Context) (a : @& Ast) : String

/-- Concatenate sequences (or strings). -/
@[extern "lean_z3_Ast_mkSeqConcat"]
opaque Ast.mkSeqConcat (ctx : @& Context) (args : @& Array Ast) : Ast

/-- Get the length of a sequence (or string). -/
@[extern "lean_z3_Ast_mkSeqLength"]
opaque Ast.mkSeqLength (ctx : @& Context) (s : @& Ast) : Ast

/-- Check if `container` contains `containee`. -/
@[extern "lean_z3_Ast_mkSeqContains"]
opaque Ast.mkSeqContains (ctx : @& Context) (container containee : @& Ast) : Ast

/-- Check if `s` starts with `prefix`. -/
@[extern "lean_z3_Ast_mkSeqPrefix"]
opaque Ast.mkSeqPrefix (ctx : @& Context) (pfx s : @& Ast) : Ast

/-- Check if `s` ends with `suffix`. -/
@[extern "lean_z3_Ast_mkSeqSuffix"]
opaque Ast.mkSeqSuffix (ctx : @& Context) (sfx s : @& Ast) : Ast

/-- Extract substring of `s` starting at `offset` with given `length`. -/
@[extern "lean_z3_Ast_mkSeqExtract"]
opaque Ast.mkSeqExtract (ctx : @& Context) (s offset length : @& Ast) : Ast

/-- Get the element at `index` in sequence `s` (unit sequence). -/
@[extern "lean_z3_Ast_mkSeqAt"]
opaque Ast.mkSeqAt (ctx : @& Context) (s index : @& Ast) : Ast

/-- Find first index of `substr` in `s` starting from `offset`. Returns -1 if not found. -/
@[extern "lean_z3_Ast_mkSeqIndex"]
opaque Ast.mkSeqIndex (ctx : @& Context) (s substr offset : @& Ast) : Ast

/-- Convert string to integer. -/
@[extern "lean_z3_Ast_mkStrToInt"]
opaque Ast.mkStrToInt (ctx : @& Context) (s : @& Ast) : Ast

/-- Convert integer to string. -/
@[extern "lean_z3_Ast_mkIntToStr"]
opaque Ast.mkIntToStr (ctx : @& Context) (s : @& Ast) : Ast

/-- Convert a sequence to a regular expression (singleton). -/
@[extern "lean_z3_Ast_mkSeqToRe"]
opaque Ast.mkSeqToRe (ctx : @& Context) (seq : @& Ast) : Ast

/-- Check membership of a sequence in a regular expression. -/
@[extern "lean_z3_Ast_mkSeqInRe"]
opaque Ast.mkSeqInRe (ctx : @& Context) (seq re : @& Ast) : Ast

/-- Kleene star of a regular expression. -/
@[extern "lean_z3_Ast_mkReStar"]
opaque Ast.mkReStar (ctx : @& Context) (re : @& Ast) : Ast

/-- Kleene plus of a regular expression. -/
@[extern "lean_z3_Ast_mkRePlus"]
opaque Ast.mkRePlus (ctx : @& Context) (re : @& Ast) : Ast

/-- Optional (zero or one) of a regular expression. -/
@[extern "lean_z3_Ast_mkReOption"]
opaque Ast.mkReOption (ctx : @& Context) (re : @& Ast) : Ast

/-- Union of regular expressions. -/
@[extern "lean_z3_Ast_mkReUnion"]
opaque Ast.mkReUnion (ctx : @& Context) (args : @& Array Ast) : Ast

/-- Concatenation of regular expressions. -/
@[extern "lean_z3_Ast_mkReConcat"]
opaque Ast.mkReConcat (ctx : @& Context) (args : @& Array Ast) : Ast

/-- Character range [lo, hi]. -/
@[extern "lean_z3_Ast_mkReRange"]
opaque Ast.mkReRange (ctx : @& Context) (lo hi : @& Ast) : Ast

/-- Complement of a regular expression. -/
@[extern "lean_z3_Ast_mkReComplement"]
opaque Ast.mkReComplement (ctx : @& Context) (re : @& Ast) : Ast

/-- Intersection of regular expressions. -/
@[extern "lean_z3_Ast_mkReIntersect"]
opaque Ast.mkReIntersect (ctx : @& Context) (args : @& Array Ast) : Ast

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

/-- Create a quantifier with patterns, no-patterns, quantifier id, and skolem id.
  `isForall` — `true` for ∀, `false` for ∃.
  `patterns` — trigger patterns (created via `mkPattern`).
  `noPatterns` — terms to exclude from pattern inference.
  `quantifierId` / `skolemId` — identifiers for the quantifier. -/
@[extern "lean_z3_Ast_mkQuantifierEx"]
opaque Ast.mkQuantifierEx (ctx : @& Context) (isForall : Bool) (weight : UInt32)
    (quantifierId : @& String) (skolemId : @& String)
    (patterns : @& Array Ast) (noPatterns : @& Array Ast)
    (sorts : @& Array Srt) (names : @& Array String)
    (body : @& Ast) : Env Ast

/-- Create a universal quantifier over constants (no de Bruijn indices needed).
  `bound` — array of constants to quantify over.
  `patterns` — trigger patterns (can be empty). -/
@[extern "lean_z3_Ast_mkForallConst"]
opaque Ast.mkForallConst (ctx : @& Context) (weight : UInt32)
    (bound : @& Array Ast) (patterns : @& Array Ast)
    (body : @& Ast) : Env Ast

/-- Create an existential quantifier over constants (no de Bruijn indices needed).
  `bound` — array of constants to quantify over.
  `patterns` — trigger patterns (can be empty). -/
@[extern "lean_z3_Ast_mkExistsConst"]
opaque Ast.mkExistsConst (ctx : @& Context) (weight : UInt32)
    (bound : @& Array Ast) (patterns : @& Array Ast)
    (body : @& Ast) : Env Ast

/-- Create a lambda expression.
  `sorts` and `names` specify the bound variables (like `mkForall`).
  `body` is the lambda body (using `mkBound` for bound variable references). -/
@[extern "lean_z3_Ast_mkLambda"]
opaque Ast.mkLambda (ctx : @& Context) (sorts : @& Array Srt)
    (names : @& Array String) (body : @& Ast) : Env Ast

/-- Create a lambda expression over constants (no de Bruijn indices needed).
  `bound` — array of constants to bind. -/
@[extern "lean_z3_Ast_mkLambdaConst"]
opaque Ast.mkLambdaConst (ctx : @& Context) (bound : @& Array Ast)
    (body : @& Ast) : Env Ast

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

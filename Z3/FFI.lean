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

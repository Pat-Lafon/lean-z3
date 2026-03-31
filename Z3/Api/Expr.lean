import Z3.Api.Monad

namespace Z3.Api

/-! ### Constants and numerals -/

def boolVal (b : Bool) : Z3M Ast := return Ast.mkBool (← getCtx) b
def numeral (val : String) (sort : Srt) : Z3M Ast := return Ast.mkNumeral (← getCtx) val sort
def intConst (name : String) : Z3M Ast := return Ast.mkIntConst (← getCtx) name
def boolConst (name : String) : Z3M Ast := return Ast.mkBoolConst (← getCtx) name
def const (name : String) (sort : Srt) : Z3M Ast := return Ast.mkConst (← getCtx) name sort
def bvConst (name : String) (size : UInt32) : Z3M Ast := return Ast.mkBvConst (← getCtx) name size
def mkInt (v : Int32) (sort : Srt) : Z3M Ast := return Ast.mkInt (← getCtx) v sort
def mkReal (num den : Int32) : Z3M Ast := return Ast.mkReal (← getCtx) num den
def mkInt64 (v : Int64) (sort : Srt) : Z3M Ast := return Ast.mkInt64 (← getCtx) v sort
def mkUInt64 (v : UInt64) (sort : Srt) : Z3M Ast := return Ast.mkUInt64 (← getCtx) v sort
def mkRealVal (num den : Int64) : Z3M Ast := return Ast.mkRealVal (← getCtx) num den
def freshConst (pfx : String) (sort : Srt) : Z3M Ast := do Ast.mkFreshConst (← getCtx) pfx sort

/-- Create an integer literal (convenience: creates sort automatically). -/
def intVal (n : Int) : Z3M Ast := do
  let ctx ← getCtx
  return Ast.mkNumeral ctx (toString n) (Srt.mkInt ctx)

/-- Create a real literal from a string like "1/3" or "3.14". -/
def realVal (s : String) : Z3M Ast := do
  let ctx ← getCtx
  return Ast.mkNumeral ctx s (Srt.mkReal ctx)

/-- Create a bitvector literal. -/
def bvVal (v : Nat) (size : UInt32) : Z3M Ast := do
  let ctx ← getCtx
  return Ast.mkNumeral ctx (toString v) (Srt.mkBv ctx size)

/-! ### Boolean operations -/

def not (a : Ast) : Z3M Ast := return Ast.not (← getCtx) a
def and (a b : Ast) : Z3M Ast := return Ast.and (← getCtx) a b
def or (a b : Ast) : Z3M Ast := return Ast.or (← getCtx) a b
def implies (a b : Ast) : Z3M Ast := return Ast.implies (← getCtx) a b
def eq (a b : Ast) : Z3M Ast := return Ast.eq (← getCtx) a b
def ite (cond t e : Ast) : Z3M Ast := return Ast.ite (← getCtx) cond t e
def xor (a b : Ast) : Z3M Ast := return Ast.xor (← getCtx) a b
def iff (a b : Ast) : Z3M Ast := return Ast.iff (← getCtx) a b
def distinct (args : Array Ast) : Z3M Ast := return Ast.distinct (← getCtx) args

/-! ### Arithmetic -/

def add (a b : Ast) : Z3M Ast := return Ast.add (← getCtx) a b
def sub (a b : Ast) : Z3M Ast := return Ast.sub (← getCtx) a b
def mul (a b : Ast) : Z3M Ast := return Ast.mul (← getCtx) a b
def div (a b : Ast) : Z3M Ast := return Ast.div (← getCtx) a b
def mod (a b : Ast) : Z3M Ast := return Ast.mod (← getCtx) a b
def rem (a b : Ast) : Z3M Ast := return Ast.rem (← getCtx) a b
def lt (a b : Ast) : Z3M Ast := return Ast.lt (← getCtx) a b
def le (a b : Ast) : Z3M Ast := return Ast.le (← getCtx) a b
def gt (a b : Ast) : Z3M Ast := return Ast.gt (← getCtx) a b
def ge (a b : Ast) : Z3M Ast := return Ast.ge (← getCtx) a b
def power (a b : Ast) : Z3M Ast := return Ast.power (← getCtx) a b
def abs (a : Ast) : Z3M Ast := return Ast.abs (← getCtx) a
def neg (a : Ast) : Z3M Ast := return Ast.unaryMinus (← getCtx) a
def int2real (a : Ast) : Z3M Ast := return Ast.int2real (← getCtx) a
def real2int (a : Ast) : Z3M Ast := return Ast.real2int (← getCtx) a
def isInt (a : Ast) : Z3M Ast := return Ast.isInt (← getCtx) a

/-! ### Bitvector operations -/

def bvneg (a : Ast) : Z3M Ast := return Ast.bvneg (← getCtx) a
def bvadd (a b : Ast) : Z3M Ast := return Ast.bvadd (← getCtx) a b
def bvsub (a b : Ast) : Z3M Ast := return Ast.bvsub (← getCtx) a b
def bvmul (a b : Ast) : Z3M Ast := return Ast.bvmul (← getCtx) a b
def bvudiv (a b : Ast) : Z3M Ast := return Ast.bvudiv (← getCtx) a b
def bvsdiv (a b : Ast) : Z3M Ast := return Ast.bvsdiv (← getCtx) a b
def bvurem (a b : Ast) : Z3M Ast := return Ast.bvurem (← getCtx) a b
def bvsrem (a b : Ast) : Z3M Ast := return Ast.bvsrem (← getCtx) a b
def bvnot (a : Ast) : Z3M Ast := return Ast.bvnot (← getCtx) a
def bvand (a b : Ast) : Z3M Ast := return Ast.bvand (← getCtx) a b
def bvor (a b : Ast) : Z3M Ast := return Ast.bvor (← getCtx) a b
def bvxor (a b : Ast) : Z3M Ast := return Ast.bvxor (← getCtx) a b
def bvshl (a b : Ast) : Z3M Ast := return Ast.bvshl (← getCtx) a b
def bvlshr (a b : Ast) : Z3M Ast := return Ast.bvlshr (← getCtx) a b
def bvashr (a b : Ast) : Z3M Ast := return Ast.bvashr (← getCtx) a b
def rotateLeft (a : Ast) (n : UInt32) : Z3M Ast := return Ast.rotateLeft (← getCtx) a n
def rotateRight (a : Ast) (n : UInt32) : Z3M Ast := return Ast.rotateRight (← getCtx) a n
def bvult (a b : Ast) : Z3M Ast := return Ast.bvult (← getCtx) a b
def bvule (a b : Ast) : Z3M Ast := return Ast.bvule (← getCtx) a b
def bvugt (a b : Ast) : Z3M Ast := return Ast.bvugt (← getCtx) a b
def bvuge (a b : Ast) : Z3M Ast := return Ast.bvuge (← getCtx) a b
def bvslt (a b : Ast) : Z3M Ast := return Ast.bvslt (← getCtx) a b
def bvsle (a b : Ast) : Z3M Ast := return Ast.bvsle (← getCtx) a b
def bvsgt (a b : Ast) : Z3M Ast := return Ast.bvsgt (← getCtx) a b
def bvsge (a b : Ast) : Z3M Ast := return Ast.bvsge (← getCtx) a b
def bvextract (high low : UInt32) (a : Ast) : Z3M Ast := return Ast.bvextract (← getCtx) high low a
def bvconcat (a b : Ast) : Z3M Ast := return Ast.bvconcat (← getCtx) a b
def bvzeroExt (n : UInt32) (a : Ast) : Z3M Ast := return Ast.bvzeroExt (← getCtx) n a
def bvsignExt (n : UInt32) (a : Ast) : Z3M Ast := return Ast.bvsignExt (← getCtx) n a
def bv2int (a : Ast) (isSigned : Bool) : Z3M Ast := return Ast.bv2int (← getCtx) a isSigned
def int2bv (n : UInt32) (a : Ast) : Z3M Ast := return Ast.int2bv (← getCtx) n a
def bvnand (a b : Ast) : Z3M Ast := return Ast.bvnand (← getCtx) a b
def bvnor (a b : Ast) : Z3M Ast := return Ast.bvnor (← getCtx) a b
def bvxnor (a b : Ast) : Z3M Ast := return Ast.bvxnor (← getCtx) a b
def bvsmod (a b : Ast) : Z3M Ast := return Ast.bvsmod (← getCtx) a b
def bvredand (a : Ast) : Z3M Ast := return Ast.bvredand (← getCtx) a
def bvredor (a : Ast) : Z3M Ast := return Ast.bvredor (← getCtx) a
def bvrepeat (n : UInt32) (a : Ast) : Z3M Ast := return Ast.bvrepeat (← getCtx) n a

/-! ### Array operations -/

def select (a i : Ast) : Z3M Ast := return Ast.select (← getCtx) a i
def store (a i v : Ast) : Z3M Ast := return Ast.store (← getCtx) a i v
def constArray (domain : Srt) (v : Ast) : Z3M Ast := return Ast.constArray (← getCtx) domain v

/-! ### Quantifiers -/

def mkBound (idx : UInt32) (s : Srt) : Z3M Ast := return Ast.mkBound (← getCtx) idx s

def forall' (sorts : Array Srt) (names : Array String) (body : Ast)
    (weight : UInt32 := 0) : Z3M Ast := do
  liftEnv (Ast.mkForall (← getCtx) sorts names body weight)

def exists' (sorts : Array Srt) (names : Array String) (body : Ast)
    (weight : UInt32 := 0) : Z3M Ast := do
  liftEnv (Ast.mkExists (← getCtx) sorts names body weight)

def forallConst (bound : Array Ast) (body : Ast)
    (patterns : Array Ast := #[]) (weight : UInt32 := 0) : Z3M Ast := do
  liftEnv (Ast.mkForallConst (← getCtx) weight bound patterns body)

def existsConst (bound : Array Ast) (body : Ast)
    (patterns : Array Ast := #[]) (weight : UInt32 := 0) : Z3M Ast := do
  liftEnv (Ast.mkExistsConst (← getCtx) weight bound patterns body)

def lambda (sorts : Array Srt) (names : Array String) (body : Ast) : Z3M Ast := do
  liftEnv (Ast.mkLambda (← getCtx) sorts names body)

def lambdaConst (bound : Array Ast) (body : Ast) : Z3M Ast := do
  liftEnv (Ast.mkLambdaConst (← getCtx) bound body)

/-! ### Uninterpreted functions -/

def funcDecl (name : String) (domain : Array Srt) (range : Srt) : Z3M FuncDecl := do
  return FuncDecl.mk (← getCtx) name domain range

def freshFuncDecl (pfx : String) (domain : Array Srt) (range : Srt) : Z3M FuncDecl := do
  FuncDecl.mkFresh (← getCtx) pfx domain range

def app (fd : FuncDecl) (args : Array Ast) : Z3M Ast := do
  return Ast.mkApp (← getCtx) fd args

/-! ### Simplification and substitution -/

def simplify (a : Ast) : Z3M Ast := return Ast.simplify (← getCtx) a
def simplifyEx (a : Ast) (p : Params) : Z3M Ast := return Ast.simplifyEx (← getCtx) a p

def substitute (a : Ast) (from_ to : Array Ast) : Z3M Ast := do
  liftEnv (Ast.substitute (← getCtx) a from_ to)

def substituteVars (a : Ast) (to : Array Ast) : Z3M Ast := do
  liftEnv (Ast.substituteVars (← getCtx) a to)

/-! ### String / Sequence operations -/

def mkString (s : String) : Z3M Ast := return Ast.mkString (← getCtx) s
def seqConcat (args : Array Ast) : Z3M Ast := return Ast.mkSeqConcat (← getCtx) args
def seqLength (s : Ast) : Z3M Ast := return Ast.mkSeqLength (← getCtx) s
def seqContains (container containee : Ast) : Z3M Ast :=
  return Ast.mkSeqContains (← getCtx) container containee
def seqPrefix (pfx s : Ast) : Z3M Ast := return Ast.mkSeqPrefix (← getCtx) pfx s
def seqSuffix (sfx s : Ast) : Z3M Ast := return Ast.mkSeqSuffix (← getCtx) sfx s
def seqExtract (s offset length : Ast) : Z3M Ast :=
  return Ast.mkSeqExtract (← getCtx) s offset length
def seqAt (s index : Ast) : Z3M Ast := return Ast.mkSeqAt (← getCtx) s index
def seqIndex (s substr offset : Ast) : Z3M Ast :=
  return Ast.mkSeqIndex (← getCtx) s substr offset
def strToInt (s : Ast) : Z3M Ast := return Ast.mkStrToInt (← getCtx) s
def intToStr (s : Ast) : Z3M Ast := return Ast.mkIntToStr (← getCtx) s
def seqToRe (seq : Ast) : Z3M Ast := return Ast.mkSeqToRe (← getCtx) seq
def seqInRe (seq re : Ast) : Z3M Ast := return Ast.mkSeqInRe (← getCtx) seq re
def reStar (re : Ast) : Z3M Ast := return Ast.mkReStar (← getCtx) re
def rePlus (re : Ast) : Z3M Ast := return Ast.mkRePlus (← getCtx) re
def reOption (re : Ast) : Z3M Ast := return Ast.mkReOption (← getCtx) re
def reUnion (args : Array Ast) : Z3M Ast := return Ast.mkReUnion (← getCtx) args
def reConcat (args : Array Ast) : Z3M Ast := return Ast.mkReConcat (← getCtx) args
def reRange (lo hi : Ast) : Z3M Ast := return Ast.mkReRange (← getCtx) lo hi
def reComplement (re : Ast) : Z3M Ast := return Ast.mkReComplement (← getCtx) re
def reIntersect (args : Array Ast) : Z3M Ast := return Ast.mkReIntersect (← getCtx) args

/-! ### Set operations -/

def emptySet (domain : Srt) : Z3M Ast := return Ast.mkEmptySet (← getCtx) domain
def fullSet (domain : Srt) : Z3M Ast := return Ast.mkFullSet (← getCtx) domain
def setAdd (set elem : Ast) : Z3M Ast := return Ast.mkSetAdd (← getCtx) set elem
def setDel (set elem : Ast) : Z3M Ast := return Ast.mkSetDel (← getCtx) set elem
def setUnion (args : Array Ast) : Z3M Ast := return Ast.mkSetUnion (← getCtx) args
def setIntersect (args : Array Ast) : Z3M Ast := return Ast.mkSetIntersect (← getCtx) args
def setDifference (a b : Ast) : Z3M Ast := return Ast.mkSetDifference (← getCtx) a b
def setComplement (a : Ast) : Z3M Ast := return Ast.mkSetComplement (← getCtx) a
def setMember (elem set : Ast) : Z3M Ast := return Ast.mkSetMember (← getCtx) elem set
def setSubset (a b : Ast) : Z3M Ast := return Ast.mkSetSubset (← getCtx) a b

end Z3.Api

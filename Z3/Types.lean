/-
Copyright (c) 2025 lean-z3 contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/

namespace Z3

/-- Three-valued Boolean used for satisfiability results. -/
inductive LBool where
  | false
  | undef
  | true
deriving Inhabited, Repr, BEq, DecidableEq

instance : ToString LBool where
  toString
    | .false => "false"
    | .undef => "undef"
    | .true => "true"

/-- Sort kinds in Z3. -/
inductive SortKind where
  | uninterpreted
  | bool
  | int
  | real
  | bv
  | array
  | datatype
  | relation
  | finiteDomain
  | floatingPoint
  | roundingMode
  | seq
  | re
  | char
  | typeVar
  | unknown
deriving Inhabited, Repr, BEq, DecidableEq

/-- Convert a raw `UInt32` Z3_sort_kind to `SortKind`. -/
def SortKind.ofRaw : UInt32 → SortKind
  | 0  => .uninterpreted | 1  => .bool   | 2  => .int     | 3  => .real
  | 4  => .bv            | 5  => .array  | 6  => .datatype| 7  => .relation
  | 8  => .finiteDomain  | 9  => .floatingPoint | 10 => .roundingMode
  | 11 => .seq           | 12 => .re     | 13 => .char    | 14 => .typeVar
  | 1000 => .unknown
  | _  => .unknown

/-- Convert `SortKind` back to a raw `UInt32`. -/
def SortKind.toRaw : SortKind → UInt32
  | .uninterpreted => 0  | .bool   => 1  | .int     => 2  | .real     => 3
  | .bv            => 4  | .array  => 5  | .datatype=> 6  | .relation => 7
  | .finiteDomain  => 8  | .floatingPoint => 9 | .roundingMode => 10
  | .seq           => 11 | .re     => 12 | .char    => 13 | .typeVar  => 14
  | .unknown       => 1000

instance : ToString SortKind where
  toString
    | .uninterpreted => "Uninterpreted"
    | .bool => "Bool"
    | .int => "Int"
    | .real => "Real"
    | .bv => "BitVec"
    | .array => "Array"
    | .datatype => "Datatype"
    | .relation => "Relation"
    | .finiteDomain => "FiniteDomain"
    | .floatingPoint => "FloatingPoint"
    | .roundingMode => "RoundingMode"
    | .seq => "Seq"
    | .re => "Re"
    | .char => "Char"
    | .typeVar => "TypeVar"
    | .unknown => "Unknown"

/-- AST kinds in Z3. -/
inductive AstKind where
  | numeral
  | app
  | var
  | quantifier
  | sort
  | funcDecl
  | unknown
deriving Inhabited, Repr, BEq, DecidableEq

/-- Convert a raw `UInt32` Z3_ast_kind to `AstKind`. -/
def AstKind.ofRaw : UInt32 → AstKind
  | 0 => .numeral
  | 1 => .app
  | 2 => .var
  | 3 => .quantifier
  | 4 => .sort
  | 5 => .funcDecl
  | _ => .unknown

instance : ToString AstKind where
  toString
    | .numeral    => "Numeral"
    | .app        => "App"
    | .var        => "Var"
    | .quantifier => "Quantifier"
    | .sort       => "Sort"
    | .funcDecl   => "FuncDecl"
    | .unknown    => "Unknown"

/-- Z3 declaration kinds (`Z3_decl_kind`). Identifies the kind of function in a Z3 application node. -/
inductive DeclKind where
  | true_
  | false_
  | eq
  | distinct
  | ite
  | and
  | or
  | iff
  | xor
  | not
  | implies
  | anum
  | agnum
  | le
  | ge
  | lt
  | gt
  | add
  | sub
  | uminus
  | mul
  | div
  | idiv
  | rem
  | mod
  | toReal
  | toInt
  | isInt
  | power
  | store
  | select
  | constArray
  | map
  | arrayDefault
  | asArray
  | setUnion
  | setIntersect
  | setDifference
  | setComplement
  | setSubset
  | bnum
  | bneg
  | badd
  | bsub
  | bmul
  | bsdiv
  | budiv
  | bsrem
  | burem
  | bsmod
  | bnot
  | band
  | bor
  | bxor
  | bnand
  | bnor
  | bxnor
  | bconcat
  | bsignExt
  | bzeroExt
  | bextract
  | brepeat
  | bredand
  | bredor
  | bshl
  | blshr
  | bashr
  | brotateLeft
  | brotateRight
  | bule
  | bsle
  | buge
  | bsge
  | bult
  | bslt
  | bugt
  | bsgt
  | bv2int
  | int2bv
  | uninterpreted
  | other (raw : UInt32)
deriving Inhabited, Repr, BEq

/-- Convert a raw `UInt32` Z3_decl_kind to `DeclKind`. -/
def DeclKind.ofRaw : UInt32 → DeclKind
  | 0x100 => .true_    | 0x101 => .false_  | 0x102 => .eq       | 0x103 => .distinct
  | 0x104 => .ite      | 0x105 => .and     | 0x106 => .or       | 0x107 => .iff
  | 0x108 => .xor      | 0x109 => .not     | 0x10a => .implies
  | 0x200 => .anum     | 0x201 => .agnum
  | 0x202 => .le       | 0x203 => .ge      | 0x204 => .lt       | 0x205 => .gt
  | 0x206 => .add      | 0x207 => .sub     | 0x208 => .uminus   | 0x209 => .mul
  | 0x20a => .div      | 0x20b => .idiv    | 0x20c => .rem      | 0x20d => .mod
  | 0x20e => .toReal   | 0x20f => .toInt   | 0x210 => .isInt    | 0x211 => .power
  | 0x300 => .store    | 0x301 => .select  | 0x302 => .constArray
  | 0x303 => .map      | 0x304 => .arrayDefault
  | 0x305 => .setUnion | 0x306 => .setIntersect | 0x307 => .setDifference
  | 0x308 => .setComplement | 0x309 => .setSubset | 0x30a => .asArray
  | 0x400 => .bnum     | 0x403 => .bneg    | 0x404 => .badd     | 0x405 => .bsub
  | 0x406 => .bmul     | 0x407 => .bsdiv   | 0x408 => .budiv    | 0x409 => .bsrem
  | 0x40a => .burem    | 0x40b => .bsmod
  | 0x411 => .bule     | 0x412 => .bsle    | 0x413 => .buge     | 0x414 => .bsge
  | 0x415 => .bult     | 0x416 => .bslt    | 0x417 => .bugt     | 0x418 => .bsgt
  | 0x419 => .band     | 0x41a => .bor     | 0x41b => .bnot     | 0x41c => .bxor
  | 0x41d => .bnand    | 0x41e => .bnor    | 0x41f => .bxnor
  | 0x420 => .bconcat  | 0x421 => .bsignExt | 0x422 => .bzeroExt
  | 0x423 => .bextract | 0x424 => .brepeat | 0x425 => .bredor   | 0x426 => .bredand
  | 0x428 => .bshl     | 0x429 => .blshr   | 0x42a => .bashr
  | 0x42b => .brotateLeft | 0x42c => .brotateRight
  | 0x430 => .int2bv   | 0x431 => .bv2int
  | 0xb02e => .uninterpreted
  | r     => .other r

/-- Convert `DeclKind` back to a raw `UInt32`. -/
def DeclKind.toRaw : DeclKind → UInt32
  | .true_  => 0x100 | .false_ => 0x101 | .eq      => 0x102 | .distinct => 0x103
  | .ite    => 0x104 | .and    => 0x105 | .or      => 0x106 | .iff      => 0x107
  | .xor    => 0x108 | .not    => 0x109 | .implies => 0x10a
  | .anum   => 0x200 | .agnum  => 0x201
  | .le     => 0x202 | .ge     => 0x203 | .lt      => 0x204 | .gt       => 0x205
  | .add    => 0x206 | .sub    => 0x207 | .uminus  => 0x208 | .mul      => 0x209
  | .div    => 0x20a | .idiv   => 0x20b | .rem     => 0x20c | .mod      => 0x20d
  | .toReal => 0x20e | .toInt  => 0x20f | .isInt   => 0x210 | .power    => 0x211
  | .store  => 0x300 | .select => 0x301 | .constArray => 0x302
  | .map    => 0x303 | .arrayDefault => 0x304
  | .setUnion => 0x305 | .setIntersect => 0x306 | .setDifference => 0x307
  | .setComplement => 0x308 | .setSubset => 0x309 | .asArray => 0x30a
  | .bnum   => 0x400 | .bneg   => 0x403 | .badd    => 0x404 | .bsub     => 0x405
  | .bmul   => 0x406 | .bsdiv  => 0x407 | .budiv   => 0x408 | .bsrem    => 0x409
  | .burem  => 0x40a | .bsmod  => 0x40b
  | .bule   => 0x411 | .bsle   => 0x412 | .buge    => 0x413 | .bsge     => 0x414
  | .bult   => 0x415 | .bslt   => 0x416 | .bugt    => 0x417 | .bsgt     => 0x418
  | .band   => 0x419 | .bor    => 0x41a | .bnot    => 0x41b | .bxor     => 0x41c
  | .bnand  => 0x41d | .bnor   => 0x41e | .bxnor   => 0x41f
  | .bconcat => 0x420 | .bsignExt => 0x421 | .bzeroExt => 0x422
  | .bextract => 0x423 | .brepeat => 0x424 | .bredor => 0x425 | .bredand => 0x426
  | .bshl   => 0x428 | .blshr  => 0x429 | .bashr   => 0x42a
  | .brotateLeft => 0x42b | .brotateRight => 0x42c
  | .int2bv => 0x430 | .bv2int => 0x431
  | .uninterpreted => 0xb02e
  | .other r => r

instance : ToString DeclKind where
  toString
    | .true_    => "True"     | .false_   => "False"     | .eq       => "Eq"
    | .distinct => "Distinct" | .ite      => "ITE"       | .and      => "And"
    | .or       => "Or"       | .iff      => "Iff"       | .xor      => "Xor"
    | .not      => "Not"      | .implies  => "Implies"
    | .anum     => "ANum"     | .agnum    => "AGNum"
    | .le       => "LE"       | .ge       => "GE"        | .lt       => "LT"
    | .gt       => "GT"       | .add      => "Add"       | .sub      => "Sub"
    | .uminus   => "UMinus"   | .mul      => "Mul"       | .div      => "Div"
    | .idiv     => "IDiv"     | .rem      => "Rem"       | .mod      => "Mod"
    | .toReal   => "ToReal"   | .toInt    => "ToInt"     | .isInt    => "IsInt"
    | .power    => "Power"
    | .store    => "Store"    | .select   => "Select"    | .constArray => "ConstArray"
    | .map      => "Map"      | .arrayDefault => "ArrayDefault" | .asArray => "AsArray"
    | .setUnion => "SetUnion" | .setIntersect => "SetIntersect"
    | .setDifference => "SetDifference"
    | .setComplement => "SetComplement" | .setSubset => "SetSubset"
    | .bnum     => "BNum"     | .bneg     => "BNeg"      | .badd     => "BAdd"
    | .bsub     => "BSub"     | .bmul     => "BMul"      | .bsdiv    => "BSDiv"
    | .budiv    => "BUDiv"    | .bsrem    => "BSRem"     | .burem    => "BURem"
    | .bsmod    => "BSMod"
    | .bnot     => "BNot"     | .band     => "BAnd"      | .bor      => "BOr"
    | .bxor     => "BXor"     | .bnand    => "BNand"     | .bnor     => "BNor"
    | .bxnor    => "BXnor"
    | .bconcat  => "BConcat"  | .bsignExt => "BSignExt"  | .bzeroExt => "BZeroExt"
    | .bextract => "BExtract" | .brepeat  => "BRepeat"   | .bredand  => "BRedAnd"
    | .bredor   => "BRedOr"
    | .bshl     => "BShl"     | .blshr    => "BLshr"     | .bashr    => "BAshr"
    | .brotateLeft => "BRotateLeft" | .brotateRight => "BRotateRight"
    | .bule     => "BUle"     | .bsle     => "BSle"      | .buge     => "BUge"
    | .bsge     => "BSge"     | .bult     => "BUlt"      | .bslt     => "BSlt"
    | .bugt     => "BUgt"     | .bsgt     => "BSgt"
    | .bv2int   => "BV2Int"   | .int2bv   => "Int2BV"
    | .uninterpreted => "Uninterpreted"
    | .other r  => s!"Other({r})"

/-- All known DeclKind variants (excluding `other`), in declaration order.
    Must match the index order used by `DeclKind.expectedRaw` in C. -/
def DeclKind.allKnown : Array DeclKind :=
  #[ .true_, .false_, .eq, .distinct, .ite
   , .and, .or, .iff, .xor, .not, .implies
   , .anum, .agnum
   , .le, .ge, .lt, .gt, .add, .sub, .uminus, .mul
   , .div, .idiv, .rem, .mod, .toReal, .toInt, .isInt, .power
   , .store, .select, .constArray
   , .map, .arrayDefault
   , .setUnion, .setIntersect, .setDifference, .setComplement, .setSubset, .asArray
   , .bnum, .bneg, .badd, .bsub, .bmul
   , .bsdiv, .budiv, .bsrem, .burem, .bsmod
   , .bnot, .band, .bor, .bxor, .bnand, .bnor, .bxnor
   , .bconcat, .bsignExt, .bzeroExt, .bextract, .brepeat, .bredand, .bredor
   , .bshl, .blshr, .bashr, .brotateLeft, .brotateRight
   , .bule, .bsle, .buge, .bsge, .bult, .bslt, .bugt, .bsgt
   , .bv2int, .int2bv
   , .uninterpreted
   ]

/-- Z3 proof rules (`Z3_OP_PR_*`). Used to identify proof steps in proof trees. -/
inductive ProofRule where
  | undef
  | «true»
  | asserted
  | goal
  | modusPonens
  | reflexivity
  | symmetry
  | transitivity
  | transitivityStar
  | monotonicity
  | quantIntro
  | bind
  | distributivity
  | andElim
  | notOrElim
  | rewrite
  | rewriteStar
  | pullQuant
  | pushQuant
  | elimUnusedVars
  | der
  | quantInst
  | hypothesis
  | lemma
  | unitResolution
  | iffTrue
  | iffFalse
  | commutativity
  | defAxiom
  | assumptionAdd
  | lemmaAdd
  | redundantDel
  | clauseTrail
  | defIntro
  | applyDef
  | iffOeq
  | nnfPos
  | nnfNeg
  | skolemize
  | modusPonensOeq
  | thLemma
  | hyperResolve
  | unknown
deriving Inhabited, Repr, BEq, DecidableEq

namespace ProofRule

/-- The raw `UInt32` offset for `Z3_OP_PR_UNDEF` (0x500). -/
private def base : UInt32 := 0x500

/-- Convert a raw `Z3_decl_kind` value to `ProofRule`, or `none` if not a proof rule. -/
def ofRaw? (raw : UInt32) : Option ProofRule :=
  if raw < base then none
  else match raw - base with
    | 0  => some .undef
    | 1  => some .true
    | 2  => some .asserted
    | 3  => some .goal
    | 4  => some .modusPonens
    | 5  => some .reflexivity
    | 6  => some .symmetry
    | 7  => some .transitivity
    | 8  => some .transitivityStar
    | 9  => some .monotonicity
    | 10 => some .quantIntro
    | 11 => some .bind
    | 12 => some .distributivity
    | 13 => some .andElim
    | 14 => some .notOrElim
    | 15 => some .rewrite
    | 16 => some .rewriteStar
    | 17 => some .pullQuant
    | 18 => some .pushQuant
    | 19 => some .elimUnusedVars
    | 20 => some .der
    | 21 => some .quantInst
    | 22 => some .hypothesis
    | 23 => some .lemma
    | 24 => some .unitResolution
    | 25 => some .iffTrue
    | 26 => some .iffFalse
    | 27 => some .commutativity
    | 28 => some .defAxiom
    | 29 => some .assumptionAdd
    | 30 => some .lemmaAdd
    | 31 => some .redundantDel
    | 32 => some .clauseTrail
    | 33 => some .defIntro
    | 34 => some .applyDef
    | 35 => some .iffOeq
    | 36 => some .nnfPos
    | 37 => some .nnfNeg
    | 38 => some .skolemize
    | 39 => some .modusPonensOeq
    | 40 => some .thLemma
    | 41 => some .hyperResolve
    | _  => some .unknown

/-- Convert to raw `UInt32` decl kind. -/
def toRaw : ProofRule → UInt32
  | .undef            => base
  | .true             => base + 1
  | .asserted         => base + 2
  | .goal             => base + 3
  | .modusPonens      => base + 4
  | .reflexivity      => base + 5
  | .symmetry         => base + 6
  | .transitivity     => base + 7
  | .transitivityStar => base + 8
  | .monotonicity     => base + 9
  | .quantIntro       => base + 10
  | .bind             => base + 11
  | .distributivity   => base + 12
  | .andElim          => base + 13
  | .notOrElim        => base + 14
  | .rewrite          => base + 15
  | .rewriteStar      => base + 16
  | .pullQuant        => base + 17
  | .pushQuant        => base + 18
  | .elimUnusedVars   => base + 19
  | .der              => base + 20
  | .quantInst        => base + 21
  | .hypothesis       => base + 22
  | .lemma            => base + 23
  | .unitResolution   => base + 24
  | .iffTrue          => base + 25
  | .iffFalse         => base + 26
  | .commutativity    => base + 27
  | .defAxiom         => base + 28
  | .assumptionAdd    => base + 29
  | .lemmaAdd         => base + 30
  | .redundantDel     => base + 31
  | .clauseTrail      => base + 32
  | .defIntro         => base + 33
  | .applyDef         => base + 34
  | .iffOeq           => base + 35
  | .nnfPos           => base + 36
  | .nnfNeg           => base + 37
  | .skolemize        => base + 38
  | .modusPonensOeq   => base + 39
  | .thLemma          => base + 40
  | .hyperResolve     => base + 41
  | .unknown          => base

end ProofRule

instance : ToString ProofRule where
  toString
    | .undef            => "undef"
    | .true             => "true"
    | .asserted         => "asserted"
    | .goal             => "goal"
    | .modusPonens      => "modus_ponens"
    | .reflexivity      => "reflexivity"
    | .symmetry         => "symmetry"
    | .transitivity     => "transitivity"
    | .transitivityStar => "transitivity*"
    | .monotonicity     => "monotonicity"
    | .quantIntro       => "quant_intro"
    | .bind             => "bind"
    | .distributivity   => "distributivity"
    | .andElim          => "and_elim"
    | .notOrElim        => "not_or_elim"
    | .rewrite          => "rewrite"
    | .rewriteStar      => "rewrite*"
    | .pullQuant        => "pull_quant"
    | .pushQuant        => "push_quant"
    | .elimUnusedVars   => "elim_unused_vars"
    | .der              => "der"
    | .quantInst        => "quant_inst"
    | .hypothesis       => "hypothesis"
    | .lemma            => "lemma"
    | .unitResolution   => "unit_resolution"
    | .iffTrue          => "iff_true"
    | .iffFalse         => "iff_false"
    | .commutativity    => "commutativity"
    | .defAxiom         => "def_axiom"
    | .assumptionAdd    => "assumption_add"
    | .lemmaAdd         => "lemma_add"
    | .redundantDel     => "redundant_del"
    | .clauseTrail      => "clause_trail"
    | .defIntro         => "def_intro"
    | .applyDef         => "apply_def"
    | .iffOeq           => "iff_oeq"
    | .nnfPos           => "nnf_pos"
    | .nnfNeg           => "nnf_neg"
    | .skolemize        => "skolemize"
    | .modusPonensOeq   => "modus_ponens_oeq"
    | .thLemma          => "th_lemma"
    | .hyperResolve     => "hyper_resolve"
    | .unknown          => "unknown"

/-- Error type for Z3 operations. -/
inductive Error where
  | error (msg : String)
  | invalidArg (msg : String)
  | parserError (msg : String)
  | exception (msg : String)
deriving Repr

namespace Error

protected def toString : Error → String
  | .error msg => s!"Z3 error: {msg}"
  | .invalidArg msg => s!"Z3 invalid argument: {msg}"
  | .parserError msg => s!"Z3 parser error: {msg}"
  | .exception msg => s!"Z3 exception: {msg}"

instance : ToString Error := ⟨Error.toString⟩

/-- Panics on errors, otherwise yields the `ok` result. -/
def unwrap! [Inhabited α] : Except Error α → α
  | .ok a => a
  | .error e => panic! e.toString

end Error

end Z3

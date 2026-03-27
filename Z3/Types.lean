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
  | unknown
deriving Inhabited, Repr, BEq, DecidableEq

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

import Z3Test.Harness

open Z3

/-! ## DeclKind enum tests — validate enum values against Z3 4.16.0 -/

/-- Helper: get DeclKind of a Z3 expression's top-level function -/
private def getDK (a : Ast) : DeclKind :=
  FuncDecl.getDeclKind (Ast.getFuncDecl a)

/-- Boolean decl kinds: true, false, and, or, not, implies, xor, iff -/
def testDeclKindBool : IO TestResult := runTest "DeclKind bool ops" do
  let ctx ← Env.run Context.new
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  let t := Ast.mkBool ctx true
  let f := Ast.mkBool ctx false
  let cases : List (String × DeclKind × DeclKind) :=
    [ ("true",    getDK t,                      .true_)
    , ("false",   getDK f,                      .false_)
    , ("and",     getDK (Ast.and ctx p q),       .and)
    , ("or",      getDK (Ast.or ctx p q),        .or)
    , ("not",     getDK (Ast.not ctx p),         .not)
    , ("implies", getDK (Ast.implies ctx p q),   .implies)
    , ("xor",     getDK (Ast.xor ctx p q),       .xor)
    , ("iff",     getDK (Ast.iff ctx p q),       .eq)  -- Z3 normalizes iff to eq for booleans
    ]
  for (name, got, expected) in cases do
    if got != expected then
      return check "DeclKind bool ops" false
        s!"expected {expected} for {name}, got {got}"
  return check "DeclKind bool ops" true

/-- Core decl kinds: eq, distinct, ite -/
def testDeclKindCore : IO TestResult := runTest "DeclKind core ops" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let z := Ast.mkIntConst ctx "z"
  let cases : List (String × DeclKind × DeclKind) :=
    [ ("eq",       getDK (Ast.eq ctx x y),            .eq)
    , ("distinct", getDK (Ast.distinct ctx #[x, y, z]), .distinct)
    , ("ite",      getDK (Ast.ite ctx (Ast.mkBool ctx true) x y), .ite)
    ]
  for (name, got, expected) in cases do
    if got != expected then
      return check "DeclKind core ops" false
        s!"expected {expected} for {name}, got {got}"
  return check "DeclKind core ops" true

/-- Arithmetic decl kinds: add, sub, mul, le, ge, lt, gt, uminus, div, mod, rem -/
def testDeclKindArith : IO TestResult := runTest "DeclKind arith ops" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let cases : List (String × DeclKind × DeclKind) :=
    [ ("add",    getDK (Ast.add ctx x y),        .add)
    , ("sub",    getDK (Ast.sub ctx x y),        .sub)
    , ("mul",    getDK (Ast.mul ctx x y),        .mul)
    , ("le",     getDK (Ast.le ctx x y),         .le)
    , ("ge",     getDK (Ast.ge ctx x y),         .ge)
    , ("lt",     getDK (Ast.lt ctx x y),         .lt)
    , ("gt",     getDK (Ast.gt ctx x y),         .gt)
    , ("uminus", getDK (Ast.unaryMinus ctx x),   .uminus)
    , ("div",    getDK (Ast.div ctx x y),        .idiv)
    , ("mod",    getDK (Ast.mod ctx x y),        .mod)
    , ("rem",    getDK (Ast.rem ctx x y),        .rem)
    ]
  for (name, got, expected) in cases do
    if got != expected then
      return check "DeclKind arith ops" false
        s!"expected {expected} for {name}, got {got}"
  return check "DeclKind arith ops" true

/-- Numeral decl kind -/
def testDeclKindNumeral : IO TestResult := runTest "DeclKind numeral" do
  let ctx ← Env.run Context.new
  let five := Ast.mkNumeral ctx "5" (Srt.mkInt ctx)
  let dk := getDK five
  return check "DeclKind numeral" (dk == .anum)
    s!"expected ANum, got {dk}"

/-- Uninterpreted function decl kind -/
def testDeclKindUninterp : IO TestResult := runTest "DeclKind uninterpreted" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  -- A plain constant is an uninterpreted 0-arity function
  let dk := getDK x
  return check "DeclKind uninterpreted" (dk == .uninterpreted)
    s!"expected Uninterpreted, got {dk}"

/-- BV decl kinds -/
def testDeclKindBV : IO TestResult := runTest "DeclKind bv ops" do
  let ctx ← Env.run Context.new
  let bv8 := Srt.mkBv ctx 8
  let a := Ast.mkNumeral ctx "10" bv8
  let b := Ast.mkNumeral ctx "3" bv8
  let cases : List (String × DeclKind × DeclKind) :=
    [ ("badd",  getDK (Ast.bvadd ctx a b),  .badd)
    , ("bsub",  getDK (Ast.bvsub ctx a b),  .bsub)
    , ("bmul",  getDK (Ast.bvmul ctx a b),  .bmul)
    , ("band",  getDK (Ast.bvand ctx a b),  .band)
    , ("bor",   getDK (Ast.bvor ctx a b),   .bor)
    , ("bxor",  getDK (Ast.bvxor ctx a b),  .bxor)
    , ("bnot",  getDK (Ast.bvnot ctx a),    .bnot)
    , ("bneg",  getDK (Ast.bvneg ctx a),    .bneg)
    , ("bshl",  getDK (Ast.bvshl ctx a b),  .bshl)
    , ("bnum",  getDK a,                     .bnum)
    ]
  for (name, got, expected) in cases do
    if got != expected then
      return check "DeclKind bv ops" false
        s!"expected {expected} for {name}, got {got}"
  return check "DeclKind bv ops" true

/-- Array decl kinds -/
def testDeclKindArray : IO TestResult := runTest "DeclKind array ops" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let arr := Ast.constArray ctx intSort zero
  let stored := Ast.store ctx arr one one
  let selected := Ast.select ctx arr zero
  let cases : List (String × DeclKind × DeclKind) :=
    [ ("const",  getDK arr,      .constArray)
    , ("store",  getDK stored,   .store)
    , ("select", getDK selected, .select)
    ]
  for (name, got, expected) in cases do
    if got != expected then
      return check "DeclKind array ops" false
        s!"expected {expected} for {name}, got {got}"
  return check "DeclKind array ops" true

/-- DeclKind roundtrip: ofRaw ∘ toRaw = id for known variants -/
def testDeclKindRoundtrip : IO TestResult := runTest "DeclKind roundtrip" do
  let kinds : List DeclKind :=
    [ .true_, .false_, .eq, .distinct, .ite
    , .and, .or, .iff, .xor, .not, .implies
    , .anum, .agnum
    , .le, .ge, .lt, .gt, .add, .sub, .uminus, .mul, .div, .idiv, .rem, .mod
    , .toReal, .toInt, .isInt, .power
    , .store, .select, .constArray
    , .bnum, .bneg, .badd, .bsub, .bmul, .bsdiv, .budiv, .bsrem, .burem, .bsmod
    , .bnot, .band, .bor, .bxor, .bnand, .bnor, .bxnor
    , .bconcat, .bsignExt, .bzeroExt, .bextract, .brepeat, .bredand, .bredor
    , .bshl, .blshr, .bashr, .brotateLeft, .brotateRight
    , .bule, .bsle, .buge, .bsge, .bult, .bslt, .bugt, .bsgt
    , .bv2int, .int2bv
    , .uninterpreted
    ]
  for k in kinds do
    let rt := DeclKind.ofRaw k.toRaw
    if rt != k then
      return check "DeclKind roundtrip" false
        s!"roundtrip failed for {k}: got {rt}"
  return check "DeclKind roundtrip" true

/-- DeclKind C validation: compare toRaw against actual Z3 C enum constants -/
def testDeclKindCValidation : IO TestResult := runTest "DeclKind C validation" do
  let all := DeclKind.allKnown
  for i in [:all.size] do
    let k := all[i]!
    let leanRaw := DeclKind.toRaw k
    let cRaw := DeclKind.expectedRaw i.toUInt32
    if leanRaw != cRaw then
      return check "DeclKind C validation" false
        s!"{k} (idx {i}): Lean toRaw=0x{String.ofList (Nat.toDigits 16 leanRaw.toNat)}, C expected=0x{String.ofList (Nat.toDigits 16 cRaw.toNat)}"
  return check "DeclKind C validation" true

def declKindTests : List (IO TestResult) :=
  [ testDeclKindBool
  , testDeclKindCore
  , testDeclKindArith
  , testDeclKindNumeral
  , testDeclKindUninterp
  , testDeclKindBV
  , testDeclKindArray
  , testDeclKindRoundtrip
  , testDeclKindCValidation
  ]

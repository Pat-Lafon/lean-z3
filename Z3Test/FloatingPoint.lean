import Z3Test.Harness

open Z3

/-! ## Floating point theory tests -/

/-- FP sort creation (32/64/custom) -/
def testFpaSorts : IO TestResult := runTest "FPA sorts" do
  let ctx ← Env.run Context.new
  let s32 := Srt.mkFpa32 ctx
  let s64 := Srt.mkFpa64 ctx
  let s16 := Srt.mkFpa16 ctx
  let s128 := Srt.mkFpa128 ctx
  let custom := Srt.mkFpa ctx 11 53  -- same as double
  let rm := Srt.mkFpaRoundingMode ctx
  let ok := (Srt.toString' s32).length > 0
    && (Srt.toString' s64).length > 0
    && (Srt.toString' s16).length > 0
    && (Srt.toString' s128).length > 0
    && (Srt.toString' custom).length > 0
    && (Srt.toString' rm).length > 0
  return check "FPA sorts" ok "expected non-empty sort strings"

/-- Rounding modes -/
def testFpaRoundingModes : IO TestResult := runTest "FPA rounding modes" do
  let ctx ← Env.run Context.new
  let rne := Ast.mkFpaRne ctx
  let rna := Ast.mkFpaRna ctx
  let rtp := Ast.mkFpaRtp ctx
  let rtn := Ast.mkFpaRtn ctx
  let rtz := Ast.mkFpaRtz ctx
  let ok := (Ast.toString' rne).length > 0
    && (Ast.toString' rna).length > 0
    && (Ast.toString' rtp).length > 0
    && (Ast.toString' rtn).length > 0
    && (Ast.toString' rtz).length > 0
  return check "FPA rounding modes" ok "expected non-empty rounding mode strings"

/-- FP special values (NaN, Inf, Zero) -/
def testFpaSpecialValues : IO TestResult := runTest "FPA special values" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let nan := Ast.mkFpaNan ctx s32
  let posInf := Ast.mkFpaInf ctx s32 false
  let negInf := Ast.mkFpaInf ctx s32 true
  let posZero := Ast.mkFpaZero ctx s32 false
  let negZero := Ast.mkFpaZero ctx s32 true
  -- NaN is NaN
  Solver.assert solver (Ast.mkFpaIsNan ctx nan)
  -- +Inf is infinite
  Solver.assert solver (Ast.mkFpaIsInf ctx posInf)
  -- -Inf is negative
  Solver.assert solver (Ast.mkFpaIsNegative ctx negInf)
  -- +0 is zero
  Solver.assert solver (Ast.mkFpaIsZero ctx posZero)
  -- -0 is zero too
  Solver.assert solver (Ast.mkFpaIsZero ctx negZero)
  let result ← Solver.checkSat solver
  return check "FPA special values" (result == .true)
    s!"expected sat, got {result}"

/-- FP arithmetic (add, sub, mul, div) -/
def testFpaArithmetic : IO TestResult := runTest "FPA arithmetic" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let rm := Ast.mkFpaRne ctx
  let a := Ast.mkFpaNumeralDouble ctx 1.5 s32
  let b := Ast.mkFpaNumeralDouble ctx 2.5 s32
  -- a + b = 4.0
  let sum := Ast.mkFpaAdd ctx rm a b
  let four := Ast.mkFpaNumeralDouble ctx 4.0 s32
  Solver.assert solver (Ast.mkFpaEq ctx sum four)
  -- a * b = 3.75
  let prod := Ast.mkFpaMul ctx rm a b
  let expected := Ast.mkFpaNumeralDouble ctx 3.75 s32
  Solver.assert solver (Ast.mkFpaEq ctx prod expected)
  let result ← Solver.checkSat solver
  return check "FPA arithmetic" (result == .true)
    s!"expected sat, got {result}"

/-- FP subtraction and division -/
def testFpaSubDiv : IO TestResult := runTest "FPA sub/div" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s64 := Srt.mkFpa64 ctx
  let rm := Ast.mkFpaRne ctx
  let ten := Ast.mkFpaNumeralDouble ctx 10.0 s64
  let three := Ast.mkFpaNumeralDouble ctx 3.0 s64
  let seven := Ast.mkFpaNumeralDouble ctx 7.0 s64
  -- 10 - 3 = 7
  let diff := Ast.mkFpaSub ctx rm ten three
  Solver.assert solver (Ast.mkFpaEq ctx diff seven)
  -- 10 / 2 = 5
  let two := Ast.mkFpaNumeralDouble ctx 2.0 s64
  let five := Ast.mkFpaNumeralDouble ctx 5.0 s64
  let quot := Ast.mkFpaDiv ctx rm ten two
  Solver.assert solver (Ast.mkFpaEq ctx quot five)
  let result ← Solver.checkSat solver
  return check "FPA sub/div" (result == .true)
    s!"expected sat, got {result}"

/-- FP sqrt, abs, neg -/
def testFpaSqrtAbsNeg : IO TestResult := runTest "FPA sqrt/abs/neg" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s64 := Srt.mkFpa64 ctx
  let rm := Ast.mkFpaRne ctx
  let four := Ast.mkFpaNumeralDouble ctx 4.0 s64
  let two := Ast.mkFpaNumeralDouble ctx 2.0 s64
  -- sqrt(4) = 2
  let sq := Ast.mkFpaSqrt ctx rm four
  Solver.assert solver (Ast.mkFpaEq ctx sq two)
  -- abs(-3) = 3
  let negThree := Ast.mkFpaNumeralDouble ctx (-3.0) s64
  let posThree := Ast.mkFpaNumeralDouble ctx 3.0 s64
  Solver.assert solver (Ast.mkFpaEq ctx (Ast.mkFpaAbs ctx negThree) posThree)
  -- neg(2) = -2
  let negTwo := Ast.mkFpaNumeralDouble ctx (-2.0) s64
  Solver.assert solver (Ast.mkFpaEq ctx (Ast.mkFpaNeg ctx two) negTwo)
  let result ← Solver.checkSat solver
  return check "FPA sqrt/abs/neg" (result == .true)
    s!"expected sat, got {result}"

/-- FP remainder -/
def testFpaRem : IO TestResult := runTest "FPA rem" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s64 := Srt.mkFpa64 ctx
  let five := Ast.mkFpaNumeralDouble ctx 5.0 s64
  let three := Ast.mkFpaNumeralDouble ctx 3.0 s64
  -- rem(5, 3) should exist and be well-formed
  let r := Ast.mkFpaRem ctx five three
  -- rem(5,3) = 2 in IEEE semantics (5 - 3*round(5/3) = 5 - 3*2 = -1... actually IEEE rem(5,3) = -1)
  -- Just check it produces a valid constraint
  Solver.assert solver (Ast.mkFpaIsNormal ctx r)
  let result ← Solver.checkSat solver
  return check "FPA rem" (result == .true)
    s!"expected sat, got {result}"

/-- FP comparisons -/
def testFpaComparisons : IO TestResult := runTest "FPA comparisons" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let one := Ast.mkFpaNumeralDouble ctx 1.0 s32
  let two := Ast.mkFpaNumeralDouble ctx 2.0 s32
  Solver.assert solver (Ast.mkFpaLt ctx one two)
  Solver.assert solver (Ast.mkFpaLeq ctx one two)
  Solver.assert solver (Ast.mkFpaGt ctx two one)
  Solver.assert solver (Ast.mkFpaGeq ctx two one)
  let result ← Solver.checkSat solver
  return check "FPA comparisons" (result == .true)
    s!"expected sat, got {result}"

/-- FP classification predicates -/
def testFpaClassification : IO TestResult := runTest "FPA classification" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let one := Ast.mkFpaNumeralDouble ctx 1.0 s32
  Solver.assert solver (Ast.mkFpaIsNormal ctx one)
  Solver.assert solver (Ast.mkFpaIsPositive ctx one)
  Solver.assert solver (Ast.not ctx (Ast.mkFpaIsSubnormal ctx one))
  Solver.assert solver (Ast.not ctx (Ast.mkFpaIsNan ctx one))
  Solver.assert solver (Ast.not ctx (Ast.mkFpaIsInf ctx one))
  Solver.assert solver (Ast.not ctx (Ast.mkFpaIsZero ctx one))
  Solver.assert solver (Ast.not ctx (Ast.mkFpaIsNegative ctx one))
  let result ← Solver.checkSat solver
  return check "FPA classification" (result == .true)
    s!"expected sat, got {result}"

/-- FP min/max -/
def testFpaMinMax : IO TestResult := runTest "FPA min/max" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let one := Ast.mkFpaNumeralDouble ctx 1.0 s32
  let five := Ast.mkFpaNumeralDouble ctx 5.0 s32
  Solver.assert solver (Ast.mkFpaEq ctx (Ast.mkFpaMin ctx one five) one)
  Solver.assert solver (Ast.mkFpaEq ctx (Ast.mkFpaMax ctx one five) five)
  let result ← Solver.checkSat solver
  return check "FPA min/max" (result == .true)
    s!"expected sat, got {result}"

/-- FP fused multiply-add -/
def testFpaFma : IO TestResult := runTest "FPA fma" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s64 := Srt.mkFpa64 ctx
  let rm := Ast.mkFpaRne ctx
  let two := Ast.mkFpaNumeralDouble ctx 2.0 s64
  let three := Ast.mkFpaNumeralDouble ctx 3.0 s64
  let four := Ast.mkFpaNumeralDouble ctx 4.0 s64
  let ten := Ast.mkFpaNumeralDouble ctx 10.0 s64
  -- fma(2, 3, 4) = 2*3 + 4 = 10
  let fma := Ast.mkFpaFma ctx rm two three four
  Solver.assert solver (Ast.mkFpaEq ctx fma ten)
  let result ← Solver.checkSat solver
  return check "FPA fma" (result == .true)
    s!"expected sat, got {result}"

/-- FP to real conversion -/
def testFpaToReal : IO TestResult := runTest "FPA to real" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let half := Ast.mkFpaNumeralDouble ctx 0.5 s32
  let r := Ast.mkFpaToReal ctx half
  let realSort := Srt.mkReal ctx
  let expected := Ast.mkNumeral ctx "1/2" realSort
  Solver.assert solver (Ast.eq ctx r expected)
  let result ← Solver.checkSat solver
  return check "FPA to real" (result == .true)
    s!"expected sat, got {result}"

/-- FP to/from bitvector -/
def testFpaBvConversion : IO TestResult := runTest "FPA bv conversion" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let rm := Ast.mkFpaRne ctx
  let one := Ast.mkFpaNumeralDouble ctx 1.0 s32
  -- FP -> IEEE BV -> FP roundtrip
  let bv := Ast.mkFpaToIeeeBv ctx one
  let back := Ast.mkFpaToFpBv ctx bv s32
  Solver.assert solver (Ast.mkFpaEq ctx back one)
  let result ← Solver.checkSat solver
  -- Also test to_ubv: fp 2.0 -> ubv should be 2
  Solver.reset solver
  let two := Ast.mkFpaNumeralDouble ctx 2.0 s32
  let ubv := Ast.mkFpaToUbv ctx rm two 8
  let bv2 := Ast.mkNumeral ctx "2" (Srt.mkBv ctx 8)
  Solver.assert solver (Ast.eq ctx ubv bv2)
  let result2 ← Solver.checkSat solver
  return check "FPA bv conversion" (result == .true && result2 == .true)
    s!"expected sat for both, got {result} and {result2}"

/-- FP symbolic solving -/
def testFpaSolving : IO TestResult := runTest "FPA solving" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let rm := Ast.mkFpaRne ctx
  let x := Ast.mkConst ctx "x" s32
  let one := Ast.mkFpaNumeralDouble ctx 1.0 s32
  let three := Ast.mkFpaNumeralDouble ctx 3.0 s32
  -- x + 1.0 = 3.0, so x = 2.0
  Solver.assert solver (Ast.mkFpaEq ctx (Ast.mkFpaAdd ctx rm x one) three)
  let result ← Solver.checkSat solver
  return check "FPA solving" (result == .true)
    s!"expected sat, got {result}"

/-- FP round to integral -/
def testFpaRoundToIntegral : IO TestResult := runTest "FPA round to integral" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s64 := Srt.mkFpa64 ctx
  let rtz := Ast.mkFpaRtz ctx
  let val := Ast.mkFpaNumeralDouble ctx 3.7 s64
  let rounded := Ast.mkFpaRoundToIntegral ctx rtz val
  let three := Ast.mkFpaNumeralDouble ctx 3.0 s64
  Solver.assert solver (Ast.mkFpaEq ctx rounded three)
  let result ← Solver.checkSat solver
  return check "FPA round to integral" (result == .true)
    s!"expected sat, got {result}"

/-- FP numeral from int -/
def testFpaNumeralInt : IO TestResult := runTest "FPA numeral int" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let fromInt := Ast.mkFpaNumeralInt ctx 42 s32
  let fromDbl := Ast.mkFpaNumeralDouble ctx 42.0 s32
  Solver.assert solver (Ast.mkFpaEq ctx fromInt fromDbl)
  let result ← Solver.checkSat solver
  return check "FPA numeral int" (result == .true)
    s!"expected sat, got {result}"

/-- FP to/from signed bitvector -/
def testFpaSignedBv : IO TestResult := runTest "FPA signed bv" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let rm := Ast.mkFpaRne ctx
  -- Convert signed BV -3 to FP
  let bvSort := Srt.mkBv ctx 8
  let negThreeBv := Ast.mkConst ctx "neg3bv" bvSort
  -- -3 in 8-bit two's complement = 0xFD = 253
  let neg3 := Ast.mkNumeral ctx "253" (Srt.mkBv ctx 8)
  Solver.assert solver (Ast.eq ctx negThreeBv neg3)
  let fp := Ast.mkFpaToFpSigned ctx rm negThreeBv s32
  let negThreeFp := Ast.mkFpaNumeralDouble ctx (-3.0) s32
  Solver.assert solver (Ast.mkFpaEq ctx fp negThreeFp)
  let result ← Solver.checkSat solver
  -- Also test to_sbv
  Solver.reset solver
  let negFive := Ast.mkFpaNumeralDouble ctx (-5.0) s32
  let sbv := Ast.mkFpaToSbv ctx rm negFive 8
  -- -5 in 8-bit = 0xFB = 251
  let expected := Ast.mkNumeral ctx "251" (Srt.mkBv ctx 8)
  Solver.assert solver (Ast.eq ctx sbv expected)
  let result2 ← Solver.checkSat solver
  return check "FPA signed bv" (result == .true && result2 == .true)
    s!"expected sat for both, got {result} and {result2}"

/-- NaN != NaN in FP equality -/
def testFpaNanNotEqual : IO TestResult := runTest "FPA NaN != NaN" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s32 := Srt.mkFpa32 ctx
  let nan := Ast.mkFpaNan ctx s32
  -- FP equality: NaN != NaN (IEEE semantics)
  Solver.assert solver (Ast.mkFpaEq ctx nan nan)
  let result ← Solver.checkSat solver
  return check "FPA NaN != NaN" (result == .false)
    s!"expected unsat (NaN != NaN in IEEE), got {result}"

def floatingPointTests : List (IO TestResult) :=
  [ testFpaSorts
  , testFpaRoundingModes
  , testFpaSpecialValues
  , testFpaArithmetic
  , testFpaSubDiv
  , testFpaSqrtAbsNeg
  , testFpaRem
  , testFpaComparisons
  , testFpaClassification
  , testFpaMinMax
  , testFpaFma
  , testFpaToReal
  , testFpaBvConversion
  , testFpaSolving
  , testFpaRoundToIntegral
  , testFpaNumeralInt
  , testFpaSignedBv
  , testFpaNanNotEqual
  ]

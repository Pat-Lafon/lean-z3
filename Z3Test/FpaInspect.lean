import Z3Test.Harness

open Z3

/-! ## FPA numeral inspection tests -/

/-- Inspect NaN -/
def testFpaIsNan : IO TestResult := runTest "fpa isNumeralNan" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24  -- float32
  let nan := Ast.mkFpaNan ctx fpSort
  let zero := Ast.mkFpaZero ctx fpSort false
  return check "fpa isNumeralNan"
    (Ast.fpaIsNumeralNan ctx nan && !Ast.fpaIsNumeralNan ctx zero)
    s!"expected nan=true, zero=false"

/-- Inspect Inf -/
def testFpaIsInf : IO TestResult := runTest "fpa isNumeralInf" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let inf := Ast.mkFpaInf ctx fpSort false
  let nan := Ast.mkFpaNan ctx fpSort
  return check "fpa isNumeralInf"
    (Ast.fpaIsNumeralInf ctx inf && !Ast.fpaIsNumeralInf ctx nan)
    s!"expected inf=true, nan=false"

/-- Inspect zero -/
def testFpaIsZero : IO TestResult := runTest "fpa isNumeralZero" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let zero := Ast.mkFpaZero ctx fpSort false
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  return check "fpa isNumeralZero"
    (Ast.fpaIsNumeralZero ctx zero && !Ast.fpaIsNumeralZero ctx one)
    s!"expected zero=true, one=false"

/-- Inspect normal numeral -/
def testFpaIsNormal : IO TestResult := runTest "fpa isNumeralNormal" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let zero := Ast.mkFpaZero ctx fpSort false
  return check "fpa isNumeralNormal"
    (Ast.fpaIsNumeralNormal ctx one && !Ast.fpaIsNumeralNormal ctx zero)
    s!"expected one=normal, zero=not normal"

/-- Inspect positive/negative -/
def testFpaIsPositiveNegative : IO TestResult := runTest "fpa isPositive/isNegative" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let posZero := Ast.mkFpaZero ctx fpSort false
  let negZero := Ast.mkFpaZero ctx fpSort true
  return check "fpa isPositive/isNegative"
    (Ast.fpaIsNumeralPositive ctx posZero && Ast.fpaIsNumeralNegative ctx negZero
     && !Ast.fpaIsNumeralNegative ctx posZero && !Ast.fpaIsNumeralPositive ctx negZero)
    s!"positive/negative check failed"

/-- Get sign of FP numeral -/
def testFpaGetSign : IO TestResult := runTest "fpa getSign" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let posInf := Ast.mkFpaInf ctx fpSort false   -- +Inf
  let negInf := Ast.mkFpaInf ctx fpSort true    -- -Inf
  let posSgn ← Ast.fpaGetNumeralSign ctx posInf
  let negSgn ← Ast.fpaGetNumeralSign ctx negInf
  -- some false = positive, some true = negative
  return check "fpa getSign" (posSgn == some false && negSgn == some true)
    s!"expected pos=some false neg=some true, got pos={posSgn} neg={negSgn}"

/-- Get significand as string -/
def testFpaGetSignificandString : IO TestResult := runTest "fpa getSignificandString" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let sig := Ast.fpaGetNumeralSignificandString ctx one
  return check "fpa getSignificandString" (sig.length > 0)
    s!"expected non-empty significand string, got '{sig}'"

/-- Get significand as UInt64 -/
def testFpaGetSignificandUInt64 : IO TestResult := runTest "fpa getSignificandUInt64" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let sig ← Ast.fpaGetNumeralSignificandUInt64 ctx one
  -- 1.0 in float32: mantissa bits are all 0 (implicit leading 1)
  return check "fpa getSignificandUInt64" (sig == 0)
    s!"expected 0, got {sig}"

/-- Get exponent as string -/
def testFpaGetExponentString : IO TestResult := runTest "fpa getExponentString" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let exp := Ast.fpaGetNumeralExponentString ctx one false
  let expBiased := Ast.fpaGetNumeralExponentString ctx one true
  return check "fpa getExponentString" (exp.length > 0 && expBiased.length > 0)
    s!"expected non-empty exponent strings, got unbiased='{exp}' biased='{expBiased}'"

/-- Get exponent as UInt64 -/
def testFpaGetExponentInt64 : IO TestResult := runTest "fpa getExponentInt64" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let exp ← Ast.fpaGetNumeralExponentInt64 ctx one false
  -- 1.0 = 2^0, so exponent should be 0
  return check "fpa getExponentInt64" (exp == 0)
    s!"expected 0, got {exp}"

/-- Get sign/significand/exponent as bitvectors -/
def testFpaGetBvComponents : IO TestResult := runTest "fpa getBv components" do
  let ctx ← Env.run Context.new
  let fpSort := Srt.mkFpa ctx 8 24
  let one := Ast.mkFpaNumeralDouble ctx 1.0 fpSort
  let signBv := Ast.fpaGetNumeralSignBv ctx one
  let sigBv := Ast.fpaGetNumeralSignificandBv ctx one
  let expBv := Ast.fpaGetNumeralExponentBv ctx one false
  -- Just verify they produce valid ASTs (non-empty toString)
  let s1 := toString signBv
  let s2 := toString sigBv
  let s3 := toString expBv
  return check "fpa getBv components" (s1.length > 0 && s2.length > 0 && s3.length > 0)
    s!"expected valid BV components, got sign='{s1}' sig='{s2}' exp='{s3}'"

def fpaInspectTests : List (IO TestResult) :=
  [ testFpaIsNan
  , testFpaIsInf
  , testFpaIsZero
  , testFpaIsNormal
  , testFpaIsPositiveNegative
  , testFpaGetSign
  , testFpaGetSignificandString
  , testFpaGetSignificandUInt64
  , testFpaGetExponentString
  , testFpaGetExponentInt64
  , testFpaGetBvComponents
  ]

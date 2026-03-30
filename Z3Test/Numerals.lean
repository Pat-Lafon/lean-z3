import Z3Test.Harness

open Z3

/-! ## Numeral constructor and extraction tests -/

/-- mkInt64: create integer from Int64, extract and verify -/
def testMkInt64 : IO TestResult := runTest "mkInt64" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let fortytwo := Ast.mkInt64 ctx 42 intSort
  Solver.assert solver (Ast.eq ctx x fortytwo)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkInt64" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkInt64" (valStr == "42")
    s!"expected 42, got {valStr}"

/-- mkInt64 negative: create negative integer from Int64 -/
def testMkInt64Neg : IO TestResult := runTest "mkInt64 negative" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let neg := Ast.mkInt64 ctx (-17) intSort
  Solver.assert solver (Ast.eq ctx x neg)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkInt64 negative" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkInt64 negative" (valStr == "-17" || valStr == "(- 17)")
    s!"expected -17, got {valStr}"

/-- mkUInt64: create unsigned integer -/
def testMkUInt64 : IO TestResult := runTest "mkUInt64" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let big := Ast.mkUInt64 ctx 1000000 intSort
  Solver.assert solver (Ast.eq ctx x big)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkUInt64" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkUInt64" (valStr == "1000000")
    s!"expected 1000000, got {valStr}"

/-- mkRealVal: create rational from numerator/denominator -/
def testMkRealVal : IO TestResult := runTest "mkRealVal (3/7)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let realSort := Srt.mkReal ctx
  let x := Ast.mkConst ctx "x" realSort
  let threeSevenths := Ast.mkRealVal ctx 3 7
  Solver.assert solver (Ast.eq ctx x threeSevenths)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkRealVal (3/7)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkRealVal (3/7)" (valStr == "3/7")
    s!"expected 3/7, got {valStr}"

/-- getNumeralDecimalString: get decimal representation -/
def testGetNumeralDecimalString : IO TestResult := runTest "getNumeralDecimalString" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let fortytwo := Ast.mkNumeral ctx "42" intSort
  let s := Ast.getNumeralDecimalString fortytwo 10
  return check "getNumeralDecimalString" (s == "42" || s == "42.0000000000")
    s!"expected 42 or 42.0000000000, got {s}"

/-- getNumeralBinaryString: get binary representation -/
def testGetNumeralBinaryString : IO TestResult := runTest "getNumeralBinaryString" do
  let ctx ← Env.run Context.new
  let bvSort := Srt.mkBv ctx 8
  let ten := Ast.mkNumeral ctx "10" bvSort
  let s := Ast.getNumeralBinaryString ten
  return check "getNumeralBinaryString" (s == "1010")
    s!"expected 1010, got {s}"

/-- getNumeralInt64: extract Int64 from numeral -/
def testGetNumeralInt64 : IO TestResult := runTest "getNumeralInt64" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let neg := Ast.mkNumeral ctx "-99" intSort
  let val ← Env.run (Ast.getNumeralInt64 neg)
  return check "getNumeralInt64" (val == -99)
    s!"expected -99, got {val}"

/-- getNumeralUInt64: extract UInt64 from numeral -/
def testGetNumeralUInt64 : IO TestResult := runTest "getNumeralUInt64" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let n := Ast.mkNumeral ctx "12345" intSort
  let val ← Env.run (Ast.getNumeralUInt64 n)
  return check "getNumeralUInt64" (val == 12345)
    s!"expected 12345, got {val}"

/-- getNumeralDouble: extract Float from numeral -/
def testGetNumeralDouble : IO TestResult := runTest "getNumeralDouble" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let n := Ast.mkNumeral ctx "42" intSort
  let d := Ast.getNumeralDouble n
  return check "getNumeralDouble" (d == 42.0)
    s!"expected 42.0, got {d}"

/-- getNumerator/getDenominator: rational decomposition -/
def testRationalDecomposition : IO TestResult := runTest "getNumerator/getDenominator" do
  let ctx ← Env.run Context.new
  let r := Ast.mkRealVal ctx 5 3
  let num := Ast.getNumerator r
  let den := Ast.getDenominator r
  let numStr := Ast.getNumeralString num
  let denStr := Ast.getNumeralString den
  return check "getNumerator/getDenominator" (numStr == "5" && denStr == "3")
    s!"expected 5/3, got {numStr}/{denStr}"

/-- mkInt64 roundtrip through getNumeralInt64 -/
def testInt64Roundtrip : IO TestResult := runTest "Int64 roundtrip" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let original : Int64 := -9876
  let ast := Ast.mkInt64 ctx original intSort
  let extracted ← Env.run (Ast.getNumeralInt64 ast)
  return check "Int64 roundtrip" (extracted == original)
    s!"expected {original}, got {extracted}"

/-- mkInt: create integer from Int32, extract and verify -/
def testMkInt : IO TestResult := runTest "mkInt (Int32)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let v := Ast.mkInt ctx 123 intSort
  Solver.assert solver (Ast.eq ctx x v)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkInt (Int32)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkInt (Int32)" (valStr == "123")
    s!"expected 123, got {valStr}"

/-- mkReal: create rational from Int32 numerator/denominator -/
def testMkReal : IO TestResult := runTest "mkReal (2/5)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let realSort := Srt.mkReal ctx
  let x := Ast.mkConst ctx "x" realSort
  let twoFifths := Ast.mkReal ctx 2 5
  Solver.assert solver (Ast.eq ctx x twoFifths)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "mkReal (2/5)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "mkReal (2/5)" (valStr == "2/5")
    s!"expected 2/5, got {valStr}"

def numeralTests : List (IO TestResult) :=
  [ testMkInt
  , testMkReal
  , testMkInt64
  , testMkInt64Neg
  , testMkUInt64
  , testMkRealVal
  , testGetNumeralDecimalString
  , testGetNumeralBinaryString
  , testGetNumeralInt64
  , testGetNumeralUInt64
  , testGetNumeralDouble
  , testRationalDecomposition
  , testInt64Roundtrip
  ]

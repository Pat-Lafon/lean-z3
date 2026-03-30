import Z3Test.Harness

open Z3

/-! ## Arithmetic operation tests -/

/-- Integer division: 7 / 2 = 3 -/
def testIntDiv : IO TestResult := runTest "int div (7 / 2 = 3)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let seven := Ast.mkNumeral ctx "7" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let divResult := Ast.div ctx seven two
  Solver.assert solver (Ast.eq ctx divResult three)
  let result ← Solver.checkSat solver
  return check "int div (7 / 2 = 3)" (result == .true)
    s!"expected sat, got {result}"

/-- Integer modulus: 7 mod 3 = 1 -/
def testIntMod : IO TestResult := runTest "int mod (7 mod 3 = 1)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let seven := Ast.mkNumeral ctx "7" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let modResult := Ast.mod ctx seven three
  Solver.assert solver (Ast.eq ctx modResult one)
  let result ← Solver.checkSat solver
  return check "int mod (7 mod 3 = 1)" (result == .true)
    s!"expected sat, got {result}"

/-- Integer remainder: -7 rem 3 = 2 (Euclidean remainder, always non-negative) -/
def testIntRem : IO TestResult := runTest "int rem (-7 rem 3 = 2)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let negSeven := Ast.mkNumeral ctx "-7" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let remResult := Ast.rem ctx negSeven three
  Solver.assert solver (Ast.eq ctx remResult two)
  let result ← Solver.checkSat solver
  return check "int rem (-7 rem 3 = 2)" (result == .true)
    s!"expected sat, got {result}"

/-- Power: 2^10 = 1024 -/
def testPower : IO TestResult := runTest "power (2^10 = 1024)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let two := Ast.mkNumeral ctx "2" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  let expected := Ast.mkNumeral ctx "1024" intSort
  let powResult := Ast.power ctx two ten
  Solver.assert solver (Ast.eq ctx powResult expected)
  let result ← Solver.checkSat solver
  return check "power (2^10 = 1024)" (result == .true)
    s!"expected sat, got {result}"

/-- Absolute value: |x| >= 0 for all x -/
def testAbs : IO TestResult := runTest "abs (|x| >= 0)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  -- Assert NOT(|x| >= 0), expect unsat
  Solver.assert solver (Ast.not ctx (Ast.ge ctx (Ast.abs ctx x) zero))
  let result ← Solver.checkSat solver
  return check "abs (|x| >= 0)" (result == .false)
    s!"expected unsat, got {result}"

/-- Unary minus: -x = 0 - x -/
def testUnaryMinus : IO TestResult := runTest "unary minus (-x = 0 - x)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  let negX := Ast.unaryMinus ctx x
  let zeroMinusX := Ast.sub ctx zero x
  -- Assert negX != zeroMinusX, expect unsat
  Solver.assert solver (Ast.not ctx (Ast.eq ctx negX zeroMinusX))
  let result ← Solver.checkSat solver
  return check "unary minus (-x = 0 - x)" (result == .false)
    s!"expected unsat, got {result}"

/-- int2real / real2int round-trip: real2int(int2real(x)) = x -/
def testInt2RealReal2Int : IO TestResult := runTest "int2real/real2int round-trip" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let roundTrip := Ast.real2int ctx (Ast.int2real ctx x)
  -- Assert x != roundTrip, expect unsat
  Solver.assert solver (Ast.not ctx (Ast.eq ctx x roundTrip))
  let result ← Solver.checkSat solver
  return check "int2real/real2int round-trip" (result == .false)
    s!"expected unsat, got {result}"

/-- isInt: int2real(x) is always an integer -/
def testIsInt : IO TestResult := runTest "isInt (int2real(x) is integer)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let asReal := Ast.int2real ctx x
  -- Assert NOT(isInt(int2real(x))), expect unsat
  Solver.assert solver (Ast.not ctx (Ast.isInt ctx asReal))
  let result ← Solver.checkSat solver
  return check "isInt (int2real(x) is integer)" (result == .false)
    s!"expected unsat, got {result}"

/-- Division model: solve 2x = 10, check x = 5 -/
def testDivModel : IO TestResult := runTest "div model (10 / x = 2, x = 5)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let ten := Ast.mkNumeral ctx "10" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  Solver.assert solver (Ast.eq ctx (Ast.div ctx ten x) two)
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "div model (10 / x = 2, x = 5)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let xVal ← Env.run (Model.eval model x true)
  let xStr := Ast.getNumeralString xVal
  return check "div model (10 / x = 2, x = 5)" (xStr == "5")
    s!"expected x = 5, got x = {xStr}"

/-- Mod property: (a mod b) + b*(a div b) = a -/
def testModDivRelation : IO TestResult := runTest "mod/div relation (a mod b + b*(a div b) = a)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let a := Ast.mkIntConst ctx "a"
  let b := Ast.mkIntConst ctx "b"
  let zero := Ast.mkNumeral ctx "0" intSort
  -- b != 0
  Solver.assert solver (Ast.not ctx (Ast.eq ctx b zero))
  -- Assert NOT(a mod b + b * (a div b) = a), expect unsat
  let lhs := Ast.add ctx (Ast.mod ctx a b) (Ast.mul ctx b (Ast.div ctx a b))
  Solver.assert solver (Ast.not ctx (Ast.eq ctx lhs a))
  let result ← Solver.checkSat solver
  return check "mod/div relation (a mod b + b*(a div b) = a)" (result == .false)
    s!"expected unsat, got {result}"

def arithmeticTests : List (IO TestResult) :=
  [ testIntDiv
  , testIntMod
  , testIntRem
  , testPower
  , testAbs
  , testUnaryMinus
  , testInt2RealReal2Int
  , testIsInt
  , testDivModel
  , testModDivRelation
  ]

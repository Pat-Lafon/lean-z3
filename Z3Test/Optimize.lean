import Z3Test.Harness

open Z3

/-! ## Optimization API tests -/

/-- Basic maximize: maximize x subject to x ≤ 10 -/
def testOptimizeMaximize : IO TestResult := runTest "Optimize.maximize" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let ten := Ast.mkNumeral ctx "10" intSort
  -- x ≤ 10
  Optimize.assert opt (Ast.le ctx x ten)
  -- maximize x
  let idx ← Optimize.maximize opt x
  let result ← Optimize.check opt
  if result != .true then
    return check "Optimize.maximize" false s!"expected sat, got {result}"
  let model ← Env.run (Optimize.getModel opt)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "Optimize.maximize" (valStr == "10")
    s!"expected x=10, got x={valStr}"

/-- Basic minimize: minimize x subject to x ≥ 5 -/
def testOptimizeMinimize : IO TestResult := runTest "Optimize.minimize" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let five := Ast.mkNumeral ctx "5" intSort
  Optimize.assert opt (Ast.ge ctx x five)
  let idx ← Optimize.minimize opt x
  let result ← Optimize.check opt
  if result != .true then
    return check "Optimize.minimize" false s!"expected sat, got {result}"
  let model ← Env.run (Optimize.getModel opt)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "Optimize.minimize" (valStr == "5")
    s!"expected x=5, got x={valStr}"

/-- getLower / getUpper: check objective bounds -/
def testOptimizeBounds : IO TestResult := runTest "Optimize bounds" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkNumeral ctx "3" intSort))
  Optimize.assert opt (Ast.le ctx x (Ast.mkNumeral ctx "7" intSort))
  let idx ← Optimize.maximize opt x
  let result ← Optimize.check opt
  if result != .true then
    return check "Optimize bounds" false s!"expected sat, got {result}"
  let upper := Optimize.getUpper opt idx
  let upperStr := Ast.getNumeralString upper
  return check "Optimize bounds" (upperStr == "7")
    s!"expected upper=7, got upper={upperStr}"

/-- Soft constraints: assert_soft with weights -/
def testOptimizeSoft : IO TestResult := runTest "Optimize.assertSoft" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  -- Hard: at least one is false
  Optimize.assert opt (Ast.or ctx (Ast.not ctx a) (Ast.not ctx b))
  -- Soft: prefer a=true (weight 2) and b=true (weight 1)
  let _ ← Optimize.assertSoft opt a "2" "group"
  let _ ← Optimize.assertSoft opt b "1" "group"
  let result ← Optimize.check opt
  if result != .true then
    return check "Optimize.assertSoft" false s!"expected sat, got {result}"
  let model ← Env.run (Optimize.getModel opt)
  let aVal ← Env.run (Model.eval model a true)
  let bVal ← Env.run (Model.eval model b true)
  let aStr := Ast.toString' aVal
  let bStr := Ast.toString' bVal
  -- Should prefer a=true (higher weight), b=false
  return check "Optimize.assertSoft" (aStr == "true" && bStr == "false")
    s!"expected a=true, b=false, got a={aStr}, b={bStr}"

/-- Push/pop scope management -/
def testOptimizePushPop : IO TestResult := runTest "Optimize push/pop" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkNumeral ctx "0" intSort))
  Optimize.push opt
  -- Add conflicting constraint in inner scope
  Optimize.assert opt (Ast.lt ctx x (Ast.mkNumeral ctx "0" intSort))
  let _ ← Optimize.minimize opt x
  let r1 ← Optimize.check opt
  if r1 == .true then
    return check "Optimize push/pop" false s!"expected unsat in inner scope, got {r1}"
  -- Pop should restore satisfiability
  Optimize.pop opt
  let _ ← Optimize.minimize opt x
  let r2 ← Optimize.check opt
  return check "Optimize push/pop" (r2 == .true)
    s!"expected sat after pop, got {r2}"

/-- toString: string representation -/
def testOptimizeToString : IO TestResult := runTest "Optimize.toString" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkNumeral ctx "0" (Srt.mkInt ctx)))
  let s := Optimize.toString' opt
  -- Should contain something about the assertion
  return check "Optimize.toString" (s.length > 0)
    s!"expected non-empty string"

/-- Unsat optimization problem -/
def testOptimizeUnsat : IO TestResult := runTest "Optimize unsat" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.gt ctx x (Ast.mkNumeral ctx "10" intSort))
  Optimize.assert opt (Ast.lt ctx x (Ast.mkNumeral ctx "5" intSort))
  let _ ← Optimize.minimize opt x
  let result ← Optimize.check opt
  return check "Optimize unsat" (result != .true)
    s!"expected unsat/undef, got {result}"

/-- assertAndTrack: tracked assertion appears in unsat core -/
def testOptimizeAssertAndTrack : IO TestResult := runTest "Optimize.assertAndTrack" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let t1 := Ast.mkBoolConst ctx "t1"
  let t2 := Ast.mkBoolConst ctx "t2"
  Optimize.assertAndTrack opt (Ast.gt ctx x (Ast.mkInt ctx 10 intSort)) t1
  Optimize.assertAndTrack opt (Ast.lt ctx x (Ast.mkInt ctx 5 intSort)) t2
  let _ ← Optimize.minimize opt x
  let result ← Optimize.check opt
  if result == .true then
    return check "Optimize.assertAndTrack" false "expected unsat"
  let core ← Optimize.getUnsatCore opt
  return check "Optimize.assertAndTrack" (core.size > 0)
    s!"expected non-empty unsat core, got {core.size} elements"

/-- fromString: load SMT-LIB2 assertions -/
def testOptimizeFromString : IO TestResult := runTest "Optimize.fromString" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  Optimize.fromString opt "(declare-const x Int)\n(assert (>= x 0))\n(minimize x)"
  let result ← Optimize.check opt
  return check "Optimize.fromString" (result == .true)
    s!"expected sat, got {result}"

/-- getHelp: returns non-empty help string -/
def testOptimizeGetHelp : IO TestResult := runTest "Optimize.getHelp" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let help ← Optimize.getHelp opt
  return check "Optimize.getHelp" (help.length > 0)
    s!"expected non-empty help string"

/-- getStatistics: returns stats after check -/
def testOptimizeGetStatistics : IO TestResult := runTest "Optimize.getStatistics" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkInt ctx 0 (Srt.mkInt ctx)))
  let _ ← Optimize.minimize opt x
  let _ ← Optimize.check opt
  let stats ← Optimize.getStatistics opt
  let s := toString stats
  return check "Optimize.getStatistics" (s.length > 0)
    s!"expected non-empty stats"

/-- getAssertions: retrieve all assertions -/
def testOptimizeGetAssertions : IO TestResult := runTest "Optimize.getAssertions" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkInt ctx 0 intSort))
  Optimize.assert opt (Ast.le ctx x (Ast.mkInt ctx 10 intSort))
  let assertions ← Optimize.getAssertions opt
  return check "Optimize.getAssertions" (assertions.size == 2)
    s!"expected 2 assertions, got {assertions.size}"

/-- getObjectives: retrieve all objective functions -/
def testOptimizeGetObjectives : IO TestResult := runTest "Optimize.getObjectives" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  Optimize.assert opt (Ast.ge ctx x (Ast.mkInt ctx 0 intSort))
  let _ ← Optimize.maximize opt x
  let _ ← Optimize.minimize opt y
  let objectives ← Optimize.getObjectives opt
  return check "Optimize.getObjectives" (objectives.size == 2)
    s!"expected 2 objectives, got {objectives.size}"

/-- getParamDescrs: returns param descriptions -/
def testOptimizeGetParamDescrs : IO TestResult := runTest "Optimize.getParamDescrs" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let pd ← Optimize.getParamDescrs ctx opt
  let n := ParamDescrs.size pd
  return check "Optimize.getParamDescrs" (n > 0)
    s!"expected params, got {n}"

/-- checkAssumptions: check with additional assumptions -/
def testOptimizeCheckAssumptions : IO TestResult := runTest "Optimize.checkAssumptions" do
  let ctx ← Env.run Context.new
  let opt ← Env.run (Optimize.new ctx)
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  -- a ∨ b
  Optimize.assert opt (Ast.or ctx a b)
  -- Check with assumption ¬a ∧ ¬b → should be unsat
  let result ← Optimize.checkAssumptions opt #[Ast.not ctx a, Ast.not ctx b]
  return check "Optimize.checkAssumptions" (result != .true)
    s!"expected unsat with conflicting assumptions, got {result}"

def optimizeTests : List (IO TestResult) :=
  [ testOptimizeMaximize
  , testOptimizeMinimize
  , testOptimizeBounds
  , testOptimizeSoft
  , testOptimizePushPop
  , testOptimizeToString
  , testOptimizeUnsat
  , testOptimizeAssertAndTrack
  , testOptimizeFromString
  , testOptimizeGetHelp
  , testOptimizeGetStatistics
  , testOptimizeGetAssertions
  , testOptimizeGetObjectives
  , testOptimizeGetParamDescrs
  , testOptimizeCheckAssumptions
  ]

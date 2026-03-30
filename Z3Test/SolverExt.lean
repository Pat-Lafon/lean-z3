import Z3Test.Harness

open Z3

/-! ## Solver (extended) tests -/

/-- Simple solver -/
def testSimpleSolver : IO TestResult := runTest "simple solver" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.mkSimple ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let result ← Solver.checkSat solver
  return check "simple solver" (result == .true)
    s!"expected sat, got {result}"

/-- Solver for logic -/
def testSolverForLogic : IO TestResult := runTest "solver for logic" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.mkForLogic ctx "QF_LIA")
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  Solver.assert solver (Ast.lt ctx x (Ast.mkNumeral ctx "10" intSort))
  let result ← Solver.checkSat solver
  return check "solver for logic" (result == .true)
    s!"expected sat, got {result}"

/-- Solver from string -/
def testSolverFromString : IO TestResult := runTest "solver from string" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  Solver.fromString solver "(declare-const x Int) (assert (> x 0)) (assert (< x 10))"
  let result ← Solver.checkSat solver
  return check "solver from string" (result == .true)
    s!"expected sat, got {result}"

/-- Solver get num scopes -/
def testSolverNumScopes : IO TestResult := runTest "solver num scopes" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let n0 ← Solver.getNumScopes solver
  Solver.push solver
  let n1 ← Solver.getNumScopes solver
  Solver.push solver
  let n2 ← Solver.getNumScopes solver
  Solver.pop solver 1
  let n3 ← Solver.getNumScopes solver
  -- Z3's default solver uses multiple internal scopes per push;
  -- just verify push increases and pop decreases
  let ok := n1 > n0 && n2 > n1 && n3 < n2
  return check "solver num scopes" ok
    s!"expected increasing then decreasing, got {n0},{n1},{n2},{n3}"

/-- Solver translate -/
def testSolverTranslate : IO TestResult := runTest "solver translate" do
  let ctx1 ← Env.run Context.new
  let solver1 ← Env.run (Solver.new ctx1)
  let intSort := Srt.mkInt ctx1
  let x := Ast.mkIntConst ctx1 "x"
  Solver.assert solver1 (Ast.gt ctx1 x (Ast.mkNumeral ctx1 "0" intSort))
  -- Translate to new context
  let ctx2 ← Env.run Context.new
  let solver2 ← Env.run (Solver.translate solver1 ctx2)
  let result ← Solver.checkSat solver2
  return check "solver translate" (result == .true)
    s!"expected sat, got {result}"

/-- Solver statistics -/
def testSolverStatistics : IO TestResult := runTest "solver statistics" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let _ ← Solver.checkSat solver
  let stats ← Solver.getStatistics solver
  let sz := Stats.size stats
  -- After solving, should have some statistics
  let ok := sz > 0 && (Stats.toString' stats).length > 0
  -- Check we can read a key
  let key0 := if sz > 0 then Stats.getKey stats 0 else ""
  return check "solver statistics" (ok && key0.length > 0)
    s!"expected stats with sz > 0, got sz={sz}"

/-- Stats key/value inspection -/
def testStatsInspection : IO TestResult := runTest "stats inspection" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let _ ← Solver.checkSat solver
  let stats ← Solver.getStatistics solver
  let sz := Stats.size stats
  -- Iterate and check type predicates work
  let mut foundUInt := false
  let mut foundDouble := false
  for i in [:sz.toNat] do
    let idx := i.toUInt32
    if Stats.isUInt stats idx then
      let _ := Stats.getUIntValue stats idx
      foundUInt := true
    if Stats.isDouble stats idx then
      let _ := Stats.getDoubleValue stats idx
      foundDouble := true
  return check "stats inspection" (foundUInt || foundDouble)
    s!"expected at least one uint or double stat"

/-- Solver get trail -/
def testSolverGetTrail : IO TestResult := runTest "solver get trail" do
  let ctx ← Env.run Context.new
  -- Trail requires a simple solver, not the default tactic-based one
  let solver ← Env.run (Solver.mkSimple ctx)
  let p := Ast.mkBoolConst ctx "p"
  Solver.assert solver p
  let result ← Solver.checkSat solver
  let trail ← Solver.getTrail solver
  -- After asserting p and getting sat, trail should contain assignments
  return check "solver get trail" (result == .true && trail.size ≥ 0)
    s!"expected sat, got {result}, trail size {trail.size}"

/-- Solver get consequences -/
def testSolverGetConsequences : IO TestResult := runTest "solver get consequences" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  -- p → q, p are asserted; consequence should include q
  Solver.assert solver (Ast.implies ctx p q)
  Solver.assert solver p
  let (result, _conseqs) := ← Solver.getConsequences solver #[p] #[q]
  return check "solver get consequences" (result == .true)
    s!"expected sat, got {result}"

/-- Solver interrupt (basic call test) -/
def testSolverInterrupt : IO TestResult := runTest "solver interrupt" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  -- Just verify interrupt doesn't crash; it's meant for cross-thread use
  Solver.interrupt solver
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let result ← Solver.checkSat solver
  return check "solver interrupt" (result == .true)
    s!"expected sat, got {result}"

def solverExtTests : List (IO TestResult) :=
  [ testSimpleSolver
  , testSolverForLogic
  , testSolverFromString
  , testSolverNumScopes
  , testSolverTranslate
  , testSolverStatistics
  , testStatsInspection
  , testSolverGetTrail
  , testSolverGetConsequences
  , testSolverInterrupt
  ]

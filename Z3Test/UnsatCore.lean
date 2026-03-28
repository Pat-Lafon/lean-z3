import Z3Test.Harness

open Z3

/-! ## Unsat core and assumptions tests -/

/-- assertAndTrack + getUnsatCore: identify which constraints cause unsat -/
def testUnsatCoreBasic : IO TestResult := runTest "unsat core basic" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  -- Track three constraints with Boolean labels
  let p1 := Ast.mkBoolConst ctx "p1"
  let p2 := Ast.mkBoolConst ctx "p2"
  let p3 := Ast.mkBoolConst ctx "p3"
  Solver.assertAndTrack solver (Ast.gt ctx x zero) p1     -- x > 0
  Solver.assertAndTrack solver (Ast.lt ctx x zero) p2     -- x < 0
  Solver.assertAndTrack solver (Ast.eq ctx x zero) p3     -- x = 0
  let result ← Solver.checkSat solver
  if result != .false then
    return check "unsat core basic" false s!"expected unsat, got {result}"
  let core ← Env.run (Solver.getUnsatCore solver)
  -- Core should be non-empty (x>0 and x<0 conflict)
  return check "unsat core basic" (core.size > 0 && core.size <= 3)
    s!"expected 1-3 core elements, got {core.size}"

/-- checkAssumptions: check with assumption literals -/
def testCheckAssumptions : IO TestResult := runTest "check assumptions" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  let ten := Ast.mkNumeral ctx "10" (Srt.mkInt ctx)
  -- Hard constraints: x > 0
  Solver.assert solver (Ast.gt ctx x zero)
  -- Check with assumption x < 10 — should be sat
  let a1 := Ast.lt ctx x ten
  let result1 ← Solver.checkAssumptions solver #[a1]
  if result1 != .true then
    return check "check assumptions" false s!"expected sat with x<10, got {result1}"
  -- Check with assumption x < 0 — should be unsat (conflicts with x > 0)
  let a2 := Ast.lt ctx x zero
  let result2 ← Solver.checkAssumptions solver #[a2]
  return check "check assumptions" (result2 == .false)
    s!"expected unsat with x<0, got {result2}"

/-- Unsat core from assumptions -/
def testUnsatCoreAssumptions : IO TestResult := runTest "unsat core from assumptions" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  -- Hard: x > 0
  Solver.assert solver (Ast.gt ctx x zero)
  -- Assumptions: a1 = (x < 0), a2 = (x > 5)
  let a1 := Ast.lt ctx x zero
  let a2 := Ast.gt ctx x (Ast.mkNumeral ctx "5" (Srt.mkInt ctx))
  let result ← Solver.checkAssumptions solver #[a1, a2]
  if result != .false then
    return check "unsat core from assumptions" false s!"expected unsat, got {result}"
  let core ← Env.run (Solver.getUnsatCore solver)
  -- The core should contain a1 (x < 0) since that conflicts with x > 0
  return check "unsat core from assumptions" (core.size > 0)
    s!"expected non-empty core, got empty"

/-- getAssertions: verify tracked assertions are retrievable -/
def testGetAssertions : IO TestResult := runTest "get assertions" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.lt ctx x (Ast.mkNumeral ctx "10" (Srt.mkInt ctx)))
  let assertions ← Solver.getAssertions solver
  return check "get assertions" (assertions.size == 2)
    s!"expected 2 assertions, got {assertions.size}"

/-- Unsat core is minimal: only conflicting constraints appear -/
def testUnsatCoreMinimal : IO TestResult := runTest "unsat core minimal" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  let p1 := Ast.mkBoolConst ctx "p1"
  let p2 := Ast.mkBoolConst ctx "p2"
  let p3 := Ast.mkBoolConst ctx "p3"
  -- p1: x > 0, p2: x < 0 (these conflict)
  -- p3: y > 0 (irrelevant to the conflict)
  Solver.assertAndTrack solver (Ast.gt ctx x zero) p1
  Solver.assertAndTrack solver (Ast.lt ctx x zero) p2
  Solver.assertAndTrack solver (Ast.gt ctx y zero) p3
  let result ← Solver.checkSat solver
  if result != .false then
    return check "unsat core minimal" false s!"expected unsat, got {result}"
  let core ← Env.run (Solver.getUnsatCore solver)
  -- Core should have exactly 2 elements (p1 and p2), not p3
  return check "unsat core minimal" (core.size == 2)
    s!"expected 2 core elements (not p3), got {core.size}"

def unsatCoreTests : List (IO TestResult) :=
  [ testUnsatCoreBasic
  , testCheckAssumptions
  , testUnsatCoreAssumptions
  , testGetAssertions
  , testUnsatCoreMinimal
  ]

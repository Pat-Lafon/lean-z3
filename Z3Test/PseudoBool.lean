import Z3Test.Harness

open Z3

/-! ## Pseudo-boolean constraint tests -/

/-- atmost: at most 1 of 3 booleans is true -/
def testAtmost : IO TestResult := runTest "Ast.mkAtmost" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  let c := Ast.mkBoolConst ctx "c"
  -- At most 1 of a,b,c is true
  Solver.assert solver (Ast.mkAtmost ctx #[a, b, c] 1)
  -- Force a and b both true → should be unsat
  Solver.assert solver a
  Solver.assert solver b
  let result ← Solver.checkSat solver
  return check "Ast.mkAtmost" (result == .false)
    s!"expected unsat, got {result}"

/-- atmost (sat case): at most 2 of 3 booleans, with 2 forced true -/
def testAtmostSat : IO TestResult := runTest "Ast.mkAtmost (sat)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  let c := Ast.mkBoolConst ctx "c"
  Solver.assert solver (Ast.mkAtmost ctx #[a, b, c] 2)
  Solver.assert solver a
  Solver.assert solver b
  let result ← Solver.checkSat solver
  return check "Ast.mkAtmost (sat)" (result == .true)
    s!"expected sat, got {result}"

/-- atleast: at least 2 of 3 booleans must be true -/
def testAtleast : IO TestResult := runTest "Ast.mkAtleast" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  let c := Ast.mkBoolConst ctx "c"
  -- At least 2 of a,b,c must be true
  Solver.assert solver (Ast.mkAtleast ctx #[a, b, c] 2)
  -- Force all false → should be unsat
  Solver.assert solver (Ast.not ctx a)
  Solver.assert solver (Ast.not ctx b)
  let result ← Solver.checkSat solver
  -- With a=false, b=false, need at least 2 true → impossible
  return check "Ast.mkAtleast" (result == .false)
    s!"expected unsat, got {result}"

/-- pble: weighted sum ≤ k -/
def testPble : IO TestResult := runTest "Ast.mkPble" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let y := Ast.mkBoolConst ctx "y"
  let z := Ast.mkBoolConst ctx "z"
  -- 3*x + 2*y + 1*z ≤ 4
  Solver.assert solver (Ast.mkPble ctx #[x, y, z] #[3, 2, 1] 4)
  -- Force x=true, y=true → 3+2=5 > 4, unsat
  Solver.assert solver x
  Solver.assert solver y
  let result ← Solver.checkSat solver
  return check "Ast.mkPble" (result == .false)
    s!"expected unsat, got {result}"

/-- pbge: weighted sum ≥ k -/
def testPbge : IO TestResult := runTest "Ast.mkPbge" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let y := Ast.mkBoolConst ctx "y"
  -- 5*x + 3*y ≥ 7
  Solver.assert solver (Ast.mkPbge ctx #[x, y] #[5, 3] 7)
  -- Force x=false → 3*y ≤ 3 < 7, unsat
  Solver.assert solver (Ast.not ctx x)
  let result ← Solver.checkSat solver
  return check "Ast.mkPbge" (result == .false)
    s!"expected unsat, got {result}"

/-- pbge (sat case): 5*x + 3*y ≥ 7 with both true → 8 ≥ 7 -/
def testPbgeSat : IO TestResult := runTest "Ast.mkPbge (sat)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let y := Ast.mkBoolConst ctx "y"
  Solver.assert solver (Ast.mkPbge ctx #[x, y] #[5, 3] 7)
  Solver.assert solver x
  Solver.assert solver y
  let result ← Solver.checkSat solver
  return check "Ast.mkPbge (sat)" (result == .true)
    s!"expected sat, got {result}"

/-- pbeq: weighted sum = k -/
def testPbeq : IO TestResult := runTest "Ast.mkPbeq" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  let c := Ast.mkBoolConst ctx "c"
  -- 1*a + 1*b + 1*c = 2 (exactly 2 of 3 must be true)
  Solver.assert solver (Ast.mkPbeq ctx #[a, b, c] #[1, 1, 1] 2)
  -- Force all three true → sum=3 ≠ 2, unsat
  Solver.assert solver a
  Solver.assert solver b
  Solver.assert solver c
  let result ← Solver.checkSat solver
  return check "Ast.mkPbeq" (result == .false)
    s!"expected unsat, got {result}"

/-- pbeq (sat case): exactly 2 of 3 with a=true, b=true, c=false -/
def testPbeqSat : IO TestResult := runTest "Ast.mkPbeq (sat)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let a := Ast.mkBoolConst ctx "a"
  let b := Ast.mkBoolConst ctx "b"
  let c := Ast.mkBoolConst ctx "c"
  Solver.assert solver (Ast.mkPbeq ctx #[a, b, c] #[1, 1, 1] 2)
  Solver.assert solver a
  Solver.assert solver b
  Solver.assert solver (Ast.not ctx c)
  let result ← Solver.checkSat solver
  return check "Ast.mkPbeq (sat)" (result == .true)
    s!"expected sat, got {result}"

def pseudoBoolTests : List (IO TestResult) :=
  [ testAtmost
  , testAtmostSat
  , testAtleast
  , testPble
  , testPbge
  , testPbgeSat
  , testPbeq
  , testPbeqSat
  ]

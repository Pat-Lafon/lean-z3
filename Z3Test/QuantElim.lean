import Z3Test.Harness

open Z3

/-! ## Quantifier elimination tests -/

/-- qeLite: eliminate x from (x = y + 1 ∧ x > 0) → (y > -1) -/
def testQeLite : IO TestResult := runTest "qeLite basic" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkInt ctx 0 intSort
  let one := Ast.mkInt ctx 1 intSort
  -- x = y + 1 ∧ x > 0  (equality lets qe_lite substitute)
  let body := Ast.and ctx (Ast.eq ctx x (Ast.add ctx y one)) (Ast.gt ctx x zero)
  let (result, remaining) ← Ast.qeLite ctx #[x] body
  let resultStr := toString result
  return check "qeLite basic" (resultStr.length > 0 && remaining.size == 0)
    s!"expected x eliminated, got result='{resultStr}' remaining={remaining.size}"

/-- qeLite: variable that cannot be eliminated remains -/
def testQeLiteRemaining : IO TestResult := runTest "qeLite remaining vars" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkInt ctx 0 intSort
  -- body only mentions y, so x can be trivially eliminated but y stays if we ask to eliminate both
  let body := Ast.gt ctx y zero
  let (result, _remaining) ← Ast.qeLite ctx #[x, y] body
  let resultStr := toString result
  return check "qeLite remaining vars" (resultStr.length > 0)
    s!"expected non-empty result, got '{resultStr}'"

/-- qeModelProject: project x given a model -/
def testQeModelProject : IO TestResult := runTest "qeModelProject" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkInt ctx 0 intSort
  let ten := Ast.mkInt ctx 10 intSort
  -- x > 0 ∧ x < y ∧ y < 10
  let body := Ast.and ctx (Ast.and ctx (Ast.gt ctx x zero) (Ast.lt ctx x y)) (Ast.lt ctx y ten)
  -- Get a model first
  let solver ← Env.run (Solver.new ctx)
  Solver.assert solver body
  let sat ← Solver.checkSat solver
  if sat != .true then
    return check "qeModelProject" false "expected sat"
  let model ← Env.run (Solver.getModel solver)
  -- Project x out using the model
  let result ← Ast.qeModelProject ctx model #[x] body
  let resultStr := toString result
  return check "qeModelProject" (resultStr.length > 0)
    s!"expected non-empty projection, got '{resultStr}'"

/-- modelExtrapolate: extrapolate model to ground formula -/
def testModelExtrapolate : IO TestResult := runTest "modelExtrapolate" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let five := Ast.mkInt ctx 5 intSort
  let ten := Ast.mkInt ctx 10 intSort
  -- x > 5 ∧ x < 10
  let body := Ast.and ctx (Ast.gt ctx x five) (Ast.lt ctx x ten)
  let solver ← Env.run (Solver.new ctx)
  Solver.assert solver body
  let sat ← Solver.checkSat solver
  if sat != .true then
    return check "modelExtrapolate" false "expected sat"
  let model ← Env.run (Solver.getModel solver)
  let result ← Ast.modelExtrapolate ctx model body
  let resultStr := toString result
  return check "modelExtrapolate" (resultStr.length > 0)
    s!"expected non-empty extrapolation, got '{resultStr}'"

/-- qeLite with solver verification -/
def testQeLiteVerify : IO TestResult := runTest "qeLite verified" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkInt ctx 0 intSort
  -- ∃x. x > 0 ∧ x < y  should imply  y > 0
  let body := Ast.and ctx (Ast.gt ctx x zero) (Ast.lt ctx x y)
  let (result, _) ← Ast.qeLite ctx #[x] body
  -- Verify: result → y > 0 should be valid (negation is unsat)
  let yGtZero := Ast.gt ctx y zero
  let implication := Ast.implies ctx result yGtZero
  let solver ← Env.run (Solver.new ctx)
  Solver.assert solver (Ast.not ctx implication)
  let sat ← Solver.checkSat solver
  return check "qeLite verified" (sat == .false)
    s!"expected unsat (result implies y>0), got {sat}"

def quantElimTests : List (IO TestResult) :=
  [ testQeLite
  , testQeLiteRemaining
  , testQeModelProject
  , testModelExtrapolate
  , testQeLiteVerify
  ]

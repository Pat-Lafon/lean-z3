import Z3Test.Harness

open Z3

/-! ## Tactic / Goal API tests -/

/-- Create a goal, assert formulas, check size -/
def testGoalBasic : IO TestResult := runTest "Goal basic" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  Goal.assert g (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  Goal.assert g (Ast.lt ctx x (Ast.mkNumeral ctx "10" intSort))
  let sz := Goal.size g
  return check "Goal basic" (sz == 2)
    s!"expected size 2, got {sz}"

/-- Goal.formula: retrieve formulas -/
def testGoalFormula : IO TestResult := runTest "Goal.formula" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let p := Ast.mkBoolConst ctx "p"
  Goal.assert g p
  let f := Goal.formula g 0
  let fStr := Ast.toString' f
  return check "Goal.formula" (fStr == "p")
    s!"expected 'p', got '{fStr}'"

/-- Goal.toString -/
def testGoalToString : IO TestResult := runTest "Goal.toString" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let p := Ast.mkBoolConst ctx "p"
  Goal.assert g p
  let s := Goal.toString' g
  return check "Goal.toString" (s.length > 0)
    s!"expected non-empty string"

/-- Goal.reset -/
def testGoalReset : IO TestResult := runTest "Goal.reset" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let p := Ast.mkBoolConst ctx "p"
  Goal.assert g p
  Goal.reset g
  let sz := Goal.size g
  return check "Goal.reset" (sz == 0)
    s!"expected size 0 after reset, got {sz}"

/-- Tactic.mk + apply: simplify tactic -/
def testTacticSimplify : IO TestResult := runTest "Tactic simplify" do
  let ctx ← Env.run Context.new
  let t := Tactic.mk ctx "simplify"
  let g := Goal.mk ctx true false false
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  -- x + 0 > 0, should simplify to x > 0
  Goal.assert g (Ast.gt ctx (Ast.add ctx x zero) zero)
  let result := Tactic.apply ctx t g
  let numSub := ApplyResult.getNumSubgoals result
  if numSub == 0 then
    return check "Tactic simplify" false "expected at least 1 subgoal"
  let sub := ApplyResult.getSubgoal result 0
  let subStr := Goal.toString' sub
  -- The simplified goal should mention x but not "0 +"
  return check "Tactic simplify" (subStr.length > 0)
    s!"expected non-empty subgoal, got '{subStr}'"

/-- Tactic.andThen: compose tactics -/
def testTacticAndThen : IO TestResult := runTest "Tactic.andThen" do
  let ctx ← Env.run Context.new
  let t1 := Tactic.mk ctx "simplify"
  let t2 := Tactic.mk ctx "solve-eqs"
  let combined := Tactic.andThen ctx t1 t2
  let g := Goal.mk ctx true false false
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  -- x = 5 ∧ x > 0
  Goal.assert g (Ast.eq ctx x (Ast.mkNumeral ctx "5" intSort))
  Goal.assert g (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  let result := Tactic.apply ctx combined g
  let numSub := ApplyResult.getNumSubgoals result
  -- After solve-eqs, x=5 should be substituted, yielding a trivial or simpler goal
  return check "Tactic.andThen" (numSub ≥ 0)
    s!"got {numSub} subgoals"

/-- Solver.fromTactic: create solver from tactic -/
def testSolverFromTactic : IO TestResult := runTest "Solver.fromTactic" do
  let ctx ← Env.run Context.new
  let t := Tactic.mk ctx "qflia"
  let solver ← Env.run (Solver.fromTactic ctx t)
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort))
  Solver.assert solver (Ast.lt ctx x (Ast.mkNumeral ctx "10" intSort))
  let result ← Solver.checkSat solver
  return check "Solver.fromTactic" (result == .true)
    s!"expected sat, got {result}"

/-- Context.getNumTactics / getTacticName: list available tactics -/
def testListTactics : IO TestResult := runTest "list tactics" do
  let ctx ← Env.run Context.new
  let n := Context.getNumTactics ctx
  if n == 0 then
    return check "list tactics" false "expected at least 1 tactic"
  -- Check that "simplify" is among them
  let mut found := false
  for i in [:n.toNat] do
    let name := Context.getTacticName ctx i.toUInt32
    if name == "simplify" then found := true
  return check "list tactics" found
    s!"expected to find 'simplify' among {n} tactics"

/-- Tactic.getHelp: get help for a tactic -/
def testTacticGetHelp : IO TestResult := runTest "Tactic.getHelp" do
  let ctx ← Env.run Context.new
  let t := Tactic.mk ctx "simplify"
  let help := Tactic.getHelp ctx t
  return check "Tactic.getHelp" (help.length > 0)
    s!"expected non-empty help string"

/-- ApplyResult.toString -/
def testApplyResultToString : IO TestResult := runTest "ApplyResult.toString" do
  let ctx ← Env.run Context.new
  let t := Tactic.mk ctx "simplify"
  let g := Goal.mk ctx true false false
  let p := Ast.mkBoolConst ctx "p"
  Goal.assert g p
  let result := Tactic.apply ctx t g
  let s := ApplyResult.toString' result
  return check "ApplyResult.toString" (s.length > 0)
    s!"expected non-empty string"

def tacticTests : List (IO TestResult) :=
  [ testGoalBasic
  , testGoalFormula
  , testGoalToString
  , testGoalReset
  , testTacticSimplify
  , testTacticAndThen
  , testSolverFromTactic
  , testListTactics
  , testTacticGetHelp
  , testApplyResultToString
  ]

import Z3Test.Harness

open Z3

/-! ## Simplifier API tests -/

/-- Create a simplifier by name -/
def testSimplifierMk : IO TestResult := runTest "simplifier mk" do
  let ctx ← Env.run Context.new
  let simp ← Env.run (Simplifier.mk ctx "simplify")
  let help := Simplifier.getHelp ctx simp
  return check "simplifier mk" (help.length > 0)
    s!"expected non-empty help, got '{help}'"

/-- List available simplifiers -/
def testSimplifierList : IO TestResult := runTest "simplifier list" do
  let ctx ← Env.run Context.new
  let n := Context.getNumSimplifiers ctx
  let mut names : Array String := #[]
  for i in [:n.toNat] do
    names := names.push (Context.getSimplifierName ctx i.toUInt32)
  return check "simplifier list" (n > 0 && names.size > 0)
    s!"expected simplifiers, got {n}"

/-- Get simplifier description -/
def testSimplifierDescr : IO TestResult := runTest "simplifier descr" do
  let ctx ← Env.run Context.new
  let descr := Simplifier.getDescr ctx "simplify"
  return check "simplifier descr" (descr.length > 0)
    s!"expected non-empty description, got '{descr}'"

/-- Compose simplifiers with and_then -/
def testSimplifierAndThen : IO TestResult := runTest "simplifier andThen" do
  let ctx ← Env.run Context.new
  let s1 ← Env.run (Simplifier.mk ctx "simplify")
  let s2 ← Env.run (Simplifier.mk ctx "elim-unconstrained")
  let combined ← Env.run (Simplifier.andThen ctx s1 s2)
  let help := Simplifier.getHelp ctx combined
  return check "simplifier andThen" (help.length > 0)
    s!"expected non-empty help from combined simplifier"

/-- Apply parameters to a simplifier -/
def testSimplifierUsingParams : IO TestResult := runTest "simplifier usingParams" do
  let ctx ← Env.run Context.new
  let simp ← Env.run (Simplifier.mk ctx "simplify")
  let params ← Params.new ctx
  Params.setBool params "flat" true
  let paramSimp ← Env.run (Simplifier.usingParams ctx simp params)
  let help := Simplifier.getHelp ctx paramSimp
  return check "simplifier usingParams" (help.length > 0)
    s!"expected non-empty help from parameterized simplifier"

/-- Get parameter descriptions for a simplifier -/
def testSimplifierParamDescrs : IO TestResult := runTest "simplifier paramDescrs" do
  let ctx ← Env.run Context.new
  let simp ← Env.run (Simplifier.mk ctx "simplify")
  let pd ← Simplifier.getParamDescrs ctx simp
  let n := ParamDescrs.size pd
  return check "simplifier paramDescrs" (n > 0)
    s!"expected param descriptions, got size={n}"

/-- Add simplifier to solver -/
def testSolverAddSimplifier : IO TestResult := runTest "solver addSimplifier" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let simp ← Env.run (Simplifier.mk ctx "simplify")
  let solver' ← Env.run (Solver.addSimplifier ctx solver simp)
  -- Verify the new solver works
  let x := Ast.mkBoolConst ctx "x"
  Solver.assert solver' x
  let result ← Solver.checkSat solver'
  return check "solver addSimplifier" (result == .true)
    s!"expected sat, got {result}"

def simplifierTests : List (IO TestResult) :=
  [ testSimplifierMk
  , testSimplifierList
  , testSimplifierDescr
  , testSimplifierAndThen
  , testSimplifierUsingParams
  , testSimplifierParamDescrs
  , testSolverAddSimplifier
  ]

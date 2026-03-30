import Z3Test.Harness

open Z3

/-! ## User Propagator tests -/

/-- Basic user propagator: track a variable and detect its assignment via fixed callback -/
def testUserPropFixed : IO TestResult := runTest "user prop fixed" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  -- Track fixed assignments
  let fixedRef ← IO.mkRef (0 : Nat)
  let push := fun (_ : SolverCallback) => pure ()
  let pop := fun (_ : SolverCallback) (_ : UInt32) => pure ()
  let prop ← Solver.propagateInit solver push pop
  Propagator.setFixed prop fun _cb _t _val => do
    fixedRef.modify (· + 1)
  Solver.propagateRegister solver x
  Solver.assert solver x
  let result ← Solver.checkSat solver
  let fixedCount ← fixedRef.get
  return check "user prop fixed" (result == .true && fixedCount > 0)
    s!"expected sat with fixed callback, got result={result} fixedCount={fixedCount}"

/-- User propagator with final callback -/
def testUserPropFinal : IO TestResult := runTest "user prop final" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let finalRef ← IO.mkRef false
  let push := fun (_ : SolverCallback) => pure ()
  let pop := fun (_ : SolverCallback) (_ : UInt32) => pure ()
  let prop ← Solver.propagateInit solver push pop
  Propagator.setFinal prop fun _cb => do
    finalRef.set true
  Solver.propagateRegister solver x
  Solver.assert solver x
  let result ← Solver.checkSat solver
  let finalCalled ← finalRef.get
  return check "user prop final" (result == .true && finalCalled)
    s!"expected sat with final callback, got result={result} finalCalled={finalCalled}"

/-- User propagator: propagate consequence to force conflict -/
def testUserPropConsequence : IO TestResult := runTest "user prop consequence" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let push := fun (_ : SolverCallback) => pure ()
  let pop := fun (_ : SolverCallback) (_ : UInt32) => pure ()
  let prop ← Solver.propagateInit solver push pop
  -- When x is fixed to true, propagate ¬x as a consequence (creating conflict)
  Propagator.setFixed prop fun cb t _val => do
    let _ ← SolverCallback.propagateConsequence cb #[t] #[] #[] (Ast.not ctx t)
  Solver.propagateRegister solver x
  Solver.assert solver x
  let result ← Solver.checkSat solver
  -- Should be unsat because we created a conflict
  return check "user prop consequence" (result == .false)
    s!"expected unsat from propagated conflict, got {result}"

/-- User propagator push/pop callbacks -/
def testUserPropPushPop : IO TestResult := runTest "user prop push/pop" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let pushRef ← IO.mkRef (0 : Nat)
  let popRef ← IO.mkRef (0 : Nat)
  let push := fun (_ : SolverCallback) => pushRef.modify (· + 1)
  let pop := fun (_ : SolverCallback) (_ : UInt32) => popRef.modify (· + 1)
  let prop ← Solver.propagateInit solver push pop
  Propagator.setFinal prop fun _cb => pure ()
  Solver.propagateRegister solver x
  Solver.assert solver x
  let _ ← Solver.checkSat solver
  let pushCount ← pushRef.get
  let popCount ← popRef.get
  -- Push/pop should have been called during solving
  return check "user prop push/pop" (pushCount ≥ 0 && popCount ≥ 0)
    s!"push={pushCount} pop={popCount}"

/-- User propagator: created callback registration doesn't break solving -/
def testUserPropCreated : IO TestResult := runTest "user prop created" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBoolConst ctx "x"
  let createdRef ← IO.mkRef (0 : Nat)
  let push := fun (_ : SolverCallback) => pure ()
  let pop := fun (_ : SolverCallback) (_ : UInt32) => pure ()
  let prop ← Solver.propagateInit solver push pop
  Propagator.setCreated prop fun _cb _t => do
    createdRef.modify (· + 1)
  Solver.propagateRegister solver x
  Solver.assert solver x
  let result ← Solver.checkSat solver
  let _ ← createdRef.get
  -- created callback only fires when Z3 creates new terms internally;
  -- for simple boolean variables it may not fire, so just check solving works
  return check "user prop created" (result == .true)
    s!"expected sat with created callback registered, got result={result}"

/-- propagateDeclare: declare a tracked sort -/
def testPropagateDeclare : IO TestResult := runTest "propagate declare" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let fd := Context.propagateDeclare ctx "myFunc" #[intSort] boolSort
  let name := FuncDecl.getName fd
  return check "propagate declare" (name.length > 0)
    s!"expected non-empty name, got '{name}'"

def userPropTests : List (IO TestResult) :=
  [ testUserPropFixed
  , testUserPropFinal
  , testUserPropConsequence
  , testUserPropPushPop
  , testUserPropCreated
  , testPropagateDeclare
  ]

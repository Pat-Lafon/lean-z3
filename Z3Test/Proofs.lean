import Z3Test.Harness

open Z3

/-! ## Proof API tests -/

/-- Basic proof: p ∧ ¬p is unsat, proof exists and has a proof rule -/
def testProofBasic : IO TestResult := runTest "proof basic (p ∧ ¬p)" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  Solver.assert solver (Ast.and ctx p (Ast.not ctx p))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof basic (p ∧ ¬p)" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  -- Proof root should be an app node
  let kind := Ast.getAstKind proof
  if kind != .app then
    return check "proof basic (p ∧ ¬p)" false s!"expected app AST kind, got {kind}"
  -- Should have a proof rule
  match Ast.getProofRule? proof with
  | none =>
    return check "proof basic (p ∧ ¬p)" false "root is not a proof rule"
  | some rule =>
    return check "proof basic (p ∧ ¬p)" true
      s!"root proof rule: {rule}"

/-- Proof tree navigation: walk children of proof root -/
def testProofChildren : IO TestResult := runTest "proof children" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  Solver.assert solver (Ast.and ctx p (Ast.not ctx p))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof children" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  let nArgs := Ast.getNumArgs proof
  -- Proof root should have at least one child
  if nArgs == 0 then
    return check "proof children" false "proof root has no children"
  -- Walk all children using getArgs
  let args := Ast.getArgs proof
  if args.size != nArgs.toNat then
    return check "proof children" false
      s!"getArgs returned {args.size} but getNumArgs returned {nArgs}"
  return check "proof children" true

/-- Proof rule identification: verify 'asserted' rule appears for user assertions -/
def testProofAsserted : IO TestResult := runTest "proof asserted rule" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  Solver.assert solver p
  Solver.assert solver (Ast.not ctx p)
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof asserted rule" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  -- Collect all proof rules in the tree
  let rules := Ast.collectProofRules proof
  -- 'asserted' should appear (we asserted facts)
  let hasAsserted := rules.contains .asserted
  return check "proof asserted rule" hasAsserted
    s!"expected 'asserted' rule in proof, got rules: {rules.map toString}"

/-- Proof from SMT-LIB: parse unsat problem, extract proof, walk tree -/
def testProofSMTLIB : IO TestResult := runTest "proof from SMT-LIB" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let formula ← Env.run (Context.parseSMTLIB2String ctx
    "(declare-const x Int) (assert (> x 5)) (assert (< x 3))")
  Solver.assert solver formula
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof from SMT-LIB" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  let rules := Ast.collectProofRules proof
  return check "proof from SMT-LIB" (rules.size > 0)
    s!"expected non-empty proof rules, got none"

/-- Proof rule variety: a more complex unsat problem should use multiple proof rules -/
def testProofRuleVariety : IO TestResult := runTest "proof rule variety" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkNumeral ctx "0" intSort
  -- x > 0 ∧ y > 0 ∧ x + y < 0 is unsat
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.gt ctx y zero)
  Solver.assert solver (Ast.lt ctx (Ast.add ctx x y) zero)
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof rule variety" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  let rules := Ast.collectProofRules proof
  -- Should use more than one type of proof rule
  return check "proof rule variety" (rules.size > 1)
    s!"expected multiple proof rules, got {rules.size}: {rules.map toString}"

/-- Proof tree depth: recursively walk and measure depth -/
def testProofTreeDepth : IO TestResult := runTest "proof tree depth" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  -- p ∧ (p → q) ∧ ¬q is unsat
  Solver.assert solver p
  Solver.assert solver (Ast.implies ctx p q)
  Solver.assert solver (Ast.not ctx q)
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof tree depth" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  -- Measure depth with iterative DFS
  let mut maxDepth : Nat := 0
  let mut stack : Array (Ast × Nat) := #[(proof, 0)]
  while h : stack.size > 0 do
    let (node, depth) := stack[stack.size - 1]
    stack := stack.pop
    if depth > maxDepth then maxDepth := depth
    if node.getAstKind == .app then
      if node.getProofRule?.isSome then
        let n := node.getNumArgs
        for i in List.range n.toNat do
          stack := stack.push (node.getArg i.toUInt32, depth + 1)
  -- Proof for p ∧ (p→q) ∧ ¬q should have non-trivial depth
  return check "proof tree depth" (maxDepth > 0)
    s!"expected depth > 0, got {maxDepth}"

/-- AstKind: verify kinds for different node types -/
def testAstKinds : IO TestResult := runTest "AST kinds" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let five := Ast.mkNumeral ctx "5" intSort
  let sum := Ast.add ctx x five
  -- x is an app (constant = nullary function application)
  let xKind := Ast.getAstKind x
  if xKind != .app then
    return check "AST kinds" false s!"expected x to be app, got {xKind}"
  -- 5 is a numeral
  let fiveKind := Ast.getAstKind five
  if fiveKind != .numeral then
    return check "AST kinds" false s!"expected 5 to be numeral, got {fiveKind}"
  -- x + 5 is an app
  let sumKind := Ast.getAstKind sum
  if sumKind != .app then
    return check "AST kinds" false s!"expected x+5 to be app, got {sumKind}"
  -- bound variable is a var
  let bound := Ast.mkBound ctx 0 intSort
  let boundKind := Ast.getAstKind bound
  if boundKind != .var then
    return check "AST kinds" false s!"expected bound to be var, got {boundKind}"
  -- quantifier
  let body := Ast.gt ctx bound (Ast.mkNumeral ctx "0" intSort)
  let forall_ ← Env.run (Ast.mkForall ctx #[intSort] #["x"] body 0)
  let forallKind := Ast.getAstKind forall_
  return check "AST kinds" (forallKind == .quantifier)
    s!"expected forall to be quantifier, got {forallKind}"

/-- On-clause collector: register callback, solve unsat problem, check we got clauses -/
def testOnClause : IO TestResult := runTest "on-clause collector" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let handle ← Solver.registerOnClause solver
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  let ten := Ast.mkNumeral ctx "10" (Srt.mkInt ctx)
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.lt ctx x ten)
  Solver.assert solver (Ast.lt ctx x zero)
  let result ← Solver.checkSat solver
  if result != .false then
    return check "on-clause collector" false s!"expected unsat, got {result}"
  let clauses ← OnClauseHandle.getClauses handle
  return check "on-clause collector" (clauses.size > 0)
    s!"expected collected clauses, got {clauses.size}"

/-- On-clause clear: register, solve, clear, check empty -/
def testOnClauseClear : IO TestResult := runTest "on-clause clear" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let handle ← Solver.registerOnClause solver
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" (Srt.mkInt ctx)
  let ten := Ast.mkNumeral ctx "10" (Srt.mkInt ctx)
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.lt ctx x ten)
  Solver.assert solver (Ast.lt ctx x zero)
  let _ ← Solver.checkSat solver
  let before ← OnClauseHandle.getClauses handle
  if before.size == 0 then
    return check "on-clause clear" false "expected clauses before clear"
  OnClauseHandle.clear handle
  let after ← OnClauseHandle.getClauses handle
  return check "on-clause clear" (after.size == 0)
    s!"expected 0 clauses after clear, got {after.size}"

def proofTests : List (IO TestResult) :=
  [ testProofBasic
  , testProofChildren
  , testProofAsserted
  , testProofSMTLIB
  , testProofRuleVariety
  , testProofTreeDepth
  , testAstKinds
  , testOnClause
  , testOnClauseClear
  ]

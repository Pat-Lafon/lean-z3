import Z3Test.Harness

open Z3

/-! ## Tests translated from z3-rs -/

/-- z3-rs: test_solving_for_model — multiple int constraints with model value verification -/
def testSolvingForModel : IO TestResult := runTest "solving for model (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let zero := Ast.mkNumeral ctx "0" intSort
  let seven := Ast.mkNumeral ctx "7" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  -- x > y
  Solver.assert solver (Ast.gt ctx x y)
  -- y > 0
  Solver.assert solver (Ast.gt ctx y zero)
  -- x + 2 > 7
  Solver.assert solver (Ast.gt ctx (Ast.add ctx x two) seven)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "solving for model (z3-rs)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let xVal ← Env.run (Model.eval model x true)
  let yVal ← Env.run (Model.eval model y true)
  let xInt := (Ast.getNumeralString xVal).toInt!
  let yInt := (Ast.getNumeralString yVal).toInt!
  -- Verify constraints hold in the model
  let c1 := xInt > yInt
  let c2 := yInt > 0
  let c3 := xInt + 2 > 7
  return check "solving for model (z3-rs)" (c1 && c2 && c3)
    s!"model x={xInt}, y={yInt} doesn't satisfy constraints"

/-- z3-rs: test_params — create params, set bool, apply to solver -/
def testParamsZ3rs : IO TestResult := runTest "params (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let params ← Params.new ctx
  Params.setBool params "model" true
  Solver.setParams solver params
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.eq ctx x five)
  let result ← Solver.checkSat solver
  return check "params (z3-rs)" (result == .true)
    s!"expected sat, got {result}"

/-- z3-rs: test_arbitrary_size_int — very large integer numerals -/
def testArbitrarySizeInt : IO TestResult := runTest "arbitrary size int (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let bigNum := Ast.mkNumeral ctx "99999999999999999999998" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let expected := Ast.mkNumeral ctx "99999999999999999999999" intSort
  Solver.assert solver (Ast.eq ctx (Ast.add ctx bigNum one) expected)
  let result ← Solver.checkSat solver
  return check "arbitrary size int (z3-rs)" (result == .true)
    s!"expected sat, got {result}"

/-- z3-rs: test_arbitrary_size_real — rational numerals -/
def testArbitrarySizeReal : IO TestResult := runTest "arbitrary size real (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let realSort := Srt.mkReal ctx
  let x := Ast.mkConst ctx "x" realSort
  -- x = 1/3
  let ratio := Ast.mkNumeral ctx "1/3" realSort
  Solver.assert solver (Ast.eq ctx x ratio)
  let result ← Solver.checkSat solver
  return check "arbitrary size real (z3-rs)" (result == .true)
    s!"expected sat, got {result}"

/-- z3-rs: test_push_pop — solver push/pop scopes -/
def testPushPop : IO TestResult := runTest "push/pop (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  -- x > 5
  Solver.assert solver (Ast.gt ctx x five)
  Solver.push solver
  -- x < 3 (contradicts x > 5)
  let three := Ast.mkNumeral ctx "3" intSort
  Solver.assert solver (Ast.lt ctx x three)
  let r1 ← Solver.checkSat solver
  if r1 != .false then
    return check "push/pop (z3-rs)" false s!"expected unsat after push, got {r1}"
  Solver.pop solver 1
  -- After pop, only x > 5 remains — should be sat
  let r2 ← Solver.checkSat solver
  if r2 != .true then
    return check "push/pop (z3-rs)" false s!"expected sat after pop, got {r2}"
  -- x < 10 — still sat
  Solver.assert solver (Ast.lt ctx x ten)
  let r3 ← Solver.checkSat solver
  return check "push/pop (z3-rs)" (r3 == .true)
    s!"expected sat with x > 5 ∧ x < 10, got {r3}"

/-- z3-rs: test_solver_reset -/
def testSolverReset : IO TestResult := runTest "solver reset (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  -- x = 5 ∧ x = 3 is unsat
  Solver.assert solver (Ast.eq ctx x five)
  Solver.assert solver (Ast.eq ctx x three)
  let r1 ← Solver.checkSat solver
  if r1 != .false then
    return check "solver reset (z3-rs)" false s!"expected unsat, got {r1}"
  -- Reset clears all assertions
  Solver.reset solver
  Solver.assert solver (Ast.eq ctx x five)
  let r2 ← Solver.checkSat solver
  return check "solver reset (z3-rs)" (r2 == .true)
    s!"expected sat after reset, got {r2}"

/-- z3-rs: test_ite — if-then-else term -/
def testIte : IO TestResult := runTest "ite (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  -- x = ite(1 < 2, 10, 20)  →  x = 10
  let cond := Ast.lt ctx one two
  let twenty := Ast.mkNumeral ctx "20" intSort
  Solver.assert solver (Ast.eq ctx x (Ast.ite ctx cond ten twenty))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "ite (z3-rs)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "ite (z3-rs)" (valStr == "10")
    s!"expected x = 10, got x = {valStr}"

/-- z3-rs: model iteration — iterate model constants -/
def testModelIteration : IO TestResult := runTest "model iteration (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let a := Ast.mkIntConst ctx "a"
  let b := Ast.mkIntConst ctx "b"
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  Solver.assert solver (Ast.eq ctx a two)
  Solver.assert solver (Ast.eq ctx b three)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "model iteration (z3-rs)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let numConsts := Model.getNumConsts model
  if numConsts != 2 then
    return check "model iteration (z3-rs)" false
      s!"expected 2 constants, got {numConsts}"
  -- Collect all (name, value) pairs
  let mut pairs : List (String × String) := []
  for i in List.range numConsts.toNat do
    let fd := Model.getConstDecl model i.toUInt32
    let name := FuncDecl.getName fd
    let val ← Env.run (Model.getConstInterp model fd)
    let valStr := Ast.getNumeralString val
    pairs := (name, valStr) :: pairs
  let hasA := pairs.any fun (n, v) => n == "a" && v == "2"
  let hasB := pairs.any fun (n, v) => n == "b" && v == "3"
  return check "model iteration (z3-rs)" (hasA && hasB)
    s!"expected a=2, b=3 in model, got {pairs}"

/-- z3-rs: test_implies — implication and model -/
def testImplies : IO TestResult := runTest "implies (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  -- p ∧ (p → q)
  Solver.assert solver p
  Solver.assert solver (Ast.implies ctx p q)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "implies (z3-rs)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let qVal ← Env.run (Model.eval model q true)
  let qStr := toString qVal
  return check "implies (z3-rs)" (qStr == "true")
    s!"expected q = true, got q = {qStr}"

/-- z3-rs: test_or — disjunction -/
def testOr : IO TestResult := runTest "or (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  -- ¬p ∧ (p ∨ q) → q must be true
  Solver.assert solver (Ast.not ctx p)
  Solver.assert solver (Ast.or ctx p q)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "or (z3-rs)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let qVal ← Env.run (Model.eval model q true)
  let qStr := toString qVal
  return check "or (z3-rs)" (qStr == "true")
    s!"expected q = true, got q = {qStr}"

/-- z3-rs: nested push/pop like test_set_membership -/
def testNestedPushPop : IO TestResult := runTest "nested push/pop (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  let five := Ast.mkNumeral ctx "5" intSort
  -- x > 0
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.push solver
  -- scope 1: x > 10
  Solver.assert solver (Ast.gt ctx x ten)
  Solver.push solver
  -- scope 2: x < 5 (contradicts x > 10)
  Solver.assert solver (Ast.lt ctx x five)
  let r1 ← Solver.checkSat solver
  if r1 != .false then
    return check "nested push/pop (z3-rs)" false s!"scope 2: expected unsat, got {r1}"
  Solver.pop solver 1
  -- back to scope 1: x > 0 ∧ x > 10 — sat
  let r2 ← Solver.checkSat solver
  if r2 != .true then
    return check "nested push/pop (z3-rs)" false s!"scope 1: expected sat, got {r2}"
  Solver.pop solver 1
  -- back to base: x > 0 — sat
  let r3 ← Solver.checkSat solver
  return check "nested push/pop (z3-rs)" (r3 == .true)
    s!"base: expected sat, got {r3}"

/-- z3-rs: test_bitvectors — basic bitvector sort and constant creation -/
def testBitvectors : IO TestResult := runTest "bitvectors (z3-rs)" do
  let ctx ← Env.run Context.new
  let bvSort := Srt.mkBv ctx 64
  let bvName := Srt.getName bvSort
  let bvSize := Srt.getBvSize bvSort
  if bvSize != 64 then
    return check "bitvectors (z3-rs)" false s!"expected BV size 64, got {bvSize}"
  -- Create BV constants
  let x := Ast.mkBvConst ctx "x" 64
  let xSort := Ast.getSort x
  let xSortKind := Srt.getKindRaw xSort
  -- Z3_BV_SORT = 4
  return check "bitvectors (z3-rs)" (xSortKind == 4 && bvName == "bv")
    s!"expected BV sort kind 4, got {xSortKind}; name={bvName}"

/-- z3-rs: test_smtlib2 with real constraints -/
def testSMTLIB2Real : IO TestResult := runTest "SMT-LIB2 real (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let problem := "(declare-const x Real)\n(declare-const y Real)\n(declare-const z Real)\n(assert (= (- (+ (* 3 x) (* 2 y)) z) 1))\n(assert (= (+ (- (* 2 x) (* 2 y)) (* 4 z)) -2))"
  let formula ← Env.run (Context.parseSMTLIB2String ctx problem)
  Solver.assert solver formula
  let result ← Solver.checkSat solver
  return check "SMT-LIB2 real (z3-rs)" (result == .true)
    s!"expected sat, got {result}"

/-- z3-rs: test_real_cmp (∀x:Real, x < x+1) -/
def testRealForall : IO TestResult := runTest "real forall (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let realSort := Srt.mkReal ctx
  let body :=
    let x := Ast.mkBound ctx 0 realSort
    let one := Ast.mkNumeral ctx "1" realSort
    Ast.lt ctx x (Ast.add ctx x one)
  let forall_ ← Env.run (Ast.mkForall ctx #[realSort] #["x"] body 0)
  Solver.assert solver forall_
  let result ← Solver.checkSat solver
  return check "real forall (z3-rs)" (result == .true)
    s!"expected sat, got {result}"

/-- Solution enumeration: find all solutions by blocking previous models -/
def testSolutionEnumeration : IO TestResult := runTest "solution enumeration (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let one := Ast.mkNumeral ctx "1" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  -- 1 ≤ x ≤ 3
  Solver.assert solver (Ast.le ctx one x)
  Solver.assert solver (Ast.le ctx x three)
  let mut count := 0
  let mut values : List String := []
  -- Enumerate all solutions
  for _ in List.range 10 do  -- safety bound
    let result ← Solver.checkSat solver
    if result != .true then break
    let model ← Env.run (Solver.getModel solver)
    let val ← Env.run (Model.eval model x true)
    let valStr := Ast.getNumeralString val
    values := valStr :: values
    -- Block this solution: x ≠ val
    Solver.assert solver (Ast.not ctx (Ast.eq ctx x val))
    count := count + 1
  -- Should find exactly 3 solutions: 1, 2, 3
  let sorted := values.mergeSort (· < ·)
  return check "solution enumeration (z3-rs)" (count == 3 && sorted == ["1", "2", "3"])
    s!"expected 3 solutions [1,2,3], got {count} solutions: {sorted}"

/-- z3-rs: uninterpreted sort with constants -/
def testUninterpretedSort : IO TestResult := runTest "uninterpreted sort (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let mySort := Srt.mkUninterpreted ctx "MySort"
  let a := Ast.mkConst ctx "a" mySort
  let b := Ast.mkConst ctx "b" mySort
  -- a = b is sat (uninterpreted)
  Solver.assert solver (Ast.eq ctx a b)
  let r1 ← Solver.checkSat solver
  if r1 != .true then
    return check "uninterpreted sort (z3-rs)" false s!"expected sat for a=b, got {r1}"
  -- a = b ∧ a ≠ b is unsat
  Solver.push solver
  Solver.assert solver (Ast.not ctx (Ast.eq ctx a b))
  let r2 ← Solver.checkSat solver
  Solver.pop solver 1
  return check "uninterpreted sort (z3-rs)" (r2 == .false)
    s!"expected unsat for a=b ∧ a≠b, got {r2}"

/-- z3-rs: datatype with constructor query and tester/accessor verification -/
def testDatatypeMaybeInt : IO TestResult := runTest "datatype MaybeInt (z3-rs)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  -- Create MaybeInt datatype: Nothing | Just(int)
  let nothingCon ← Env.run (Constructor.mk ctx "Nothing" "isNothing" #[] #[] #[])
  let justCon ← Env.run (Constructor.mk ctx "Just" "isJust"
    #["val"] #[intSort] #[0])
  let _maybeSort ← Env.run (Srt.mkDatatype ctx "MaybeInt" #[nothingCon, justCon])
  -- Query constructors
  let (nothingDecl, isNothingDecl, _nothingAccessors) ←
    Env.run (Constructor.query nothingCon 0)
  let (justDecl, isJustDecl, justAccessors) ←
    Env.run (Constructor.query justCon 1)
  -- Verify names
  let nName := FuncDecl.getName nothingDecl
  let jName := FuncDecl.getName justDecl
  let isNName := FuncDecl.getName isNothingDecl
  let isJName := FuncDecl.getName isJustDecl
  if nName != "Nothing" then
    return check "datatype MaybeInt (z3-rs)" false s!"expected 'Nothing', got '{nName}'"
  if jName != "Just" then
    return check "datatype MaybeInt (z3-rs)" false s!"expected 'Just', got '{jName}'"
  -- Z3 may rename recognizers; just verify they exist and are non-empty
  if isNName.isEmpty then
    return check "datatype MaybeInt (z3-rs)" false "expected non-empty recognizer name for Nothing"
  if isJName.isEmpty then
    return check "datatype MaybeInt (z3-rs)" false "expected non-empty recognizer name for Just"
  -- Verify accessor
  if justAccessors.size != 1 then
    return check "datatype MaybeInt (z3-rs)" false
      s!"expected 1 accessor, got {justAccessors.size}"
  match justAccessors[0]? with
  | some acc =>
    let accName := FuncDecl.getName acc
    return check "datatype MaybeInt (z3-rs)" (accName == "val")
      s!"expected accessor 'val', got '{accName}'"
  | none =>
    return check "datatype MaybeInt (z3-rs)" false "accessor array empty"

/-- Proof production: context with proofs enabled, check unsat, extract proof -/
def testProofProduction : IO TestResult := runTest "proof production" do
  let ctx ← Env.run Context.newWithProofs
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  -- p ∧ ¬p is unsat
  Solver.assert solver (Ast.and ctx p (Ast.not ctx p))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "proof production" false s!"expected unsat, got {result}"
  let proof ← Env.run (Solver.getProof solver)
  let proofStr := toString proof
  return check "proof production" (proofStr.length > 0)
    s!"expected non-empty proof, got empty string"

def z3rsTests : List (IO TestResult) :=
  [ testSolvingForModel
  , testParamsZ3rs
  , testArbitrarySizeInt
  , testArbitrarySizeReal
  , testPushPop
  , testSolverReset
  , testIte
  , testModelIteration
  , testImplies
  , testOr
  , testNestedPushPop
  , testBitvectors
  , testSMTLIB2Real
  , testRealForall
  , testSolutionEnumeration
  , testUninterpretedSort
  , testDatatypeMaybeInt
  , testProofProduction
  ]

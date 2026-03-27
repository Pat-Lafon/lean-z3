import Z3Test.Harness

open Z3

/-! ## Core binding tests -/

def testContextCreation : IO TestResult := runTest "Context.new" do
  let _ctx ← Env.run Context.new
  return check "Context.new" true

def testIntSat : IO TestResult := runTest "int sat (x > 0 ∧ x < 10)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.lt ctx x ten)
  let result ← Solver.checkSat solver
  return check "int sat (x > 0 ∧ x < 10)" (result == .true)
    s!"expected sat, got {result}"

def testIntUnsat : IO TestResult := runTest "int unsat (x > 0 ∧ x < 0)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  Solver.assert solver (Ast.gt ctx x zero)
  Solver.assert solver (Ast.lt ctx x zero)
  let result ← Solver.checkSat solver
  return check "int unsat (x > 0 ∧ x < 0)" (result == .false)
    s!"expected unsat, got {result}"

def testModelEval : IO TestResult := runTest "model eval" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.eq ctx x five)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "model eval" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "model eval" (valStr == "5")
    s!"expected x = 5, got x = {valStr}"

def testBoolSat : IO TestResult := runTest "bool sat (p ∧ ¬q)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  let q := Ast.mkBoolConst ctx "q"
  Solver.assert solver (Ast.and ctx p (Ast.not ctx q))
  let result ← Solver.checkSat solver
  return check "bool sat (p ∧ ¬q)" (result == .true)
    s!"expected sat, got {result}"

def testBoolUnsat : IO TestResult := runTest "bool unsat (p ∧ ¬p)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let p := Ast.mkBoolConst ctx "p"
  Solver.assert solver (Ast.and ctx p (Ast.not ctx p))
  let result ← Solver.checkSat solver
  return check "bool unsat (p ∧ ¬p)" (result == .false)
    s!"expected unsat, got {result}"

def testArithmetic : IO TestResult := runTest "arithmetic (2x + 3 = 11)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let eleven := Ast.mkNumeral ctx "11" intSort
  let lhs := Ast.add ctx (Ast.mul ctx two x) three
  Solver.assert solver (Ast.eq ctx lhs eleven)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "arithmetic (2x + 3 = 11)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  return check "arithmetic (2x + 3 = 11)" (valStr == "4")
    s!"expected x = 4, got x = {valStr}"

def testForallUnsat : IO TestResult := runTest "forall (¬(∀x, x>0 → x≥1) is unsat)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let body :=
    let x := Ast.mkBound ctx 0 intSort
    let zero := Ast.mkNumeral ctx "0" intSort
    let one := Ast.mkNumeral ctx "1" intSort
    Ast.implies ctx (Ast.gt ctx x zero) (Ast.ge ctx x one)
  let forall_ ← Env.run (Ast.mkForall ctx #[intSort] #["x"] body 0)
  Solver.assert solver (Ast.not ctx forall_)
  let result ← Solver.checkSat solver
  return check "forall (¬(∀x, x>0 → x≥1) is unsat)" (result == .false)
    s!"expected unsat, got {result}"

def testExistsSat : IO TestResult := runTest "exists (∃x, x > 100) is sat" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let body :=
    let x := Ast.mkBound ctx 0 intSort
    let hundred := Ast.mkNumeral ctx "100" intSort
    Ast.gt ctx x hundred
  let exists_ ← Env.run (Ast.mkExists ctx #[intSort] #["x"] body 0)
  Solver.assert solver exists_
  let result ← Solver.checkSat solver
  return check "exists (∃x, x > 100) is sat" (result == .true)
    s!"expected sat, got {result}"

def testDatatype : IO TestResult := runTest "datatype (Pair)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let pairCon ← Env.run (Constructor.mk ctx "mkPair" "is-mkPair"
    #["fst", "snd"] #[intSort, intSort] #[0, 0])
  let pairSort ← Env.run (Srt.mkDatatype ctx "Pair" #[pairCon])
  let sortName := Srt.getName pairSort
  if sortName != "Pair" then
    return check "datatype (Pair)" false s!"expected sort name 'Pair', got '{sortName}'"
  let (_mkPairDecl, _isPairDecl, accessors) ← Env.run (Constructor.query pairCon 2)
  return check "datatype (Pair)" (accessors.size == 2)
    s!"expected 2 accessors, got {accessors.size}"

def testSolverToString : IO TestResult := runTest "solver toString" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.gt ctx x five)
  let s := toString solver
  let parts := s.splitOn "x"
  return check "solver toString" (parts.length > 1)
    s!"expected solver string to mention 'x', got: {s}"

def testSortKind : IO TestResult := runTest "sort kinds" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let bvSort := Srt.mkBv ctx 32
  -- Z3_BOOL_SORT=1, Z3_INT_SORT=2, Z3_BV_SORT=4
  let intKind := Srt.getKindRaw intSort
  let boolKind := Srt.getKindRaw boolSort
  let bvKind := Srt.getKindRaw bvSort
  if intKind != 2 then
    return check "sort kinds" false s!"expected Int sort kind (2), got {intKind}"
  if boolKind != 1 then
    return check "sort kinds" false s!"expected Bool sort kind (1), got {boolKind}"
  return check "sort kinds" (bvKind == 4)
    s!"expected BitVec sort kind (4), got {bvKind}"

def testParseSMTLIB2 : IO TestResult := runTest "parse SMT-LIB2" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let formula ← Env.run (Context.parseSMTLIB2String ctx
    "(declare-const x Int) (assert (> x 42))")
  Solver.assert solver formula
  let result ← Solver.checkSat solver
  if result != .true then
    return check "parse SMT-LIB2" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let x := Ast.mkIntConst ctx "x"
  let val ← Env.run (Model.eval model x true)
  let valStr := Ast.getNumeralString val
  let valInt := valStr.toInt!
  return check "parse SMT-LIB2" (valInt > 42)
    s!"expected x > 42, got x = {valStr}"

def testMultipleContexts : IO TestResult := runTest "multiple contexts" do
  let ctx1 ← Env.run Context.new
  let ctx2 ← Env.run Context.new
  let s1 ← Solver.new ctx1
  let s2 ← Solver.new ctx2
  let x1 := Ast.mkIntConst ctx1 "x"
  let x2 := Ast.mkIntConst ctx2 "x"
  let intSort1 := Srt.mkInt ctx1
  let intSort2 := Srt.mkInt ctx2
  Solver.assert s1 (Ast.eq ctx1 x1 (Ast.mkNumeral ctx1 "1" intSort1))
  Solver.assert s2 (Ast.eq ctx2 x2 (Ast.mkNumeral ctx2 "2" intSort2))
  let r1 ← Solver.checkSat s1
  let r2 ← Solver.checkSat s2
  if r1 != .true || r2 != .true then
    return check "multiple contexts" false s!"expected both sat, got {r1}, {r2}"
  let m1 ← Env.run (Solver.getModel s1)
  let m2 ← Env.run (Solver.getModel s2)
  let v1 := Ast.getNumeralString (← Env.run (Model.eval m1 x1 true))
  let v2 := Ast.getNumeralString (← Env.run (Model.eval m2 x2 true))
  return check "multiple contexts" (v1 == "1" && v2 == "2")
    s!"expected x=1, x=2, got x={v1}, x={v2}"

def basicTests : List (IO TestResult) :=
  [ testContextCreation
  , testIntSat
  , testIntUnsat
  , testModelEval
  , testBoolSat
  , testBoolUnsat
  , testArithmetic
  , testForallUnsat
  , testExistsSat
  , testDatatype
  , testSolverToString
  , testSortKind
  , testParseSMTLIB2
  , testMultipleContexts
  ]

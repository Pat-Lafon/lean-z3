import Z3Test.Harness

open Z3

/-! ## Extended quantifier and params tests -/

/-- mkForallConst: ∀x. x > 0 → x ≥ 1 (negation is unsat) -/
def testForallConst : IO TestResult := runTest "forallConst (∀x. x>0 → x≥1)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let body := Ast.implies ctx (Ast.gt ctx x zero) (Ast.ge ctx x one)
  let forall_ ← Env.run (Ast.mkForallConst ctx 0 #[x] #[] body)
  Solver.assert solver (Ast.not ctx forall_)
  let result ← Solver.checkSat solver
  return check "forallConst (∀x. x>0 → x≥1)" (result == .false)
    s!"expected unsat, got {result}"

/-- mkExistsConst: ∃x. x > 100 (sat) -/
def testExistsConst : IO TestResult := runTest "existsConst (∃x. x>100)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let hundred := Ast.mkNumeral ctx "100" intSort
  let body := Ast.gt ctx x hundred
  let exists_ ← Env.run (Ast.mkExistsConst ctx 0 #[x] #[] body)
  Solver.assert solver exists_
  let result ← Solver.checkSat solver
  return check "existsConst (∃x. x>100)" (result == .true)
    s!"expected sat, got {result}"

/-- mkForallConst with pattern trigger -/
def testForallConstWithPattern : IO TestResult := runTest "forallConst with pattern" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let f := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let fx := Ast.mkApp ctx f #[x]
  let zero := Ast.mkNumeral ctx "0" intSort
  -- ∀x. f(x) > 0, with pattern {f(x)}
  let body := Ast.gt ctx fx zero
  let pat := Ast.mkPattern ctx #[fx]
  let forall_ ← Env.run (Ast.mkForallConst ctx 0 #[x] #[pat] body)
  Solver.assert solver forall_
  -- f(5) should be > 0
  let five := Ast.mkNumeral ctx "5" intSort
  let f5 := Ast.mkApp ctx f #[five]
  Solver.assert solver (Ast.gt ctx f5 zero)
  let result ← Solver.checkSat solver
  return check "forallConst with pattern" (result == .true)
    s!"expected sat, got {result}"

/-- mkQuantifierEx: forall with id and patterns -/
def testQuantifierEx : IO TestResult := runTest "quantifierEx (forall with id)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let body :=
    let x := Ast.mkBound ctx 0 intSort
    let zero := Ast.mkNumeral ctx "0" intSort
    let one := Ast.mkNumeral ctx "1" intSort
    Ast.implies ctx (Ast.gt ctx x zero) (Ast.ge ctx x one)
  let forall_ ← Env.run (Ast.mkQuantifierEx ctx true 0
    "my_quantifier" "my_skolem"
    #[] #[] #[intSort] #["x"] body)
  Solver.assert solver (Ast.not ctx forall_)
  let result ← Solver.checkSat solver
  return check "quantifierEx (forall with id)" (result == .false)
    s!"expected unsat, got {result}"

/-- mkQuantifierEx: exists variant -/
def testQuantifierExExists : IO TestResult := runTest "quantifierEx (exists)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let body :=
    let x := Ast.mkBound ctx 0 intSort
    let hundred := Ast.mkNumeral ctx "100" intSort
    Ast.gt ctx x hundred
  let exists_ ← Env.run (Ast.mkQuantifierEx ctx false 0
    "q_id" "sk_id" #[] #[] #[intSort] #["x"] body)
  Solver.assert solver exists_
  let result ← Solver.checkSat solver
  return check "quantifierEx (exists)" (result == .true)
    s!"expected sat, got {result}"

/-- mkLambda: create lambda f = λx. x + 1, apply it -/
def testLambda : IO TestResult := runTest "lambda (λx. x+1)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let one := Ast.mkNumeral ctx "1" intSort
  let body := Ast.add ctx (Ast.mkBound ctx 0 intSort) one
  let lam ← Env.run (Ast.mkLambda ctx #[intSort] #["x"] body)
  -- The lambda should be recognized as a lambda
  let isLam := Ast.isLambda lam
  return check "lambda (λx. x+1)" isLam
    s!"expected isLambda = true"

/-- mkLambdaConst: create lambda from constants -/
def testLambdaConst : IO TestResult := runTest "lambdaConst (λx. x+1)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let one := Ast.mkNumeral ctx "1" intSort
  let body := Ast.add ctx x one
  let lam ← Env.run (Ast.mkLambdaConst ctx #[x] body)
  let isLam := Ast.isLambda lam
  return check "lambdaConst (λx. x+1)" isLam
    s!"expected isLambda = true"

/-- Params.setDouble: set a double parameter -/
def testParamsSetDouble : IO TestResult := runTest "Params.setDouble" do
  let ctx ← Env.run Context.new
  let params ← Params.new ctx
  Params.setDouble params "timeout" 5000.0
  let s := toString params
  return check "Params.setDouble" (s.length > 0)
    s!"expected non-empty params string, got: {s}"

/-- Params.setSymbol: set a symbol parameter -/
def testParamsSetSymbol : IO TestResult := runTest "Params.setSymbol" do
  let ctx ← Env.run Context.new
  let params ← Params.new ctx
  Params.setSymbol params "some_param" "some_value"
  let s := toString params
  return check "Params.setSymbol" (s.length > 0)
    s!"expected non-empty params string, got: {s}"

/-- Params.toString: verify string representation contains set values -/
def testParamsToString : IO TestResult := runTest "Params.toString" do
  let ctx ← Env.run Context.new
  let params ← Params.new ctx
  Params.setUInt params "timeout" 1000
  Params.setBool params "model" true
  let s := toString params
  let hasTimeout := (s.splitOn "timeout").length > 1
  let hasModel := (s.splitOn "model").length > 1
  return check "Params.toString" (hasTimeout && hasModel)
    s!"expected params string to contain 'timeout' and 'model', got: {s}"

/-- Multi-variable forallConst: ∀x y. x < y → x + 1 ≤ y (negation unsat) -/
def testForallConstMultiVar : IO TestResult := runTest "forallConst multi-var" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let one := Ast.mkNumeral ctx "1" intSort
  let body := Ast.implies ctx (Ast.lt ctx x y) (Ast.le ctx (Ast.add ctx x one) y)
  let forall_ ← Env.run (Ast.mkForallConst ctx 0 #[x, y] #[] body)
  Solver.assert solver (Ast.not ctx forall_)
  let result ← Solver.checkSat solver
  return check "forallConst multi-var" (result == .false)
    s!"expected unsat, got {result}"

def quantifierTests : List (IO TestResult) :=
  [ testForallConst
  , testExistsConst
  , testForallConstWithPattern
  , testQuantifierEx
  , testQuantifierExExists
  , testLambda
  , testLambdaConst
  , testParamsSetDouble
  , testParamsSetSymbol
  , testParamsToString
  , testForallConstMultiVar
  ]

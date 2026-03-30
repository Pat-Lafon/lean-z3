import Z3Test.Harness

open Z3

/-! ## Substitution & simplification tests -/

/-- simplify: (x + 0) simplifies to x -/
def testSimplify : IO TestResult := runTest "simplify (x + 0 → x)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  let expr := Ast.add ctx x zero
  let simplified := Ast.simplify ctx expr
  let s := toString simplified
  return check "simplify (x + 0 → x)" (s == "x")
    s!"expected 'x', got '{s}'"

/-- simplify: (true ∧ p) simplifies to p -/
def testSimplifyBool : IO TestResult := runTest "simplify (true ∧ p → p)" do
  let ctx ← Env.run Context.new
  let p := Ast.mkBoolConst ctx "p"
  let t := Ast.mkBool ctx true
  let expr := Ast.and ctx t p
  let simplified := Ast.simplify ctx expr
  let s := toString simplified
  return check "simplify (true ∧ p → p)" (s == "p")
    s!"expected 'p', got '{s}'"

/-- simplify: constant expression (2 + 3) simplifies to 5 -/
def testSimplifyConst : IO TestResult := runTest "simplify (2 + 3 → 5)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let expr := Ast.add ctx two three
  let simplified := Ast.simplify ctx expr
  let s := Ast.getNumeralString simplified
  return check "simplify (2 + 3 → 5)" (s == "5")
    s!"expected '5', got '{s}'"

/-- simplifyEx: simplify with custom params -/
def testSimplifyEx : IO TestResult := runTest "simplifyEx" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let zero := Ast.mkNumeral ctx "0" intSort
  let expr := Ast.add ctx x zero
  let params ← Params.new ctx
  let simplified := Ast.simplifyEx ctx expr params
  let s := toString simplified
  return check "simplifyEx" (s == "x")
    s!"expected 'x', got '{s}'"

/-- substitute: replace x with 5 in (x + 1) -/
def testSubstitute : IO TestResult := runTest "substitute (x → 5 in x+1)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let one := Ast.mkNumeral ctx "1" intSort
  let five := Ast.mkNumeral ctx "5" intSort
  let expr := Ast.add ctx x one
  let result ← Env.run (Ast.substitute ctx expr #[x] #[five])
  -- After substitution: 5 + 1, simplify to check
  let simplified := Ast.simplify ctx result
  let s := Ast.getNumeralString simplified
  return check "substitute (x → 5 in x+1)" (s == "6")
    s!"expected '6', got '{s}'"

/-- substitute: replace multiple variables -/
def testSubstituteMulti : IO TestResult := runTest "substitute multi (x→1, y→2 in x+y)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let expr := Ast.add ctx x y
  let result ← Env.run (Ast.substitute ctx expr #[x, y] #[one, two])
  let simplified := Ast.simplify ctx result
  let s := Ast.getNumeralString simplified
  return check "substitute multi (x→1, y→2 in x+y)" (s == "3")
    s!"expected '3', got '{s}'"

/-- substituteVars: substitute bound variable in quantifier body -/
def testSubstituteVars : IO TestResult := runTest "substituteVars" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let one := Ast.mkNumeral ctx "1" intSort
  let ten := Ast.mkNumeral ctx "10" intSort
  -- Build body with bound variable: (bound_0 + 1)
  let bound0 := Ast.mkBound ctx 0 intSort
  let body := Ast.add ctx bound0 one
  -- Substitute bound variable 0 with 10: should give (10 + 1)
  let result ← Env.run (Ast.substituteVars ctx body #[ten])
  let simplified := Ast.simplify ctx result
  let s := Ast.getNumeralString simplified
  return check "substituteVars" (s == "11")
    s!"expected '11', got '{s}'"

/-- substitute preserves semantics: solver check -/
def testSubstituteSolver : IO TestResult := runTest "substitute solver check" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let five := Ast.mkNumeral ctx "5" intSort
  -- Original: x > 0
  let expr := Ast.gt ctx x (Ast.mkNumeral ctx "0" intSort)
  -- Substitute x with y: y > 0
  let subst ← Env.run (Ast.substitute ctx expr #[x] #[y])
  Solver.assert solver subst
  Solver.assert solver (Ast.eq ctx y five)
  let result ← Solver.checkSat solver
  return check "substitute solver check" (result == .true)
    s!"expected sat, got {result}"

/-- simplifyGetParamDescrs: can obtain simplifier param descriptions -/
def testSimplifyGetParamDescrs : IO TestResult := runTest "simplifyGetParamDescrs" do
  let ctx ← Env.run Context.new
  let pd ← Context.simplifyGetParamDescrs ctx
  let sz := ParamDescrs.size pd
  return check "simplifyGetParamDescrs" (sz > 0)
    s!"expected size > 0, got {sz}"

def substTests : List (IO TestResult) :=
  [ testSimplify
  , testSimplifyBool
  , testSimplifyConst
  , testSimplifyEx
  , testSubstitute
  , testSubstituteMulti
  , testSubstituteVars
  , testSubstituteSolver
  , testSimplifyGetParamDescrs
  ]

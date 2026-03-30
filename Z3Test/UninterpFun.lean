import Z3Test.Harness

open Z3

/-! ## Uninterpreted function tests -/

/-- Declare f : Int -> Int, assert f(0) = 1 and f(1) = 0, check sat -/
def testUFBasic : IO TestResult := runTest "UF basic (f(0)=1, f(1)=0)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let f := FuncDecl.mk ctx "f" #[intSort] intSort
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let f0 := Ast.mkApp ctx f #[zero]
  let f1 := Ast.mkApp ctx f #[one]
  Solver.assert solver (Ast.eq ctx f0 one)
  Solver.assert solver (Ast.eq ctx f1 zero)
  let result ← Solver.checkSat solver
  return check "UF basic (f(0)=1, f(1)=0)" (result == .true)
    s!"expected sat, got {result}"

/-- f : Int -> Int, assert f(x) = f(y) and x != y, check sat (should be sat) -/
def testUFDifferentArgs : IO TestResult := runTest "UF different args" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let f := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let fx := Ast.mkApp ctx f #[x]
  let fy := Ast.mkApp ctx f #[y]
  Solver.assert solver (Ast.eq ctx fx fy)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx x y))
  let result ← Solver.checkSat solver
  return check "UF different args" (result == .true)
    s!"expected sat, got {result}"

/-- Congruence: f(x) = f(y) and x = y should be trivially sat -/
def testUFCongruence : IO TestResult := runTest "UF congruence (x=y -> f(x)=f(y))" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let f := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let fx := Ast.mkApp ctx f #[x]
  let fy := Ast.mkApp ctx f #[y]
  -- x = y AND f(x) != f(y) should be unsat by congruence
  Solver.assert solver (Ast.eq ctx x y)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx fx fy))
  let result ← Solver.checkSat solver
  return check "UF congruence (x=y -> f(x)=f(y))" (result == .false)
    s!"expected unsat, got {result}"

/-- Multi-arity: g : Int x Int -> Bool -/
def testUFMultiArity : IO TestResult := runTest "UF multi-arity (g : Int x Int -> Bool)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let g := FuncDecl.mk ctx "g" #[intSort, intSort] boolSort
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let g01 := Ast.mkApp ctx g #[zero, one]
  Solver.assert solver g01
  let result ← Solver.checkSat solver
  return check "UF multi-arity (g : Int x Int -> Bool)" (result == .true)
    s!"expected sat, got {result}"

/-- FuncDecl inspection: arity, domain, range -/
def testUFInspection : IO TestResult := runTest "UF inspection (arity/domain/range)" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let f := FuncDecl.mk ctx "f" #[intSort, boolSort] intSort
  let arity := FuncDecl.getArity f
  if arity != 2 then
    return check "UF inspection (arity/domain/range)" false s!"expected arity 2, got {arity}"
  let dom0 := FuncDecl.getDomain f 0
  let dom1 := FuncDecl.getDomain f 1
  let rng := FuncDecl.getRange f
  let dom0Name := toString dom0
  let dom1Name := toString dom1
  let rngName := toString rng
  return check "UF inspection (arity/domain/range)"
    (dom0Name == "Int" && dom1Name == "Bool" && rngName == "Int")
    s!"got domain=({dom0Name}, {dom1Name}), range={rngName}"

/-- Fresh constant: two fresh consts with same prefix are distinct -/
def testFreshConst : IO TestResult := runTest "fresh const (distinct names)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let a ← Ast.mkFreshConst ctx "x" intSort
  let b ← Ast.mkFreshConst ctx "x" intSort
  -- They should be allowed to differ
  Solver.assert solver (Ast.eq ctx a (Ast.mkNumeral ctx "1" intSort))
  Solver.assert solver (Ast.eq ctx b (Ast.mkNumeral ctx "2" intSort))
  let result ← Solver.checkSat solver
  return check "fresh const (distinct names)" (result == .true)
    s!"expected sat, got {result}"

/-- Fresh func decl -/
def testFreshFuncDecl : IO TestResult := runTest "fresh func decl" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let f ← FuncDecl.mkFresh ctx "f" #[intSort] intSort
  let g ← FuncDecl.mkFresh ctx "f" #[intSort] intSort
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  -- f(0) = 1 and g(0) = 0 should be sat since they're different functions
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx f #[zero]) one)
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx g #[zero]) zero)
  let result ← Solver.checkSat solver
  return check "fresh func decl" (result == .true)
    s!"expected sat, got {result}"

/-- mkApp with 0 args (constant from func decl) -/
def testUFConstant : IO TestResult := runTest "UF constant (0-arity app)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let c := FuncDecl.mk ctx "c" #[] intSort
  let cAst := Ast.mkApp ctx c #[]
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.eq ctx cAst five)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "UF constant (0-arity app)" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let val ← Env.run (Model.eval model cAst true)
  let valStr := Ast.getNumeralString val
  return check "UF constant (0-arity app)" (valStr == "5")
    s!"expected c = 5, got c = {valStr}"

def uninterpFunTests : List (IO TestResult) :=
  [ testUFBasic
  , testUFDifferentArgs
  , testUFCongruence
  , testUFMultiArity
  , testUFInspection
  , testFreshConst
  , testFreshFuncDecl
  , testUFConstant
  ]

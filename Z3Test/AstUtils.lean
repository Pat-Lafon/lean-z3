import Z3Test.Harness

open Z3

/-! ## AST utility tests -/

/-- isApp: application nodes -/
def testIsApp : IO TestResult := runTest "Ast.isApp" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let sum := Ast.add ctx x y
  -- Constants and applications are app nodes
  let xIsApp := Ast.isApp x
  let sumIsApp := Ast.isApp sum
  return check "Ast.isApp" (xIsApp && sumIsApp)
    s!"expected both true, got x={xIsApp}, sum={sumIsApp}"

/-- isNumeralAst: numeral detection -/
def testIsNumeralAst : IO TestResult := runTest "Ast.isNumeralAst" do
  let ctx ← Env.run Context.new
  let five := Ast.mkNumeral ctx "5" (Srt.mkInt ctx)
  let x := Ast.mkIntConst ctx "x"
  let fiveIsNum := Ast.isNumeralAst five
  let xIsNum := Ast.isNumeralAst x
  return check "Ast.isNumeralAst" (fiveIsNum && !xIsNum)
    s!"expected five=true, x=false, got five={fiveIsNum}, x={xIsNum}"

/-- isWellSorted: type correctness -/
def testIsWellSorted : IO TestResult := runTest "Ast.isWellSorted" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let sum := Ast.add ctx x (Ast.mkNumeral ctx "1" (Srt.mkInt ctx))
  return check "Ast.isWellSorted" (Ast.isWellSorted sum)
    s!"expected well-sorted"

/-- isEqAst: structural equality -/
def testIsEqAst : IO TestResult := runTest "Ast.isEqAst" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  -- Same AST should be equal to itself
  let selfEq := Ast.isEqAst x x
  -- Different ASTs should not be equal
  let diffEq := Ast.isEqAst x y
  return check "Ast.isEqAst" (selfEq && !diffEq)
    s!"expected self=true, diff=false, got self={selfEq}, diff={diffEq}"

/-- getId: unique identifiers -/
def testGetId : IO TestResult := runTest "Ast.getId" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let idX := Ast.getId x
  let idY := Ast.getId y
  -- Same AST should have same id
  let idX2 := Ast.getId x
  return check "Ast.getId" (idX == idX2 && idX != idY)
    s!"expected idX==idX2 && idX!=idY, got idX={idX}, idX2={idX2}, idY={idY}"

/-- getHash: hash values -/
def testGetHash : IO TestResult := runTest "Ast.getHash" do
  let ctx ← Env.run Context.new
  let x := Ast.mkIntConst ctx "x"
  let h1 := Ast.getHash x
  let h2 := Ast.getHash x
  -- Same AST should have same hash
  return check "Ast.getHash" (h1 == h2)
    s!"expected same hash, got h1={h1}, h2={h2}"

/-- translate: move AST between contexts -/
def testTranslate : IO TestResult := runTest "Ast.translate" do
  let ctx1 ← Env.run Context.new
  let ctx2 ← Env.run Context.new
  let x := Ast.mkIntConst ctx1 "x"
  let five := Ast.mkNumeral ctx1 "5" (Srt.mkInt ctx1)
  let expr := Ast.add ctx1 x five
  -- Translate to second context
  let translated := Ast.translate expr ctx2
  -- Should be well-sorted in the target context
  let ws := Ast.isWellSorted translated
  -- String representation should be the same
  let origStr := Ast.toString' expr
  let transStr := Ast.toString' translated
  return check "Ast.translate" (ws && origStr == transStr)
    s!"expected well-sorted with same repr, got ws={ws}, orig='{origStr}', trans='{transStr}'"

def astUtilTests : List (IO TestResult) :=
  [ testIsApp
  , testIsNumeralAst
  , testIsWellSorted
  , testIsEqAst
  , testGetId
  , testGetHash
  , testTranslate
  ]

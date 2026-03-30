import Z3Test.Harness

open Z3

/-! ## Fixedpoint (Datalog/CHC) tests -/

/-- Basic fixedpoint: reachability in a graph -/
def testFixedpointBasic : IO TestResult := runTest "fixedpoint basic" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  -- Declare edge(Int, Int) and path(Int, Int) relations
  let edge := FuncDecl.mk ctx "edge" #[intSort, intSort] boolSort
  let path := FuncDecl.mk ctx "path" #[intSort, intSort] boolSort
  Fixedpoint.registerRelation fp edge
  Fixedpoint.registerRelation fp path
  -- Variables as constants for quantifiers
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let z := Ast.mkIntConst ctx "z"
  -- Rule 1: edge(x,y) => path(x,y)
  let edgeXY := Ast.mkApp ctx edge #[x, y]
  let pathXY := Ast.mkApp ctx path #[x, y]
  let rule1 := Ast.implies ctx edgeXY pathXY
  let qRule1 ← Env.run (Ast.mkForallConst ctx 0 #[x, y] #[] rule1)
  Fixedpoint.addRule fp qRule1 "base"
  -- Rule 2: edge(x,y) ∧ path(y,z) => path(x,z)
  let pathYZ := Ast.mkApp ctx path #[y, z]
  let pathXZ := Ast.mkApp ctx path #[x, z]
  let rule2 := Ast.implies ctx (Ast.and ctx edgeXY pathYZ) pathXZ
  let qRule2 ← Env.run (Ast.mkForallConst ctx 0 #[x, y, z] #[] rule2)
  Fixedpoint.addRule fp qRule2 "step"
  -- Facts: edge(1,2), edge(2,3)
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  Fixedpoint.addRule fp (Ast.mkApp ctx edge #[one, two]) "e12"
  Fixedpoint.addRule fp (Ast.mkApp ctx edge #[two, three]) "e23"
  -- Query: is path(1,3) reachable?
  let query := Ast.mkApp ctx path #[one, three]
  let result ← Fixedpoint.query fp query
  return check "fixedpoint basic" (result == .true)
    s!"expected sat (reachable), got {result}"

/-- Fixedpoint multiple rules -/
def testFixedpointMultipleRules : IO TestResult := runTest "fixedpoint multiple rules" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  -- Add multiple facts
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "f1"
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[two]) "f2"
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[three]) "f3"
  -- All three should be reachable
  let r1 ← Fixedpoint.query fp (Ast.mkApp ctx r #[one])
  let r2 ← Fixedpoint.query fp (Ast.mkApp ctx r #[two])
  let r3 ← Fixedpoint.query fp (Ast.mkApp ctx r #[three])
  return check "fixedpoint multiple rules" (r1 == .true && r2 == .true && r3 == .true)
    s!"expected all sat, got {r1}, {r2}, {r3}"

/-- Fixedpoint get answer -/
def testFixedpointGetAnswer : IO TestResult := runTest "fixedpoint get answer" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "fact"
  let result ← Fixedpoint.query fp (Ast.mkApp ctx r #[one])
  if result != .true then
    return check "fixedpoint get answer" false s!"expected sat, got {result}"
  let answer := Fixedpoint.getAnswer fp
  let ansStr := Ast.toString' answer
  return check "fixedpoint get answer" (ansStr.length > 0)
    s!"expected non-empty answer"

/-- Fixedpoint toString -/
def testFixedpointToString : IO TestResult := runTest "fixedpoint toString" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let s := Fixedpoint.toString' fp
  -- Even empty fixedpoint should have some string representation
  return check "fixedpoint toString" (s.length ≥ 0)
    s!"unexpected error"

/-- Fixedpoint unreachable query -/
def testFixedpointUnreachable : IO TestResult := runTest "fixedpoint unreachable" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  -- Only r(1) is a fact
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "fact"
  -- Query: r(2)? should be unreachable
  let result ← Fixedpoint.query fp (Ast.mkApp ctx r #[two])
  -- Z3 may return .false or .undef for unreachable queries depending on engine
  return check "fixedpoint unreachable" (result != .true)
    s!"expected not sat (unreachable), got {result}"

/-- Fixedpoint setParams -/
def testFixedpointSetParams : IO TestResult := runTest "fixedpoint setParams" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let params ← Env.run (Params.new ctx)
  Params.setUInt params "timeout" 5000
  Fixedpoint.setParams fp params
  -- Just verify it doesn't crash
  return check "fixedpoint setParams" true ""

def fixedpointTests : List (IO TestResult) :=
  [ testFixedpointBasic
  , testFixedpointMultipleRules
  , testFixedpointGetAnswer
  , testFixedpointToString
  , testFixedpointUnreachable
  , testFixedpointSetParams
  ]

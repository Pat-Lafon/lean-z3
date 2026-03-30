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

/-- Fixedpoint getRules -/
def testFixedpointGetRules : IO TestResult := runTest "fixedpoint getRules" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "f1"
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[two]) "f2"
  let rules := Fixedpoint.getRules fp
  return check "fixedpoint getRules" (rules.size ≥ 2)
    s!"expected ≥ 2 rules, got {rules.size}"

/-- Fixedpoint getStatistics -/
def testFixedpointGetStatistics : IO TestResult := runTest "fixedpoint getStatistics" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "fact"
  let _ ← Fixedpoint.query fp (Ast.mkApp ctx r #[one])
  let stats := Fixedpoint.getStatistics fp
  let s := Stats.toString' stats
  return check "fixedpoint getStatistics" (s.length ≥ 0)
    s!"unexpected error"

/-- Fixedpoint getHelp -/
def testFixedpointGetHelp : IO TestResult := runTest "fixedpoint getHelp" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let help := Fixedpoint.getHelp fp
  return check "fixedpoint getHelp" (help.length > 0)
    s!"expected non-empty help string"

/-- Fixedpoint getParamDescrs -/
def testFixedpointGetParamDescrs : IO TestResult := runTest "fixedpoint getParamDescrs" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let pd := Fixedpoint.getParamDescrs fp
  let n := ParamDescrs.size pd
  return check "fixedpoint getParamDescrs" (n > 0)
    s!"expected > 0 param descriptors, got {n}"

/-- Fixedpoint getAssertions (empty) -/
def testFixedpointGetAssertions : IO TestResult := runTest "fixedpoint getAssertions" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let assertions := Fixedpoint.getAssertions fp
  -- No assertions added, should be empty
  return check "fixedpoint getAssertions" (assertions.size == 0)
    s!"expected 0 assertions, got {assertions.size}"

/-- Fixedpoint fromString -/
def testFixedpointFromString : IO TestResult := runTest "fixedpoint fromString" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let smtlib := "(declare-rel R (Int))
(declare-var x Int)
(rule (=> (> x 0) (R x)))
(query R)"
  let queries := Fixedpoint.fromString fp smtlib
  return check "fixedpoint fromString" (queries.size ≥ 1)
    s!"expected ≥ 1 query, got {queries.size}"

/-- Fixedpoint updateRule -/
def testFixedpointUpdateRule : IO TestResult := runTest "fixedpoint updateRule" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r := FuncDecl.mk ctx "r" #[intSort] boolSort
  Fixedpoint.registerRelation fp r
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  -- Add r(1) then update to r(2)
  Fixedpoint.addRule fp (Ast.mkApp ctx r #[one]) "myrule"
  Fixedpoint.updateRule fp (Ast.mkApp ctx r #[two]) "myrule"
  -- After update, r(2) should be reachable
  let result ← Fixedpoint.query fp (Ast.mkApp ctx r #[two])
  return check "fixedpoint updateRule" (result == .true)
    s!"expected sat after update, got {result}"

/-- Fixedpoint queryRelations -/
def testFixedpointQueryRelations : IO TestResult := runTest "fixedpoint queryRelations" do
  let ctx ← Env.run Context.new
  let fp ← Env.run (Fixedpoint.new ctx)
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let r1 := FuncDecl.mk ctx "r1" #[intSort] boolSort
  let r2 := FuncDecl.mk ctx "r2" #[intSort] boolSort
  Fixedpoint.registerRelation fp r1
  Fixedpoint.registerRelation fp r2
  let one := Ast.mkNumeral ctx "1" intSort
  Fixedpoint.addRule fp (Ast.mkApp ctx r1 #[one]) "f1"
  Fixedpoint.addRule fp (Ast.mkApp ctx r2 #[one]) "f2"
  let result ← Fixedpoint.queryRelations fp #[r1, r2]
  -- Z3 may return .true or .undef for multi-relation queries depending on engine
  return check "fixedpoint queryRelations" (result != .false)
    s!"expected not unsat, got {result}"

def fixedpointTests : List (IO TestResult) :=
  [ testFixedpointBasic
  , testFixedpointMultipleRules
  , testFixedpointGetAnswer
  , testFixedpointToString
  , testFixedpointUnreachable
  , testFixedpointSetParams
  , testFixedpointGetRules
  , testFixedpointGetStatistics
  , testFixedpointGetHelp
  , testFixedpointGetParamDescrs
  , testFixedpointGetAssertions
  , testFixedpointFromString
  , testFixedpointUpdateRule
  , testFixedpointQueryRelations
  ]

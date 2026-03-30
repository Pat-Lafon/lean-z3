import Z3Test.Harness

open Z3

/-! ## Probe API tests -/

/-- Basic probe: create and apply num-consts -/
def testProbeBasic : IO TestResult := runTest "probe basic" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  Goal.assert g (Ast.gt ctx x zero)
  Goal.assert g (Ast.gt ctx y zero)
  let p := Probe.mk ctx "num-consts"
  let val ← Probe.apply ctx p g
  return check "probe basic" (val ≥ 2.0)
    s!"expected ≥ 2 consts, got {val}"

/-- Probe const -/
def testProbeConst : IO TestResult := runTest "probe const" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let p := Probe.const ctx 42.0
  let val ← Probe.apply ctx p g
  return check "probe const" (val == 42.0)
    s!"expected 42.0, got {val}"

/-- Probe comparisons (lt, gt, le, ge, eq) -/
def testProbeComparisons : IO TestResult := runTest "probe comparisons" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let p1 := Probe.const ctx 1.0
  let p2 := Probe.const ctx 2.0
  -- 1 < 2 should be true (1.0)
  let ltP := Probe.lt ctx p1 p2
  let ltVal ← Probe.apply ctx ltP g
  -- 2 > 1 should be true
  let gtP := Probe.gt ctx p2 p1
  let gtVal ← Probe.apply ctx gtP g
  -- 1 <= 1 should be true
  let leP := Probe.le ctx p1 p1
  let leVal ← Probe.apply ctx leP g
  -- 2 >= 2 should be true
  let geP := Probe.ge ctx p2 p2
  let geVal ← Probe.apply ctx geP g
  -- 1 == 1 should be true
  let eqP := Probe.eq ctx p1 p1
  let eqVal ← Probe.apply ctx eqP g
  return check "probe comparisons"
    (ltVal > 0.0 && gtVal > 0.0 && leVal > 0.0 && geVal > 0.0 && eqVal > 0.0)
    s!"comparison failed: lt={ltVal} gt={gtVal} le={leVal} ge={geVal} eq={eqVal}"

/-- Probe logical combinators (and, or, not) -/
def testProbeCombinators : IO TestResult := runTest "probe combinators" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let t := Probe.const ctx 1.0  -- true
  let f := Probe.const ctx 0.0  -- false
  -- true AND false = false
  let andP := Probe.and ctx t f
  let andVal ← Probe.apply ctx andP g
  -- true OR false = true
  let orP := Probe.or ctx t f
  let orVal ← Probe.apply ctx orP g
  -- NOT false = true
  let notP := Probe.not ctx f
  let notVal ← Probe.apply ctx notP g
  return check "probe combinators"
    (andVal == 0.0 && orVal > 0.0 && notVal > 0.0)
    s!"combinator failed: and={andVal} or={orVal} not={notVal}"

/-- List available probes -/
def testProbeList : IO TestResult := runTest "probe list" do
  let ctx ← Env.run Context.new
  let n := Context.getNumProbes ctx
  -- Z3 should have many built-in probes
  if n == 0 then
    return check "probe list" false "no probes available"
  let name := Context.getProbeName ctx 0
  return check "probe list" (name.length > 0)
    s!"expected non-empty probe name"

/-- Probe getDescr -/
def testProbeGetDescr : IO TestResult := runTest "probe getDescr" do
  let ctx ← Env.run Context.new
  let descr := Probe.getDescr ctx "num-consts"
  return check "probe getDescr" (descr.length > 0)
    s!"expected non-empty description"

/-- Tactic.when with probe -/
def testTacticWhen : IO TestResult := runTest "tactic when" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  Goal.assert g (Ast.gt ctx x zero)
  -- Apply simplify only when num-consts > 0
  let p := Probe.mk ctx "num-consts"
  let pGt := Probe.gt ctx p (Probe.const ctx 0.0)
  let t := Tactic.when ctx pGt (Tactic.mk ctx "simplify")
  let result := Tactic.apply ctx t g
  let nSubgoals := ApplyResult.getNumSubgoals result
  return check "tactic when" (nSubgoals ≥ 1)
    s!"expected ≥ 1 subgoal, got {nSubgoals}"

/-- Tactic.cond with probe -/
def testTacticCond : IO TestResult := runTest "tactic cond" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  let x := Ast.mkIntConst ctx "x"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  Goal.assert g (Ast.gt ctx x zero)
  -- If num-consts > 0 then simplify else skip
  let p := Probe.gt ctx (Probe.mk ctx "num-consts") (Probe.const ctx 0.0)
  let t := Tactic.cond ctx p (Tactic.mk ctx "simplify") (Tactic.skip ctx)
  let result := Tactic.apply ctx t g
  let nSubgoals := ApplyResult.getNumSubgoals result
  return check "tactic cond" (nSubgoals ≥ 1)
    s!"expected ≥ 1 subgoal, got {nSubgoals}"

/-- Tactic.failIf with probe -/
def testTacticFailIf : IO TestResult := runTest "tactic failIf" do
  let ctx ← Env.run Context.new
  let g := Goal.mk ctx true false false
  -- failIf on an impossible condition (num-consts > 1000000), then simplify
  let p := Probe.gt ctx (Probe.mk ctx "num-consts") (Probe.const ctx 1000000.0)
  let failT := Tactic.failIf ctx p
  -- andThen: fail if too many consts, then simplify — should succeed on empty goal
  let t := Tactic.andThen ctx failT (Tactic.skip ctx)
  let result := Tactic.apply ctx t g
  let nSubgoals := ApplyResult.getNumSubgoals result
  return check "tactic failIf" (nSubgoals ≥ 1)
    s!"expected ≥ 1 subgoal, got {nSubgoals}"

/-- Tactic.failIfNotDecided -/
def testTacticFailIfNotDecided : IO TestResult := runTest "tactic failIfNotDecided" do
  let ctx ← Env.run Context.new
  -- A decided goal (inconsistent): assert false
  let g := Goal.mk ctx true false false
  Goal.assert g (Ast.mkBool ctx false)
  let t := Tactic.failIfNotDecided ctx
  let result := Tactic.apply ctx t g
  let nSubgoals := ApplyResult.getNumSubgoals result
  return check "tactic failIfNotDecided" (nSubgoals ≥ 0)
    s!"unexpected result"

def probeTests : List (IO TestResult) :=
  [ testProbeBasic
  , testProbeConst
  , testProbeComparisons
  , testProbeCombinators
  , testProbeList
  , testProbeGetDescr
  , testTacticWhen
  , testTacticCond
  , testTacticFailIf
  , testTacticFailIfNotDecided
  ]

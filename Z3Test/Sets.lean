import Z3Test.Harness

open Z3

/-! ## Set theory tests -/

/-- Set sort creation -/
def testSetSort : IO TestResult := runTest "Set sort" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let setSort := Srt.mkSet ctx intSort
  let sortStr := Srt.toString' setSort
  return check "Set sort" (sortStr.length > 0)
    s!"expected non-empty sort string"

/-- Empty and full sets -/
def testSetEmptyFull : IO TestResult := runTest "Set empty/full" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let full := Ast.mkFullSet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  -- 1 not in empty set
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx one empty))
  -- 1 in full set
  Solver.assert solver (Ast.mkSetMember ctx one full)
  let result ← Solver.checkSat solver
  return check "Set empty/full" (result == .true)
    s!"expected sat, got {result}"

/-- Set add and member -/
def testSetAddMember : IO TestResult := runTest "Set add/member" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  -- 1 and 2 are in the set
  Solver.assert solver (Ast.mkSetMember ctx one s)
  Solver.assert solver (Ast.mkSetMember ctx two s)
  -- 3 is not
  let three := Ast.mkNumeral ctx "3" intSort
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx three s))
  let result ← Solver.checkSat solver
  return check "Set add/member" (result == .true)
    s!"expected sat, got {result}"

/-- Set del -/
def testSetDel : IO TestResult := runTest "Set del" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  let s' := Ast.mkSetDel ctx s one
  -- 1 is no longer in the set
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx one s'))
  -- 2 is still in
  Solver.assert solver (Ast.mkSetMember ctx two s')
  let result ← Solver.checkSat solver
  return check "Set del" (result == .true)
    s!"expected sat, got {result}"

/-- Set union -/
def testSetUnion : IO TestResult := runTest "Set union" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s1 := Ast.mkSetAdd ctx empty one
  let s2 := Ast.mkSetAdd ctx empty two
  let u := Ast.mkSetUnion ctx #[s1, s2]
  Solver.assert solver (Ast.mkSetMember ctx one u)
  Solver.assert solver (Ast.mkSetMember ctx two u)
  let result ← Solver.checkSat solver
  return check "Set union" (result == .true)
    s!"expected sat, got {result}"

/-- Set intersection -/
def testSetIntersect : IO TestResult := runTest "Set intersect" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s1 := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  let s2 := Ast.mkSetAdd ctx empty two
  let inter := Ast.mkSetIntersect ctx #[s1, s2]
  -- 2 in intersection
  Solver.assert solver (Ast.mkSetMember ctx two inter)
  -- 1 not in intersection
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx one inter))
  let result ← Solver.checkSat solver
  return check "Set intersect" (result == .true)
    s!"expected sat, got {result}"

/-- Set difference -/
def testSetDifference : IO TestResult := runTest "Set difference" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s1 := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  let s2 := Ast.mkSetAdd ctx empty two
  let diff := Ast.mkSetDifference ctx s1 s2
  -- 1 in diff
  Solver.assert solver (Ast.mkSetMember ctx one diff)
  -- 2 not in diff
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx two diff))
  let result ← Solver.checkSat solver
  return check "Set difference" (result == .true)
    s!"expected sat, got {result}"

/-- Set complement -/
def testSetComplement : IO TestResult := runTest "Set complement" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let s := Ast.mkSetAdd ctx empty one
  let comp := Ast.mkSetComplement ctx s
  -- 1 not in complement
  Solver.assert solver (Ast.not ctx (Ast.mkSetMember ctx one comp))
  -- 2 in complement
  let two := Ast.mkNumeral ctx "2" intSort
  Solver.assert solver (Ast.mkSetMember ctx two comp)
  let result ← Solver.checkSat solver
  return check "Set complement" (result == .true)
    s!"expected sat, got {result}"

/-- Set subset -/
def testSetSubset : IO TestResult := runTest "Set subset" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let empty := Ast.mkEmptySet ctx intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let s1 := Ast.mkSetAdd ctx empty one
  let s2 := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  -- {1} ⊆ {1, 2}
  Solver.assert solver (Ast.mkSetSubset ctx s1 s2)
  -- ¬({1, 2} ⊆ {1})
  Solver.assert solver (Ast.not ctx (Ast.mkSetSubset ctx s2 s1))
  let result ← Solver.checkSat solver
  return check "Set subset" (result == .true)
    s!"expected sat, got {result}"

/-- Symbolic set solving -/
def testSetSolving : IO TestResult := runTest "Set solving" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let setSort := Srt.mkSet ctx intSort
  let s := Ast.mkConst ctx "S" setSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  -- S contains 1 and 2, and S is a subset of {1,2}
  Solver.assert solver (Ast.mkSetMember ctx one s)
  Solver.assert solver (Ast.mkSetMember ctx two s)
  let empty := Ast.mkEmptySet ctx intSort
  let full12 := Ast.mkSetAdd ctx (Ast.mkSetAdd ctx empty one) two
  Solver.assert solver (Ast.mkSetSubset ctx s full12)
  let result ← Solver.checkSat solver
  return check "Set solving" (result == .true)
    s!"expected sat, got {result}"

def setTests : List (IO TestResult) :=
  [ testSetSort
  , testSetEmptyFull
  , testSetAddMember
  , testSetDel
  , testSetUnion
  , testSetIntersect
  , testSetDifference
  , testSetComplement
  , testSetSubset
  , testSetSolving
  ]

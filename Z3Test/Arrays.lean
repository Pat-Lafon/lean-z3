import Z3Test.Harness

open Z3

/-! ## Array operation tests -/

/-- z3-rs: test_array_store_select — store then select returns the stored value -/
def testArrayStoreSelect : IO TestResult := runTest "array store/select (z3-rs)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  -- a = (const_array[Int→Int]).store(0, 1)
  let arrSort := Srt.mkArray ctx intSort intSort
  let a := Ast.mkConst ctx "a" arrSort
  let aStored := Ast.store ctx a zero one
  -- assert a[0] = 1 after store, then assert ¬(a'[0] = 1) is unsat
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.select ctx aStored zero) one))
  let result ← Solver.checkSat solver
  return check "array store/select (z3-rs)" (result == .false)
    s!"expected unsat, got {result}"

/-- Constant array: every index maps to the same value -/
def testConstArray : IO TestResult := runTest "const array" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let forty2 := Ast.mkNumeral ctx "42" intSort
  -- arr = const_array(42), so arr[i] = 42 for any i
  let arr := Ast.constArray ctx intSort forty2
  let i := Ast.mkIntConst ctx "i"
  Solver.assert solver (Ast.eq ctx (Ast.select ctx arr i) forty2)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "const array" false s!"expected sat, got {result}"
  -- assert arr[i] ≠ 42 is unsat
  Solver.push solver
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.select ctx arr i) forty2))
  let r2 ← Solver.checkSat solver
  Solver.pop solver 1
  return check "const array" (r2 == .false)
    s!"expected unsat for arr[i] ≠ 42, got {r2}"

/-- Array sort kind is Z3_ARRAY_SORT (5) -/
def testArraySortKind : IO TestResult := runTest "array sort kind" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let arrSort := Srt.mkArray ctx intSort boolSort
  let kind := Srt.getKindRaw arrSort
  -- Z3_ARRAY_SORT = 5
  return check "array sort kind" (kind == 5)
    s!"expected array sort kind (5), got {kind}"

/-- Store overwrites: store twice at same index, second wins -/
def testArrayStoreOverwrite : IO TestResult := runTest "array store overwrite" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let arrSort := Srt.mkArray ctx intSort intSort
  let a := Ast.mkConst ctx "a" arrSort
  -- store 1 at index 0, then store 2 at index 0
  let a1 := Ast.store ctx a zero one
  let a2 := Ast.store ctx a1 zero two
  -- a2[0] should be 2, not 1
  Solver.assert solver (Ast.eq ctx (Ast.select ctx a2 zero) two)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "array store overwrite" false s!"expected sat, got {result}"
  -- assert a2[0] = 1 is unsat (overwritten)
  Solver.push solver
  Solver.assert solver (Ast.eq ctx (Ast.select ctx a2 zero) one)
  let r2 ← Solver.checkSat solver
  Solver.pop solver 1
  return check "array store overwrite" (r2 == .false)
    s!"expected unsat for a2[0]=1, got {r2}"

/-- Store at one index doesn't affect other indices -/
def testArrayStoreOtherIndex : IO TestResult := runTest "array store other index" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let five := Ast.mkNumeral ctx "5" intSort
  let forty2 := Ast.mkNumeral ctx "42" intSort
  -- arr = const_array(42), store 5 at index 0
  let arr := Ast.constArray ctx intSort forty2
  let arr2 := Ast.store ctx arr zero five
  -- arr2[0] = 5
  Solver.assert solver (Ast.eq ctx (Ast.select ctx arr2 zero) five)
  -- arr2[1] should still be 42
  Solver.assert solver (Ast.eq ctx (Ast.select ctx arr2 one) forty2)
  let result ← Solver.checkSat solver
  return check "array store other index" (result == .true)
    s!"expected sat, got {result}"

/-- Array with BV domain and range (from z3-rs test_array_example1) -/
def testArrayBvDomainRange : IO TestResult := runTest "array BV domain/range" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let bv32Sort := Srt.mkBv ctx 32
  let arrSort := Srt.mkArray ctx intSort bv32Sort
  let arr := Ast.mkConst ctx "arr" arrSort
  let zero := Ast.mkNumeral ctx "0" intSort
  let sel := Ast.select ctx arr zero
  let selSort := Ast.getSort sel
  let selKind := Srt.getKindRaw selSort
  -- Selected element should have BV sort (kind 4)
  return check "array BV domain/range" (selKind == 4)
    s!"expected BV sort kind (4) for select result, got {selKind}"

/-- Distinct — all elements are pairwise different -/
def testDistinct : IO TestResult := runTest "distinct" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let z := Ast.mkIntConst ctx "z"
  let one := Ast.mkNumeral ctx "1" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  -- distinct(x, y, z) ∧ 1 ≤ x,y,z ≤ 3 → exactly one assignment
  Solver.assert solver (Ast.distinct ctx #[x, y, z])
  for v in [x, y, z] do
    Solver.assert solver (Ast.ge ctx v one)
    Solver.assert solver (Ast.le ctx v three)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "distinct" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let xv := (Ast.getNumeralString (← Env.run (Model.eval model x true))).toNat!
  let yv := (Ast.getNumeralString (← Env.run (Model.eval model y true))).toNat!
  let zv := (Ast.getNumeralString (← Env.run (Model.eval model z true))).toNat!
  -- All must be different
  return check "distinct" (xv != yv && yv != zv && xv != zv)
    s!"expected all distinct, got x={xv}, y={yv}, z={zv}"

/-- Distinct with 2 values in range of 2 — sat; with 3 values — unsat -/
def testDistinctUnsat : IO TestResult := runTest "distinct unsat" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let x := Ast.mkIntConst ctx "x"
  let y := Ast.mkIntConst ctx "y"
  let z := Ast.mkIntConst ctx "z"
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  -- distinct(x, y, z) ∧ 1 ≤ all ≤ 2 → unsat (pigeonhole)
  Solver.assert solver (Ast.distinct ctx #[x, y, z])
  for v in [x, y, z] do
    Solver.assert solver (Ast.ge ctx v one)
    Solver.assert solver (Ast.le ctx v two)
  let result ← Solver.checkSat solver
  return check "distinct unsat" (result == .false)
    s!"expected unsat (pigeonhole), got {result}"

def arrayTests : List (IO TestResult) :=
  [ testArrayStoreSelect
  , testConstArray
  , testArraySortKind
  , testArrayStoreOverwrite
  , testArrayStoreOtherIndex
  , testArrayBvDomainRange
  , testDistinct
  , testDistinctUnsat
  ]

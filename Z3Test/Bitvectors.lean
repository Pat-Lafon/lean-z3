import Z3Test.Harness

open Z3

/-! ## Bitvector operation tests -/

/-- BV arithmetic: x + y = x - y has solutions (e.g., y = 0) -/
def testBvArith : IO TestResult := runTest "bv arithmetic (add/sub)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 32
  let y := Ast.mkBvConst ctx "y" 32
  -- x + y == x - y  ⟺  2y == 0
  Solver.assert solver (Ast.eq ctx (Ast.bvadd ctx x y) (Ast.bvsub ctx x y))
  let result ← Solver.checkSat solver
  return check "bv arithmetic (add/sub)" (result == .true)
    s!"expected sat, got {result}"

/-- BV multiplication: x * 2 == x + x -/
def testBvMul : IO TestResult := runTest "bv mul == add self" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 8
  let two := Ast.mkNumeral ctx "2" (Srt.mkBv ctx 8)
  -- assert NOT (x * 2 == x + x) — should be unsat
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.bvmul ctx x two) (Ast.bvadd ctx x x)))
  let result ← Solver.checkSat solver
  return check "bv mul == add self" (result == .false)
    s!"expected unsat, got {result}"

/-- BV bitwise: x & x == x -/
def testBvBitwise : IO TestResult := runTest "bv bitwise (and/or/xor/not)" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 16
  -- NOT (x & x == x) should be unsat
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.bvand ctx x x) x))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "bv bitwise (and/or/xor/not)" false s!"x & x != x was sat"
  -- x ^ x == 0
  Solver.reset solver
  let zero := Ast.mkNumeral ctx "0" (Srt.mkBv ctx 16)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.bvxor ctx x x) zero))
  let result2 ← Solver.checkSat solver
  return check "bv bitwise (and/or/xor/not)" (result2 == .false)
    s!"x ^ x != 0 was sat"

/-- BV shifts: x << 1 == x + x (for all x) -/
def testBvShift : IO TestResult := runTest "bv shift left" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 32
  let one := Ast.mkNumeral ctx "1" (Srt.mkBv ctx 32)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx (Ast.bvshl ctx x one) (Ast.bvadd ctx x x)))
  let result ← Solver.checkSat solver
  return check "bv shift left" (result == .false)
    s!"expected unsat, got {result}"

/-- BV signed comparison: -1 <s 0 -/
def testBvSignedCmp : IO TestResult := runTest "bv signed comparison" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let neg1 := Ast.mkNumeral ctx "255" bv8  -- -1 in 8-bit two's complement
  let zero := Ast.mkNumeral ctx "0" bv8
  -- -1 <s 0 should be true
  Solver.assert solver (Ast.bvslt ctx neg1 zero)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "bv signed comparison" false s!"expected -1 <s 0 to be sat"
  -- -1 >u 0 should also be true (255 > 0 unsigned)
  Solver.reset solver
  Solver.assert solver (Ast.bvugt ctx neg1 zero)
  let result2 ← Solver.checkSat solver
  return check "bv signed comparison" (result2 == .true)
    s!"expected 255 >u 0 to be sat"

/-- BV extract and concat: extract high/low halves, concat back -/
def testBvExtractConcat : IO TestResult := runTest "bv extract/concat" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 16
  -- extract [15:8] (high byte) and [7:0] (low byte), concat should equal x
  let high := Ast.bvextract ctx 15 8 x
  let low := Ast.bvextract ctx 7 0 x
  let rejoined := Ast.bvconcat ctx high low
  Solver.assert solver (Ast.not ctx (Ast.eq ctx rejoined x))
  let result ← Solver.checkSat solver
  return check "bv extract/concat" (result == .false)
    s!"expected unsat, got {result}"

/-- BV zero-extend and sign-extend -/
def testBvExtend : IO TestResult := runTest "bv zero/sign extend" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let val := Ast.mkNumeral ctx "200" bv8  -- 0xC8, sign bit is 1
  -- zero-extend by 8: result should be 200 (0x00C8)
  let zext := Ast.bvzeroExt ctx 8 val
  let expected_z := Ast.mkNumeral ctx "200" (Srt.mkBv ctx 16)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx zext expected_z))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "bv zero/sign extend" false "zero-extend failed"
  -- sign-extend by 8: 0xC8 → 0xFFC8 = 65480
  Solver.reset solver
  let sext := Ast.bvsignExt ctx 8 val
  let expected_s := Ast.mkNumeral ctx "65480" (Srt.mkBv ctx 16)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx sext expected_s))
  let result2 ← Solver.checkSat solver
  return check "bv zero/sign extend" (result2 == .false)
    s!"sign-extend failed"

/-- BV rotation: rotate_left(x, 8) on 16-bit swaps bytes -/
def testBvRotate : IO TestResult := runTest "bv rotation" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv16 := Srt.mkBv ctx 16
  let val := Ast.mkNumeral ctx "256" bv16  -- 0x0100
  -- rotate_left(0x0100, 8) == 0x0001 == 1
  let rotated := Ast.rotateLeft ctx val 8
  let expected := Ast.mkNumeral ctx "1" bv16
  Solver.assert solver (Ast.not ctx (Ast.eq ctx rotated expected))
  let result ← Solver.checkSat solver
  return check "bv rotation" (result == .false)
    s!"expected unsat, got {result}"

/-- BV to int conversion -/
def testBvIntConvert : IO TestResult := runTest "bv/int conversion" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let val := Ast.mkNumeral ctx "255" bv8
  -- unsigned bv2int(255) == 255
  let asInt := Ast.bv2int ctx val false
  let expected := Ast.mkNumeral ctx "255" (Srt.mkInt ctx)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx asInt expected))
  let result ← Solver.checkSat solver
  if result != .false then
    return check "bv/int conversion" false "unsigned bv2int failed"
  -- signed bv2int(255) == -1
  Solver.reset solver
  let asIntSigned := Ast.bv2int ctx val true
  let expectedSigned := Ast.mkNumeral ctx "-1" (Srt.mkInt ctx)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx asIntSigned expectedSigned))
  let result2 ← Solver.checkSat solver
  return check "bv/int conversion" (result2 == .false)
    s!"signed bv2int failed"

/-- BV division: 10 /u 3 == 3, 10 %u 3 == 1 -/
def testBvDiv : IO TestResult := runTest "bv division" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let ten := Ast.mkNumeral ctx "10" bv8
  let three := Ast.mkNumeral ctx "3" bv8
  let quot := Ast.bvudiv ctx ten three
  let rem := Ast.bvurem ctx ten three
  let expectedQ := Ast.mkNumeral ctx "3" bv8
  let expectedR := Ast.mkNumeral ctx "1" bv8
  Solver.assert solver (Ast.not ctx (Ast.and ctx
    (Ast.eq ctx quot expectedQ) (Ast.eq ctx rem expectedR)))
  let result ← Solver.checkSat solver
  return check "bv division" (result == .false)
    s!"expected unsat, got {result}"

def bitvectorTests : List (IO TestResult) :=
  [ testBvArith
  , testBvMul
  , testBvBitwise
  , testBvShift
  , testBvSignedCmp
  , testBvExtractConcat
  , testBvExtend
  , testBvRotate
  , testBvIntConvert
  , testBvDiv
  ]

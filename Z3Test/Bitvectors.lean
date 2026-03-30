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

/-- bvnand: ~(a & b) -/
def testBvNand : IO TestResult := runTest "bv nand" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let a := Ast.mkNumeral ctx "255" bv8  -- 0xFF
  let b := Ast.mkNumeral ctx "15" bv8   -- 0x0F
  let result := Ast.bvnand ctx a b
  -- nand(0xFF, 0x0F) = ~(0x0F) = 0xF0 = 240
  let expected := Ast.mkNumeral ctx "240" bv8
  Solver.assert solver (Ast.not ctx (Ast.eq ctx result expected))
  let r ← Solver.checkSat solver
  return check "bv nand" (r == .false)
    s!"expected unsat, got {r}"

/-- bvnor: ~(a | b) -/
def testBvNor : IO TestResult := runTest "bv nor" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let a := Ast.mkNumeral ctx "240" bv8  -- 0xF0
  let b := Ast.mkNumeral ctx "15" bv8   -- 0x0F
  let result := Ast.bvnor ctx a b
  -- nor(0xF0, 0x0F) = ~(0xFF) = 0x00
  let expected := Ast.mkNumeral ctx "0" bv8
  Solver.assert solver (Ast.not ctx (Ast.eq ctx result expected))
  let r ← Solver.checkSat solver
  return check "bv nor" (r == .false)
    s!"expected unsat, got {r}"

/-- bvxnor: ~(a ^ b) -/
def testBvXnor : IO TestResult := runTest "bv xnor" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let a := Ast.mkNumeral ctx "170" bv8  -- 0xAA
  let b := Ast.mkNumeral ctx "170" bv8  -- 0xAA
  let result := Ast.bvxnor ctx a b
  -- xnor(x, x) = ~0 = 0xFF = 255
  let expected := Ast.mkNumeral ctx "255" bv8
  Solver.assert solver (Ast.not ctx (Ast.eq ctx result expected))
  let r ← Solver.checkSat solver
  return check "bv xnor" (r == .false)
    s!"expected unsat, got {r}"

/-- bvsmod: signed modulus -/
def testBvSmod : IO TestResult := runTest "bv smod" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  -- -7 mod 3 in signed 8-bit: -7 = 249 unsigned
  let a := Ast.mkNumeral ctx "249" bv8  -- -7 signed
  let b := Ast.mkNumeral ctx "3" bv8
  let result := Ast.bvsmod ctx a b
  -- smod(-7, 3) = 2 (result has same sign as divisor)
  let expected := Ast.mkNumeral ctx "2" bv8
  Solver.assert solver (Ast.not ctx (Ast.eq ctx result expected))
  let r ← Solver.checkSat solver
  return check "bv smod" (r == .false)
    s!"expected unsat, got {r}"

/-- bvredand: AND reduction (all bits 1 → 1) -/
def testBvRedand : IO TestResult := runTest "bv redand" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let bv1 := Srt.mkBv ctx 1
  let allOnes := Ast.mkNumeral ctx "255" bv8
  let notAll := Ast.mkNumeral ctx "254" bv8
  let r1 := Ast.bvredand ctx allOnes   -- should be 1
  let r2 := Ast.bvredand ctx notAll    -- should be 0
  let one := Ast.mkNumeral ctx "1" bv1
  let zero := Ast.mkNumeral ctx "0" bv1
  Solver.assert solver (Ast.eq ctx r1 one)
  Solver.assert solver (Ast.eq ctx r2 zero)
  let r ← Solver.checkSat solver
  return check "bv redand" (r == .true)
    s!"expected sat, got {r}"

/-- bvredor: OR reduction (any bit 1 → 1) -/
def testBvRedor : IO TestResult := runTest "bv redor" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let bv1 := Srt.mkBv ctx 1
  let allZeros := Ast.mkNumeral ctx "0" bv8
  let someOne := Ast.mkNumeral ctx "1" bv8
  let r1 := Ast.bvredor ctx allZeros  -- should be 0
  let r2 := Ast.bvredor ctx someOne   -- should be 1
  let zero := Ast.mkNumeral ctx "0" bv1
  let one := Ast.mkNumeral ctx "1" bv1
  Solver.assert solver (Ast.eq ctx r1 zero)
  Solver.assert solver (Ast.eq ctx r2 one)
  let r ← Solver.checkSat solver
  return check "bv redor" (r == .true)
    s!"expected sat, got {r}"

/-- bvrepeat: repeat 4-bit value 2 times to get 8-bit -/
def testBvRepeat : IO TestResult := runTest "bv repeat" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv4 := Srt.mkBv ctx 4
  let bv8 := Srt.mkBv ctx 8
  let nibble := Ast.mkNumeral ctx "10" bv4  -- 0xA = 1010
  let repeated := Ast.bvrepeat ctx 2 nibble -- 0xAA = 10101010
  let expected := Ast.mkNumeral ctx "170" bv8  -- 0xAA
  Solver.assert solver (Ast.not ctx (Ast.eq ctx repeated expected))
  let r ← Solver.checkSat solver
  return check "bv repeat" (r == .false)
    s!"expected unsat, got {r}"

/-- bvaddNoOverflow: unsigned overflow detection -/
def testBvAddNoOverflow : IO TestResult := runTest "bv add no overflow" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  let a := Ast.mkNumeral ctx "200" bv8
  let b := Ast.mkNumeral ctx "100" bv8
  -- 200 + 100 = 300 > 255, so this overflows unsigned
  let noOverflow := Ast.bvaddNoOverflow ctx a b false  -- unsigned
  Solver.assert solver noOverflow
  let r ← Solver.checkSat solver
  return check "bv add no overflow" (r == .false)
    s!"expected unsat (200+100 overflows u8), got {r}"

/-- bvnegNoOverflow: signed negation overflow (MIN_INT) -/
def testBvNegNoOverflow : IO TestResult := runTest "bv neg no overflow" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let bv8 := Srt.mkBv ctx 8
  -- -128 (0x80) signed: negating overflows since 128 > 127
  let minInt := Ast.mkNumeral ctx "128" bv8
  let noOverflow := Ast.bvnegNoOverflow ctx minInt
  Solver.assert solver noOverflow
  let r ← Solver.checkSat solver
  return check "bv neg no overflow" (r == .false)
    s!"expected unsat (-(-128) overflows i8), got {r}"

/-- overflow checks with symbolic values -/
def testBvOverflowSymbolic : IO TestResult := runTest "bv overflow symbolic" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let x := Ast.mkBvConst ctx "x" 8
  let y := Ast.mkBvConst ctx "y" 8
  -- If no unsigned overflow on x+y, then x+y >= x
  let noOvf := Ast.bvaddNoOverflow ctx x y false
  let sum := Ast.bvadd ctx x y
  let geq := Ast.bvuge ctx sum x
  -- Assert: no overflow AND sum < x → should be unsat
  Solver.assert solver noOvf
  Solver.assert solver (Ast.not ctx geq)
  let r ← Solver.checkSat solver
  return check "bv overflow symbolic" (r == .false)
    s!"expected unsat, got {r}"

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
  , testBvNand
  , testBvNor
  , testBvXnor
  , testBvSmod
  , testBvRedand
  , testBvRedor
  , testBvRepeat
  , testBvAddNoOverflow
  , testBvNegNoOverflow
  , testBvOverflowSymbolic
  ]

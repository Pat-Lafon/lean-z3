import Z3Test.Harness

open Z3 Z3.Api

/-! ## High-level API tests -/

/-- Basic arithmetic: 2x + 3 = 11, solve for x -/
def testApiArithmetic : IO TestResult := runTest "api arithmetic" do
  let result ← Api.run do
    let x ← intConst "x"
    let two ← intVal 2
    let three ← intVal 3
    let eleven ← intVal 11
    let lhs ← add (← mul two x) three
    withSolver fun s => do
      Api.assert s (← eq lhs eleven)
      let model? ← solve s
      match model? with
      | some m => return Ast.getNumeralString (← Api.eval m x)
      | none => return "no model"
  return check "api arithmetic" (result == "4") s!"expected 4, got {result}"

/-- Boolean: p ∧ ¬q, check sat -/
def testApiBool : IO TestResult := runTest "api boolean" do
  let result ← Api.run do
    let p ← boolConst "p"
    let q ← boolConst "q"
    withSolver fun s => do
      Api.assert s (← Api.and p (← Api.not q))
      checkSat s
  return check "api boolean" (result == .true) s!"expected sat, got {result}"

/-- Bitvector: x + y = 10 with 8-bit vectors -/
def testApiBv : IO TestResult := runTest "api bitvector" do
  let result ← Api.run do
    let x ← bvConst "x" 8
    let y ← bvConst "y" 8
    let ten ← bvVal 10 8
    withSolver fun s => do
      Api.assert s (← eq (← bvadd x y) ten)
      Api.assert s (← eq x (← bvVal 3 8))
      let model? ← solve s
      match model? with
      | some m => return Ast.getNumeralString (← Api.eval m y)
      | none => return "no model"
  return check "api bitvector" (result == "7") s!"expected 7, got {result}"

/-- Scoped push/pop -/
def testApiScope : IO TestResult := runTest "api scope" do
  let result ← Api.run do
    let x ← intConst "x"
    let zero ← intVal 0
    withSolver fun s => do
      Api.assert s (← gt x zero)
      -- Inner scope adds conflicting constraint
      let innerResult ← scope s do
        Api.assert s (← lt x zero)
        checkSat s
      -- After pop, should be sat again
      let outerResult ← checkSat s
      return (innerResult, outerResult)
  return check "api scope" (result.1 != .true && result.2 == .true)
    s!"expected (unsat, sat), got ({result.1}, {result.2})"

/-- withSolver + solve convenience -/
def testApiSolve : IO TestResult := runTest "api solve" do
  let result ← Api.run do
    let x ← intConst "x"
    withSolver fun s => do
      Api.assert s (← eq x (← intVal 42))
      let model? ← solve s
      match model? with
      | some m => evalInt m x
      | none => return 0
  return check "api solve" (result == 42) s!"expected 42, got {result}"

/-- Proof mode via Config -/
def testApiProofMode : IO TestResult := runTest "api proof mode" do
  let result ← Api.runWith { proofs := true } do
    let p ← boolConst "p"
    withSolver fun s => do
      Api.assert s p
      Api.assert s (← Api.not p)
      let sat ← checkSat s
      if sat == .false then
        let proof ← getProof s
        let proofStr := toString proof
        return proofStr.length
      else
        return 0
  return check "api proof mode" (result > 0) s!"expected non-empty proof, got length {result}"

/-- Uninterpreted functions -/
def testApiUF : IO TestResult := runTest "api uninterpreted functions" do
  let result ← Api.run do
    let is ← intSort
    let f ← funcDecl "f" #[is] is
    let zero ← intVal 0
    let one ← intVal 1
    let fZero ← app f #[zero]
    let fOne ← app f #[one]
    withSolver fun s => do
      Api.assert s (← eq fZero one)
      Api.assert s (← eq fOne zero)
      let model? ← solve s
      match model? with
      | some m =>
        let v0 := Ast.getNumeralString (← Api.eval m fZero)
        let v1 := Ast.getNumeralString (← Api.eval m fOne)
        return (v0, v1)
      | none => return ("", "")
  return check "api uninterpreted functions" (result == ("1", "0"))
    s!"expected (1, 0), got {result}"

/-- Array theory -/
def testApiArrays : IO TestResult := runTest "api arrays" do
  let result ← Api.run do
    let is ← intSort
    let arrSort ← arraySort is is
    let a ← const "a" arrSort
    let zero ← intVal 0
    let one ← intVal 1
    let a' ← store a zero one
    let sel ← select a' zero
    withSolver fun s => do
      let model? ← solve s
      match model? with
      | some m => return Ast.getNumeralString (← Api.eval m sel)
      | none => return "no model"
  return check "api arrays" (result == "1") s!"expected 1, got {result}"

def apiBasicTests : List (IO TestResult) :=
  [ testApiArithmetic
  , testApiBool
  , testApiBv
  , testApiScope
  , testApiSolve
  , testApiProofMode
  , testApiUF
  , testApiArrays
  ]

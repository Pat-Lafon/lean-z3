import Z3Test.Harness

open Z3

/-! ## String / Sequence theory tests -/

/-- String sort and literal creation -/
def testStringBasic : IO TestResult := runTest "String basic" do
  let ctx ← Env.run Context.new
  let _strSort := Srt.mkString ctx
  let hello := Ast.mkString ctx "hello"
  let s := Ast.getString ctx hello
  return check "String basic" (s == "hello")
    s!"expected 'hello', got '{s}'"

/-- String concatenation -/
def testStringConcat : IO TestResult := runTest "String concat" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let a := Ast.mkString ctx "ab"
  let b := Ast.mkString ctx "cd"
  let ab := Ast.mkSeqConcat ctx #[a, b]
  let expected := Ast.mkString ctx "abcd"
  Solver.assert solver (Ast.eq ctx ab expected)
  let result ← Solver.checkSat solver
  return check "String concat" (result == .true)
    s!"expected sat, got {result}"

/-- String length -/
def testStringLength : IO TestResult := runTest "String length" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello"
  let len := Ast.mkSeqLength ctx hello
  let intSort := Srt.mkInt ctx
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.eq ctx len five)
  let result ← Solver.checkSat solver
  return check "String length" (result == .true)
    s!"expected sat, got {result}"

/-- String contains -/
def testStringContains : IO TestResult := runTest "String contains" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello world"
  let world := Ast.mkString ctx "world"
  Solver.assert solver (Ast.mkSeqContains ctx hello world)
  let result ← Solver.checkSat solver
  return check "String contains" (result == .true)
    s!"expected sat, got {result}"

/-- String prefix/suffix -/
def testStringPrefixSuffix : IO TestResult := runTest "String prefix/suffix" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello"
  let he := Ast.mkString ctx "he"
  let lo := Ast.mkString ctx "lo"
  Solver.assert solver (Ast.mkSeqPrefix ctx he hello)
  Solver.assert solver (Ast.mkSeqSuffix ctx lo hello)
  let result ← Solver.checkSat solver
  return check "String prefix/suffix" (result == .true)
    s!"expected sat, got {result}"

/-- String extract (substring) -/
def testStringExtract : IO TestResult := runTest "String extract" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello"
  let intSort := Srt.mkInt ctx
  let one := Ast.mkNumeral ctx "1" intSort
  let three := Ast.mkNumeral ctx "3" intSort
  let sub := Ast.mkSeqExtract ctx hello one three
  let expected := Ast.mkString ctx "ell"
  Solver.assert solver (Ast.eq ctx sub expected)
  let result ← Solver.checkSat solver
  return check "String extract" (result == .true)
    s!"expected sat, got {result}"

/-- String at (single character) -/
def testStringAt : IO TestResult := runTest "String at" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let ch := Ast.mkSeqAt ctx hello zero
  let expected := Ast.mkString ctx "h"
  Solver.assert solver (Ast.eq ctx ch expected)
  let result ← Solver.checkSat solver
  return check "String at" (result == .true)
    s!"expected sat, got {result}"

/-- String index -/
def testStringIndex : IO TestResult := runTest "String index" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let hello := Ast.mkString ctx "hello"
  let ll := Ast.mkString ctx "ll"
  let intSort := Srt.mkInt ctx
  let zero := Ast.mkNumeral ctx "0" intSort
  let idx := Ast.mkSeqIndex ctx hello ll zero
  let two := Ast.mkNumeral ctx "2" intSort
  Solver.assert solver (Ast.eq ctx idx two)
  let result ← Solver.checkSat solver
  return check "String index" (result == .true)
    s!"expected sat, got {result}"

/-- String to int / int to string -/
def testStrIntConversion : IO TestResult := runTest "str/int conversion" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let s42 := Ast.mkString ctx "42"
  let n := Ast.mkStrToInt ctx s42
  let intSort := Srt.mkInt ctx
  let fortyTwo := Ast.mkNumeral ctx "42" intSort
  Solver.assert solver (Ast.eq ctx n fortyTwo)
  -- int to string round-trip
  let back := Ast.mkIntToStr ctx fortyTwo
  Solver.assert solver (Ast.eq ctx back s42)
  let result ← Solver.checkSat solver
  return check "str/int conversion" (result == .true)
    s!"expected sat, got {result}"

/-- Regex membership (seq_in_re) -/
def testRegexMembership : IO TestResult := runTest "regex membership" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  -- "abc" in re(a.b.c)
  let a := Ast.mkString ctx "a"
  let b := Ast.mkString ctx "b"
  let c := Ast.mkString ctx "c"
  let reA := Ast.mkSeqToRe ctx a
  let reB := Ast.mkSeqToRe ctx b
  let reC := Ast.mkSeqToRe ctx c
  let reABC := Ast.mkReConcat ctx #[reA, reB, reC]
  let abc := Ast.mkString ctx "abc"
  Solver.assert solver (Ast.mkSeqInRe ctx abc reABC)
  let result ← Solver.checkSat solver
  return check "regex membership" (result == .true)
    s!"expected sat, got {result}"

/-- Regex star -/
def testRegexStar : IO TestResult := runTest "regex star" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  -- "aaa" in re(a*)
  let a := Ast.mkString ctx "a"
  let reA := Ast.mkSeqToRe ctx a
  let reStar := Ast.mkReStar ctx reA
  let aaa := Ast.mkString ctx "aaa"
  Solver.assert solver (Ast.mkSeqInRe ctx aaa reStar)
  let result ← Solver.checkSat solver
  return check "regex star" (result == .true)
    s!"expected sat, got {result}"

/-- Regex union -/
def testRegexUnion : IO TestResult := runTest "regex union" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let a := Ast.mkString ctx "a"
  let b := Ast.mkString ctx "b"
  let reA := Ast.mkSeqToRe ctx a
  let reB := Ast.mkSeqToRe ctx b
  let reAorB := Ast.mkReUnion ctx #[reA, reB]
  -- "b" should be in (a|b)
  Solver.assert solver (Ast.mkSeqInRe ctx b reAorB)
  let result ← Solver.checkSat solver
  return check "regex union" (result == .true)
    s!"expected sat, got {result}"

/-- Regex range [a-z] -/
def testRegexRange : IO TestResult := runTest "regex range" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let a := Ast.mkString ctx "a"
  let z := Ast.mkString ctx "z"
  let reAZ := Ast.mkReRange ctx a z
  let rePlus := Ast.mkRePlus ctx reAZ
  let hello := Ast.mkString ctx "hello"
  Solver.assert solver (Ast.mkSeqInRe ctx hello rePlus)
  let result ← Solver.checkSat solver
  return check "regex range" (result == .true)
    s!"expected sat, got {result}"

/-- Symbolic string solving -/
def testStringSolving : IO TestResult := runTest "String solving" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let strSort := Srt.mkString ctx
  let x := Ast.mkConst ctx "x" strSort
  let intSort := Srt.mkInt ctx
  -- x contains "hello" and len(x) = 5, so x must be "hello"
  let hello := Ast.mkString ctx "hello"
  Solver.assert solver (Ast.mkSeqContains ctx x hello)
  let len := Ast.mkSeqLength ctx x
  let five := Ast.mkNumeral ctx "5" intSort
  Solver.assert solver (Ast.eq ctx len five)
  let result ← Solver.checkSat solver
  return check "String solving" (result == .true)
    s!"expected sat, got {result}"

/-- Seq sort (non-string sequences) -/
def testSeqSort : IO TestResult := runTest "Seq sort" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let seqSort := Srt.mkSeq ctx intSort
  let sortStr := Srt.toString' seqSort
  return check "Seq sort" (sortStr.length > 0)
    s!"expected non-empty sort string"

/-- Re sort -/
def testReSort : IO TestResult := runTest "Re sort" do
  let ctx ← Env.run Context.new
  let strSort := Srt.mkString ctx
  let reSort := Srt.mkRe ctx strSort
  let sortStr := Srt.toString' reSort
  return check "Re sort" (sortStr.length > 0)
    s!"expected non-empty sort string"

def stringTests : List (IO TestResult) :=
  [ testStringBasic
  , testStringConcat
  , testStringLength
  , testStringContains
  , testStringPrefixSuffix
  , testStringExtract
  , testStringAt
  , testStringIndex
  , testStrIntConversion
  , testRegexMembership
  , testRegexStar
  , testRegexUnion
  , testRegexRange
  , testStringSolving
  , testSeqSort
  , testReSort
  ]

import Z3

open Z3

/-! ## Test harness -/

structure TestResult where
  name : String
  passed : Bool
  message : String

def runTest (name : String) (test : IO TestResult) : IO TestResult := do
  try
    test
  catch e =>
    return { name, passed := false, message := s!"Exception: {e}" }

def check (name : String) (cond : Bool) (msg : String := "assertion failed") : TestResult :=
  if cond then { name, passed := true, message := "ok" }
  else { name, passed := false, message := msg }

def runTests (tests : List (IO TestResult)) : IO UInt32 := do
  let mut passed := 0
  let mut failed := 0
  for t in tests do
    let result ← t
    if result.passed then
      IO.println s!"  ✓ {result.name}"
      passed := passed + 1
    else
      IO.println s!"  ✗ {result.name}: {result.message}"
      failed := failed + 1
  IO.println ""
  IO.println s!"{passed}/{passed + failed} tests passed"
  if failed > 0 then
    return 1
  return 0

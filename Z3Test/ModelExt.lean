import Z3Test.Harness

open Z3

/-! ## Model (extended) tests -/

/-- Model.getNumFuncs / getFuncDecl for an uninterpreted function -/
def testModelGetNumFuncs : IO TestResult := runTest "Model.getNumFuncs" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  -- Declare uninterpreted function f : Int → Int
  let fDecl := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let fx := Ast.mkApp ctx fDecl #[x]
  -- Assert f(x) == 42
  Solver.assert solver (Ast.eq ctx fx (Ast.mkNumeral ctx "42" intSort))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "Model.getNumFuncs" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let numFuncs := Model.getNumFuncs model
  -- Should have at least 1 function interpretation (for f)
  if numFuncs == 0 then
    return check "Model.getNumFuncs" false "expected at least 1 function, got 0"
  -- Check we can retrieve the function declarations
  let mut foundF := false
  for i in [:numFuncs.toNat] do
    let fd := Model.getFuncDecl model i.toUInt32
    if FuncDecl.getName fd == "f" then foundF := true
  return check "Model.getNumFuncs" foundF
    s!"expected to find function 'f' among {numFuncs} functions"

/-- Model.hasInterp -/
def testModelHasInterp : IO TestResult := runTest "Model.hasInterp" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let fDecl := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let fx := Ast.mkApp ctx fDecl #[x]
  Solver.assert solver (Ast.eq ctx fx (Ast.mkNumeral ctx "10" intSort))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "Model.hasInterp" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let has := Model.hasInterp model fDecl
  return check "Model.hasInterp" has
    s!"expected hasInterp for f to be true"

/-- Model.getFuncInterp + FuncInterp.getElse / getArity -/
def testModelGetFuncInterp : IO TestResult := runTest "Model.getFuncInterp" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let fDecl := FuncDecl.mk ctx "f" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  let fx := Ast.mkApp ctx fDecl #[x]
  Solver.assert solver (Ast.eq ctx fx (Ast.mkNumeral ctx "10" intSort))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "Model.getFuncInterp" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let fi ← Env.run (Model.getFuncInterp model fDecl)
  let arity := FuncInterp.getArity fi
  if arity != 1 then
    return check "Model.getFuncInterp" false s!"expected arity 1, got {arity}"
  -- The else value should give us 10
  let elseVal := FuncInterp.getElse fi
  let elseStr := Ast.getNumeralString elseVal
  return check "Model.getFuncInterp" (elseStr == "10")
    s!"expected else value '10', got '{elseStr}'"

/-- FuncInterp entries for a piecewise function -/
def testFuncInterpEntries : IO TestResult := runTest "FuncInterp entries" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let fDecl := FuncDecl.mk ctx "g" #[intSort] intSort
  let zero := Ast.mkNumeral ctx "0" intSort
  let one := Ast.mkNumeral ctx "1" intSort
  let two := Ast.mkNumeral ctx "2" intSort
  let hundred := Ast.mkNumeral ctx "100" intSort
  let twohundred := Ast.mkNumeral ctx "200" intSort
  -- Assert g(1) = 100 and g(2) = 200
  let g1 := Ast.mkApp ctx fDecl #[one]
  let g2 := Ast.mkApp ctx fDecl #[two]
  Solver.assert solver (Ast.eq ctx g1 hundred)
  Solver.assert solver (Ast.eq ctx g2 twohundred)
  -- Also constrain g(0) so the model is more interesting
  let g0 := Ast.mkApp ctx fDecl #[zero]
  Solver.assert solver (Ast.eq ctx g0 zero)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "FuncInterp entries" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let fi ← Env.run (Model.getFuncInterp model fDecl)
  let numEntries := FuncInterp.getNumEntries fi
  -- Should have at least 2 entries (could have 3)
  if numEntries < 2 then
    return check "FuncInterp entries" false
      s!"expected at least 2 entries, got {numEntries}"
  -- Check that we can read entries and their args/values
  let mut ok := true
  for i in [:numEntries.toNat] do
    let entry := FuncInterp.getEntry fi i.toUInt32
    let numArgs := FuncEntry.getNumArgs entry
    if numArgs != 1 then
      ok := false
    let _arg := FuncEntry.getArg entry 0
    let _val := FuncEntry.getValue entry
    pure ()
  return check "FuncInterp entries" ok
    s!"expected 1 argument per entry"

/-- FuncEntry getValue / getArg round-trip -/
def testFuncEntryValues : IO TestResult := runTest "FuncEntry values" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  let fDecl := FuncDecl.mk ctx "h" #[intSort] intSort
  -- Two distinct points force Z3 to create actual entries
  let five := Ast.mkNumeral ctx "5" intSort
  let six := Ast.mkNumeral ctx "6" intSort
  let fifty := Ast.mkNumeral ctx "50" intSort
  let sixty := Ast.mkNumeral ctx "60" intSort
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx fDecl #[five]) fifty)
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx fDecl #[six]) sixty)
  let result ← Solver.checkSat solver
  if result != .true then
    return check "FuncEntry values" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let fi ← Env.run (Model.getFuncInterp model fDecl)
  let numEntries := FuncInterp.getNumEntries fi
  -- Collect all arg→value mappings
  let mut mappings : List (String × String) := []
  for i in [:numEntries.toNat] do
    let entry := FuncInterp.getEntry fi i.toUInt32
    let arg := FuncEntry.getArg entry 0
    let val := FuncEntry.getValue entry
    mappings := mappings ++ [(Ast.getNumeralString arg, Ast.getNumeralString val)]
  -- At least one entry should exist (the other might be the else value)
  if numEntries == 0 then
    return check "FuncEntry values" false "expected at least 1 entry, got 0"
  -- Verify entries have correct numArgs
  let entry0 := FuncInterp.getEntry fi 0
  let numArgs := FuncEntry.getNumArgs entry0
  return check "FuncEntry values" (numArgs == 1)
    s!"expected 1 arg per entry, got {numArgs}; mappings: {mappings}"

/-- Model.getSortUniverse for an uninterpreted sort -/
def testModelSortUniverse : IO TestResult := runTest "Model.getSortUniverse" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  -- Create an uninterpreted sort
  let colorSort := Srt.mkUninterpreted ctx "Color"
  -- Create constants of that sort
  let r := Ast.mkConst ctx "red" colorSort
  let g := Ast.mkConst ctx "green" colorSort
  -- Assert they are distinct
  Solver.assert solver (Ast.distinct ctx #[r, g])
  let result ← Solver.checkSat solver
  if result != .true then
    return check "Model.getSortUniverse" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let univ ← Env.run (Model.getSortUniverse model colorSort)
  -- Universe should have at least 2 elements
  return check "Model.getSortUniverse" (univ.size ≥ 2)
    s!"expected univ size >= 2, got {univ.size}"

/-- Model iteration: list all function interpretations -/
def testModelFuncIteration : IO TestResult := runTest "Model func iteration" do
  let ctx ← Env.run Context.new
  let solver ← Solver.new ctx
  let intSort := Srt.mkInt ctx
  -- Two functions
  let fDecl := FuncDecl.mk ctx "f" #[intSort] intSort
  let gDecl := FuncDecl.mk ctx "g" #[intSort] intSort
  let x := Ast.mkIntConst ctx "x"
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx fDecl #[x]) (Ast.mkNumeral ctx "1" intSort))
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx gDecl #[x]) (Ast.mkNumeral ctx "2" intSort))
  let result ← Solver.checkSat solver
  if result != .true then
    return check "Model func iteration" false s!"expected sat, got {result}"
  let model ← Env.run (Solver.getModel solver)
  let numFuncs := Model.getNumFuncs model
  let mut names : List String := []
  for i in [:numFuncs.toNat] do
    let fd := Model.getFuncDecl model i.toUInt32
    names := names ++ [FuncDecl.getName fd]
  let hasF := names.contains "f"
  let hasG := names.contains "g"
  return check "Model func iteration" (hasF && hasG)
    s!"expected both f and g in model functions, got {names}"

def modelExtTests : List (IO TestResult) :=
  [ testModelGetNumFuncs
  , testModelHasInterp
  , testModelGetFuncInterp
  , testFuncInterpEntries
  , testFuncEntryValues
  , testModelSortUniverse
  , testModelFuncIteration
  ]

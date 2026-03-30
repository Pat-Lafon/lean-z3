import Z3Test.Harness

open Z3

/-! ## Sort inspection (extended) tests -/

/-- Array sort domain/range inspection -/
def testArraySortDomainRange : IO TestResult := runTest "array sort domain/range" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let arrSort := Srt.mkArray ctx intSort boolSort
  let domain := Srt.getArraySortDomain ctx arrSort
  let range := Srt.getArraySortRange ctx arrSort
  let domStr := Srt.toString' domain
  let ranStr := Srt.toString' range
  let ok := domStr == Srt.toString' intSort && ranStr == Srt.toString' boolSort
  return check "array sort domain/range" ok
    s!"expected Int/Bool, got '{domStr}'/'{ranStr}'"

/-- Array sort domain N (for standard arrays, index 0 = domain) -/
def testArraySortDomainN : IO TestResult := runTest "array sort domain N" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let realSort := Srt.mkReal ctx
  let arrSort := Srt.mkArray ctx intSort realSort
  let domain0 := Srt.getArraySortDomainN ctx arrSort 0
  let domStr := Srt.toString' domain0
  return check "array sort domain N" (domStr == Srt.toString' intSort)
    s!"expected Int, got '{domStr}'"

/-- Datatype sort num constructors -/
def testDatatypeNumConstructors : IO TestResult := runTest "datatype num constructors" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let noneCon ← Env.run (Constructor.mk ctx "None" "is_None" #[] #[] #[])
  let someCon ← Env.run (Constructor.mk ctx "Some" "is_Some" #["val"] #[intSort] #[0])
  let dt ← Env.run (Srt.mkDatatype ctx "MaybeInt" #[noneCon, someCon])
  let n := Srt.getDatatypeSortNumConstructors ctx dt
  return check "datatype num constructors" (n == 2)
    s!"expected 2, got {n}"

/-- Datatype sort constructor/recognizer -/
def testDatatypeConstructorRecognizer : IO TestResult := runTest "datatype constructor/recognizer" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let noneCon ← Env.run (Constructor.mk ctx "None" "is_None" #[] #[] #[])
  let someCon ← Env.run (Constructor.mk ctx "Some" "is_Some" #["val"] #[intSort] #[0])
  let dt ← Env.run (Srt.mkDatatype ctx "MaybeInt" #[noneCon, someCon])
  let con0 := Srt.getDatatypeSortConstructor ctx dt 0
  let rec0 := Srt.getDatatypeSortRecognizer ctx dt 0
  let con0Name := FuncDecl.getName con0
  let rec0Name := FuncDecl.getName rec0
  -- Z3 may shorten recognizer names; just check constructor name and that recognizer exists
  let ok := con0Name == "None" && rec0Name.length > 0
  return check "datatype constructor/recognizer" ok
    s!"expected 'None' constructor and non-empty recognizer, got '{con0Name}'/'{rec0Name}'"

/-- Datatype sort constructor accessor -/
def testDatatypeAccessor : IO TestResult := runTest "datatype accessor" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let noneCon ← Env.run (Constructor.mk ctx "None" "is_None" #[] #[] #[])
  let someCon ← Env.run (Constructor.mk ctx "Some" "is_Some" #["val"] #[intSort] #[0])
  let dt ← Env.run (Srt.mkDatatype ctx "MaybeInt" #[noneCon, someCon])
  -- Constructor 1 (Some) has accessor 0 (val)
  let acc := Srt.getDatatypeSortConstructorAccessor ctx dt 1 0
  let accName := FuncDecl.getName acc
  return check "datatype accessor" (accName == "val")
    s!"expected 'val', got '{accName}'"

/-- Datatype inspection with solver -/
def testDatatypeInspectionSolve : IO TestResult := runTest "datatype inspection solve" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let intSort := Srt.mkInt ctx
  let noneCon ← Env.run (Constructor.mk ctx "None" "is_None" #[] #[] #[])
  let someCon ← Env.run (Constructor.mk ctx "Some" "is_Some" #["val"] #[intSort] #[0])
  let dt ← Env.run (Srt.mkDatatype ctx "MaybeInt" #[noneCon, someCon])
  -- Use inspected constructor to build terms
  let someDecl := Srt.getDatatypeSortConstructor ctx dt 1
  let isSomeDecl := Srt.getDatatypeSortRecognizer ctx dt 1
  let valDecl := Srt.getDatatypeSortConstructorAccessor ctx dt 1 0
  let five := Ast.mkNumeral ctx "5" intSort
  let someFive := Ast.mkApp ctx someDecl #[five]
  -- is_Some(Some(5)) should hold
  Solver.assert solver (Ast.mkApp ctx isSomeDecl #[someFive])
  -- val(Some(5)) = 5
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx valDecl #[someFive]) five)
  let result ← Solver.checkSat solver
  return check "datatype inspection solve" (result == .true)
    s!"expected sat, got {result}"

def sortInspectTests : List (IO TestResult) :=
  [ testArraySortDomainRange
  , testArraySortDomainN
  , testDatatypeNumConstructors
  , testDatatypeConstructorRecognizer
  , testDatatypeAccessor
  , testDatatypeInspectionSolve
  ]

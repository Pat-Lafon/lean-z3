import Z3Test.Harness

open Z3

private unsafe def unsafeGetFD (a : Array FuncDecl) (i : Nat) : FuncDecl :=
  a.uget (USize.ofNat i) lcProof
@[implemented_by unsafeGetFD]
private opaque getFD (a : Array FuncDecl) (i : Nat) : FuncDecl

private unsafe def unsafeGetSrt (a : Array Srt) (i : Nat) : Srt :=
  a.uget (USize.ofNat i) lcProof
@[implemented_by unsafeGetSrt]
private opaque getSrt (a : Array Srt) (i : Nat) : Srt

/-! ## Additional sorts tests -/

/-- Finite domain sort -/
def testFiniteDomainSort : IO TestResult := runTest "finite domain sort" do
  let ctx ← Env.run Context.new
  let solver ← Env.run (Solver.new ctx)
  let fd := Srt.mkFiniteDomain ctx "Color" 3
  let x := Ast.mkConst ctx "x" fd
  let y := Ast.mkConst ctx "y" fd
  -- x ≠ y is satisfiable (3 elements)
  Solver.assert solver (Ast.not ctx (Ast.eq ctx x y))
  let result ← Solver.checkSat solver
  return check "finite domain sort" (result == .true)
    s!"expected sat, got {result}"

/-- Char sort -/
def testCharSort : IO TestResult := runTest "char sort" do
  let ctx ← Env.run Context.new
  let charSort := Srt.mkChar ctx
  let sortStr := Srt.toString' charSort
  return check "char sort" (sortStr.length > 0)
    s!"expected non-empty sort string"

/-- Enumeration sort -/
def testEnumerationSort : IO TestResult := runTest "enumeration sort" do
  let ctx ← Env.run Context.new
  let (sort, consts, testers) ← Env.run
    (Srt.mkEnumeration ctx "Color" #["Red", "Green", "Blue"])
  let solver ← Env.run (Solver.new ctx)
  -- Create Red, Green values via the enum constant func_decls (0-arity)
  let red := Ast.mkApp ctx (getFD consts 0) #[]
  let green := Ast.mkApp ctx (getFD consts 1) #[]
  -- Red ≠ Green
  Solver.assert solver (Ast.not ctx (Ast.eq ctx red green))
  let result ← Solver.checkSat solver
  -- Test tester: is_Red(Red) should be true
  Solver.assert solver (Ast.mkApp ctx (getFD testers 0) #[red])
  let result2 ← Solver.checkSat solver
  let ok := result == .true && result2 == .true
    && consts.size == 3 && testers.size == 3
    && (Srt.toString' sort).length > 0
  return check "enumeration sort" ok
    s!"expected sat and 3 consts/testers, got {result}, {result2}, {consts.size}, {testers.size}"

/-- List sort -/
def testListSort : IO TestResult := runTest "list sort" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let (listSort, nilDecl, isNilDecl, consDecl, isConsDecl, headDecl, tailDecl) ←
    Env.run (Srt.mkList ctx "IntList" intSort)
  let solver ← Env.run (Solver.new ctx)
  -- nil
  let nilVal := Ast.mkApp ctx nilDecl #[]
  -- is_nil(nil) should hold
  Solver.assert solver (Ast.mkApp ctx isNilDecl #[nilVal])
  let result ← Solver.checkSat solver
  -- cons(1, nil)
  Solver.reset solver
  let one := Ast.mkNumeral ctx "1" intSort
  let lst := Ast.mkApp ctx consDecl #[one, nilVal]
  -- is_cons(cons(1, nil))
  Solver.assert solver (Ast.mkApp ctx isConsDecl #[lst])
  -- head(cons(1, nil)) = 1
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx headDecl #[lst]) one)
  -- tail(cons(1, nil)) = nil
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx tailDecl #[lst]) nilVal)
  let result2 ← Solver.checkSat solver
  let ok := result == .true && result2 == .true
    && (Srt.toString' listSort).length > 0
  return check "list sort" ok
    s!"expected sat, got {result}, {result2}"

/-- Tuple sort -/
def testTupleSort : IO TestResult := runTest "tuple sort" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let boolSort := Srt.mkBool ctx
  let (tupleSort, mkTuple, projs) ← Env.run
    (Srt.mkTuple ctx "IntBool" #["fst", "snd"] #[intSort, boolSort])
  let solver ← Env.run (Solver.new ctx)
  -- Create tuple (42, true)
  let fortyTwo := Ast.mkNumeral ctx "42" intSort
  let tt := Ast.mkBool ctx true
  let tup := Ast.mkApp ctx mkTuple #[fortyTwo, tt]
  -- fst(tup) = 42
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx (getFD projs 0) #[tup]) fortyTwo)
  -- snd(tup) = true
  Solver.assert solver (Ast.eq ctx (Ast.mkApp ctx (getFD projs 1) #[tup]) tt)
  let result ← Solver.checkSat solver
  let ok := result == .true && projs.size == 2
    && (Srt.toString' tupleSort).length > 0
  return check "tuple sort" ok
    s!"expected sat with 2 projections, got {result}, {projs.size}"

/-- Mutually recursive datatypes -/
def testMutualDatatypes : IO TestResult := runTest "mutual datatypes" do
  let ctx ← Env.run Context.new
  -- Tree = Leaf(Int) | Node(Forest)
  -- Forest = Nil | Cons(Tree, Forest)
  let intSort := Srt.mkInt ctx
  let leafCon ← Env.run (Constructor.mk ctx "Leaf" "is_Leaf"
    #["val"] #[intSort] #[0])
  -- Node has a field of sort Forest (index 1 in the sort array)
  let nodeCon ← Env.run (Constructor.mk ctx "Node" "is_Node"
    #["children"] #[intSort] #[1])  -- sort ref 1 = Forest
  let nilCon ← Env.run (Constructor.mk ctx "FNil" "is_FNil"
    #[] #[] #[])
  let consCon ← Env.run (Constructor.mk ctx "FCons" "is_FCons"
    #["head", "tail"] #[intSort, intSort] #[0, 1])  -- sort refs: 0=Tree, 1=Forest
  let sorts ← Env.run (Srt.mkDatatypes ctx
    #["Tree", "Forest"]
    #[#[leafCon, nodeCon], #[nilCon, consCon]])
  let ok := sorts.size == 2
    && (Srt.toString' (getSrt sorts 0)).length > 0
    && (Srt.toString' (getSrt sorts 1)).length > 0
  return check "mutual datatypes" ok
    s!"expected 2 sorts, got {sorts.size}"

/-- Tuple sort symbolic solving -/
def testTupleSolving : IO TestResult := runTest "tuple solving" do
  let ctx ← Env.run Context.new
  let intSort := Srt.mkInt ctx
  let (tupleSort, _mkTuple, projs) ← Env.run
    (Srt.mkTuple ctx "Pair" #["x", "y"] #[intSort, intSort])
  let solver ← Env.run (Solver.new ctx)
  let p := Ast.mkConst ctx "p" tupleSort
  let ten := Ast.mkNumeral ctx "10" intSort
  -- fst(p) + snd(p) = 10
  Solver.assert solver (Ast.eq ctx
    (Ast.add ctx (Ast.mkApp ctx (getFD projs 0) #[p]) (Ast.mkApp ctx (getFD projs 1) #[p]))
    ten)
  -- fst(p) > 0, snd(p) > 0
  let zero := Ast.mkNumeral ctx "0" intSort
  Solver.assert solver (Ast.gt ctx (Ast.mkApp ctx (getFD projs 0) #[p]) zero)
  Solver.assert solver (Ast.gt ctx (Ast.mkApp ctx (getFD projs 1) #[p]) zero)
  let result ← Solver.checkSat solver
  return check "tuple solving" (result == .true)
    s!"expected sat, got {result}"

def additionalSortTests : List (IO TestResult) :=
  [ testFiniteDomainSort
  , testCharSort
  , testEnumerationSort
  , testListSort
  , testTupleSort
  , testMutualDatatypes
  , testTupleSolving
  ]

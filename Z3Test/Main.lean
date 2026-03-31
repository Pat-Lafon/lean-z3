import Z3Test.Basic
import Z3Test.Z3Rs
import Z3Test.Arrays
import Z3Test.Proofs
import Z3Test.Bitvectors
import Z3Test.UnsatCore
import Z3Test.Arithmetic
import Z3Test.UninterpFun
import Z3Test.Numerals
import Z3Test.Quantifiers
import Z3Test.Subst
import Z3Test.DeclKind
import Z3Test.ModelExt
import Z3Test.PseudoBool
import Z3Test.AstUtils
import Z3Test.Optimize
import Z3Test.Tactics
import Z3Test.Strings
import Z3Test.FloatingPoint
import Z3Test.Sets
import Z3Test.AdditionalSorts
import Z3Test.SortInspect
import Z3Test.SolverExt
import Z3Test.Fixedpoint
import Z3Test.Probes
import Z3Test.UserProp
import Z3Test.Simplifier
import Z3Test.FpaInspect
import Z3Test.QuantElim
import Z3Test.ApiBasic

def main : IO UInt32 :=
  runTests (basicTests ++ z3rsTests ++ arrayTests ++ proofTests
    ++ bitvectorTests ++ unsatCoreTests ++ arithmeticTests ++ uninterpFunTests
    ++ numeralTests ++ quantifierTests ++ substTests ++ declKindTests
    ++ modelExtTests ++ pseudoBoolTests ++ astUtilTests ++ optimizeTests
    ++ tacticTests ++ stringTests ++ floatingPointTests ++ setTests
    ++ additionalSortTests ++ sortInspectTests ++ solverExtTests
    ++ fixedpointTests ++ probeTests ++ userPropTests ++ simplifierTests
    ++ fpaInspectTests ++ quantElimTests ++ apiBasicTests)

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

def main : IO UInt32 :=
  runTests (basicTests ++ z3rsTests ++ arrayTests ++ proofTests
    ++ bitvectorTests ++ unsatCoreTests ++ arithmeticTests ++ uninterpFunTests
    ++ numeralTests ++ quantifierTests ++ substTests ++ declKindTests
    ++ modelExtTests ++ pseudoBoolTests ++ astUtilTests)

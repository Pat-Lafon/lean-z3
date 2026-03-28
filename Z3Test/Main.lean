import Z3Test.Basic
import Z3Test.Z3Rs
import Z3Test.Arrays
import Z3Test.Proofs
import Z3Test.Bitvectors
import Z3Test.UnsatCore

def main : IO UInt32 :=
  runTests (basicTests ++ z3rsTests ++ arrayTests ++ proofTests
    ++ bitvectorTests ++ unsatCoreTests)

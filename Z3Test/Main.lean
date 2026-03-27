import Z3Test.Basic
import Z3Test.Z3Rs
import Z3Test.Arrays
import Z3Test.Proofs

def main : IO UInt32 :=
  runTests (basicTests ++ z3rsTests ++ arrayTests ++ proofTests)

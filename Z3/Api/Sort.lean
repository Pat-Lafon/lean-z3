import Z3.Api.Monad

namespace Z3.Api

def boolSort : Z3M Srt := return Srt.mkBool (← getCtx)
def intSort : Z3M Srt := return Srt.mkInt (← getCtx)
def realSort : Z3M Srt := return Srt.mkReal (← getCtx)
def bvSort (size : UInt32) : Z3M Srt := return Srt.mkBv (← getCtx) size
def uninterpretedSort (name : String) : Z3M Srt := return Srt.mkUninterpreted (← getCtx) name
def arraySort (domain range : Srt) : Z3M Srt := return Srt.mkArray (← getCtx) domain range
def stringSort : Z3M Srt := return Srt.mkString (← getCtx)
def seqSort (elem : Srt) : Z3M Srt := return Srt.mkSeq (← getCtx) elem
def reSort (elem : Srt) : Z3M Srt := return Srt.mkRe (← getCtx) elem
def setSort (elem : Srt) : Z3M Srt := return Srt.mkSet (← getCtx) elem
def charSort : Z3M Srt := return Srt.mkChar (← getCtx)
def fpaSort (ebits sbits : UInt32) : Z3M Srt := return Srt.mkFpa (← getCtx) ebits sbits
def fpa16Sort : Z3M Srt := return Srt.mkFpa16 (← getCtx)
def fpa32Sort : Z3M Srt := return Srt.mkFpa32 (← getCtx)
def fpa64Sort : Z3M Srt := return Srt.mkFpa64 (← getCtx)
def fpa128Sort : Z3M Srt := return Srt.mkFpa128 (← getCtx)
def finiteDomainSort (name : String) (size : UInt64) : Z3M Srt :=
  return Srt.mkFiniteDomain (← getCtx) name size

end Z3.Api

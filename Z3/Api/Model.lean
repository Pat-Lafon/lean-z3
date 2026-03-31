import Z3.Api.Monad

namespace Z3.Api

/-- Evaluate an expression in a model (with completion by default). -/
def eval (m : Model) (a : Ast) (completion : Bool := true) : Z3M Ast :=
  liftEnv (Model.eval m a completion)

/-- Get the integer value of an expression in a model. -/
def evalInt (m : Model) (a : Ast) : Z3M Int := do
  let val ← liftEnv (Model.eval m a true)
  return (Ast.getNumeralString val).toInt!

/-- Get the Boolean value of an expression in a model. -/
def evalBool (m : Model) (a : Ast) : Z3M (Option Bool) := do
  let val ← liftEnv (Model.eval m a true)
  match Ast.getBoolValue val with
  | .true => return some true
  | .false => return some false
  | .undef => return none

/-- Iterate over all constant assignments in a model. -/
def forConstants (m : Model) (f : FuncDecl → Ast → Z3M Unit) : Z3M Unit := do
  let n := Model.getNumConsts m
  for i in List.range n.toNat do
    let fd := Model.getConstDecl m i.toUInt32
    let val ← liftEnv (Model.getConstInterp m fd)
    f fd val

end Z3.Api

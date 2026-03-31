import Z3.Api.Monad

namespace Z3.Api

/-- Create a new solver. -/
def mkSolver : Z3M Solver := do Solver.new (← getCtx)

/-- Create a solver for a specific logic (e.g., "QF_LIA", "QF_BV"). -/
def mkSolverForLogic (logic : String) : Z3M Solver := do
  liftEnv (Solver.mkForLogic (← getCtx) logic)

/-- Create a solver from a tactic. -/
def mkSolverFromTactic (t : Tactic) : Z3M Solver := do
  liftEnv (Solver.fromTactic (← getCtx) t)

/-- Run an action with a fresh solver. -/
def withSolver (action : Solver → Z3M α) : Z3M α := do
  let s ← mkSolver
  action s

/-- Run an action inside a push/pop scope on the solver.
    The scope is always popped, even on error. -/
def scope (s : Solver) (action : Z3M α) : Z3M α := do
  Solver.push s
  try
    let result ← action
    Solver.pop s 1
    return result
  catch e =>
    Solver.pop s 1
    throw e

/-- Assert a constraint on the solver. -/
def assert (s : Solver) (a : Ast) : Z3M PUnit := Solver.assert s a

/-- Assert multiple constraints on the solver. -/
def assertAll (s : Solver) (constraints : Array Ast) : Z3M PUnit := do
  for c in constraints do
    Solver.assert s c

/-- Check satisfiability. -/
def checkSat (s : Solver) : Z3M LBool := Solver.checkSat s

/-- Check satisfiability and return the model if sat. -/
def solve (s : Solver) : Z3M (Option Model) := do
  let result ← Solver.checkSat s
  match result with
  | .true => return some (← liftEnv (Solver.getModel s))
  | _ => return none

/-- Get the model (after a successful checkSat). -/
def getModel (s : Solver) : Z3M Model := liftEnv (Solver.getModel s)

/-- Get the proof (after checkSat returns unsat, requires proof context). -/
def getProof (s : Solver) : Z3M Ast := liftEnv (Solver.getProof s)

/-- Get the unsat core. -/
def getUnsatCore (s : Solver) : Z3M (Array Ast) := Solver.getUnsatCore s

/-- Create new params in the current context. -/
def mkParams : Z3M Params := do Params.new (← getCtx)

end Z3.Api

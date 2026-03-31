import Z3.FFI

namespace Z3.Api

/-- Configuration for Z3 context creation. -/
structure Config where
  proofs : Bool := false

/-- The Z3 monad: threads a `Context` implicitly and handles errors via `Env`. -/
abbrev Z3M (α : Type) := ReaderT Context Env α

/-- Retrieve the Z3 context from the environment. -/
def getCtx : Z3M Context := read

/-- Lift a raw `Env` action into `Z3M`. -/
def liftEnv (action : Env α) : Z3M α :=
  fun _ => action

/-- Run a `Z3M` computation with the given configuration, creating a fresh context.
    Errors are surfaced as `IO.Error`. -/
def runWith (cfg : Config) (action : Z3M α) : IO α := do
  let ctx ← Env.run (if cfg.proofs then Context.newWithProofs else Context.new)
  let result : Except Error α ← liftM (ExceptT.run (action ctx))
  match result with
  | .ok a => pure a
  | .error e => throw <| IO.userError (toString e)

/-- Run a `Z3M` computation, creating a fresh context with default configuration.
    Errors are surfaced as `IO.Error`. -/
def run (action : Z3M α) : IO α := runWith {} action

end Z3.Api

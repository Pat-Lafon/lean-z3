import Z3.Types

namespace Z3

/-- Z3 environment monad transformer.
Threads error handling for Z3 operations.
-/
abbrev EnvT (m : Type → Type) (α : Type) : Type :=
  ExceptT Error m α

/-- Z3 environment monad in `BaseIO`. -/
abbrev Env (α : Type) := EnvT BaseIO α

namespace Env

-- Functions used by the underlying C layer
section ffi

@[export z3_env_pure]
private def env_pure (a : α) : Env α := return a

@[export z3_env_bool]
private def env_bool (b : Bool) : Env Bool := return b

@[export z3_env_string]
private def env_string (s : String) : Env String := return s

@[export z3_env_uint32]
private def env_uint32 (u : UInt32) : Env UInt32 := return u

@[export z3_env_uint64]
private def env_uint64 (u : UInt64) : Env UInt64 := return u

@[export z3_env_throw]
private def env_throw (e : Error) : Env α := throw e

@[export z3_env_throw_string]
private def env_throw_string (msg : String) : Env α := throw (.error msg)

end ffi

/-- Run an `Env` action in `IO`, throwing on errors. -/
def run (action : Env α) : IO α := do
  let result : Except Error α ← liftM (ExceptT.run action)
  match result with
  | .ok a => pure a
  | .error e => throw <| IO.userError (toString e)

end Env

end Z3

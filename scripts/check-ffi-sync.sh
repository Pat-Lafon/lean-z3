#!/usr/bin/env bash
# check-ffi-sync.sh — Verify Lean @[extern] declarations match C LEAN_EXPORT functions.
#
# Exits 0 if every Lean extern has a C implementation and vice versa.
# Exits 1 if there are mismatches (missing on either side).
#
# Usage:
#   ./scripts/check-ffi-sync.sh          # check sync only
#   ./scripts/check-ffi-sync.sh --coverage /path/to/z3/include
#                                         # also report Z3 API coverage

set -euo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FFI_LEAN="$REPO_ROOT/Z3/FFI.lean"
FFI_C="$REPO_ROOT/ffi/z3_ffi.c"

# Extract sorted lists of extern names
lean_externs=$(sed -n 's/.*@\[extern "\([^"]*\)".*/\1/p' "$FFI_LEAN" | sort)
c_exports=$(sed -n 's/^LEAN_EXPORT[[:space:]]*[^ ]*[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' "$FFI_C" | sort)

lean_count=$(echo "$lean_externs" | wc -l | tr -d ' ')
c_count=$(echo "$c_exports" | wc -l | tr -d ' ')

echo "Lean @[extern] declarations: $lean_count"
echo "C LEAN_EXPORT functions:     $c_count"

# Find mismatches
in_lean_not_c=$(comm -23 <(echo "$lean_externs") <(echo "$c_exports"))
in_c_not_lean=$(comm -13 <(echo "$lean_externs") <(echo "$c_exports"))

errors=0

if [ -n "$in_lean_not_c" ]; then
  echo ""
  echo "ERROR: Lean externs missing C implementation:"
  echo "$in_lean_not_c" | sed 's/^/  - /'
  errors=1
fi

if [ -n "$in_c_not_lean" ]; then
  echo ""
  echo "ERROR: C exports missing Lean @[extern] declaration:"
  echo "$in_c_not_lean" | sed 's/^/  - /'
  errors=1
fi

if [ "$errors" -eq 0 ]; then
  echo "OK: All $lean_count extern declarations are in sync."
fi

# Optional: Z3 API coverage report
if [ "${1:-}" = "--coverage" ] && [ -n "${2:-}" ]; then
  z3_include="$2"
  echo ""
  echo "--- Z3 API Coverage ---"

  # Collect all Z3_API function names from headers
  z3_api=$(find "$z3_include" -name '*.h' -exec \
    sed -n 's/.*Z3_API[[:space:]]*\(Z3_[a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' {} + | sort -u)
  z3_total=$(echo "$z3_api" | wc -l | tr -d ' ')

  # Find Z3 API calls in our C code
  z3_used=$(sed -n 's/.*\(Z3_[a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' "$FFI_C" | sort -u)
  z3_bound=$(comm -12 <(echo "$z3_api") <(echo "$z3_used"))
  z3_bound_count=$(echo "$z3_bound" | wc -l | tr -d ' ')

  echo "Z3 API functions (total): $z3_total"
  echo "Z3 API functions (bound): $z3_bound_count"

  if command -v python3 &>/dev/null; then
    python3 -c "print(f'Coverage: {$z3_bound_count/$z3_total*100:.1f}%')"
  fi

  # Show unbound functions grouped by prefix
  z3_unbound=$(comm -23 <(echo "$z3_api") <(echo "$z3_used"))
  unbound_count=$(echo "$z3_unbound" | grep -c . || true)
  if [ "$unbound_count" -gt 0 ]; then
    echo ""
    echo "Unbound Z3 functions ($unbound_count):"
    echo "$z3_unbound" | sed 's/^/  /'
  fi
fi

exit "$errors"

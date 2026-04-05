#!/usr/bin/env bash
# tests/test_sac.sh — unit tests for sac.sh
#
# Run from the repo root:
#   bash tests/test_sac.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAC="$SCRIPT_DIR/../sac.sh"

PASS=0
FAIL=0

# ── Minimal test framework ─────────────────────────────────────────────────────
ok() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '✅  PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '❌  FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

expect_output() {
  local name="$1" pattern="$2"; shift 2
  local out
  out=$("$@" 2>&1 || true)
  if printf '%s' "$out" | grep -q -e "$pattern"; then
    printf '✅  PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '❌  FAIL: %s (pattern "%s" not found in output)\n' "$name" "$pattern"
    printf '         Output was: %s\n' "$out"
    FAIL=$((FAIL + 1))
  fi
}

expect_exit() {
  local name="$1" expected_code="$2"; shift 2
  local actual_code=0
  "$@" >/dev/null 2>&1 || actual_code=$?
  if [[ "$actual_code" -eq "$expected_code" ]]; then
    printf '✅  PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '❌  FAIL: %s (expected exit %d, got %d)\n' "$name" "$expected_code" "$actual_code"
    FAIL=$((FAIL + 1))
  fi
}

# ── Tests ──────────────────────────────────────────────────────────────────────

# 1. Script exists and is readable
ok "sac.sh exists" test -f "$SAC"

# 2. --help flag prints usage and exits 0
ok "--help exits 0" bash "$SAC" --help
expect_output "--help mentions default one-line" "single line" bash "$SAC" --help
expect_output "--help mentions funny"  "funny"   bash "$SAC" --help
expect_output "--help mentions config" "OPENROUTER_API_KEY" bash "$SAC" --help

# 3. Missing API key exits with an error (use an empty XDG_CONFIG_HOME so no config is loaded)
expect_exit "no API key → exit 1" 1 \
  env -u OPENROUTER_API_KEY XDG_CONFIG_HOME=/tmp/sac-no-cfg bash "$SAC"

expect_output "no API key → error message" "OPENROUTER_API_KEY" \
  env -u OPENROUTER_API_KEY XDG_CONFIG_HOME=/tmp/sac-no-cfg bash "$SAC"

# 4. Unknown CLI flag exits with an error
expect_output "unknown flag → error message" "Unknown argument" \
  bash "$SAC" --not-a-valid-flag 2>&1 || true

# 4b. Invalid SAC_STYLE still surfaces as Unknown style (isolated config so ~/.config does not override)
expect_output "invalid SAC_STYLE → error message" "Unknown style" \
  env OPENROUTER_API_KEY="test-key" SAC_STYLE=bogus bash -c '
    _xdg=$(mktemp -d)
    _tmpbin=$(mktemp -d)
    cat >"$_tmpbin/git" <<'"'"'GIT'"'"'
#!/usr/bin/env bash
if [[ "$1" == "diff" ]]; then echo "fake diff"; else command git "$@"; fi
GIT
    chmod +x "$_tmpbin/git"
    XDG_CONFIG_HOME="$_xdg" PATH="$_tmpbin:$PATH" bash '"$SAC"' 2>&1 || true
    rm -rf "$_tmpbin" "$_xdg"
  '

# 5. No staged changes → informative error
expect_output "no staged changes → error message" "staged" \
  env OPENROUTER_API_KEY="test-key" \
  bash -c '
    _tmpdir=$(mktemp -d)
    cd "$_tmpdir"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    bash '"$SAC"' 2>&1 || true
    rm -rf "$_tmpdir"
  '

# 6. Style options appear in --help
expect_output "--help mentions --funny"    "--funny"    bash "$SAC" --help
expect_output "--help mentions --detailed" "--detailed" bash "$SAC" --help

# 7. config.example has all required keys
ok "config.example exists" test -f "$SCRIPT_DIR/../config.example"
expect_output "config.example has OPENROUTER_API_KEY" "OPENROUTER_API_KEY" \
  cat "$SCRIPT_DIR/../config.example"
expect_output "config.example has MODEL"              "MODEL"              \
  cat "$SCRIPT_DIR/../config.example"
expect_output "config.example documents STYLE"         "# STYLE="          \
  cat "$SCRIPT_DIR/../config.example"

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]] || exit 1

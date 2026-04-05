#!/usr/bin/env bash
# sac - Simple AI Commit
# Generates a git commit message from staged changes using OpenRouter.
#
# Usage:
#   sac [--funny|--detailed] [--model MODEL]   (default: one-line message)
#
# Config file: ~/.config/simple-ai-commit/config

set -euo pipefail

# ── Config location ────────────────────────────────────────────────────────────
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/simple-ai-commit"
CONFIG_FILE="$CONFIG_DIR/config"

# ── Defaults (overridden by config file or environment) ───────────────────────
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
MODEL="${SAC_MODEL:-openai/gpt-4o-mini}"
STYLE="${SAC_STYLE:-concise}"

# ── Style prompts ──────────────────────────────────────────────────────────────
PROMPT_CONCISE="Write a concise, single-line git commit message (50 characters or fewer). \
Use the imperative mood (e.g. \"Fix bug\" not \"Fixed bug\"). \
Output only the commit message — no explanation, no quotes."

PROMPT_FUNNY="Write a humorous and witty git commit message that still clearly describes \
what changed. Be creative and fun but keep it relevant. \
Output only the commit message — no explanation, no quotes."

PROMPT_DETAILED="Write a detailed git commit message. The first line is a short subject \
(50 characters max) in the imperative mood. Leave a blank line, then add bullet points \
(each starting with \"- \") that explain what changed and why. \
Output only the commit message — no explanation, no extra text."

# ── Helpers ────────────────────────────────────────────────────────────────────
die() { printf '❌  Error: %s\n' "$*" >&2; exit 1; }

check_deps() {
  local missing=()
  for cmd in curl jq git; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "Missing required tools: ${missing[*]}"
}

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
  fi
}

get_style_prompt() {
  case "$STYLE" in
    concise|"") printf '%s' "$PROMPT_CONCISE" ;;
    funny)    printf '%s' "$PROMPT_FUNNY"    ;;
    detailed) printf '%s' "$PROMPT_DETAILED" ;;
    *) die "Unknown style '$STYLE'. Use --funny, --detailed, or the default (omit STYLE)." ;;
  esac
}

call_openrouter() {
  local system_prompt="$1"
  local diff="$2"

  local payload
  payload=$(jq -n \
    --arg model   "$MODEL" \
    --arg system  "$system_prompt" \
    --arg content "Here are the staged git changes:\n\n$diff" \
    '{
      model: $model,
      messages: [
        { role: "system", content: $system  },
        { role: "user",   content: $content }
      ]
    }')

  curl -sS \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://openrouter.ai/api/v1/chat/completions
}

usage() {
  cat <<EOF
sac — Simple AI Commit

Generates a git commit message from your staged changes using OpenRouter.

Usage:
  sac [OPTIONS]

Options:
  By default, messages are a single line (≤50 chars, imperative mood).
  --funny             Humorous message that still describes the change
  --detailed          Subject line + blank line + bullet-point body
  -m, --model MODEL   OpenRouter model slug                       (default: openai/gpt-4o-mini)
  -h, --help          Show this help and exit

Configuration file: $CONFIG_FILE
  OPENROUTER_API_KEY="sk-or-..."   # required
  MODEL="openai/gpt-4o-mini"       # optional
  STYLE="funny" or STYLE="detailed"   # optional; omit for default one-line messages

Environment variables (override config file):
  OPENROUTER_API_KEY, SAC_MODEL, SAC_STYLE  (SAC_STYLE: funny or detailed)

Bash alias example (~/.bashrc or ~/.zshrc):
  alias aic='sac'
  alias aic-funny='sac --funny'
  alias aic-detail='sac --detailed'
EOF
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  check_deps
  load_config

  # Parse CLI flags (override config)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --funny)     STYLE=funny;     shift ;;
      --detailed)  STYLE=detailed;  shift ;;
      -m|--model)  MODEL="${2:?'--model requires a value'}";  shift 2 ;;
      -h|--help)   usage; exit 0 ;;
      *) die "Unknown argument: $1. Run 'sac --help' for usage." ;;
    esac
  done

  [[ -z "$STYLE" ]] && STYLE=concise

  # Validate
  if [[ -z "$OPENROUTER_API_KEY" ]]; then
    die "OPENROUTER_API_KEY is not set.
  Add it to $CONFIG_FILE or export it as an environment variable.
  Run 'sac --help' for details."
  fi

  local diff
  diff=$(git diff --cached)
  [[ -z "$diff" ]] && die "No staged changes found. Run 'git add <files>' first."

  local style_prompt
  style_prompt=$(get_style_prompt)

  if [[ "$STYLE" == "concise" ]]; then
    printf '🤖  Generating commit message via %s...\n' "$MODEL"
  else
    printf '🤖  Generating %s commit message via %s...\n' "$STYLE" "$MODEL"
  fi

  local response commit_msg
  response=$(call_openrouter "$style_prompt" "$diff")

  commit_msg=$(printf '%s' "$response" | jq -r '.choices[0].message.content // empty')
  [[ -z "$commit_msg" ]] && die "No message returned by API.\nFull response:\n$response"

  # Strip surrounding quotes that some models add
  commit_msg="${commit_msg#\"}"
  commit_msg="${commit_msg%\"}"

  printf '\n📝  Suggested commit message:\n'
  printf '%.0s─' {1..50}; printf '\n'
  printf '%s\n' "$commit_msg"
  printf '%.0s─' {1..50}; printf '\n\n'

  local answer answer_lower
  read -r -p "Use this message? [y/n/e(dit)] " answer
  # Lowercase without ${var,,} (requires bash 4+; macOS ships bash 3.2).
  answer_lower=$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')
  case "$answer_lower" in
    ""|y|yes)
      git commit -m "$commit_msg"
      printf '✅  Committed!\n'
      ;;
    e|edit)
      local tmpfile
      tmpfile=$(mktemp)
      printf '%s\n' "$commit_msg" > "$tmpfile"
      "${EDITOR:-vi}" "$tmpfile"
      local edited_msg
      edited_msg=$(cat "$tmpfile")
      rm -f "$tmpfile"
      [[ -z "$edited_msg" ]] && die "Commit message is empty after editing. Aborted."
      git commit -m "$edited_msg"
      printf '✅  Committed!\n'
      ;;
    *)
      printf 'Aborted.\n'
      exit 0
      ;;
  esac
}

main "$@"

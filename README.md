# simple-ai-commit

A minimal bash tool that reads your staged Git changes, sends them to
[OpenRouter](https://openrouter.ai), and returns a commit message you can
use immediately — or edit before committing.

By default, messages are a **single line** (≤ 50 characters, imperative mood). Use a config value or CLI flags for **funny** or **detailed** when you want something different:

| | Description |
|--|-------------|
| *(default)* | Single line, ≤ 50 chars |
| `funny` / `sac --funny` | Humorous and witty, still describes the change |
| `detailed` / `sac --detailed` | Subject line + blank line + bullet-point body |

---

## Requirements

- **bash** ≥ 4
- **git**
- **curl**
- **jq**
- An [OpenRouter API key](https://openrouter.ai/keys)

---

## Installation

```bash
git clone https://github.com/jrmusan/simple-ai-commit.git
cd simple-ai-commit
bash install.sh
```

The installer copies `sac.sh` to `~/.local/bin/sac` and creates a starter
config at `~/.config/simple-ai-commit/config`.

> Make sure `~/.local/bin` is in your `$PATH`.

---

## Configuration

Edit `~/.config/simple-ai-commit/config`:

```bash
# Required
OPENROUTER_API_KEY="sk-or-..."

# Optional — defaults shown
MODEL="openai/gpt-4o-mini"   # any model on openrouter.ai/models
# STYLE="funny"               # or "detailed"; omit for default one-line messages
```

Environment variables `OPENROUTER_API_KEY`, `SAC_MODEL`, and `SAC_STYLE`
override the config file.

---

## Usage

```bash
# Stage your changes first
git add .

# Generate a commit message (one line by default; honors STYLE in config if set)
sac

# Optional variants
sac --funny
sac --detailed

# Use a different model
sac --model anthropic/claude-3-haiku

# Combined
sac --detailed --model openai/gpt-4o
```

When `sac` runs you will see:

```
🤖  Generating commit message via openai/gpt-4o-mini...

📝  Suggested commit message:
──────────────────────────────────────────────────
Add OpenRouter integration with style config
──────────────────────────────────────────────────

Use this message? [Y/n/e(dit)]
```

- Press **Enter** or type `y` to commit immediately.
- Type `e` to open the message in `$EDITOR` before committing.
- Type `n` to abort without committing.

---

## Running tests

```bash
bash tests/test_sac.sh
```

---

## License

MIT

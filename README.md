# simple-ai-commit

A minimal bash tool that reads your staged Git changes, sends them to
[OpenRouter](https://openrouter.ai), and returns a commit message you can
use immediately — or edit before committing.

Switch between three styles via a config file or short CLI flags:

| Style | Description |
|---------|-------------|
| `concise` | Single line, ≤ 50 chars, imperative mood |
| `funny` | Humorous and witty, still describes the change |
| `detailed` | Subject line + blank line + bullet-point body |

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
STYLE="concise"              # concise | funny | detailed
```

Environment variables `OPENROUTER_API_KEY`, `SAC_MODEL`, and `SAC_STYLE`
override the config file.

---

## Usage

```bash
# Stage your changes first
git add .

# Generate a commit message (uses STYLE from config)
sac

# Override the style on the fly
sac --funny
sac --detailed
sac --concise   # explicit concise (same as default when STYLE=concise in config)

# Use a different model
sac --model anthropic/claude-3-haiku

# Combined
sac --detailed --model openai/gpt-4o
```

When `sac` runs you will see:

```
🤖  Generating concise commit message via openai/gpt-4o-mini...

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

## Bash aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias aic='sac'                         # default style from config
alias aic-funny='sac --funny'
alias aic-detail='sac --detailed'
```

Then just run `aic` after staging your files.

---

## Running tests

```bash
bash tests/test_sac.sh
```

---

## License

MIT

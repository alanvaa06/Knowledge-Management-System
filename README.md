# obsidian-vault-kit

A reusable scaffold + Claude Code skill set for running an Obsidian vault as a structured knowledge base.

## What you get

- A canonical vault directory tree: `raw/` (inbox), `wiki/` (compiled knowledge), `notes/` (your handwritten notes — sacred), `output/` (artifacts)
- A generic, interview-tailored `CLAUDE.md` that teaches Claude Code how to operate the vault
- Five vault-scoped slash commands and one auto-triggered skill:
  - `/vault-init` — one-time interview wizard
  - `/compile` — process `raw/` into `wiki/` with mandatory plan-and-confirm
  - `/audit` — read-only review of `wiki/` (broken links, dupes, stale index, tag conformance)
  - `/refine <path>` — voice-preserving editor pass on a `notes/` file
  - `/refresh-index` — rebuild `wiki/_master-index.md`
  - `vault-query` skill — auto-fires when you ask the vault a question

All commands live inside `<vault>/.claude/` after install — they exist only inside vaults that ran the kit. No global pollution, no name collisions.

## Install

Clone the kit anywhere on disk:

```bash
git clone https://github.com/<you>/obsidian-vault-kit.git ~/tools/obsidian-vault-kit
```

Then run the bootstrap inside your target vault folder:

**POSIX (macOS/Linux/WSL/Git Bash):**
```bash
cd /path/to/new-vault
bash ~/tools/obsidian-vault-kit/install.sh
```

**Windows PowerShell:**
```powershell
cd C:\path\to\new-vault
pwsh ~\tools\obsidian-vault-kit\install.ps1
```

The installer:
1. Copies `<kit>/templates/.claude/` → `<vault>/.claude/`
2. Drops a stub `CLAUDE.md` (still containing `{{placeholders}}`)
3. Caches the pristine template at `<vault>/.claude/.vault-init-template.md`
4. Creates `raw/`, `wiki/`, `notes/`, `output/` empty directories
5. Drops a vault-level `README.md`

After bootstrap, open the vault in Claude Code and run `/vault-init` — an 8-question interview fills in the `CLAUDE.md` template.

### Re-running the installer

If the target vault already has a `.claude/` or `CLAUDE.md`, the installer refuses unless you pass `--force`. With `--force`, it overwrites the kit-managed files but never touches `raw/`, `notes/`, `output/`, or any non-template content in `wiki/`.

## Tests

```bash
bash tests/render-template.test.sh
bash tests/install.test.sh
```

## License

MIT — see `LICENSE`.

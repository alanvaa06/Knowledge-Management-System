# Knowledge Management System

> An Obsidian vault kit for LLM-powered knowledge bases — built on Andrej Karpathy's wiki framework, extended for domain experts who need their own thinking to stay sovereign.

## The framework

Andrej Karpathy [described](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) a clean architecture for LLM-powered knowledge bases: raw sources land in one folder, an LLM compiles them into a wiki in another, and outputs flow into a third. The human curates. The LLM authors. Three folders: `raw/ → wiki/ → output/`.

That model assumes one role for the human: librarian. You bring sources in; the LLM organizes them.

## Where this departs

If you are also a domain expert — generating investment theses, drafting research arguments, codifying product strategy, developing legal positions, or shaping any work where your synthesis is the asset — you have a second role. That knowledge needs a home the LLM can reference but can't overwrite.

This kit keeps Karpathy's foundation and adds two folders:

- **`notes/`** — your handwritten, voice-preserving notes. Sacred. The LLM can cite and backlink them, but never compiles from them. Your knowledge enters the system on your terms.
- **`notes/private/`** — content that never leaks into persisted files. Invisible to compile and audit. You can pull it into any query alongside the full wiki, on demand, and the answer stays in chat unless you explicitly ask for a file.

Karpathy's model casts the human as librarian. This kit makes room for the human to also be a scholar — with strict walls so the two roles never bleed into each other.

## Architecture

Four folders, each with a single role:

| Folder | Role | LLM access |
|---|---|---|
| `raw/` | Inbox for unprocessed sources (PDFs, papers, decks, transcripts) | Read-only |
| `wiki/` | Compiled knowledge base. Flat, organized by domain, indexed by `_master-index.md` | Read + write (compile target) |
| `wiki/_log.md` | Append-only ops journal. What `compile`, `audit`, and `refresh-index` did, and when | Append one entry per run. Never rewritten |
| `notes/` | Your handwritten notes. Sacred — voice-preserving | Read + cite. Edits only via `/refine` (diff-and-confirm) |
| `notes/private/` | Private synthesis. Never persists | Read on demand during queries. Never written to wiki/output |
| `output/` | Artifacts you explicitly ask for | Write only when explicitly requested |

The directionality is one-way: `raw/ → wiki/ → output/`. `notes/` is a reference side-channel — the wiki cites and backlinks notes, never generates from them. `notes/private/` is a query-time side-channel — pulled in only when you ask, and only into the chat response.

Most rules are instructions: the operating manual (`CLAUDE.md`) and the slash commands tell Claude what it may do, and Claude follows them. `compile` refuses to write without your explicit approval of the plan. `audit` is read-only apart from its log entry; any fix it proposes goes through the same approval gate as `compile`. `refine` always shows a diff before touching `notes/`. `compile` and `audit` are instructed never to read `notes/private/`.

One rule is also enforced by Claude Code itself: the installer ships `.claude/settings.json` with a permission deny rule, `Edit(/raw/**)`, so Claude's file tools cannot modify or create files in `raw/` even if an instruction is ignored. It does not stop a script Claude runs from writing files on its own; for OS-level enforcement, enable Claude Code's [sandbox](https://code.claude.com/docs/en/sandboxing). `notes/private/` has no deny rule on purpose: queries need to read it when you ask.

## What `notes/private/` unlocks

Private notes are where this architecture earns its keep. They never persist into the wiki or any output file, but they can be loaded into any query alongside the full compiled knowledge base.

That intersection — your private thinking colliding with the LLM's compiled knowledge, on demand, without contaminating either side — is the use case:

- **Stress-test an investment thesis** against the dozens of articles the wiki has compiled on a sector's market structure, regulatory environment, and competitive dynamics.
- **Pressure-test a business idea** against everything the wiki knows about adjacent markets, prior failures, and competitor moves.
- **Sanity-check a research argument** against the full corpus of papers and notes you've ingested on a topic.
- **Rehearse a strategic decision** by surfacing every relevant precedent, counter-argument, and constraint already captured in the wiki — without committing the decision itself to writing.
- **Develop a private hypothesis in the open** — keep working drafts, half-formed claims, and confidential context in `notes/private/`, and use the wiki as the sparring partner that knows your domain.

The wall stays intact. Private synthesis informs the answer; the answer stays in chat unless you ask for a file. The wiki never learns what you wrote in private, and your private notes never leak into anything you publish.

## Workflows

The kit ships with six vault-scoped slash commands and one auto-triggered skill, all loaded after install:

- **`/vault-init`** — one-time interview that tailors `CLAUDE.md` to you (your name, domains, tag policy, voice).
- **`/compile`** — process `raw/` into `wiki/`. Plan-and-confirm: lists what it will write and which existing claims the new source contradicts, waits for explicit approval, then writes only the wiki articles, marks superseded claims with a `> [!warning] Superseded` callout, updates `_master-index.md`, and appends one `_log.md` entry.
- **`/audit`** — read-only review of `wiki/`. Surfaces broken wikilinks, duplicates, stale index entries, tag drift. `/audit deep` adds content-level checks: contradictions between articles, stale claims missing a superseded callout, orphans, data gaps. Reports only — never auto-fixes. The audit pass writes nothing but one `_log.md` entry; fixes you approve run as a separate gated pass and append their own entry.
- **`/refine <path>`** — voice-preserving editor pass on a `notes/` file. Fixes typos silently, flags unclear passages with `> [!question]` callouts, never paraphrases. Always shows a diff before applying.
- **`/refresh-index`** — rebuild `wiki/_master-index.md` from scratch. Shows a diff, waits for approval, then writes the index and appends one `_log.md` entry.
- **`/teach <topic>`** — multi-session tutor grounded in the wiki. New topic starts with a short mission interview; each session writes one lesson to `output/teach/<topic>/sessions/` and tracks progress in `progress.md`. Cites wiki articles, never touches `wiki/` or `notes/`.
- **`vault-query` skill** — auto-fires when you ask the vault a question. Walks `_master-index.md` and wikilinks before answering, cites every source, defaults to chat output.

All commands live inside `<vault>/.claude/` after install — they exist only inside vaults that ran the kit. No global pollution, no name collisions.

## Install

Clone the kit anywhere on disk:

```bash
git clone https://github.com/alanvaa06/Knowledge-Management-System.git ~/tools/knowledge-management-system
```

Then run the bootstrap inside your target vault folder:

**POSIX (macOS/Linux/WSL/Git Bash):**
```bash
cd /path/to/new-vault
bash ~/tools/knowledge-management-system/install.sh
```

**Windows PowerShell (5.1, ships with Windows) or PowerShell 7:**
```powershell
cd C:\path\to\new-vault
powershell -ExecutionPolicy Bypass -File "$HOME\tools\knowledge-management-system\install.ps1"
```

The installer:
1. Copies `<kit>/templates/.claude/` → `<vault>/.claude/`
2. Drops a stub `CLAUDE.md` (still containing `{{placeholders}}`)
3. Caches the pristine template at `<vault>/.claude/.vault-init-template.md`
4. Drops `.claude/settings.json` with the `Edit(/raw/**)` deny rule (only if the vault has no `settings.json` yet)
5. Drops `wiki/_master-index.md` (stub, rendered by `/vault-init`) and `wiki/_log.md`, the append-only ops journal (never overwritten on re-run)
6. Drops a vault-level `README.md`
7. Creates `raw/`, `wiki/`, `notes/`, `output/` if missing

After bootstrap, open the vault in Claude Code and run `/vault-init` — an interview fills in the `CLAUDE.md` template.

### Re-running the installer

If the target vault already has a `.claude/` or `CLAUDE.md`, the installer refuses unless you pass `--force`. With `--force`, it overwrites `.claude/`, `CLAUDE.md`, and the vault-level `README.md`, but never touches `raw/`, `notes/`, `output/`, or your wiki articles. `wiki/_log.md` is never overwritten (it is your history), and `wiki/_master-index.md` is replaced only if it still contains unrendered `{{placeholders}}`. An existing `.claude/settings.json` is never overwritten either; if it lacks the `raw/` deny rule, the installer prints the line to add.

## Tests

```bash
bash tests/render-template.test.sh
bash tests/install.test.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File tests/render-template.test.ps1
powershell -ExecutionPolicy Bypass -File tests/install.test.ps1
```

Both renderers are checked against the same fixtures, so a pass on both means they produce identical output. CI runs the bash suite on Ubuntu, on macOS with the stock bash 3.2, and on Windows (Git Bash), plus the PowerShell suite on Windows.

## License

MIT — see `LICENSE`.

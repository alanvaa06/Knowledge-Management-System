# README Philosophy Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `README.md` around the four-folder architecture (Karpathy framework + `notes/` + `notes/private/` extension) so the kit's philosophical intent travels with the code.

**Architecture:** Single-file rewrite of `README.md`. Linear narrative — Header → The framework → Where this departs → Architecture → What `notes/private/` unlocks → Workflows → Install → Tests → License. No code changes, no template changes, no installer changes.

**Tech Stack:** Markdown only. Renders on GitHub. No tooling required.

**Spec:** [docs/superpowers/specs/2026-05-05-readme-philosophy-rewrite-design.md](../specs/2026-05-05-readme-philosophy-rewrite-design.md)

---

## File Structure

- **Modify:** `README.md` (full rewrite, ~110 lines → ~150 lines)
- **Untouched:** `templates/README.md.tmpl`, `templates/CLAUDE.md.tmpl`, `install.sh`, `install.ps1`, `tests/`, all command files

Everything that ships into a user vault stays the same. This plan only changes the kit's outward-facing README.

## TDD note

No automated test covers `README.md` contents. Verification is manual — checking the rendered Markdown against the acceptance criteria from the spec. Each acceptance criterion gets a verification step in Task 2.

---

### Task 1: Rewrite README.md

**Files:**
- Modify: `README.md` (replace entire contents)

- [ ] **Step 1: Read the current README to confirm baseline**

Run: `cat README.md`

Expected: existing 64-line README starting with `# obsidian-vault-kit`, ending with `MIT — see \`LICENSE\`.`

If the file does not match this baseline, stop and surface the discrepancy before continuing.

- [ ] **Step 2: Replace README.md with new content**

Overwrite `README.md` with exactly this content:

````markdown
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
| `notes/` | Your handwritten notes. Sacred — voice-preserving | Read + cite. Edits only via `/refine` (diff-and-confirm) |
| `notes/private/` | Private synthesis. Never persists | Read on demand during queries. Never written to wiki/output |
| `output/` | Artifacts you explicitly ask for | Write only when explicitly requested |

The directionality is one-way: `raw/ → wiki/ → output/`. `notes/` is a reference side-channel — the wiki cites and backlinks notes, never generates from them. `notes/private/` is a query-time side-channel — pulled in only when you ask, and only into the chat response.

The rules are enforced by the operating manual (`CLAUDE.md`) and the slash commands themselves. `compile` refuses to write without your explicit approval of the plan. `audit` is read-only. `refine` always shows a diff before touching `notes/`. `notes/private/` is invisible to compile and audit by construction.

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

The kit ships with five vault-scoped slash commands and one auto-triggered skill, all loaded after install:

- **`/vault-init`** — one-time interview that tailors `CLAUDE.md` to you (your name, domains, tag policy, voice).
- **`/compile`** — process `raw/` into `wiki/`. Plan-and-confirm: lists what it will write, waits for explicit approval, then writes only the wiki articles and updates `_master-index.md`.
- **`/audit`** — read-only review of `wiki/`. Surfaces broken wikilinks, duplicates, stale index entries, tag drift. Reports only — never auto-fixes.
- **`/refine <path>`** — voice-preserving editor pass on a `notes/` file. Fixes typos silently, flags unclear passages with `> [!question]` callouts, never paraphrases. Always shows a diff before applying.
- **`/refresh-index`** — rebuild `wiki/_master-index.md` from scratch.
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

**Windows PowerShell:**
```powershell
cd C:\path\to\new-vault
pwsh ~\tools\knowledge-management-system\install.ps1
```

The installer:
1. Copies `<kit>/templates/.claude/` → `<vault>/.claude/`
2. Drops a stub `CLAUDE.md` (still containing `{{placeholders}}`)
3. Caches the pristine template at `<vault>/.claude/.vault-init-template.md`
4. Creates `raw/`, `wiki/`, `notes/`, `output/` empty directories
5. Drops a vault-level `README.md`

After bootstrap, open the vault in Claude Code and run `/vault-init` — an interview fills in the `CLAUDE.md` template.

### Re-running the installer

If the target vault already has a `.claude/` or `CLAUDE.md`, the installer refuses unless you pass `--force`. With `--force`, it overwrites the kit-managed files but never touches `raw/`, `notes/`, `output/`, or any non-template content in `wiki/`.

## Tests

```bash
bash tests/render-template.test.sh
bash tests/install.test.sh
```

## License

MIT — see `LICENSE`.
````

- [ ] **Step 3: Verify the file was written correctly**

Run: `wc -l README.md && head -3 README.md`

Expected: line count between 100 and 160. First line: `# Knowledge Management System`. Third line begins with `> An Obsidian vault kit`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): restructure around four-folder philosophy

Lead with the Karpathy framework summary, name the librarian-vs-scholar
departure, and explain what notes/ and notes/private/ unlock. Folder
list, install steps, and test commands preserved with the URL updated
to the renamed repo."
```

---

### Task 2: Verify acceptance criteria

**Files:** None modified. Verification only.

- [ ] **Step 1: Render check (table + code fences)**

Run: `grep -c '^|' README.md`

Expected: at least 6 (one header row, one separator row, five folder rows).

Run: `grep -c '^```' README.md`

Expected: an even number (every fence opens and closes). At least 6 fences total (POSIX install block, PowerShell install block, tests block, and any others).

- [ ] **Step 2: Section order check**

Run: `grep -n '^## ' README.md`

Expected (in this order):
1. `## The framework`
2. `## Where this departs`
3. `## Architecture`
4. `## What \`notes/private/\` unlocks`
5. `## Workflows`
6. `## Install`
7. `## Tests`
8. `## License`

Plus one `### Re-running the installer` after `## Install`.

- [ ] **Step 3: Karpathy attribution check**

Run: `grep -c 'karpathy/442a6bf555914893e9891c11519de94f' README.md`

Expected: exactly 1 (the gist URL appears once, in the Framework section).

- [ ] **Step 4: Architecture table folder coverage**

Run: `grep -E '^\| \`(raw|wiki|notes|notes/private|output)/\`' README.md | wc -l`

Expected: exactly 5 (one row per folder).

- [ ] **Step 5: Domain breadth in "Where this departs"**

Read lines under `## Where this departs` and confirm at least four distinct domain examples appear (e.g., investment, research, product strategy, legal). The phrase "any work where your synthesis is the asset" should also be present.

Run: `sed -n '/^## Where this departs/,/^## Architecture/p' README.md`

Expected output contains: `investment theses`, `research arguments`, `product strategy`, `legal positions`, and `synthesis is the asset`.

- [ ] **Step 6: notes/private/ use case count**

Run: `sed -n '/^## What `notes\/private\/` unlocks/,/^## Workflows/p' README.md | grep -c '^- \*\*'`

Expected: exactly 5.

- [ ] **Step 7: No LinkedIn reference leaked into README**

Run: `grep -ci 'linkedin' README.md`

Expected: 0.

- [ ] **Step 8: Install URL points at renamed repo**

Run: `grep -c 'alanvaa06/Knowledge-Management-System' README.md`

Expected: at least 1.

Run: `grep -c 'obsidian-vault-kit' README.md`

Expected: 0 (the old repo slug must not appear anywhere).

- [ ] **Step 9: Installer-behavior list preserved**

Run: `sed -n '/^The installer:/,/^After bootstrap/p' README.md`

Expected output contains all five numbered installer steps:
1. Copies `<kit>/templates/.claude/` → `<vault>/.claude/`
2. Drops a stub `CLAUDE.md` (still containing `{{placeholders}}`)
3. Caches the pristine template at `<vault>/.claude/.vault-init-template.md`
4. Creates `raw/`, `wiki/`, `notes/`, `output/` empty directories
5. Drops a vault-level `README.md`

- [ ] **Step 10: Existing tests still pass (no regression)**

Run: `bash tests/render-template.test.sh && bash tests/install.test.sh`

Expected: both pass. (Neither test reads `README.md`, so a pass confirms no incidental damage.)

- [ ] **Step 11: GitHub render preview (optional but recommended)**

Push the branch (or open the file in any Markdown previewer that mimics GitHub) and confirm:
- Table renders with five data rows.
- Subtitle blockquote renders.
- All code fences close.
- Karpathy gist link is clickable.

If any acceptance check fails, fix `README.md` and amend the previous commit (or add a fix-up commit), then re-run the failing checks.

---

## Self-review summary

- Spec coverage: every acceptance criterion in the spec has a verification step in Task 2 (render → 1, section order → 2, Karpathy link → 3, table coverage → 4, domain breadth → 5, use-case count → 6, no LinkedIn → 7, install URL → 8, installer steps → 9, regression → 10, render preview → 11). ✓
- Placeholder scan: no TBDs, no "implement later", no "similar to Task N". Full README content embedded in Task 1, Step 2. ✓
- Type consistency: N/A (no code).
- Frequent commits: one commit for the rewrite, optional fix-up commits if verification fails. Reasonable for a single-file documentation change.

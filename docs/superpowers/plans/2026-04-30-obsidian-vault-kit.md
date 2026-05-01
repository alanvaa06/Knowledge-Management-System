# obsidian-vault-kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a distributable kit that scaffolds an Obsidian vault with a generic vault-operating-manual `CLAUDE.md` and five vault-scoped Claude Code skills/commands (`/compile`, `/audit`, `/refine`, `/refresh-index`, `vault-query` skill, plus `/vault-init` interview wizard) — installed via a bootstrap shell script that copies templates into the target vault folder.

**Architecture:** Bootstrap installer (`install.sh` / `install.ps1`) copies pristine templates from `<kit>/templates/` into the user's vault folder. A shared template-rendering script (`render-template.sh` / `.ps1`) lives inside the vault's `.claude/lib/` so both runtime (`/vault-init`) and tests use the same substitution logic — single source of truth for `{{key}}` and `{{#if key}}…{{/if}}` rules. Skills and commands are vault-scoped (live under `<vault>/.claude/`) — never global, never colliding with unrelated projects.

**Tech Stack:** Bash + POSIX coreutils (awk, sed, cp, mkdir) for POSIX install path. PowerShell 5.1+ for Windows install path. Markdown for templates, slash commands, and skill bodies. No runtime dependencies, no package managers.

**Repo:** `C:/Proyectos/Obsidian_Set/obsidian-vault-kit/`

**Source vault to extract patterns from (read-only):** `C:/Obsidian/CLAUDE.md` — generic-ify all five skill bodies from this file. Strip personal references (CFA, JHU, Cambridge, "Alan", domain examples specific to the user's vault). Keep behavior, plan-and-confirm gates, sacred-notes rules, and `raw/ → wiki/ → output/` directionality verbatim.

---

## Phase 1: Project chrome (LICENSE + kit README)

### Task 1: LICENSE

**Files:**
- Create: `LICENSE`

- [ ] **Step 1: Write MIT LICENSE**

```
MIT License

Copyright (c) 2026 obsidian-vault-kit contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Commit**

```bash
git add LICENSE
git commit -m "chore: add MIT LICENSE"
```

---

### Task 2: Kit README (root-level)

**Files:**
- Create: `README.md` (kit-level — describes the kit itself, NOT vault-level which lives in templates/)

- [ ] **Step 1: Write kit README**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add kit-level README"
```

---

## Phase 2: Vault templates (CLAUDE.md, master index, vault README)

### Task 3: `templates/CLAUDE.md.tmpl`

**Files:**
- Create: `templates/CLAUDE.md.tmpl`

The template uses two substitution mechanisms (both implemented in Phase 4 by `render-template.sh`):
1. `{{key}}` — simple string replacement
2. `{{#if key}}…{{/if}}` — block stripped if `key != "yes"`. Markers must each be on their own line.

Substitution keys (set by `/vault-init` answers, see Phase 3 Task 9):
- `owner_name` — full name + role (Q1)
- `owner_first_name` — derived first token of `owner_name`
- `owner_bio` — one-line bio derived from Q1
- `domain_tag_list` — comma-separated domains from Q2
- `voice_paragraph` — voice instructions from Q3
- `notes_sacred` — `yes`/`no` (Q4)
- `private_notes` — `yes`/`no` (Q5)
- `tag_count_rule` — phrase like "exactly two" or "any number" derived from Q6
- `tag_policy_paragraph` — paragraph derived from Q6
- `citation_paragraph` — derived from Q7
- `output_explicit_only` — `yes`/`no` (Q8)

- [ ] **Step 1: Write the template**

```markdown
# CLAUDE.md — Vault Operating Manual

Read this before touching the vault.

## {{owner_name}}
{{owner_bio}}

{{voice_paragraph}}

## Structure
- `raw/` — inbox: PDFs, papers, decks, notebooks. You read, never write.
- `wiki/` — compiled knowledge base. You own it. Flat: files live directly under domain folders ({{domain_tag_list}}). No subfolders, no per-folder `_index.md`.
- `wiki/_master-index.md` — the one and only index.
- `notes/` — {{owner_first_name}}'s human-authored notes.{{#if notes_sacred}} SACRED. Read-only.{{/if}}
- `output/` — artifacts {{owner_first_name}} explicitly asks for. Never dump compile logs here.

## Directionality
`raw/ → wiki/ → output/`. `notes/` is a reference side-channel: cite and backlink from wiki articles, never generate from.

## Wiki Conventions
- Frontmatter: `Writer`, `Link` (if applicable), `tags` ({{tag_count_rule}}). Nothing else.
{{tag_policy_paragraph}}
- Dense bullets, tables, `==highlights==`, `[[wikilinks]]`. End every article with `## Key Takeaways` (3–7 bullets).
- Match the voice of existing articles. No padding phrases.
- Never create subfolders inside a domain folder.

{{citation_paragraph}}

{{#if notes_sacred}}
## notes/ — Sacred Rules
- Never edit, restructure, or paraphrase notes. Never copy their content into the wiki.
- Notes never trigger wiki generation on their own. Wiki articles are born from `raw/`.
- When a raw source overlaps a note, backlink to the note with a `[[wikilink]]`.
{{#if private_notes}}
- **`notes/private/`** — completely invisible to `compile` and `audit`. During `query`, read only if {{owner_first_name}} explicitly references it (e.g., "how does my idea in private/X connect to wiki/Y"). Answers stay in chat — never written to `wiki/` or `output/` unless {{owner_first_name}} asks.
{{/if}}
- **Exception — `refine`:** editor role only. Fix typos silently. Preserve voice, headers, `==highlights==`, `[[links]]`, analogies. Flag unclear spots with `> [!question]` callouts — never invent. Always show a diff before applying.
{{/if}}

## Commands

### `compile`
Process `raw/` into `wiki/`. MANDATORY plan-and-confirm before writing.
1. List raw sources to process, target wiki paths, notes to backlink, any new folders. Present in chat.
2. Wait for explicit "go" / "proceed" / "ok". Revise if asked. Never write files without approval.
3. After approval: write wiki articles only. Update `_master-index.md`. Report in chat.
4. Never write compile reports, plans, or logs as files.
5. Never generate wiki articles from `notes/` alone. Scoped `compile notes/X into wiki/X` is the only exception — rare and explicit.
6. Never write to `raw/`, `notes/`, or `output/` during a compile.

### `audit`
Read-only review of `wiki/`. Reports only, never auto-fixes.
- Broken `[[wikilinks]]` and missing backlinks.
- Duplicate or overlapping articles.
- Stale or missing `_master-index.md` entries.
- Wiki articles referencing raw sources no longer in `raw/`.
- Concepts referenced but not defined.
- Tag conformance.
- Frontmatter conformance (`Writer`, optional `Link`, `tags` only).
Present findings as a plan. Wait for confirmation before applying any fix.

### `query` / `ask`
Answer a question using `wiki/` first, then `notes/`, then `raw/`.
1. **Read the graph first.** Before answering, scan `_master-index.md` end-to-end and trace `[[wikilinks]]` between related articles to build a map of what the vault covers. Never answer from a single article in isolation.
2. Drill into the specific articles surfaced by the graph walk.
3. Pull from `notes/` when {{owner_first_name}}'s synthesis is more specific than the wiki. Cite every source with a `[[wikilink]]`.
4. Default output is the chat response. Write to `output/` only if {{owner_first_name}} asks for a file.
5. If the answer exposes a wiki gap, flag it in chat — don't silently patch during a query.

### `refine`
Editor pass over a `notes/` file. Voice-preserving, never generative.
1. Fix typos and obvious slips silently. Preserve voice, headers, `==highlights==`, `[[links]]`, analogies, and bullet structure.
2. Flag unclear or ambiguous passages with `> [!question]` callouts — never rewrite or invent content to resolve them.
3. Always present a diff in chat and wait for explicit approval before applying changes to the file.
4. Never restructure, re-order, or paraphrase. Never pull content into `wiki/` as a side effect.
{{#if private_notes}}
5. `notes/private/` is in scope for `refine` only when {{owner_first_name}} names the file explicitly.
{{/if}}

### `refresh index`
Rebuild `_master-index.md` from scratch based on what's in `wiki/`. Flat grouped list with `[[wikilinks]]` and one-line descriptions. Single index — no per-folder indexes.

## Hard Don'ts
{{#if notes_sacred}}
- Don't edit `notes/` outside of `refine`.
{{/if}}
- Don't move or delete files in `raw/`.
{{#if output_explicit_only}}
- Don't write to `output/` unless {{owner_first_name}} explicitly asks.
{{/if}}
- Don't invent citations. If it's not in `raw/` or `notes/`, say so.
- Don't create subfolders in `wiki/`.
- Don't rewrite articles in generic LLM voice during compile.
- Don't write any file during `compile` without {{owner_first_name}}'s explicit approval of the plan.
```

- [ ] **Step 2: Commit**

```bash
git add templates/CLAUDE.md.tmpl
git commit -m "feat(templates): add CLAUDE.md.tmpl with placeholder + conditional markers"
```

---

### Task 4: `templates/_master-index.md.tmpl`

The wizard appends domain headers after substitution; the template is just a stub.

**Files:**
- Create: `templates/_master-index.md.tmpl`

- [ ] **Step 1: Write the stub**

```markdown
# Master Index

> Single, flat index of every article in `wiki/`. Rebuilt by `/refresh-index`. Do not edit by hand outside of compile/refresh-index runs.

{{domain_index_sections}}
```

The `{{domain_index_sections}}` placeholder is filled by `/vault-init` with one `## <Domain>` section per chosen domain (see Task 9, step on building domain index sections).

- [ ] **Step 2: Commit**

```bash
git add templates/_master-index.md.tmpl
git commit -m "feat(templates): add _master-index.md.tmpl stub"
```

---

### Task 5: `templates/README.md.tmpl` (vault-level)

This is the README the end user sees inside their vault — distinct from the kit-level README written in Task 2.

**Files:**
- Create: `templates/README.md.tmpl`

- [ ] **Step 1: Write the vault README template**

```markdown
# {{owner_first_name}}'s Vault

Structured knowledge base scaffolded by [obsidian-vault-kit](https://github.com/<you>/obsidian-vault-kit).

## Layout

- `raw/` — drop unprocessed sources here (PDFs, papers, decks, notebooks)
- `wiki/` — compiled knowledge base, organized by domain
- `wiki/_master-index.md` — single flat index
- `notes/` — your handwritten notes{{#if notes_sacred}} (sacred — Claude only edits via `/refine`){{/if}}
- `output/` — artifacts you explicitly ask Claude to produce

## Working with Claude Code

Open this folder in Claude Code. Available commands:

- `/compile` — process `raw/` into `wiki/`
- `/audit` — review `wiki/` for issues (read-only)
- `/refine <path>` — editor pass on a `notes/` file
- `/refresh-index` — rebuild the master index

Just ask a question and the `vault-query` skill auto-fires.

## Re-tailoring the operating manual

Run `/vault-init force` to re-run the interview and regenerate `CLAUDE.md`.
```

- [ ] **Step 2: Commit**

```bash
git add templates/README.md.tmpl
git commit -m "feat(templates): add vault-level README template"
```

---

## Phase 3: Slash commands + skill (vault-scoped)

All files in this phase live under `templates/.claude/`. They are markdown bodies executed by Claude when the command/skill fires.

### Task 6: `templates/.claude/commands/compile.md`

**Files:**
- Create: `templates/.claude/commands/compile.md`

- [ ] **Step 1: Write the compile slash command**

```markdown
---
description: Process raw/ into wiki/ with mandatory plan-and-confirm before any write
---

# /compile

Process new content from `raw/` into structured `wiki/` articles.

## Hard rule: plan-and-confirm gate

You MUST present a plan in chat and receive explicit approval ("go", "proceed", "ok", "yes") before writing any file. Never bypass this gate, even for "obvious" or "small" compiles.

## Procedure

1. **Survey raw/.** List sources not yet represented in `wiki/`. For each, propose:
   - Target wiki path (`wiki/<Domain>/<slug>.md`)
   - Existing wiki articles to update or backlink
   - `notes/` files to cite (read `notes/` to find overlap — never copy notes content into wiki)
   - Any new domain folders required
2. **Present the plan in chat.** Use a compact list. Wait.
3. **On approval:** write only the wiki articles + update `wiki/_master-index.md`. Report what you wrote in chat.

## Hard don'ts

- Never write to `raw/`, `notes/`, or `output/` during a compile.
- Never generate wiki articles from `notes/` alone. The only exception is when the user explicitly invokes a scoped `compile notes/X into wiki/Y` — rare.
- Never write a compile log, plan file, or report file. Plans live in chat.
- Never proceed without the explicit approval token.
- Never read `notes/private/` during a compile (if that folder exists).

## Frontmatter convention

Every wiki article: `Writer`, optional `Link`, `tags`. Nothing else. Tags follow the rule in `CLAUDE.md`.

## Voice

Match the voice of existing wiki articles. Dense bullets, tables, `==highlights==`, `[[wikilinks]]`. End every article with `## Key Takeaways` (3–7 bullets). No padding phrases, no generic LLM cadence.
```

- [ ] **Step 2: Commit**

```bash
git add templates/.claude/commands/compile.md
git commit -m "feat(commands): add /compile slash command"
```

---

### Task 7: `templates/.claude/commands/audit.md`

**Files:**
- Create: `templates/.claude/commands/audit.md`

- [ ] **Step 1: Write the audit slash command**

```markdown
---
description: Read-only review of wiki/ — reports broken links, dupes, stale index entries, tag/frontmatter conformance
---

# /audit

Read-only review of `wiki/`. Report findings as a plan. Never auto-fix.

## Procedure

1. Walk every file in `wiki/` (recursively).
2. For each file, check:
   - **Frontmatter conformance** — exactly the fields `Writer`, optional `Link`, `tags`. No others.
   - **Tag conformance** — see `CLAUDE.md` for the active tag policy. Flag violations.
   - **Wikilink validity** — every `[[link]]` resolves to an existing wiki file or note.
   - **Backlink reciprocity** — articles referenced by others should ideally back-reference where it makes sense. Flag missing reciprocals as suggestions, not errors.
   - **Master index coverage** — every wiki article appears in `_master-index.md`. Every index entry resolves to an existing file.
   - **Stale raw references** — wiki articles citing a raw source no longer in `raw/`.
   - **Duplicate or overlapping articles** — flag potential merges.
   - **Concepts referenced but not defined** — `[[Foo]]` where no `wiki/.../Foo.md` exists.
3. Present all findings in chat, grouped by category, with file paths and line numbers.
4. If the user asks you to fix specific findings, present a fix plan and wait for approval (same gate as `/compile`).

## Hard don'ts

- Never modify any file during an audit pass. Reports only.
- Never read `notes/private/` (if that folder exists).
- Never write a report file. Findings live in chat.
```

- [ ] **Step 2: Commit**

```bash
git add templates/.claude/commands/audit.md
git commit -m "feat(commands): add /audit slash command"
```

---

### Task 8: `templates/.claude/commands/refine.md`

**Files:**
- Create: `templates/.claude/commands/refine.md`

- [ ] **Step 1: Write the refine slash command**

```markdown
---
description: Voice-preserving editor pass on a single notes/ file. Diff-first, never invents content.
---

# /refine

Editor pass over a single file in `notes/`. Voice-preserving. Never generative.

Usage: `/refine <path-to-notes-file>`

## Procedure

1. **Read the target file.** Verify it lives under `notes/`. Refuse to refine anything outside `notes/`.
2. **Identify changes.** Allowed edits:
   - Fix obvious typos (e.g., "explotation" → "exploitation", "optiomal" → "optimal", "throught" → "thought").
   - Preserve voice, headers, `==highlights==`, `[[links]]`, analogies, bullet structure.
3. **Flag — never resolve — ambiguity.** For unclear or incomplete passages, insert an Obsidian callout:
   ```
   > [!question]
   > <one-sentence question about the unclear passage>
   ```
   Never rewrite the passage to resolve the ambiguity. Never invent content.
4. **Show the diff in chat.** Use a unified diff or before/after blocks. Wait for explicit approval.
5. **On approval:** write the changes to the file. Report what was applied.

## Hard don'ts

- Never restructure, re-order, or paraphrase content.
- Never pull notes content into `wiki/` as a side effect of a refine pass.
- Never refine `notes/private/` (if that folder exists) unless the user explicitly names the file in the path argument.
- Never proceed without the diff approval.
```

- [ ] **Step 2: Commit**

```bash
git add templates/.claude/commands/refine.md
git commit -m "feat(commands): add /refine slash command"
```

---

### Task 9: `templates/.claude/commands/refresh-index.md`

**Files:**
- Create: `templates/.claude/commands/refresh-index.md`

- [ ] **Step 1: Write the refresh-index slash command**

```markdown
---
description: Rebuild wiki/_master-index.md from current wiki/ contents. Flat grouped list.
---

# /refresh-index

Rebuild `wiki/_master-index.md` from scratch based on what is currently in `wiki/`.

## Procedure

1. List every `.md` file in `wiki/` recursively, excluding `_master-index.md` itself.
2. Group by top-level subfolder (which corresponds to the domain).
3. For each article, extract the first H1 (`# Title`) as the display name and the first non-empty paragraph (or the line tagged "Description:") as a one-line summary. If neither is present, use the filename and "(no description)".
4. Render the index as:
   ```
   # Master Index

   ## <Domain>
   - [[<file-stem>]] — <one-line summary>
   - [[<file-stem>]] — <one-line summary>

   ## <Other Domain>
   - [[<file-stem>]] — <one-line summary>
   ```
5. **Present the rebuilt index in chat.** Show a diff against the existing file.
6. **On approval:** write to `wiki/_master-index.md`. Report.

## Hard don'ts

- Never create per-folder indexes. The master index is the only index.
- Never modify any wiki article during a refresh.
- Never read `notes/` or `raw/` during a refresh.
```

- [ ] **Step 2: Commit**

```bash
git add templates/.claude/commands/refresh-index.md
git commit -m "feat(commands): add /refresh-index slash command"
```

---

### Task 10: `templates/.claude/skills/vault-query/SKILL.md`

**Files:**
- Create: `templates/.claude/skills/vault-query/SKILL.md`

This is the auto-triggered skill (per spec §7).

- [ ] **Step 1: Write the vault-query skill**

```markdown
---
name: vault-query
description: Use when the user asks a question that should be answered from the vault — reads wiki/_master-index.md graph first, walks wikilinks between related articles, then drills into specific articles. Cites every source with a wikilink. Never patches the wiki silently.
---

# vault-query

Answer a user question by reading the vault. Wiki first, then notes, then raw — never the other way.

## Procedure

1. **Read the graph first.** Open `wiki/_master-index.md` and read it end-to-end. Identify the entries most relevant to the question. Trace `[[wikilinks]]` between candidate articles to build a small map of what the vault covers in this area. Do not answer from a single article in isolation — neighbors often hold the sharper framing.
2. **Drill in.** Read the articles your graph walk surfaced.
3. **Cross-check `notes/`.** If the user's handwritten synthesis in `notes/` is more specific than the wiki on this topic, pull from there. Cite every source with a `[[wikilink]]`. Treat `notes/private/` (if it exists) as out of scope unless the user explicitly references a path inside it.
4. **Answer in chat.** Default output is a chat response, not a file. Write to `output/` only if the user explicitly asks for a file.
5. **Flag gaps in chat.** If the question exposes a missing or thin wiki article, mention it as a follow-up — do NOT silently patch the wiki during a query.

## Hard don'ts

- Never invent citations. If a claim does not have a source in `raw/` or `notes/`, say so.
- Never write to `wiki/`, `notes/`, or `raw/` during a query.
- Never read `notes/private/` unless the user names a specific path inside it.

## When to fire

Use this skill whenever the user asks a question that the vault might answer — phrasing like "what does the vault say about…", "summarize what we have on…", "how do X and Y relate?", or just a direct factual question whose answer plausibly lives in `wiki/` or `notes/`.

Do NOT fire for: code-editing tasks, requests to run a slash command, requests to compile or refresh, or questions explicitly about files outside the vault structure.
```

- [ ] **Step 2: Commit**

```bash
git add templates/.claude/skills/vault-query/SKILL.md
git commit -m "feat(skills): add vault-query auto-triggered skill"
```

---

### Task 11: `templates/.claude/commands/vault-init.md`

This is the wizard. It runs the 8-question interview, builds an answers file, then invokes the shared renderer (built in Phase 4) to fill in `CLAUDE.md`.

**Files:**
- Create: `templates/.claude/commands/vault-init.md`

- [ ] **Step 1: Write the vault-init slash command**

```markdown
---
description: One-time interview wizard that fills in CLAUDE.md from the cached template. Pass `force` to re-run.
---

# /vault-init

Interactive wizard. Asks 8 questions one at a time, then renders `CLAUDE.md` from the cached pristine template at `.claude/.vault-init-template.md`.

## Pre-flight

1. Verify `.claude/.vault-init-template.md` exists. If missing, abort with: "Template cache not found — re-run the bootstrap installer."
2. Check whether `CLAUDE.md` still contains `{{` placeholders (i.e., is unrendered). If it does NOT contain `{{`, the wizard has run before:
   - If the user passed `force` as the slash command argument, proceed.
   - Otherwise abort with: "Vault already initialized. Run `/vault-init force` to re-run the interview."

## Interview (one question per turn)

Ask each question, wait for the answer, then move to the next. Be terse.

1. **Owner name + role** (free text, e.g., "Jane Doe — staff ML engineer"). Capture as `owner_name`. Derive `owner_first_name` from the first whitespace-separated token of the part before " — " or "—" (or the whole string if no dash). Derive `owner_bio` as the role part after the dash (or empty if no dash).
2. **Primary domains** — multi-select. Present: AI, Finance, Business, Science, Law, Engineering, Design, Other. Accept comma-separated list. Capture as `domains` (array). Derive `domain_tag_list` as a comma-separated, code-formatted list, e.g., `` `AI`, `Finance` ``.
3. **Voice** — terse / standard / verbose. Capture as `voice`. Derive `voice_paragraph`:
   - terse: "Voice: terse. Drop padding. Fragments OK. No pleasantries. Match user's compact style."
   - standard: "Voice: standard. Clear, complete sentences. No filler, no hedging. Direct."
   - verbose: "Voice: verbose. Complete sentences with context. Explain reasoning where it adds clarity. No padding, but room to elaborate."
4. **Notes sacred?** — yes / no. Capture as `notes_sacred`.
5. **Private notes carve-out?** — yes / no. Capture as `private_notes`.
6. **Tag policy** — strict / loose. Capture as `tag_policy`. Derive:
   - `tag_count_rule`: "exactly two" if strict, "any number" if loose.
   - `tag_policy_paragraph`: if strict, paragraph describing 1 domain + 1 topic with cross-domain exception; if loose, "Use any tags that aid retrieval. `/audit` does not enforce tag count."
7. **Citation style** — wikilinks-only / wikilinks-plus-paths. Capture as `citation_style`. Derive `citation_paragraph`:
   - wikilinks-only: "Citations: `[[wikilinks]]` to other vault articles only."
   - wikilinks-plus-paths: "Citations: `[[wikilinks]]` to other vault articles, plus inline source paths (e.g., `raw/foo.pdf`) when citing raw sources directly."
8. **Output dir purpose** — explicit-ask only / freeform scratch. Capture as `output_explicit_only` (yes if explicit-ask, no if freeform).

## Render

1. Write a JSON answers file to `.claude/.vault-init-answers.json` with all derived keys.
2. Invoke the shared renderer:
   - On macOS/Linux/Git Bash: `bash .claude/lib/render-template.sh .claude/.vault-init-template.md .claude/.vault-init-answers.json CLAUDE.md`
   - On Windows PowerShell: `pwsh .claude/lib/render-template.ps1 .claude/.vault-init-template.md .claude/.vault-init-answers.json CLAUDE.md`
3. Verify the resulting `CLAUDE.md` contains no remaining `{{` and no orphan `{{#if}}` / `{{/if}}` markers. If any remain, abort and report which keys were missing.

## Post-render scaffold

1. For each domain in `domains`, create directory `wiki/<Domain>/` if missing.
2. Render `wiki/_master-index.md` from `.claude/.vault-init-template-index.md` (or write directly): replace `{{domain_index_sections}}` with one `## <Domain>\n\n_(no articles yet)_\n` block per chosen domain. Note: the cached index template is the original `templates/_master-index.md.tmpl` content — if `.claude/.vault-init-template-index.md` is missing, fall back to a minimal `# Master Index\n\n` header plus the domain sections.
3. If `private_notes == "yes"`, create `notes/private/`.
4. Report in chat: "Vault initialized. Run `/compile` when you have content in `raw/`."

## Hard don'ts

- Never proceed without all 8 answers.
- Never write `CLAUDE.md` directly — always go through the renderer so substitution and conditional stripping stay consistent with snapshot tests.
- Never read or write outside `<vault>/` (the current working directory and its subtree).
```

- [ ] **Step 2: Update installer spec note for the index cache**

Re-read the design spec §5.1 — only `CLAUDE.md.tmpl` is cached. The index template is small enough that `/vault-init` can re-derive it. The fallback path in step 2 above handles the missing-cache case. No spec change needed.

- [ ] **Step 3: Commit**

```bash
git add templates/.claude/commands/vault-init.md
git commit -m "feat(commands): add /vault-init interview wizard"
```

---

## Phase 4: Shared template renderer + tests (TDD)

The renderer is the single source of truth for `{{key}}` substitution and `{{#if key}}…{{/if}}` block stripping. Both `/vault-init` and the snapshot test invoke it.

Substitution rules (locked):
1. `{{key}}` — anywhere on a line, replaced with the string value of `key` from the answers JSON. Missing key = render error.
2. `{{#if key}}` and `{{/if}}` — each MUST be on its own line (whitespace-only lines OK). The block between them is kept iff `answers[key] == "yes"`. Otherwise the entire block (including the marker lines) is stripped.
3. Nesting — supported up to one level (the `notes_sacred` block contains a `private_notes` inner block in `CLAUDE.md.tmpl`).
4. No `else` branch. No loops.

### Task 12: Snapshot test fixture (write the failing test first)

**Files:**
- Create: `tests/fixtures/answers.json`
- Create: `tests/fixtures/expected-CLAUDE.md`
- Create: `tests/render-template.test.sh`

- [ ] **Step 1: Write canned answers fixture**

`tests/fixtures/answers.json`:
```json
{
  "owner_name": "Jane Doe — staff ML engineer",
  "owner_first_name": "Jane",
  "owner_bio": "staff ML engineer",
  "domain_tag_list": "`AI`, `Engineering`",
  "voice_paragraph": "Voice: standard. Clear, complete sentences. No filler, no hedging. Direct.",
  "notes_sacred": "yes",
  "private_notes": "yes",
  "tag_count_rule": "exactly two",
  "tag_policy_paragraph": "  - Domain tags: `AI`, `Engineering`.\n  - Default: one domain tag + one topic tag.",
  "citation_paragraph": "Citations: `[[wikilinks]]` to other vault articles only.",
  "output_explicit_only": "yes"
}
```

- [ ] **Step 2: Write expected rendered CLAUDE.md**

Generate the expected file by hand from `templates/CLAUDE.md.tmpl` with the answers above:
- All `{{key}}` values substituted
- All `{{#if key}}…{{/if}}` markers removed (since all conditionals are "yes" in this fixture)
- The block content kept

Save as `tests/fixtures/expected-CLAUDE.md`. Take care to reproduce exactly what the renderer should produce — match whitespace, blank lines around stripped marker lines (the renderer strips marker lines entirely, so blank-line collapsing rules matter — see Step 4 of next task for the collapse rule).

- [ ] **Step 3: Write the test runner**

`tests/render-template.test.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash "$ROOT/templates/.claude/lib/render-template.sh" \
  "$ROOT/templates/CLAUDE.md.tmpl" \
  "$ROOT/tests/fixtures/answers.json" \
  "$TMP/actual.md"

if diff -u "$ROOT/tests/fixtures/expected-CLAUDE.md" "$TMP/actual.md"; then
  echo "PASS: render matches fixture"
else
  echo "FAIL: render differs from fixture"
  exit 1
fi
```

- [ ] **Step 4: Make the test executable + run it (expect FAIL — renderer not yet built)**

```bash
chmod +x tests/render-template.test.sh
bash tests/render-template.test.sh
```

Expected: FAIL with error like `bash: .../render-template.sh: No such file or directory`.

- [ ] **Step 5: Commit fixtures + failing test**

```bash
git add tests/
git commit -m "test(render): add snapshot fixture + failing test for template renderer"
```

---

### Task 13: Implement the bash renderer

**Files:**
- Create: `templates/.claude/lib/render-template.sh`

- [ ] **Step 1: Write the renderer**

`templates/.claude/lib/render-template.sh`:
```bash
#!/usr/bin/env bash
# render-template.sh — substitute {{key}} and strip {{#if key}}…{{/if}} blocks.
# Usage: render-template.sh <template> <answers.json> <output>
# answers.json must be a flat object of string values. Conditional keys must be "yes" or "no".

set -euo pipefail

TEMPLATE="$1"
ANSWERS="$2"
OUTPUT="$3"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "render-template.sh: template not found: $TEMPLATE" >&2
  exit 1
fi
if [[ ! -f "$ANSWERS" ]]; then
  echo "render-template.sh: answers not found: $ANSWERS" >&2
  exit 1
fi

# Parse the JSON answers into bash associative array using a minimal JSON-to-shell pass.
# Requires only POSIX awk + sed; no jq dep.
declare -A VARS
while IFS=$'\t' read -r KEY VALUE; do
  [[ -z "$KEY" ]] && continue
  VARS["$KEY"]="$VALUE"
done < <(awk '
  BEGIN { RS=""; FS="" }
  {
    s = $0
    # crude but adequate for flat string-value objects
    while (match(s, /"[a-zA-Z_][a-zA-Z0-9_]*"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"/)) {
      pair = substr(s, RSTART, RLENGTH)
      s = substr(s, RSTART + RLENGTH)
      kstart = index(pair, "\"") + 1
      kend = index(substr(pair, kstart), "\"")
      key = substr(pair, kstart, kend - 1)
      vstart = index(pair, ":")
      rest = substr(pair, vstart + 1)
      sub(/^[[:space:]]*"/, "", rest)
      sub(/"[[:space:]]*$/, "", rest)
      gsub(/\\n/, "\n", rest)
      gsub(/\\"/, "\"", rest)
      gsub(/\\\\/, "\\", rest)
      printf "%s\t%s\n", key, rest
    }
  }
' "$ANSWERS")

# Strip {{#if key}}…{{/if}} blocks (one level of nesting allowed).
# Each marker MUST be on its own line.
strip_blocks() {
  local infile="$1"
  local outfile="$2"
  awk -v vars_str="$(for k in "${!VARS[@]}"; do printf "%s=%s\n" "$k" "${VARS[$k]}"; done)" '
    BEGIN {
      n = split(vars_str, lines, "\n")
      for (i = 1; i <= n; i++) {
        eq = index(lines[i], "=")
        if (eq > 0) {
          k = substr(lines[i], 1, eq - 1)
          v = substr(lines[i], eq + 1)
          vars[k] = v
        }
      }
      depth = 0
      skip_depth = 0
    }
    {
      line = $0
      if (match(line, /^[[:space:]]*\{\{#if[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*\}\}[[:space:]]*$/)) {
        m = substr(line, RSTART, RLENGTH)
        sub(/^[[:space:]]*\{\{#if[[:space:]]+/, "", m)
        sub(/\}\}[[:space:]]*$/, "", m)
        key = m
        depth++
        if (skip_depth == 0 && vars[key] != "yes") {
          skip_depth = depth
        }
        next
      }
      if (match(line, /^[[:space:]]*\{\{\/if\}\}[[:space:]]*$/)) {
        if (skip_depth == depth) skip_depth = 0
        depth--
        next
      }
      if (skip_depth == 0) print line
    }
  ' "$infile" > "$outfile"
}

# Substitute {{key}} placeholders. Each value treated as literal — no nested expansion.
substitute_keys() {
  local infile="$1"
  local outfile="$2"
  cp "$infile" "$outfile"
  for k in "${!VARS[@]}"; do
    v="${VARS[$k]}"
    # Use a Python one-liner for safe literal replace if available, else fall back to sed with escaping.
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f: s = f.read()
s = s.replace('{{' + sys.argv[2] + '}}', sys.argv[3])
with open(sys.argv[1], 'w', encoding='utf-8') as f: f.write(s)
" "$outfile" "$k" "$v"
    else
      # sed fallback — escape sed metacharacters in $v
      esc=$(printf '%s' "$v" | sed -e 's/[\/&]/\\&/g')
      sed -i.bak "s/{{${k}}}/${esc}/g" "$outfile"
      rm -f "${outfile}.bak"
    fi
  done
}

TMP1="$(mktemp)"
TMP2="$(mktemp)"
trap 'rm -f "$TMP1" "$TMP2"' EXIT

strip_blocks "$TEMPLATE" "$TMP1"
substitute_keys "$TMP1" "$TMP2"

# Final verification — no remaining {{...}} markers.
if grep -qE '\{\{' "$TMP2"; then
  echo "render-template.sh: unresolved markers remain in output:" >&2
  grep -nE '\{\{[^}]*\}\}' "$TMP2" >&2
  exit 1
fi

mv "$TMP2" "$OUTPUT"
```

- [ ] **Step 2: Make it executable + run the snapshot test**

```bash
chmod +x templates/.claude/lib/render-template.sh
bash tests/render-template.test.sh
```

Expected: PASS (or a clear diff showing exactly what to fix in either the renderer or the expected fixture). If the test FAILS, inspect the diff:
- If the failure is a whitespace mismatch around stripped markers, decide whether the renderer should also strip the trailing newline of the marker line (current behavior: `next` consumes the entire line including its newline via awk's record handling — no extra blank line is left). Update the fixture to match the renderer's deterministic output.
- If a `{{key}}` value is wrong, fix the answers fixture.
- If a key is missing from the renderer output, the renderer's substitute pass has a bug.

Iterate until PASS.

- [ ] **Step 3: Commit the renderer**

```bash
git add templates/.claude/lib/render-template.sh
git commit -m "feat(lib): add bash template renderer with {{key}} + {{#if}} support"
```

---

### Task 14: PowerShell renderer parity

**Files:**
- Create: `templates/.claude/lib/render-template.ps1`

- [ ] **Step 1: Write the PowerShell port**

`templates/.claude/lib/render-template.ps1`:
```powershell
# render-template.ps1 — substitute {{key}} and strip {{#if key}}…{{/if}} blocks.
# Usage: render-template.ps1 <template> <answers.json> <output>

param(
  [Parameter(Mandatory=$true)][string]$Template,
  [Parameter(Mandatory=$true)][string]$Answers,
  [Parameter(Mandatory=$true)][string]$Output
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Template)) { throw "template not found: $Template" }
if (-not (Test-Path $Answers)) { throw "answers not found: $Answers" }

$vars = Get-Content -Raw -Encoding UTF8 $Answers | ConvertFrom-Json
$varHash = @{}
foreach ($prop in $vars.PSObject.Properties) {
  $varHash[$prop.Name] = [string]$prop.Value
}

$lines = Get-Content -Encoding UTF8 $Template
$kept = New-Object System.Collections.Generic.List[string]
$skipDepth = 0
$depth = 0

foreach ($line in $lines) {
  if ($line -match '^\s*\{\{#if\s+([a-zA-Z_][a-zA-Z0-9_]*)\}\}\s*$') {
    $key = $Matches[1]
    $depth++
    if ($skipDepth -eq 0 -and $varHash[$key] -ne 'yes') {
      $skipDepth = $depth
    }
    continue
  }
  if ($line -match '^\s*\{\{/if\}\}\s*$') {
    if ($skipDepth -eq $depth) { $skipDepth = 0 }
    $depth--
    continue
  }
  if ($skipDepth -eq 0) { $kept.Add($line) }
}

$rendered = ($kept -join "`n")
foreach ($k in $varHash.Keys) {
  $rendered = $rendered.Replace("{{$k}}", $varHash[$k])
}

if ($rendered -match '\{\{') {
  Write-Error "render-template.ps1: unresolved markers remain"
  $rendered -split "`n" | Select-String '\{\{[^}]*\}\}' | ForEach-Object { Write-Error $_.Line }
  exit 1
}

Set-Content -Path $Output -Value $rendered -Encoding UTF8 -NoNewline
```

- [ ] **Step 2: Smoke test the PowerShell port**

Run:
```powershell
pwsh templates/.claude/lib/render-template.ps1 templates/CLAUDE.md.tmpl tests/fixtures/answers.json /tmp/ps-actual.md
diff tests/fixtures/expected-CLAUDE.md /tmp/ps-actual.md
```

Expected: no diff (same output as the bash renderer). If the diff shows trailing-newline differences only, decide which behavior is canonical (recommend: bash output is canonical; align PowerShell to match by appending `"`n"` if needed) and update the PowerShell port.

- [ ] **Step 3: Commit**

```bash
git add templates/.claude/lib/render-template.ps1
git commit -m "feat(lib): add PowerShell template renderer (parity with bash)"
```

---

## Phase 5: Bootstrap installers (TDD)

### Task 15: Installer test (write the failing test first)

**Files:**
- Create: `tests/install.test.sh`

- [ ] **Step 1: Write the installer test**

`tests/install.test.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

cd "$SCRATCH"
bash "$KIT/install.sh"

# Required files
test -f CLAUDE.md || { echo "FAIL: CLAUDE.md not created"; exit 1; }
test -f README.md || { echo "FAIL: README.md not created"; exit 1; }
test -f wiki/_master-index.md || { echo "FAIL: wiki/_master-index.md not created"; exit 1; }
test -f .claude/.vault-init-template.md || { echo "FAIL: .vault-init-template.md not cached"; exit 1; }
test -f .claude/commands/vault-init.md || { echo "FAIL: vault-init command not copied"; exit 1; }
test -f .claude/commands/compile.md || { echo "FAIL: compile command not copied"; exit 1; }
test -f .claude/commands/audit.md || { echo "FAIL: audit command not copied"; exit 1; }
test -f .claude/commands/refine.md || { echo "FAIL: refine command not copied"; exit 1; }
test -f .claude/commands/refresh-index.md || { echo "FAIL: refresh-index command not copied"; exit 1; }
test -f .claude/skills/vault-query/SKILL.md || { echo "FAIL: vault-query skill not copied"; exit 1; }
test -f .claude/lib/render-template.sh || { echo "FAIL: renderer not copied"; exit 1; }
test -f .claude/lib/render-template.ps1 || { echo "FAIL: PS renderer not copied"; exit 1; }

# Required directories
for d in raw wiki notes output; do
  test -d "$d" || { echo "FAIL: $d/ not created"; exit 1; }
done

# CLAUDE.md still has placeholders (wizard runs in Claude Code, not installer)
grep -q '{{owner_name}}' CLAUDE.md || { echo "FAIL: CLAUDE.md should still contain {{owner_name}} placeholder"; exit 1; }

# Re-run without --force should fail
if bash "$KIT/install.sh" 2>/dev/null; then
  echo "FAIL: re-run without --force should have failed"
  exit 1
fi

# Re-run with --force should succeed
bash "$KIT/install.sh" --force

# User content sacred — drop a sentinel file in raw/ and notes/, re-run with --force, verify untouched
echo "sentinel" > raw/sentinel.txt
echo "sentinel" > notes/sentinel.txt
echo "sentinel" > output/sentinel.txt
echo "user wiki article" > wiki/foo.md
bash "$KIT/install.sh" --force
test "$(cat raw/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched raw/"; exit 1; }
test "$(cat notes/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched notes/"; exit 1; }
test "$(cat output/sentinel.txt)" = "sentinel" || { echo "FAIL: --force touched output/"; exit 1; }
test "$(cat wiki/foo.md)" = "user wiki article" || { echo "FAIL: --force touched wiki/foo.md (non-template wiki content)"; exit 1; }

echo "PASS: installer behaves correctly"
```

- [ ] **Step 2: Run the test (expect FAIL — installer not yet built)**

```bash
chmod +x tests/install.test.sh
bash tests/install.test.sh
```

Expected: FAIL with `bash: .../install.sh: No such file or directory`.

- [ ] **Step 3: Commit**

```bash
git add tests/install.test.sh
git commit -m "test(install): add installer behavior test (currently failing)"
```

---

### Task 16: Implement `install.sh`

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write the installer**

`install.sh`:
```bash
#!/usr/bin/env bash
# install.sh — bootstrap an obsidian-vault-kit scaffold into the current directory.
# Usage: bash /path/to/obsidian-vault-kit/install.sh [--force] [--kit-root <path>]

set -euo pipefail

FORCE=0
KIT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --kit-root) KIT_ROOT="$2"; shift 2 ;;
    *) echo "install.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$KIT_ROOT" ]]; then
  KIT_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

TEMPLATES="$KIT_ROOT/templates"
if [[ ! -d "$TEMPLATES" ]]; then
  echo "install.sh: kit templates dir not found at $TEMPLATES" >&2
  exit 1
fi

CWD="$(pwd)"

# Pre-flight refusal
if [[ $FORCE -eq 0 ]]; then
  if [[ -d "$CWD/.claude" ]]; then
    echo "install.sh: refusing to overwrite existing $CWD/.claude (pass --force to override)" >&2
    exit 1
  fi
  if [[ -f "$CWD/CLAUDE.md" ]]; then
    echo "install.sh: refusing to overwrite existing $CWD/CLAUDE.md (pass --force to override)" >&2
    exit 1
  fi
fi

# Copy .claude/ tree
mkdir -p "$CWD/.claude"
cp -R "$TEMPLATES/.claude/." "$CWD/.claude/"

# Copy CLAUDE.md (still containing placeholders)
cp "$TEMPLATES/CLAUDE.md.tmpl" "$CWD/CLAUDE.md"

# Cache pristine template for /vault-init force re-runs
cp "$TEMPLATES/CLAUDE.md.tmpl" "$CWD/.claude/.vault-init-template.md"

# Copy master index stub (only if not present, to honor "user wiki content sacred")
if [[ ! -f "$CWD/wiki/_master-index.md" ]] || [[ $FORCE -eq 1 ]]; then
  mkdir -p "$CWD/wiki"
  # On --force, we still skip if the file has been substituted (no {{ markers).
  if [[ -f "$CWD/wiki/_master-index.md" ]] && ! grep -q '{{' "$CWD/wiki/_master-index.md"; then
    : # leave user-modified index alone
  else
    cp "$TEMPLATES/_master-index.md.tmpl" "$CWD/wiki/_master-index.md"
  fi
fi

# Copy vault-level README (only if not present, to honor user edits)
if [[ ! -f "$CWD/README.md" ]] || [[ $FORCE -eq 1 ]]; then
  cp "$TEMPLATES/README.md.tmpl" "$CWD/README.md"
fi

# Create canonical empty dirs
for d in raw wiki notes output; do
  mkdir -p "$CWD/$d"
done

cat <<EOF
Vault scaffold installed at: $CWD

Next:
  1. Open this folder in Claude Code.
  2. Run: /vault-init
EOF
```

- [ ] **Step 2: Make executable + run the installer test**

```bash
chmod +x install.sh
bash tests/install.test.sh
```

Expected: PASS. If a test assertion fails, inspect the failure message and fix either the installer or the assertion. Common gotchas:
- `cp -R "$TEMPLATES/.claude/."` — the trailing `/.` is required to copy the dir's contents (including hidden files) into the destination, not the dir itself. Verify with `ls -la /tmp/.../.claude/` after a manual run.
- The "user wiki article" check: the installer's `wiki/_master-index.md` clause must skip files without `{{` markers — re-read the conditional in step 1 if the test fails on `wiki/foo.md`.

- [ ] **Step 3: Run the renderer snapshot test too**

```bash
bash tests/render-template.test.sh
```

Expected: still PASS (no regression).

- [ ] **Step 4: Commit**

```bash
git add install.sh
git commit -m "feat: add install.sh bootstrap with --force gating + sacred-content protection"
```

---

### Task 17: Implement `install.ps1`

**Files:**
- Create: `install.ps1`

- [ ] **Step 1: Write the PowerShell installer**

`install.ps1`:
```powershell
# install.ps1 — bootstrap an obsidian-vault-kit scaffold into the current directory.
# Usage: pwsh /path/to/obsidian-vault-kit/install.ps1 [-Force] [-KitRoot <path>]

param(
  [switch]$Force,
  [string]$KitRoot
)

$ErrorActionPreference = 'Stop'

if (-not $KitRoot) {
  $KitRoot = Split-Path -Parent $PSCommandPath
}

$Templates = Join-Path $KitRoot 'templates'
if (-not (Test-Path $Templates)) {
  throw "install.ps1: kit templates dir not found at $Templates"
}

$Cwd = (Get-Location).Path

# Pre-flight refusal
if (-not $Force) {
  if (Test-Path (Join-Path $Cwd '.claude')) {
    throw "install.ps1: refusing to overwrite existing .claude (pass -Force to override)"
  }
  if (Test-Path (Join-Path $Cwd 'CLAUDE.md')) {
    throw "install.ps1: refusing to overwrite existing CLAUDE.md (pass -Force to override)"
  }
}

# Copy .claude/ tree
$DotClaude = Join-Path $Cwd '.claude'
if (-not (Test-Path $DotClaude)) { New-Item -ItemType Directory -Path $DotClaude | Out-Null }
Copy-Item -Recurse -Force (Join-Path $Templates '.claude\*') $DotClaude

# Copy CLAUDE.md (still containing placeholders)
Copy-Item -Force (Join-Path $Templates 'CLAUDE.md.tmpl') (Join-Path $Cwd 'CLAUDE.md')

# Cache pristine template for /vault-init force re-runs
Copy-Item -Force (Join-Path $Templates 'CLAUDE.md.tmpl') (Join-Path $DotClaude '.vault-init-template.md')

# Copy master index stub — skip if user has substituted it already
$WikiDir = Join-Path $Cwd 'wiki'
if (-not (Test-Path $WikiDir)) { New-Item -ItemType Directory -Path $WikiDir | Out-Null }
$IndexPath = Join-Path $WikiDir '_master-index.md'
$ShouldCopyIndex = (-not (Test-Path $IndexPath)) -or ($Force -and (Get-Content -Raw $IndexPath) -match '\{\{')
if ($ShouldCopyIndex) {
  Copy-Item -Force (Join-Path $Templates '_master-index.md.tmpl') $IndexPath
}

# Copy vault-level README — overwrite only if --force or missing
$ReadmePath = Join-Path $Cwd 'README.md'
if (-not (Test-Path $ReadmePath) -or $Force) {
  Copy-Item -Force (Join-Path $Templates 'README.md.tmpl') $ReadmePath
}

# Create canonical empty dirs
foreach ($d in @('raw', 'wiki', 'notes', 'output')) {
  $p = Join-Path $Cwd $d
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

Write-Output "Vault scaffold installed at: $Cwd"
Write-Output ""
Write-Output "Next:"
Write-Output "  1. Open this folder in Claude Code."
Write-Output "  2. Run: /vault-init"
```

- [ ] **Step 2: Smoke test the PowerShell installer manually**

```powershell
$scratch = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "ovk-smoke-$(Get-Random)")
Push-Location $scratch
pwsh C:\Proyectos\Obsidian_Set\obsidian-vault-kit\install.ps1
# Verify scaffolding
Get-ChildItem -Force
Get-ChildItem .claude -Recurse
Pop-Location
Remove-Item -Recurse -Force $scratch
```

Expected: same scaffolding as the bash installer produces.

- [ ] **Step 3: Commit**

```bash
git add install.ps1
git commit -m "feat: add install.ps1 (Windows parity with install.sh)"
```

---

## Phase 6: End-to-end smoke + final polish

### Task 18: Full end-to-end smoke test

- [ ] **Step 1: Run automated tests one more time**

```bash
bash tests/render-template.test.sh
bash tests/install.test.sh
```

Both must PASS. If either fails, fix before proceeding.

- [ ] **Step 2: Manual end-to-end smoke**

```bash
SMOKE="$(mktemp -d)"
cd "$SMOKE"
bash /c/Proyectos/Obsidian_Set/obsidian-vault-kit/install.sh
ls -la
ls -la .claude
cat CLAUDE.md | head -30
cat wiki/_master-index.md
```

Verify:
- All files/dirs from the spec §5.1 are present
- `CLAUDE.md` still contains `{{` markers
- `wiki/_master-index.md` contains `{{domain_index_sections}}`
- `.claude/.vault-init-template.md` exists and equals `templates/CLAUDE.md.tmpl`

```bash
diff "$SMOKE/.claude/.vault-init-template.md" /c/Proyectos/Obsidian_Set/obsidian-vault-kit/templates/CLAUDE.md.tmpl
```

Expected: no diff.

- [ ] **Step 3: Render the template manually using the renderer + canned answers**

```bash
bash /c/Proyectos/Obsidian_Set/obsidian-vault-kit/templates/.claude/lib/render-template.sh \
  "$SMOKE/.claude/.vault-init-template.md" \
  /c/Proyectos/Obsidian_Set/obsidian-vault-kit/tests/fixtures/answers.json \
  "$SMOKE/CLAUDE.md.rendered"

# Assert no remaining markers
! grep -q '{{' "$SMOKE/CLAUDE.md.rendered" && echo "OK: no unresolved markers" || { echo "FAIL: unresolved markers"; grep -n '{{' "$SMOKE/CLAUDE.md.rendered"; exit 1; }
```

Expected: "OK: no unresolved markers".

- [ ] **Step 4: Cleanup smoke dir**

```bash
rm -rf "$SMOKE"
```

- [ ] **Step 5: Verify the kit's own working tree is clean**

```bash
cd /c/Proyectos/Obsidian_Set/obsidian-vault-kit
git status
```

Expected: clean working tree (all task commits already made).

- [ ] **Step 6: Final commit (if any pending changes from smoke fixes)**

If smoke testing required fixes, commit them with a descriptive message. Otherwise, no commit — the working tree should already be clean.

```bash
git log --oneline
```

Verify the commit history matches the task order.

---

## Summary — files created

```
LICENSE
README.md
install.sh
install.ps1
templates/
  CLAUDE.md.tmpl
  _master-index.md.tmpl
  README.md.tmpl
  .claude/
    lib/
      render-template.sh
      render-template.ps1
    skills/
      vault-query/SKILL.md
    commands/
      vault-init.md
      compile.md
      audit.md
      refine.md
      refresh-index.md
tests/
  fixtures/
    answers.json
    expected-CLAUDE.md
  render-template.test.sh
  install.test.sh
docs/superpowers/specs/2026-04-30-obsidian-vault-kit-design.md   (already exists from spec phase)
docs/superpowers/plans/2026-04-30-obsidian-vault-kit.md          (this plan)
```

## Out of scope for this plan (deferred — see spec §11)

- npm distribution
- Multi-vault upgrade tooling
- Tag taxonomy auto-suggestion
- Migration tool for existing non-kit vaults
- GUI installer
- `--answers <file>` non-interactive mode for `/vault-init`

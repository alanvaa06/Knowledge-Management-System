# obsidian-vault-kit — Design Spec

**Date:** 2026-04-30
**Status:** Draft (awaiting user review)
**Repo:** `C:/Proyectos/Obsidian_Set/obsidian-vault-kit/`

## 1. Purpose

Reusable scaffold + skill set for running an Obsidian vault as a structured knowledge base. Generic-ified extraction of a personal vault operating manual into a distributable kit. Anyone can clone the kit, run an installer inside any folder, and end up with:

- A vault directory tree (`raw/`, `wiki/`, `notes/`, `output/`)
- A `CLAUDE.md` tailored via interview (no hardcoded personal info)
- Five vault-scoped skills/commands for ingesting, querying, auditing, refining, and indexing knowledge

## 2. Non-Goals

- Not a Claude Code marketplace plugin (see §3 conflict analysis).
- No Obsidian app plugin — works at the file-system level only.
- No runtime daemon, no background sync, no cloud component.
- No template engine dependency — simple `{{key}}` substitution.
- No support for renaming the four canonical folders. Names are fixed conventions.

## 3. Distribution + Scoping (why bootstrap, not plugin)

Initial direction was a Claude Code plugin. Rejected because plugins install globally to `~/.claude/plugins/`, and:

1. Slash command names (`/compile`, `/audit`, `/refresh-index`) collide with build/security/DB tools in unrelated repos.
2. The `vault-query` skill auto-triggers on natural questions ("what does the vault say…") — would fire in non-vault projects if globally registered.
3. `/vault-init` available in every folder = risk of accidentally scaffolding a vault inside an unrelated repo.

**Chosen approach: bootstrap installer, vault-scoped install.**

- Kit repo cloned once, anywhere on disk.
- User runs `bash install.sh` (or `pwsh install.ps1` on Windows) from inside the target vault folder.
- Installer copies `templates/.claude/` → `<vault>/.claude/`, drops a stub `CLAUDE.md` and the canonical folder tree, then exits.
- User opens the vault in Claude Code and runs `/vault-init` — wizard fills in the `CLAUDE.md` template via 8-question interview.

Outcome: skills + commands exist **only inside vaults that ran the installer**. Zero global footprint. Zero name collision risk. Each vault can independently upgrade or pin its kit version.

## 4. Repo Layout

```
obsidian-vault-kit/
├── .claude-plugin/                      # NOT used — kit ships as installer, not plugin
├── install.sh                           # POSIX bootstrap
├── install.ps1                          # Windows bootstrap
├── templates/
│   ├── .claude/
│   │   ├── skills/
│   │   │   └── vault-query/
│   │   │       └── SKILL.md             # auto-triggered skill
│   │   └── commands/
│   │       ├── vault-init.md            # /vault-init — interview wizard
│   │       ├── compile.md               # /compile — raw → wiki
│   │       ├── audit.md                 # /audit — read-only review
│   │       ├── refine.md                # /refine <path> — notes editor
│   │       └── refresh-index.md         # /refresh-index — rebuild master index
│   ├── CLAUDE.md.tmpl                   # generic vault operating manual w/ {{placeholders}}
│   ├── _master-index.md.tmpl            # empty index w/ section headers per domain
│   └── README.md.tmpl                   # vault-level README for end user
├── docs/superpowers/specs/              # design specs + plans
├── tests/
│   └── render-template.test.sh          # snapshot test of template rendering
├── README.md                            # kit-level docs
└── LICENSE                              # MIT
```

> Note: `.claude-plugin/` directory listed for clarity that it is intentionally absent — the kit is not a plugin.

## 5. Bootstrap Installer

### 5.1 Behavior

`install.sh` (and PowerShell equivalent) executes inside the target vault folder. It performs only filesystem operations — no network, no package installs, no interactive prompts.

Steps:

1. Refuse to run if `<cwd>/.claude/` already exists, unless `--force` is passed. Print clear error.
2. Refuse to run if `<cwd>/CLAUDE.md` already exists, unless `--force`.
3. Copy `<kit>/templates/.claude/` → `<cwd>/.claude/` (preserves structure).
4. Copy `<kit>/templates/CLAUDE.md.tmpl` → `<cwd>/CLAUDE.md` **as-is, still containing `{{placeholders}}`**. The wizard fills these in later.
5. Copy `<kit>/templates/CLAUDE.md.tmpl` → `<cwd>/.claude/.vault-init-template.md` (cached pristine copy used by `/vault-init force` re-runs — see §6.3).
6. Copy `<kit>/templates/_master-index.md.tmpl` → `<cwd>/wiki/_master-index.md`.
7. Copy `<kit>/templates/README.md.tmpl` → `<cwd>/README.md`.
8. Create empty directories: `raw/`, `wiki/`, `notes/`, `output/`.
9. Print: "Vault scaffold installed. Open this folder in Claude Code and run `/vault-init` to complete setup."

### 5.2 Locating the kit

The installer must find the kit's `templates/` directory. Resolution order:

1. `--kit-root <path>` flag.
2. The directory containing the script itself (`dirname "$0"`).

No global config, no env vars.

### 5.3 Idempotency

Re-running the installer with `--force` overwrites `.claude/`, `CLAUDE.md`, and `wiki/_master-index.md`, but never touches `raw/`, `notes/`, `output/`, or any non-template file in `wiki/`. User content is sacred.

## 6. `/vault-init` Interview Wizard

Implemented as a slash command (`templates/.claude/commands/vault-init.md`). Runs inside Claude Code after bootstrap. Asks 8 questions one at a time.

### 6.1 Questions

| # | Question | Type | Drives |
|---|----------|------|--------|
| 1 | Owner name + role (free text, e.g., "Jane Doe — staff ML engineer") | text | `## {{owner_name}}` block in CLAUDE.md |
| 2 | Primary domains | multi-select (AI, Finance, Business, Science, Law, Engineering, Design, Other…) | `wiki/<Domain>/` subfolders + `_master-index.md` sections + tag taxonomy seeds |
| 3 | Voice preference | terse / standard / verbose | "Voice" paragraph in CLAUDE.md |
| 4 | Notes sacred? | yes / no | Toggles `## notes/ — Sacred Rules` section in CLAUDE.md |
| 5 | Private notes carve-out? | yes / no | If yes, creates `notes/private/` and adds invisibility rules to compile/audit/query |
| 6 | Tag policy | strict 2-tag (1 domain + 1 topic, enforced by `/audit`) / loose (any number of tags, no audit enforcement) | Frontmatter convention paragraph |
| 7 | Citation style | wikilinks only / wikilinks + inline source paths | Citation rule in `query` and `compile` commands |
| 8 | Output dir purpose | explicit-ask only / freeform scratch | Hard Don'ts section |

### 6.2 Wizard execution

After collecting answers, the wizard:

1. Reads the pristine template from `<vault>/.claude/.vault-init-template.md` (created by installer in §5.1 step 5). Always read from cache, never from `<vault>/CLAUDE.md` — that file may already be substituted from a prior run.
2. Substitutes each `{{key}}` with the answer (simple string replace, no engine).
3. Conditionally strips template blocks gated by `{{#if key}}…{{/if}}` markers — implemented as a small awk pass, no Mustache/Handlebars dep.
4. Writes substituted result to `<vault>/CLAUDE.md` (overwrites).
5. Creates `wiki/<Domain>/` subfolder per domain selected in Q2.
6. Updates `wiki/_master-index.md` with one section header per domain.
7. Creates `notes/private/` if Q5 = yes.
8. Reports in chat: "Vault initialized. Run `/compile` when you have content in `raw/`."

### 6.3 Re-running

If user re-runs `/vault-init` after initial setup, the wizard refuses unless explicit `force` argument is passed in chat. Re-running with force re-runs the full interview and re-renders `CLAUDE.md` from the cached pristine template at `<vault>/.claude/.vault-init-template.md` (created by installer in §5.1 step 5).

## 7. Skills + Commands Inventory

| Name | Type | Vault location | Purpose | Writes |
|------|------|----------------|---------|--------|
| `/vault-init` | slash command | `.claude/commands/vault-init.md` | One-time interview + scaffold completion | `CLAUDE.md`, `wiki/<Domain>/`, `_master-index.md`, `notes/private/` (conditional) |
| `/compile` | slash command | `.claude/commands/compile.md` | Process `raw/` → `wiki/`. Mandatory plan-and-confirm before any write. | `wiki/`, `_master-index.md` |
| `/audit` | slash command | `.claude/commands/audit.md` | Read-only review of `wiki/`. Reports broken wikilinks, dupes, stale index entries, tag/frontmatter conformance. Never auto-fixes. | none |
| `/refine <path>` | slash command | `.claude/commands/refine.md` | Voice-preserving editor pass on a single `notes/` file. Diff-first, never invents content, flags ambiguity with `> [!question]` callouts. | `notes/<path>` after explicit approval |
| `/refresh-index` | slash command | `.claude/commands/refresh-index.md` | Rebuild `_master-index.md` from current `wiki/` contents. Flat grouped list. | `_master-index.md` only |
| `vault-query` | skill | `.claude/skills/vault-query/SKILL.md` | Auto-triggered when user asks a vault question. Reads `_master-index.md` graph first, walks wikilinks, then drills into specific articles. Cites sources. | chat only (file write only if user asks) |

All five files are **direct generic-izations** of the corresponding sections in the source vault's `CLAUDE.md`. Personal references (CFA, JHU, Cambridge, "Alan") are stripped. Behavior, plan-and-confirm gates, sacred-notes rules, and directionality (`raw/ → wiki/ → output/`) are preserved verbatim.

## 8. `CLAUDE.md.tmpl` Structure

Template mirrors the source vault's `CLAUDE.md` shape:

```markdown
# CLAUDE.md — Vault Operating Manual

## {{owner_name}}
{{owner_bio}}

## Structure
- `raw/` — inbox …
- `wiki/` — compiled knowledge base …
- `notes/` — {{owner_first_name}}'s human-authored notes. {{#if notes_sacred}}SACRED. Read-only.{{/if}}
- `output/` — artifacts {{owner_first_name}} explicitly asks for. …

## Directionality
…unchanged from source…

## Wiki Conventions
- Frontmatter: `Writer`, `Link`, `tags` ({{tag_count_rule}}).
  - Domain tags: {{domain_tag_list}}.
  - …

{{#if notes_sacred}}
## notes/ — Sacred Rules
…
{{#if private_notes}}
- **`notes/private/`** — invisible to compile/audit. Query only with explicit reference. …
{{/if}}
{{/if}}

## Commands
### `compile`
…
### `audit`
…
### `query` / `ask`
…
### `refine`
…
### `refresh index`
…

## Hard Don'ts
…
{{#if output_explicit_only}}
- Don't write to `output/` unless explicitly asked.
{{/if}}
```

Substitution keys derived from interview answers in §6.1. Conditional blocks use `{{#if key}}…{{/if}}` markers — handled by a small awk/sed pass, no template engine.

## 9. Conflict Analysis (recap)

| Risk | Mitigation |
|------|------------|
| Slash command name collision (`/compile` clashes with build tools) | Vault-scoped install — commands only registered when CWD is the vault |
| `vault-query` skill auto-fires in unrelated projects | Same — skill lives in `<vault>/.claude/skills/`, only loaded when CWD is vault |
| `/vault-init` runs accidentally outside vault | Same — command unavailable outside any vault that ran installer |
| Installer overwrites user content | `--force` required for any pre-existing `.claude/` or `CLAUDE.md`; never touches `raw/notes/output/` |
| Kit version drift across vaults | Each vault independently upgraded by re-running installer with `--force` against newer kit |

## 10. Testing

- `tests/render-template.test.sh` — feeds canned answers through the substitution logic, diffs result against a fixture file. Catches regressions in template rendering or conditional handling.
- Manual smoke test: clone kit → run `install.sh` in scratch dir → open in Claude Code → run `/vault-init` with sample answers → verify scaffold tree matches expected layout, `CLAUDE.md` has no remaining `{{placeholders}}` and no orphan `{{#if}}` markers.
- No unit tests for the slash command bodies themselves — they are markdown instructions executed by Claude, not code.

## 11. Out of Scope (v1)

- npm distribution (deferred — git clone only for v1).
- Multi-vault management / kit upgrade tooling.
- Tag taxonomy auto-suggestion from existing wiki content.
- Migration tool for converting an existing non-kit vault.
- GUI installer.
- Localization of `CLAUDE.md` template (English only).

## 12. Open Questions

None blocking. To revisit after v1 ships:

- Should `/vault-init` support an `--answers <yaml-file>` flag for non-interactive setup (CI, dotfiles)?
- Should the installer offer to `git init` the vault?
- Whether to add a `/digest` skill that summarizes recent `wiki/` changes.

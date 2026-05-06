# README Philosophy Rewrite — Design Spec

**Date:** 2026-05-05
**Owner:** alanvaa06
**Status:** Approved (pending user spec review)

## Goal

Restructure `README.md` to lead with the *why* of the four-folder architecture instead of installation instructions. The current README sells the kit as scaffolding; the rewrite sells it as a philosophical fork of Andrej Karpathy's LLM-powered wiki framework — extended to keep a domain expert's own knowledge sovereign.

## Why now

The kit's distinguishing feature is the `notes/` + `notes/private/` split — a deliberate departure from Karpathy's three-folder model. The current README describes that split functionally but never explains why it exists or what it unlocks. New readers cannot tell the kit apart from a generic Obsidian + Claude scaffold.

A LinkedIn post by the project owner already articulates the philosophy clearly. This rewrite ports that framing into the README so the architecture's intent travels with the code.

## Non-goals

- Changing any code, commands, templates, or installer behavior.
- Renaming the repo, the kit, or any files.
- Updating `templates/README.md.tmpl` (the per-vault README dropped into user vaults). That template stays as-is — vault owners do not need the philosophical framing.
- Producing marketing copy. Tone stays neutral/third-person docs voice.

## Audience

A reader who has read or heard of Karpathy's framework and is evaluating whether to fork or adopt this kit. They want to understand:
1. What architectural decisions this kit makes.
2. Why those decisions differ from Karpathy's.
3. What those differences unlock.
4. How to install and operate it.

## Structure

Linear narrative — orient → contrast → mechanics → reference. Seven sections:

### 1. Header

Hybrid name: `# Knowledge Management System` as H1, followed by a single-line markdown blockquote subtitle. Exact text:

> An Obsidian vault kit for LLM-powered knowledge bases — built on Andrej Karpathy's wiki framework, extended for domain experts who need their own thinking to stay sovereign.

Names the lineage (Karpathy) and the twist (sovereignty). One sentence. No tagline padding.

### 2. The framework

A single paragraph summarizing Karpathy's three-folder model (`raw/ → wiki/ → output/`, LLM-as-author, human-as-librarian) with a link to the gist. Closes with the assumption that gets challenged: "That model assumes one role for the human: librarian."

Tone: factual, fair to Karpathy. No straw-manning.

### 3. Where this departs

Three beats:
1. Name the unmet need — domain experts who generate their own synthesis (investment theses, research arguments, product strategy, legal positions, etc.).
2. Name the additions — `notes/` (sacred, voice-preserving, never compiled from) and `notes/private/` (never persists, queryable on demand).
3. Name the role shift — librarian → librarian + scholar, with strict walls.

Domain examples must span beyond finance: research, business, product, legal, "any work where your synthesis is the asset".

### 4. Architecture

A five-row table mapping each folder (`raw/`, `wiki/`, `notes/`, `notes/private/`, `output/`) to its role and the LLM's access level. Below the table: directionality (`raw/ → wiki/ → output/`, with `notes/` as reference side-channel and `notes/private/` as query-time side-channel) and a paragraph naming the enforcement points (`CLAUDE.md`, plan-and-confirm in `compile`, read-only `audit`, diff-before-apply in `refine`, compile/audit invisibility for `notes/private/`).

This section absorbs the current README's "What you get" content. Folder list lives next to its rationale.

### 5. What `notes/private/` unlocks

Five concrete use cases, each one bullet:
1. Stress-test an investment thesis against the wiki's compiled domain knowledge.
2. Pressure-test a business idea against compiled market structure and competitor analysis.
3. Sanity-check a research argument against the full ingested corpus.
4. Rehearse a strategic decision against precedents and constraints already captured.
5. Develop a private hypothesis "in the open" — keep working drafts in `notes/private/`, use the wiki as a domain-aware sparring partner.

Closes with a wall-restated reminder: private synthesis informs the answer, the answer stays in chat unless explicitly asked for a file, the wiki never learns what was written in private.

### 6. Workflows

Bullet list of the five slash commands plus the `vault-query` skill. Each command tagged with the discipline that protects the architecture: plan-and-confirm (`compile`), read-only (`audit`), diff-and-confirm (`refine`). Closes with the "all commands live inside `<vault>/.claude/`" line preserved verbatim from the current README.

### 7. Install / Tests / License

Functionally identical to the current README. Two changes:
- Clone URL updated from placeholder `<you>/obsidian-vault-kit` to `alanvaa06/Knowledge-Management-System`.
- Local clone target dir renamed `~/tools/knowledge-management-system` (was `~/tools/obsidian-vault-kit`).

The installer-behavior bullets and the `--force` re-run paragraph are preserved verbatim.

## Voice and tone

- Third-person, neutral docs voice. No first-person "I built".
- Drop articles/filler in headings only if they read naturally. Body copy stays standard English.
- No emojis. No marketing hype words ("powerful", "revolutionary", "blazing fast").
- Karpathy gets credited fairly — the kit is a fork that respects the original, not a critique.
- The librarian-vs-scholar framing is the single rhetorical device. Use it once in section 3 and let it carry; do not repeat the metaphor in later sections.

## Out-of-scope considerations addressed

- **Repo rename:** Header uses `Knowledge Management System` (matches GitHub slug); subtitle keeps "Obsidian vault kit" as functional descriptor. No code/file/command renames required by this spec.
- **`templates/README.md.tmpl`:** Untouched. Per-vault READMEs target a different audience (vault owners post-install) and do not need the philosophy.
- **`CLAUDE.md.tmpl`:** Untouched. Already encodes the architecture rules; this rewrite only documents them at the README level.

## Acceptance criteria

1. `README.md` renders cleanly on GitHub (table renders, code fences close, links resolve).
2. The seven sections appear in the order: Header → Framework → Where this departs → Architecture → What `notes/private/` unlocks → Workflows → Install → Tests → License.
3. Karpathy's gist URL is linked once in the Framework section.
4. The architecture table includes all five folders (`raw/`, `wiki/`, `notes/`, `notes/private/`, `output/`) with role and LLM-access columns.
5. Domain examples in "Where this departs" name at least four distinct fields (e.g., investment, research, product/business strategy, legal).
6. `notes/private/` use cases include at least five distinct examples spanning multiple domains.
7. No mention of the LinkedIn post inside the README itself.
8. Install commands point at `alanvaa06/Knowledge-Management-System`.
9. Installer-behavior list and `--force` paragraph are byte-identical to the current README's equivalents (excluding the URL/dir-name change).

## Implementation notes

- Single-file change: `README.md`.
- No tests need updating (no test currently covers README contents).
- Commit as a single change with message `docs(readme): restructure around four-folder philosophy`.

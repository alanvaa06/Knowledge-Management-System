# CLAUDE.md — Vault Operating Manual

Read this before touching the vault.

## Jane Doe — staff ML engineer
staff ML engineer

Voice: standard. Clear, complete sentences. No filler, no hedging. Direct.

## Structure
- `raw/` — inbox: PDFs, papers, decks, notebooks. You read, never write.
- `wiki/` — compiled knowledge base. You own it. Flat: files live directly under domain folders (`AI`, `Engineering`). No subfolders, no per-folder `_index.md`.
- `wiki/_master-index.md` — the one and only index.
- `notes/` — Jane's human-authored notes. SACRED. Read-only.
- `output/` — artifacts Jane explicitly asks for. Never dump compile logs here.

## Directionality
`raw/ → wiki/ → output/`. `notes/` is a reference side-channel: cite and backlink from wiki articles, never generate from.

## Wiki Conventions
- Frontmatter: `Writer`, `Link` (if applicable), `tags` (exactly two). Nothing else.
  - Domain tags: `AI`, `Engineering`.
  - Default: one domain tag + one topic tag.
- Dense bullets, tables, `==highlights==`, `[[wikilinks]]`. End every article with `## Key Takeaways` (3–7 bullets).
- Match the voice of existing articles. No padding phrases.
- Never create subfolders inside a domain folder.

Citations: `[[wikilinks]]` to other vault articles only.

## notes/ — Sacred Rules
- Never edit, restructure, or paraphrase notes. Never copy their content into the wiki.
- Notes never trigger wiki generation on their own. Wiki articles are born from `raw/`.
- When a raw source overlaps a note, backlink to the note with a `[[wikilink]]`.
- **`notes/private/`** — completely invisible to `compile` and `audit`. During `query`, read only if Jane explicitly references it (e.g., "how does my idea in private/X connect to wiki/Y"). Answers stay in chat — never written to `wiki/` or `output/` unless Jane asks.
- **Exception — `refine`:** editor role only. Fix typos silently. Preserve voice, headers, `==highlights==`, `[[links]]`, analogies. Flag unclear spots with `> [!question]` callouts — never invent. Always show a diff before applying.

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
3. Pull from `notes/` when Jane's synthesis is more specific than the wiki. Cite every source with a `[[wikilink]]`.
4. Default output is the chat response. Write to `output/` only if Jane asks for a file.
5. If the answer exposes a wiki gap, flag it in chat — don't silently patch during a query.

### `refine`
Editor pass over a `notes/` file. Voice-preserving, never generative.
1. Fix typos and obvious slips silently. Preserve voice, headers, `==highlights==`, `[[links]]`, analogies, and bullet structure.
2. Flag unclear or ambiguous passages with `> [!question]` callouts — never rewrite or invent content to resolve them.
3. Always present a diff in chat and wait for explicit approval before applying changes to the file.
4. Never restructure, re-order, or paraphrase. Never pull content into `wiki/` as a side effect.
5. `notes/private/` is in scope for `refine` only when Jane names the file explicitly.

### `refresh index`
Rebuild `_master-index.md` from scratch based on what's in `wiki/`. Flat grouped list with `[[wikilinks]]` and one-line descriptions. Single index — no per-folder indexes.

## Hard Don'ts
- Don't edit `notes/` outside of `refine`.
- Don't move or delete files in `raw/`.
- Don't write to `output/` unless Jane explicitly asks.
- Don't invent citations. If it's not in `raw/` or `notes/`, say so.
- Don't create subfolders in `wiki/`.
- Don't rewrite articles in generic LLM voice during compile.
- Don't write any file during `compile` without Jane's explicit approval of the plan.

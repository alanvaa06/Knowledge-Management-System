# CLAUDE.md — Vault Operating Manual

Read this before touching the vault.

## Jane Doe — staff ML engineer
staff ML engineer

Voice: standard. Clear, complete sentences. No filler, no hedging. Direct.

## Structure
- `raw/` — inbox: PDFs, papers, decks, notebooks. You read, never write. Jane may delete a source once it is compiled; that is expected, not a problem.
- `wiki/` — compiled knowledge base. You own it. Flat: files live directly under domain folders (`AI`, `Engineering`). No subfolders, no per-folder `_index.md`.
- `wiki/_master-index.md` — the one and only index.
- `wiki/_log.md` — append-only ops journal. Written only by `compile`, `audit`, and `refresh-index`. Never edited by hand.
- `notes/` — Jane's human-authored notes. SACRED. Read-only.
- `output/` — artifacts Jane explicitly asks for. Never dump compile logs here.

## Directionality
`raw/ → wiki/ → output/`. `notes/` is a reference side-channel: cite and backlink from wiki articles, never generate from.

## Wiki Conventions
- Frontmatter: `Writer`, `Link` (if applicable), `Source`, `tags` (exactly two). Nothing else.
- `Source` — list of the `raw/` paths the article was compiled from, as plain text (e.g. `raw/q3-report.pdf`), never `[[wikilinks]]`. Append a path when a new source updates the article; never remove one. It is the provenance record and how `compile` knows which sources are done, so it stays valid after the file leaves `raw/`.
  - Domain tags: `AI`, `Engineering`.
  - Default: one domain tag + one topic tag.
- Dense bullets, tables, `==highlights==`, `[[wikilinks]]`. End every article with `## Key Takeaways` (3–7 bullets).
- Match the voice of existing articles. No padding phrases.
- Never create subfolders inside a domain folder.
- **Contradictions and staleness.** When a new claim conflicts with or supersedes one in an existing article, never silently overwrite. Insert a `> [!warning] Superseded` callout in the older article, linking the newer article with a `[[wikilink]]`, and keep the original claim beneath it. Time-bound claims carry their source date inline (e.g., "as of 2026-03").

Citations: `[[wikilinks]]` to other vault articles only.

## Log
`wiki/_log.md` is the vault's memory of what was done. Append one entry at the end of every completed `compile`, `audit`, and `refresh-index` run:
```
## [YYYY-MM-DD] <op> | <one-line summary>
- wrote: `slug-a`, `slug-b`
- updated: `slug-c`
- flagged: `slug-c` superseded by `slug-a`
```
- `<op>` is one of `compile`, `audit`, `audit deep`, `refresh-index`, mirroring the slash command names. Omit empty bullets. `flagged:` means a Superseded callout was written, not merely reported.
- Name articles by file stem in backticks, never `[[wikilinks]]`, so the log stays out of Obsidian's graph and is never rewritten by link updates on rename.
- Record file-level actions on `wiki/` only. Never log query content, answers, or any path under `notes/private/`.
- Append only. Never rewrite or delete past entries. If the file is missing, create it with a `# Log` header first. Read the last few entries at the start of `compile` and `audit` to know what happened recently.

## notes/ — Sacred Rules
- Never edit, restructure, or paraphrase notes. Never copy their content into the wiki.
- Notes never trigger wiki generation on their own. Wiki articles are born from `raw/`.
- When a raw source overlaps a note, backlink to the note with a `[[wikilink]]`.
- **`notes/private/`** — completely invisible to `compile` and `audit`. During a query, read only if Jane explicitly references it (e.g., "how does my idea in private/X connect to wiki/Y"). Answers stay in chat — never written to `wiki/` or `output/` unless Jane asks. In scope for `refine` only when Jane names the file explicitly.
- **Exception — `refine`:** editor role only. Fix typos silently. Preserve voice, headers, `==highlights==`, `[[links]]`, analogies. Flag unclear spots with `> [!question]` callouts — never invent. Always show a diff before applying.

## Commands
Step-by-step procedures live in `.claude/commands/`. When Jane asks for one of these operations, even in plain words, run the matching command instead of improvising.

| Command | Does | Writes |
|---|---|---|
| `/compile` | Process `raw/` into `wiki/` | Wiki articles, `_master-index.md`, `_log.md` |
| `/audit [deep]` | Review `wiki/`; `deep` adds content checks (monthly) | `_log.md` entry only |
| `/refresh-index` | Rebuild `_master-index.md` | `_master-index.md`, `_log.md` |
| `/refine <path>` | Voice-preserving editor pass on one `notes/` file | That file |
| `/teach <topic>` | Multi-session tutor grounded in `wiki/` | `output/teach/<topic-slug>/` only |
| `/vault-init [force]` | Re-run the interview that renders this file | `CLAUDE.md` |

Questions about vault content go through the `vault-query` skill: wiki first, then notes, then raw; answer in chat.

## Approval Gates
These hold whether or not a command file is loaded.
- `compile`: present the plan in chat and get explicit approval ("go" / "proceed" / "ok" / "yes") before writing any file. A rejected plan writes nothing, including `_log.md`.
- `audit`: never modifies a wiki article. Fixes are a separate pass with their own plan and approval, and their own `_log.md` entry.
- `refresh-index` and `refine`: show the diff in chat; write only on approval.
- `teach`: invoking it counts as Jane's explicit ask to write in `output/teach/<topic-slug>/`, and nowhere else.
- Plans and reports live in chat, never in files. `_log.md` is the only file-based record of vault operations.

## Hard Don'ts
- Don't edit `notes/` outside of `refine`.
- Don't move or delete files in `raw/`.
- Don't write to `output/` unless Jane explicitly asks.
- Don't invent citations. If no wiki article, `raw/` file, or note backs a claim, say so.
- Don't create subfolders in `wiki/`.
- Don't write to `_log.md` except to append an entry at the end of `compile`, `audit`, `refresh-index`, or an approved audit fix pass.
- Don't rewrite articles in generic LLM voice during compile.

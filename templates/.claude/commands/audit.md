---
description: Read-only review of wiki/ — broken links, dupes, stale index entries, tag/frontmatter conformance. Pass `deep` for contradictions, stale claims, orphans, data gaps. Appends one _log.md entry.
argument-hint: "[deep]"
---

# /audit

Read-only review of `wiki/`. Report findings as a plan. Never auto-fix.

Usage: `/audit` (structural, fast) or `/audit deep` (adds content-level checks, slow).

## Procedure

1. **Read recent history.** If `wiki/_log.md` exists, run `grep "^## \[" wiki/_log.md | tail -5` (or read its tail) so you know when the last audit ran and what the last compiles touched. If it is missing, note that and continue; step 6 creates it. In `deep` mode read the whole log, not just the tail: `wrote:` / `updated:` dates are the recency signal for the stale-claims check.
2. **Walk every file in `wiki/`** (recursively), skipping `_master-index.md` and `_log.md` themselves. Neither is an article: no frontmatter, no inbound links expected.
3. **Structural checks** (always):
   - **Frontmatter conformance** — exactly the fields `Writer`, optional `Link`, `tags`. No others.
   - **Tag conformance** — see `CLAUDE.md` for the active tag policy. Flag violations.
   - **Wikilink validity** — every `[[link]]` resolves to an existing wiki file or note. List `notes/` excluding `notes/private/`; a wiki link pointing into `notes/private/` is itself a finding.
   - **Backlink reciprocity** — articles referenced by others should ideally back-reference where it makes sense. Flag missing reciprocals as suggestions, not errors.
   - **Master index coverage** — every wiki article appears in `_master-index.md`. Every index entry resolves to an existing file.
   - **Stale raw references** — wiki articles citing a raw source no longer in `raw/`.
   - **Duplicate or overlapping articles** — flag potential merges.
   - **Concepts referenced but not defined** — `[[Foo]]` where no `wiki/.../Foo.md` exists.
4. **Deep checks** (only when the argument is `deep`). Read article bodies, not just frontmatter and links:
   - **Contradictions** — two articles asserting incompatible claims about the same thing. Quote both, with file paths.
   - **Stale claims** — a claim superseded by a newer article that lacks the `> [!warning] Superseded` callout required by `CLAUDE.md`. Also list here, marked "undated", time-bound claims with no inline source date (`CLAUDE.md` requires one).
   - **Orphans** — articles with no inbound `[[wikilink]]` from any other article (the index does not count).
   - **Data gaps** — concepts the wiki leans on repeatedly that have no article. Check `raw/` by filename only, never open sources; if a raw file plausibly covers the concept, report it as uncompiled rather than a gap. Suggest what kind of source would fill each true gap.
5. **Present all findings in chat**, grouped by category, with file paths and line numbers. Deep findings go in their own group.
6. **Append one entry to `wiki/_log.md`**: `## [YYYY-MM-DD] audit | <N> findings` or `## [YYYY-MM-DD] audit deep | <N> findings`, where N counts every item listed in step 5, suggestions included. Header line only, no bullets: findings are not file-level actions, and an audit writes no callouts. If the file is missing, create it with a `# Log` header first. This is the only file write an audit pass performs.
7. **Fixes are a separate, gated pass.** If the user asks you to fix specific findings, present a fix plan and wait for approval (same gate as `/compile`). Fixes to superseded claims use the callout rule from `CLAUDE.md`, never a rewrite. After applying approved fixes, append its own entry, `## [YYYY-MM-DD] audit | fixes applied`, with `updated:` / `flagged:` bullets listing only what was actually written. Fixes never create new wiki articles; that is `/compile`'s job from a `raw/` source.

## Hard don'ts

- Never modify any wiki article during the audit pass. Reports only. The `_log.md` append is the only write; approved fixes in step 7 happen after their own approval gate.
- Never run deep checks unless `deep` was passed. They are expensive.
- Never read `notes/private/` (if that folder exists). Never mention it in `_log.md`.
- Never write a report file. Findings live in chat.

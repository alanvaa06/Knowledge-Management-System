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

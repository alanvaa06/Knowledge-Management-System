---
description: Process raw/ into wiki/ with mandatory plan-and-confirm before any write. Flags contradictions with existing articles. Appends one _log.md entry.
---

# /compile

Process new content from `raw/` into structured `wiki/` articles.

## Hard rule: plan-and-confirm gate

You MUST present a plan in chat and receive explicit approval ("go", "proceed", "ok", "yes") before writing any file. Never bypass this gate, even for "obvious" or "small" compiles.

## Procedure

1. **Read recent history.** If `wiki/_log.md` exists, run `grep "^## \[" wiki/_log.md | tail -5` (or read its tail) so you know what the last compiles and audits touched. If it is missing, note that and continue; step 6 creates it.
2. **Survey raw/.** List sources not yet represented in `wiki/`. If nothing is pending, say so and stop: no plan, no approval, no `_log.md` entry. For each pending source, propose:
   - Target wiki path (`wiki/<Domain>/<slug>.md`)
   - Existing wiki articles to update or backlink
   - `notes/` files to cite (read `notes/`, excluding `notes/private/`, to find overlap — never copy notes content into wiki)
   - Any new domain folders required
3. **Check for contradictions.** For every existing article the plan touches, read it and compare its claims against the new source. List each conflict or supersession in the plan as `[[old-article]]: "<old claim>" vs new source: "<new claim>"`. If none, say so. Do not scan articles outside the plan — wiki-wide contradiction detection belongs to `audit deep`.
4. **Present the plan in chat.** Use a compact list. Wait. If asked to change anything, revise and re-present; the gate applies to the revised plan.
5. **On approval:** write only the wiki articles + update `wiki/_master-index.md`. For each contradiction listed in the approved plan (approving the plan confirms them; skip any the user struck during revision), apply the rule from `CLAUDE.md`: insert a `> [!warning] Superseded` callout in the older article linking the newer one, keep the original claim beneath it.
6. **Append one entry to `wiki/_log.md`** in the format defined in `CLAUDE.md`: `## [YYYY-MM-DD] compile | <summary>` plus `wrote:` / `updated:` / `flagged:` bullets (omit empty ones; `flagged:` lists only callouts actually written). If the file is missing, create it with a `# Log` header first. Newest entry last. Never edit earlier entries.
7. **Report in chat** what you wrote, updated, and flagged.

## Hard don'ts

- Never write to `raw/`, `notes/`, or `output/` during a compile.
- Never generate wiki articles from `notes/` alone. The only exception is when the user explicitly invokes a scoped `compile notes/X into wiki/Y` — rare.
- Never write a compile report or plan file. Plans live in chat. The `_log.md` entry is the only file-based record.
- Never silently overwrite an existing claim. Contradictions get the callout, never a rewrite.
- Never proceed without the explicit approval token. A rejected plan writes nothing, including to `_log.md`.
- Never read `notes/private/` during a compile (if that folder exists). Never mention it in `_log.md`.

## Frontmatter convention

Every wiki article: `Writer`, optional `Link`, `tags`. Nothing else. Tags follow the rule in `CLAUDE.md`.

## Voice

Match the voice of existing wiki articles. Dense bullets, tables, `==highlights==`, `[[wikilinks]]`. End every article with `## Key Takeaways` (3–7 bullets). No padding phrases, no generic LLM cadence.

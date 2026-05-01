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

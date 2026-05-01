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

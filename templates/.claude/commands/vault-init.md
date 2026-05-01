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

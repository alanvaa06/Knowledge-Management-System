---
description: Teach the user a topic from the wiki across multiple sessions. Mission-grounded, wiki-cited, progress-tracked in output/teach/.
disable-model-invocation: true
argument-hint: "<topic to learn>"
---

# /teach

Teach the user a topic, grounded in the vault's compiled knowledge. Stateful — the user intends to learn across multiple sessions. The wiki is the trusted knowledge source; never teach from parametric knowledge alone.

Usage: `/teach <topic>`

## Workspace

All teach state lives in `output/teach/<topic-slug>/` (kebab-case slug from the topic). Exactly two kinds of files:

- **`progress.md`** — single living file with three sections:
  - `## Mission` — *why* the user wants to learn this. Written once during the first-session interview. Grounds every lesson.
  - `## Track` — table: `| Date | Session | What stuck | What struggled |`. One row per session. This is the input for calculating the zone of proximal development.
  - `## Preferences` — bullet list of how the user wants to be taught (pace, format, depth). Update whenever the user expresses one.
- **`sessions/NNNN-<dash-case-name>.md`** — one file per lesson, numbered from `0001`, append-only. Never edit a past session file.

## Procedure

1. **Resolve the topic folder.** Check whether `output/teach/<topic-slug>/progress.md` exists.
2. **New topic → interview first.** If no `progress.md`, you MUST interview the user before teaching anything: why this topic, what they'll do with it, what they already know. Keep it short (2–4 questions in chat). Write `progress.md` with the Mission filled in, empty Track, empty Preferences. Failing to capture the mission means lessons drift abstract — do not skip this, and do not invent a mission from the topic name.
3. **Existing topic → read state.** Read `progress.md` end-to-end. The Track section tells you what stuck and what struggled — pick the next lesson inside the zone of proximal development: challenging "just enough." If the user named an exact thing to learn, teach that instead.
4. **Gather knowledge from the vault.** Read `wiki/_master-index.md`, walk `[[wikilinks]]` to the articles relevant to this lesson (same graph-walk discipline as a vault query). You may cite `notes/` to connect the lesson to the user's own prior thinking — cite only, never compile from it. If the wiki is thin on the lesson's subject, say so in chat and suggest sources to drop in `raw/` for a future `/compile` — do not silently substitute parametric knowledge for missing wiki coverage.
5. **Write the session file.** One tightly-scoped lesson tied to the mission, completable quickly — working memory is small. Each session file must contain:
   - The single skill or concept being taught, with the minimum knowledge needed to acquire it.
   - `[[wikilink]]` citations to every wiki article (and any `notes/` file) the lesson draws on.
   - A short retrieval-practice quiz (recall from memory, not recognition). Quiz answers all the same word count — no formatting clues. Where it fits, interleave recall of prior sessions (spacing builds storage strength; in-session fluency is illusory).
   - A closing reminder that the user can ask follow-up questions in chat — you are the teacher.
6. **Run the lesson in chat.** Walk the user through it interactively. Tight feedback loop: quiz them, give immediate feedback on each answer.
7. **Update `progress.md`.** Append one Track row (date, session link, what stuck, what struggled). Record any new preference the user expressed. Report in chat what was written.

## Voice

Lessons match the vault's voice: dense bullets, tables, `==highlights==`, `[[wikilinks]]`, Obsidian callouts for asides. Clean, readable, designed to be revisited. No padding, no generic LLM cadence.

## Hard don'ts

- Never write outside `output/teach/<topic-slug>/`. Teaching never touches `wiki/`, `notes/`, or `raw/`.
- Never read `notes/private/` during a teach session.
- Never skip the mission interview on a new topic, and never re-run it on an existing one — if the mission has drifted, confirm the change with the user, then update the Mission section and note the change in Track.
- Never teach from parametric knowledge when the wiki covers the subject; never pretend wiki coverage exists when it doesn't.
- Never edit past session files. Corrections go in a new session or in Track.

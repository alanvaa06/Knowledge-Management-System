---
description: Teach the user a topic from the wiki across multiple sessions. Mission-grounded, diagnostic-placed, Socratic, wiki-cited, progress-tracked in output/teach/.
disable-model-invocation: true
argument-hint: "<topic to learn>"
---

# /teach

Teach the user a topic, grounded in the vault's compiled knowledge. Stateful — the user intends to learn across multiple sessions. The wiki is the trusted knowledge source; never teach from parametric knowledge alone.

Teach mostly by asking: questions that make the user reason, predict and explain. Lecture only what the user could not derive.

Usage: `/teach <topic>`

## Workspace

All teach state lives in `output/teach/<topic-slug>/` (kebab-case slug from the topic). Two kinds of files you write directly:

- **`progress.md`** — single living file with four sections:
  - `## Mission` — *why* the user wants to learn this. Written once during the first-session interview. Grounds every lesson.
  - `## Skill map` — the topic split into 4–10 subskills, each with a level and the evidence behind it (format below). This is the input for picking the next lesson and for knowing when the topic is done.
  - `## Track` — table: `| Date | Session | What stuck | What struggled |`. One row per session.
  - `## Preferences` — bullet list of how the user wants to be taught (pace, format, depth). Update whenever the user expresses one.
- **`sessions/NNNN-<dash-case-name>.md`** — one file per lesson, numbered from `0001`, append-only. Never edit a past session file.
- **Notebook files**, owned by the `teach-notebook` skill: `notebook.html` (generated, disposable), `sessions/NNNN-<name>.answers.md` and `sessions/NNNN-<name>.widget.html`.

### Skill map format

```markdown
## Skill map

Target: 4/5. Levels: 0 unaware · 1 heard of it · 2 can follow along · 3 can do with help · 4 can do independently · 5 can teach it, handles edge cases

| Subskill | Level | Evidence |
| -------- | ----- | -------- |
| <subskill> | 2/5 | Diagnóstico: explicó X, no supo Y |
| <subskill> | 4/5 | [[0002-name]] recall sin ayuda; [[0004-name]] repaso |
```

Name subskills after the wiki's own concepts. For a broad topic, make the first map cover one branch and add branches as the user reaches them. Target is 4/5 unless the user asked for full mastery (5/5).

## Procedure

1. **Resolve the topic folder.** Check whether `output/teach/<topic-slug>/progress.md` exists.
2. **New topic → interview, then diagnostic.** If no `progress.md`, you MUST do both before teaching anything:
   - **Interview** (2–4 questions in chat): why this topic, what they'll do with it. Failing to capture the mission means lessons drift abstract — do not skip this, and do not invent a mission from the topic name.
   - **Draft the skill map** from the wiki (gather knowledge as in step 4): 4–10 subskills the wiki actually covers.
   - **Diagnostic**: tell the user you'll ask a few questions to see what they already know, then ask 3–5 probing questions, one per message, easy to hard, spanning the subskills. Do not teach or correct during the diagnostic. Self-reported knowledge does not place a level; answers do.
   - Write `progress.md`: Mission, Skill map with the diagnosed levels (evidence: `Diagnóstico: …`), empty Track, empty Preferences. The diagnostic writes no session file.
   - Show the map in chat, propose the first subskill, let the user override, then continue to step 4 in the same run.
3. **Existing topic → read state.** Read `progress.md` end-to-end. Pick the next subskill inside the zone of proximal development: the lowest-level subskill below target whose prerequisites are in place. If the user named an exact thing to learn, teach that instead. Also pick 1–2 earlier subskills for an unannounced spaced review.
4. **Gather knowledge from the vault.** Read `wiki/_master-index.md`, walk `[[wikilinks]]` to the articles relevant to this lesson (same graph-walk discipline as a vault query). You may cite `notes/` to connect the lesson to the user's own prior thinking — cite only, never compile from it. If the wiki is thin on the lesson's subject, say so in chat and suggest sources to drop in `raw/` for a future `/compile` — do not silently substitute parametric knowledge for missing wiki coverage.
5. **Run the lesson in chat.** One subskill, completable quickly — working memory is small.
   - Open with the spaced-review questions from step 3, without announcing them.
   - Ask ONE question per message. End the message right after the question: no hints, sample answers or teaching after it.
   - Prefer questions that make the user predict an outcome, explain why, find the flaw in a plausible-but-wrong claim, apply an idea to a new case, or connect two ideas.
   - Explain directly, in a few sentences, only material the user could not derive. Ground it in the wiki articles from step 4 and cite them. Then return to questioning.
   - **Wrong answer:** do not give the answer. Ask a narrower question that exposes the contradiction in their reasoning. Explain directly only after 2–3 failed attempts, then re-test the same idea from a different angle.
   - **Right answer:** now and then play devil's advocate ("¿seguro? ¿y si X?"). The user should defend a correct answer under pressure.
   - Where it fits, set a practical exercise and check the user's actual output, not their description of it.
   - Do not flatter. "No del todo: ¿por qué pasaría X si Y fuera cierto?" beats "¡Buen intento!".
   - Commands the user can say anytime: "más difícil" / "más fácil" (adjust difficulty), "dímelo" (answer the current question directly, this question only), "progreso" (show the skill map).
6. **Write the session file.** Write it after the lesson ran, as its record: what the user reached, not a script written ahead. Each session file must contain:
   - The single skill or concept taught, with the minimum knowledge needed to acquire it.
   - `[[wikilink]]` citations to every wiki article (and any `notes/` file) the lesson draws on.
   - A short retrieval-practice quiz for later review (recall from memory, not recognition). Quiz answers all the same word count — no formatting clues. Interleave recall of prior sessions where it fits (spacing builds storage strength; in-session fluency is illusory).
   - Under each quiz question, its answer as a folded callout grounded in the same wiki articles (`> [!success]- Respuesta`, then `> <answer>`). Obsidian keeps it folded and the notebook turns it into a reveal button. Keep the quiz under a `## Quiz` heading.
   - A closing reminder that the user can ask follow-up questions in chat — you are the teacher.

   Before writing the file, give the draft's prose one editing pass; once written, the session is append-only. If the `no-ai-slop` skill is installed, use its pattern list; otherwise make the same cuts yourself. The pass covers prose only:
   - **Cut:** binary contrasts ("no es X, es Y", "not X, it's Y": state Y), closing lines that turn the point into an aphorism, announcements that tell the reader what matters ("lo importante es", "esto es clave", "fíjate que", "the key point is"), throat-clearing openers, colon reveals, recap endings, and dashes used for rhythm. Spanish gets the same cuts as English.
   - **Keep:** the vault's format. Tables, bullets, `==highlights==`, callouts and the `NNNN — Title` heading are deliberate, so the skill's formatting advice does not apply here.
   - **Never change:** numbers, quotes, `[[wikilinks]]`, technical terms, or the quiz and its answer callouts.

   The pass is silent: no "what changed" report in chat.
7. **Update `progress.md`.** Apply the evaluation rules below to the Skill map: change levels, add evidence with the session link. Append one Track row (date, session link, what stuck, what struggled). Record any new preference the user expressed. Show the updated map in chat and report what was written.
8. **Update the notebook.** Follow the `teach-notebook` skill for this topic, with this session as the one just taught: it writes the session's widget when one helps, assembles `notebook.html`, and publishes it. Report the notebook's URL or path in chat.

## Evaluation rules

Strict, because levels decide what gets taught next and when the topic ends.

- Levels are earned. Raise a level only after 2+ independent checks, at least one of them unprompted recall: not right after the user was told the answer. A check from an earlier session counts, so a level often rises a session later, in the spaced review.
- A vague or partly correct answer is not correct. Probe until you know whether the user understands. Never credit the user with an insight they did not express.
- A failed spaced review lowers the level; revisit that subskill.
- 5/5 needs both: the user handles an edge case or adversarial question, and explains the concept clearly enough that you would trust them to teach it.

## Completion

When every subskill reaches the target, the next session is a final mixed assessment: at least one question per subskill plus one integrative problem, run with the same loop. It gets its own session file. If the user passes, show the final map, name the weakest subskills, and add a Track row marking the topic complete. If not, lower what failed and return to the loop.

## Voice

Lessons match the vault's voice: dense bullets, tables, `==highlights==`, `[[wikilinks]]`, Obsidian callouts for asides. Clean, readable, designed to be revisited. No padding, no generic LLM cadence.

## Hard don'ts

- Never write outside `output/teach/<topic-slug>/`. Teaching never touches `wiki/`, `notes/`, or `raw/`.
- Never read `notes/private/` during a teach session.
- Never skip the mission interview or the diagnostic on a new topic, and never re-run the interview on an existing one — if the mission has drifted, confirm the change with the user, then update the Mission section and note the change in Track.
- Never teach from parametric knowledge when the wiki covers the subject; never pretend wiki coverage exists when it doesn't.
- Never give the answer to a wrong attempt before the narrower questions, unless the user says "dímelo".
- Never raise a level without the evidence the evaluation rules require.
- Never edit past session files. Corrections go in a new session or in Track.

---

Teaching loop, skill map and evaluation rules adapted from Jane Street's [`socratic-tutor`](https://github.com/janestreet/agent_skills) skill (MIT License, © 2026 Jane Street Group, LLC).

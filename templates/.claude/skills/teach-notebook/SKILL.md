---
name: teach-notebook
description: Use after a /teach session, or when the user asks to build, rebuild, update, or publish the notebook of a teach topic ("notebook de agent-harness", "rebuild the teach notebook", "publica el notebook"). Assembles output/teach/<topic>/notebook.html, one interactive tab per session with quiz answers to reveal and a widget per session, and publishes it as an Artifact when that tool exists.
---

# teach-notebook

One living HTML notebook per `/teach` topic: every session is a tab, the quiz answers can be revealed, and a session can carry one hands-on widget. A script rebuilds the whole page from disk on every run, so `notebook.html` is disposable: delete it and the next run recreates it.

## Inputs

- **Topic:** `output/teach/<topic-slug>/` with a `progress.md` and `sessions/NNNN-<name>.md` files. Anything else (for example instructor scripts in `Sesiones/S01-*.md`) is not a `/teach` topic: say so and stop.
- **Session just taught** (optional): set when `/teach` step 8 calls this skill. Only that session can get a new widget.

## Files you own

Only inside `output/teach/<topic-slug>/`:

| File | Rule |
|---|---|
| `notebook.html` | Written by the assembler. Never edit it by hand, except the `artifact-url` meta after a first publish |
| `sessions/NNNN-<name>.answers.md` | Answers for a session whose file has no answer callouts |
| `sessions/NNNN-<name>.widget.html` | The widget for one session |

Never edit `sessions/NNNN-<name>.md` or `progress.md`: session files are append-only and `progress.md` belongs to `/teach`.

## Procedure

1. **Check the topic.** Confirm `progress.md` and at least one `sessions/NNNN-*.md` exist. If not, stop with: "`<folder>` is not a `/teach` topic".

2. **Backfill answers.** A session already has answers when its quiz carries a `> [!success]- Respuesta` callout under each question, or one `> [!success]- Respuestas` block with a numbered list (the notebook splits it per question), or an `.answers.md` beside it. For each session with none of these, write `sessions/NNNN-<name>.answers.md`:

   ```markdown
   ---
   session: NNNN
   generated: YYYY-MM-DD
   ---

   # Respuestas — NNNN

   1. <answer to question 1> ([[Wiki Article]])
   2. <answer to question 2> ([[Wiki Article]])
   ```

   Answer every quiz question, numbered like the quiz. Ground each answer in the wiki articles the session cites: read them, cite them with `[[wikilinks]]`. When the wiki does not cover a question, write `Sin cobertura en el wiki: <what is missing>` instead of answering from memory. Before saving, give the answers the same prose pass as `/teach` step 5: cut contrasts, aphorism endings and reader-directing announcements; keep numbers, wikilinks and `==highlights==`.

3. **Widget (session just taught only).** If that session has no `.widget.html`, decide whether an interactive piece makes its core idea tangible: a simulator, a slider over a parameter, a diagram to explore, a sorting exercise. If nothing in the lesson gains from interaction, write no widget and say so in chat. Otherwise write `sessions/NNNN-<name>.widget.html` following the widget contract below. Never write widgets for older sessions unless the user asks for one by number.

4. **Assemble.** From the vault root:

   ```bash
   bash .claude/skills/teach-notebook/assemble-notebook.sh output/teach/<topic-slug>
   ```

   Where bash is unavailable:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/teach-notebook/assemble-notebook.ps1 output/teach/<topic-slug>
   ```

   Success prints `[ok] notebook.html: N session(s) -> <path>`. On a non-zero exit, report the message and stop.

5. **Publish.** Read the `artifact-url` meta in `notebook.html`.

   | Situation | Action |
   |---|---|
   | No `Artifact` tool in this session | Skip publishing |
   | Meta empty | Publish `notebook.html` with the Artifact tool (`icon: "book"`, one-sentence `description` naming the topic). Then edit the returned URL into `<meta name="artifact-url" content="...">`; the assembler keeps it on every later run |
   | Meta set, not yet read or published in this conversation | `action: "read"` on that URL first, then publish `notebook.html` with that `url` |
   | Meta set, already published in this conversation | Publish `notebook.html` with that `url` |
   | Publish refused or in conflict | Keep the local file, report its path, do not retry and never pass `force` |

6. **Report** in chat: the notebook URL (or the local path to open in a browser), the session count, and every `.answers.md` or `.widget.html` you wrote.

## Widget contract

A widget is one self-contained HTML fragment that the page mounts in a shadow root inside an "Explora" card, above the quiz.

- Markup, an optional `<style>`, and `<script>` blocks. No `<html>`, `<head>` or `<body>`.
- Scripts get a `root` variable (the shadow root). Query with `root.querySelector(...)`, never `document`. Styles in the fragment apply only inside the widget.
- Colors and fonts come from the page's CSS variables, which reach into the shadow root and switch with dark mode: `--paper`, `--paper-2`, `--rule`, `--ink`, `--ink-2`, `--muted`, `--accent`, `--accent-soft`, `--mark`, `--ok`, `--danger`, `--sans`, `--serif`, `--mono`. No hard-coded colors.
- Libraries only through `<script src>` from cdnjs.cloudflare.com, cdn.jsdelivr.net/npm or unpkg.com, with an exact version (`chart.js@4.4.1`, never `chart.js`). They load in order before the inline scripts run.
- Fit a 760px-wide column and still work at 360px. Labels in the session's language. Round every displayed number.
- Teach, don't decorate: the widget makes the lesson's one idea manipulable, with its controls named after the lesson's concepts.

Skeleton:

```html
<style>
  .row { display: flex; gap: 12px; align-items: center; font-family: var(--sans); }
  output { color: var(--accent); font-family: var(--mono); }
</style>
<div class="row">
  <label for="x">Parámetro</label>
  <input id="x" type="range" min="0" max="100" value="50">
  <output>50</output>
</div>
<script>
var input = root.querySelector('#x');
var out = root.querySelector('output');
input.addEventListener('input', function () { out.textContent = input.value; });
</script>
```

## Hard don'ts

- Never write outside `output/teach/<topic-slug>/`.
- Never hand-edit `notebook.html` beyond the `artifact-url` meta; change the template in the skill folder instead.
- Never edit session files or `progress.md`.
- Never answer quiz questions from memory when the wiki covers them, and never pretend the wiki covers what it doesn't.
- Never read `notes/private/`.

---
description: Voice-preserving editor pass on a single notes/ file. Diff-first, never invents content.
---

# /refine

Editor pass over a single file in `notes/`. Voice-preserving. Never generative.

Usage: `/refine <path-to-notes-file>`

## Procedure

1. **Read the target file.** Verify it lives under `notes/`. Refuse to refine anything outside `notes/`.
2. **Identify changes.** Allowed edits:
   - Fix obvious typos (e.g., "explotation" → "exploitation", "optiomal" → "optimal", "throught" → "thought").
   - Preserve voice, headers, `==highlights==`, `[[links]]`, analogies, bullet structure.
3. **Flag — never resolve — ambiguity.** For unclear or incomplete passages, insert an Obsidian callout:
   ```
   > [!question]
   > <one-sentence question about the unclear passage>
   ```
   Never rewrite the passage to resolve the ambiguity. Never invent content.
4. **Show the diff in chat.** Use a unified diff or before/after blocks. Wait for explicit approval.
5. **On approval:** write the changes to the file. Report what was applied.

## Hard don'ts

- Never restructure, re-order, or paraphrase content.
- Never pull notes content into `wiki/` as a side effect of a refine pass.
- Never refine `notes/private/` (if that folder exists) unless the user explicitly names the file in the path argument.
- Never proceed without the diff approval.

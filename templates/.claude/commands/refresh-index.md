---
description: Rebuild wiki/_master-index.md from current wiki/ contents. Flat grouped list.
---

# /refresh-index

Rebuild `wiki/_master-index.md` from scratch based on what is currently in `wiki/`.

## Procedure

1. List every `.md` file in `wiki/` recursively, excluding `_master-index.md` itself.
2. Group by top-level subfolder (which corresponds to the domain).
3. For each article, extract the first H1 (`# Title`) as the display name and the first non-empty paragraph (or the line tagged "Description:") as a one-line summary. If neither is present, use the filename and "(no description)".
4. Render the index as:
   ```
   # Master Index

   ## <Domain>
   - [[<file-stem>]] — <one-line summary>
   - [[<file-stem>]] — <one-line summary>

   ## <Other Domain>
   - [[<file-stem>]] — <one-line summary>
   ```
5. **Present the rebuilt index in chat.** Show a diff against the existing file.
6. **On approval:** write to `wiki/_master-index.md`. Report.

## Hard don'ts

- Never create per-folder indexes. The master index is the only index.
- Never modify any wiki article during a refresh.
- Never read `notes/` or `raw/` during a refresh.

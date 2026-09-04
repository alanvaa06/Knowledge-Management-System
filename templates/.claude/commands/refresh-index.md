---
description: Rebuild wiki/_master-index.md from current wiki/ contents. Flat grouped list. Appends one _log.md entry.
---

# /refresh-index

Rebuild `wiki/_master-index.md` from scratch based on what is currently in `wiki/`.

## Procedure

1. List every `.md` file in `wiki/` recursively, excluding `_master-index.md` and `_log.md` themselves.
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
6. **On approval:** write to `wiki/_master-index.md`. Append one entry to `wiki/_log.md`: `## [YYYY-MM-DD] refresh-index | <N> articles indexed`, header line only, where N is the number of files listed in step 1. If the file is missing, create it with a `# Log` header first. Report.

## Hard don'ts

- Never create per-folder indexes. The master index is the only index.
- Never list `_log.md` or `_master-index.md` as articles.
- Never modify any wiki article during a refresh. The `_log.md` append is the only other write.
- Never write on a rejected plan. If the diff is not approved, nothing is written, including to `_log.md`.
- Never read `notes/` or `raw/` during a refresh.

---
name: sync-source-doc
description: >-
  Re-read the Ringbots design document and the shared Drive folder, then
  update the local docs that reference them, including the unresolved list.
  Use when the user says to update the repo, check the source doc, sync the
  design doc, check the spreadsheet, or refresh the Google Drive notes.
  Also use on its own when they ask to check the source without publishing.
---

# Sync the source doc

The gameplay sources are the design document and the shared Drive folder he updates alongside it. Read both. Do not edit either.

- [Our Thoughts on Ringbots](https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/edit)
- [Ringbots Drive folder](https://drive.google.com/drive/folders/1UIDdYlvKWp7DTWIwFE0Uh_kvxlYP7SGA)

Do this when the user asks on its own, and as the first docs step of a repo update. On its own, leave the changes uncommitted. A repo update publishes them through [session-wrap-up](../session-wrap-up/SKILL.md).

## Read

The doc is link-accessible. Download both:

- `https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/export?format=txt`
- `https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/export?format=zip`

Use the text for rules. Use the zip's `images/` for figures. Match each image to the caption nearest it in the HTML. Do not open the doc in a browser to edit it.

List the Drive folder before downloading. He adds and replaces files. The embedded listing is `https://drive.google.com/embeddedfolderview?id=1UIDdYlvKWp7DTWIwFE0Uh_kvxlYP7SGA`. Download a file with `https://drive.google.com/uc?export=download&id=FILE_ID`.

The folder currently holds the design document plus two spreadsheets:

| File | Id |
| --- | --- |
| Ringbots Parts Spreadsheet - Parts.csv | `1foiqPbIhLgip7P72vvxg6y6KqvMv1D_5` |
| Ringbots Parts Spreadsheet - Rings.csv | `1ojFrgNfZWqkPum4b4z8G7SZE7IwlG01v` |

Those ids are a convenience. If the listing disagrees, trust the listing. Parts.csv is one row per part (name, type, attribute, technique, and stat columns). Rings.csv is one row per ring (name and a number for each action category).

Replace the local copies on every sync. Download Parts.csv over `docs/catalog/parts.csv` and Rings.csv over `docs/catalog/rings.csv`. Keep the downloaded bytes. Do not rewrite a sheet into the markdown, and do not drop a catalog file because its rules are still unsettled. Read the local copies after that. The Drive folder stays the source; the catalog folder is so the notes can be read offline.

If the sheet and the document disagree, write both and note the conflict. Do not decide that the sheet wins, or that the document wins. A column the document never defines does not close a gap and does not create a new rule.

## What to update

`docs/` is the transcription. Scope stays combat (source section 4) plus the component, team, deployment, and Setting 1 match rules combat depends on. Leave purpose, mission, setting prose, and the worldbuilding parking lot in the source unless the user widens that scope.

Update only the local file that owns the changed rule. Keep the split in [docs/README.md](../../../docs/README.md), including the catalog rows. If the source adds a figure, replace the file in `docs/images/` and the link that points at it. If a figure is unchanged, leave the file. If he adds another spreadsheet, save it in `docs/catalog/` and add a row for it.

## Stay true to the source

Write the rule he wrote, including where it is incomplete or conflicts with another rule. Note that issue in **Unresolved in the source**. Do not pick an interpretation and record it as the design.

Do not merge two definitions he kept separate. Do not correct a printed input into the word you think he meant. Do not add a formula, constant, or stat the source does not give. A cleaner local sentence is only allowed when it still says the same thing.

## Unresolved list

`docs/README.md` has **Unresolved in the source**. The design author uses that list. Keep it honest.

- Remove an item when the source now states the rule. Put that rule in the file that owns it.
- Rewrite an item when the source changed the gap but did not close it.
- Add an item when a new rule names an input, factor, or diagram with no number or formula.
- Leave an item when the source still does not answer it.

Say what changed in the list, including when nothing did.

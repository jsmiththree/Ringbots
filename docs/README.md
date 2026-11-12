# Ringbots design context

Local working notes split out of the design document [Our Thoughts on Ringbots](https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/edit) and the [shared Drive folder](https://drive.google.com/drive/folders/1UIDdYlvKWp7DTWIwFE0Uh_kvxlYP7SGA) updated alongside it. That folder holds the document plus the parts and rings spreadsheets. The document stays the source of the gameplay rules. Local copies of both spreadsheets are in [catalog/](catalog/). A sync replaces those files from Drive. These markdown files are a read-only transcription, grouped so each system can be opened on its own. How the prototype is built is a separate note in [engineering/README.md](../engineering/README.md). Figures from the source are saved in [images/](images/) and linked from the file that uses them.

## Scope

Included:

- Combat, source section 4.
- The component, team, deployment, and organized-play rules combat depends on, from the Ringbot overview and the Setting 1 match rules.

Left in the source document:

- Purpose and mission.
- Setting prose.
- The worldbuilding ideas parking lot (transhumanism, time travel).
- The combat ideas parking lot, which is still empty in the source.
- User interface. Section 5 names a Main Menu and leaves the next item blank.

Setting 2 combat (protect the Ringfighter, third-party interruptions) is recorded only as deferred. The source marks that win condition as later work.

## Files

| File | What it holds |
| --- | --- |
| [components.md](components.md) | The six parts, armour model, teams, deployment, match and forfeit rules |
| [stats.md](stats.md) | Base stats and which part contributes which stats |
| [actions.md](actions.md) | The eight action categories, their scopes, and quirks |
| [techniques.md](techniques.md) | Technique effects on Head and Arm actions |
| [status-conditions.md](status-conditions.md) | Status conditions and how reapplication works |
| [resolution.md](resolution.md) | Derived combat values, space, terrain, and mechanical terms |
| [combat-flow.md](combat-flow.md) | Real-time command loop, win conditions, and CPU |
| [catalog/parts.csv](catalog/parts.csv) | Named Head, Arm, and Leg parts and their sheet stats |
| [catalog/rings.csv](catalog/rings.csv) | Ring names and a number for each action category |

## Names used twice

The source uses a few words for two different things. These files keep both meanings and name which one is in play.

- **Attribute** is a part stat (`ATT`, pair-ring compatibility) and also the name of an action category (Strike, Berserk, Shoot, and the rest).
- **Scope** is the action-category width (Standard, Wide, Narrow, Unrestricted) and also a derived value (`SCP`) for how forgiving target selection is.

## Unresolved in the source

These are transcribed as written. No formulas or missing stats were filled in.

- Derived values list their inputs. They are not equations.
- Parts each contribute stats, and resolution reads user-level stats such as Power and Rate of Success. How a bot combines the same stat from several parts is not defined.
- **Defence** is an input to Damage, the Aim Shot quirk, and the Enfeebled status. It is not one of the base stats.
- Action scopes have no angles or distances. "Specified factor" on techniques and on Clash has no number.
- Parry is defined as a term and referenced by Defend and Bind. It has no full timing or input spec.
- The deployment distance still has no number. The starting layout is the figure in [components.md](components.md).
- CPU behavior is a weighted decision tree and is planned last. No tree is written.

# Ringbots design context

Local working notes split out of the design document [Our Thoughts on Ringbots](https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/edit). That document stays the source of the gameplay rules. These files are a read-only transcription, grouped so each system can be opened on its own. How the prototype is built is a separate note in [engineering/README.md](../engineering/README.md). Figures from the source are saved in [images/](images/) and linked from the file that uses them.

## Scope

Included:

- Combat, source section 4.
- The component, team, deployment, and organized-play rules combat depends on, from the Ringbot overview and the Setting 1 match rules.

Left in the source document:

- Purpose and mission.
- Setting prose.
- The worldbuilding ideas parking lot (transhumanism, time travel).
- The combat ideas parking lot, which is still empty in the source.

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

## Names used twice

The source uses a few words for two different things. These files keep both meanings and name which one is in play.

- **Attribute** is a part stat (`ATT`, pair-ring compatibility) and also the name of an action category (Strike, Berserk, Shoot, and the rest).
- **Scope** is the action-category width (Standard, Wide, Narrow, Unlimited) and also a derived value (`SCP`) for how forgiving target selection is.
- **Radiation** (`RAD`) is a part stat for the wait after an action. A Ringbot "in its RAD state" is in that recovery wait. Counterattack checks for it.

## Unresolved in the source

These are transcribed as written. No formulas or missing stats were filled in.

- Derived values list their inputs. They are not equations.
- Parts each contribute stats, and resolution reads user-level stats such as Power and Rate of Success. How a bot combines the same stat from several parts is not defined.
- **Defense** is an input to Damage, the Aim Shot quirk, and the Enfeebled status. It is not one of the base stats.
- Action scopes have no angles or distances. "Specified factor" on techniques and on Clash has no number.
- Critical Hit overflow ("chain reactions" into other parts) is named, not specified.
- Parry is defined as a term and referenced by Defend and Bind. It has no full timing or input spec.
- Knockback and Pushback are both defined, with different inputs. They are not merged.
- Boot Time's inputs are printed as the user's RAM and "Use's PRP".
- The deployment distance still has no number. The starting layout is the figure in [components.md](components.md).
- CPU behavior is a weighted decision tree and is planned last. No tree is written.

# Stats

Source: combat stat list, and the part-to-stat mapping. Abbreviations are the ones used by techniques and by the derived values in [resolution.md](resolution.md).

## Base stats

| Stat | Abbr. | Type | Meaning |
| --- | --- | --- | --- |
| Attribute | ATT | Categorical | Which category the part belongs to. Used for Pair-ring compatibility. This is not the action category, which is also called Attribute in the source. |
| Armour | AMR | Discrete | Durability. The part is destroyed at 0. Damage to a part already at 0 does nothing, except when the part is the Head. |
| Power | PWR | Continuous | Attack power, or how strong the part's effect is. |
| Rate of Success | ROS | Continuous | Drives Intent, and the chance of a Critical Hit. |
| Charge | CRG | Continuous | Wait from selecting an action until it is performed. |
| Active | ATV | Continuous | How long the action's active effects last. |
| Radiation | RAD | Continuous | Wait after the action is performed before the next action can be selected. |
| Range | RNG | Continuous | Combat range for Ranged attacks. |
| Reach | RCH | Continuous | Combat range for Grapple attacks. |
| Uses | USE | Discrete | How many times a Head part can be used per battle. |
| Type | TYP | Categorical | Which terrains the leg set performs best on. Values are in [resolution.md](resolution.md). |
| Propulsion | PRP | Continuous | Movement speed. |
| Evasion | EVA | Continuous | Ability to dodge. |
| Proximity | PRX | Continuous | Influences Grapple attacks. |
| Remoteness | REM | Continuous | Influences Ranged attacks. |
| Affinity | AFF | Continuous | Bonus from the part's Attribute. |
| RAM Slots | RAM | Discrete | How many Pair-rings are allocated to the Frame. Affects the Ringbot's size. |

## What each part contributes

Left and right arms are separate parts. Each one contributes the arm stat set. Legs, the Pair-ring, and the Frame do not carry a Technique.

| Part | Stats |
| --- | --- |
| Head | Attribute, Armour, Power, Rate of Success, Charge, Active, Radiation, Range, Reach, Uses |
| Arm (left and right, each) | Attribute, Armour, Power, Rate of Success, Charge, Active, Radiation, Range, Reach |
| Leg set | Attribute, Type, Armour, Propulsion, Evasion, Proximity, Remoteness |
| Pair-ring | Affinity |
| Frame | RAM Slots |

Resolution talks about the user's Power, Rate of Success, and similar as single values, and about Total Armour. The source does not say whether those are summed, taken from the part that is acting, or combined some other way.

Defence is referenced by Damage, by the Aim Shot quirk, and by Enfeebled. It is not in this stat list.

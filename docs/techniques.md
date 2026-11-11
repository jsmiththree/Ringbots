# Techniques

Source: the Head and Arm technique list. Each Head part and each Arm part has a Technique. The Technique adds an effect on top of the action category in [actions.md](actions.md).

Durations, factors, and potencies are described relative to a stat. The source does not give the curves or the constants. "Specified factor" means a per-technique constant that is not written down yet.

"User" is the Ringbot using the part. Where the source says "its Power" (Attract), that wording is kept.

| Technique | Effect |
| --- | --- |
| Accelerate | Lowers Charge and Radiation of all other equipped parts. The factor follows the user's Rate of Success. The duration follows the user's Power. |
| Anti-Air | This action deals more damage to Air Ringbots, by a specified factor. |
| Anti-Sea | This action deals more damage to Sea Ringbots, by a specified factor. |
| Attract | Pulls the nearest allied Ringbot for a duration relative to its Power. Potency follows the Size of the Ringbots involved. |
| Beam | This action deals more damage to Ringbots, by a specified factor. |
| Bind | The target cannot Parry. Duration follows the user's Rate of Success. |
| Break | Raises this action's Rate of Success by a specified factor. |
| Bug | Applies Mask. Duration follows the user's Rate of Success. |
| Burn | Applies Flow. Duration follows the user's Rate of Success. |
| Cancel Bomb | Passive. Incoming damage from Missile or Napalm sources becomes 0. |
| Cancel Gravity | Passive. Incoming damage from Break or Press sources becomes 0. |
| Cancel Optics | Passive. Incoming damage from Laser or Beam sources becomes 0. |
| Chain Gun | No additional effect. |
| Conceal | Raises another Ringbot's Evasion. The factor follows the user's Rate of Success. The duration follows the user's Power. |
| Confusion | Applies Chaos. Duration follows the user's Rate of Success. |
| Counterattack | If the target is in its Radiation state, the targeted part's Armour becomes 0. Otherwise this action's damage is reduced by a specified factor. |
| Defense Change | Transforms this part into a random defensive part, other than itself. |
| Disappear | Raises the user's Evasion. The factor follows the user's Rate of Success. The duration follows the user's Power. |
| Drone | This action's Intent becomes 200%. The projectile ignores allies along its trajectory. |
| Emboss | Grants Chrome to the user. Duration follows the user's Rate of Success. |
| Eradicate | This part's Armour becomes 0. Damage dealt by this action increases relative to the user's Power. |
| Forcedrain | Lowers the target's Intent by a factor of the user's Power, and raises the user's Intent by that same amount. Duration follows the user's Power. |
| Freeze | Applies Stop. Duration follows the user's Rate of Success. |
| Grapple Trap | Applies a conditional Impair that triggers when the target uses a Grapple action. The trap and the Impair together last for a duration relative to the user's Power. |
| Hammer | No additional effect. |
| Hardness | Applies Feedback to the user. Duration follows the user's Rate of Success. |
| Heal Change | Transforms this part into a random recovery part, other than itself. |
| Hold | Raises the target Ringbot's Charge and Radiation. The factor follows the user's Rate of Success. The duration follows the user's Power. |
| Intercept | Deletes the next Ranged projectile that enters the user's Reach. Lasts until it triggers. |
| Interrupt Change | Transforms this part into a random Interrupt part, other than itself. |
| Laser | This action deals more damage to Ringbots, by a specified factor. |
| Melt | Applies Flow. Duration follows the user's Power. |
| Mirror | Copies the targeted part and gains its actions and abilities. Duration follows the original source's Power. |
| Missile | This action's Intent becomes 100%. The projectile ignores allies along its trajectory. |
| No Defense | Applies Enfeebled. Duration follows the user's Rate of Success. |
| No Escape | Applies Ensnared. Duration follows the user's Rate of Success. |
| Offensive Change | Transforms this part into a random Strike, Berserk, Shoot, or Aim Shot part, other than itself. |
| Overclock | Passive. Lowers Charge and Radiation of the other equipped parts by a factor of the user's Power. |
| Polish | Grants Chrome to a target. Duration follows the user's Power. |
| Prepare | The target is Braced. Duration follows the user's Power. |
| Press | Raises this action's Rate of Success by a specified factor. |
| Pushover | The target's Poise becomes 0. Duration follows the user's Power. |
| Ranged Trap | Applies a conditional Impair that triggers when the target uses a Ranged action. The trap and the Impair together last for a duration relative to the user's Power. |
| Rapid | Sharply lowers the target's Charge and Radiation. The factor follows the user's Rate of Success. The duration follows the user's Rate of Success. |
| Reboot | Revives a deactivated target Ringbot. |
| Repair | Restores Armour to the target part, relative to the user's Power. |
| Restore | Reactivates a deactivated target part and restores Armour relative to the user's Power. |
| Reversal | The next damaging Grapple against the user deals 0 damage, and the Grapple's source takes the damage that was prevented. Duration follows the user's Power. |
| Rifle | No additional effect. |
| Scout | Raises another Ringbot's Rate of Success. The factor follows the user's Rate of Success. The duration follows the user's Power. |
| Slipstream | Lowers the target's Propulsion by a factor of the user's Power, and raises the user's Propulsion by that same amount. Duration follows the user's Rate of Success. |
| Soothe | Restores Armour on every remaining part of another Ringbot. Duration follows the user's Radiation. Potency follows the user's Power. |
| Stability | Applies Nullify to the user. Duration follows the user's Rate of Success. |
| Suppressed | The target can only use movement actions. Duration follows the user's Rate of Success. |
| Sword | No additional effect. |
| Temper | Raises the user's Power and Rate of Success by a factor of the user's Rate of Success. Duration follows the user's Power. |
| Thunder | Applies Stop. Duration follows the user's Power. |
| True Change | Transforms this part into any random part, other than itself. |
| Unite | Damage scales with how many allies are inside the user's Reach. Each of those allies rotates toward the action's target at a rate relative to their Torque. |
| Virus | Applies Mask. Duration follows the user's Power. |
| Wave | Raises the target Ringbot's Charge and Radiation. The factor follows the user's Power. The duration follows the user's Rate of Success. |

Status names (Mask, Flow, Chaos, and the rest) are defined in [status-conditions.md](status-conditions.md). Intent, Poise, Torque, and Size are derived values in [resolution.md](resolution.md).

Napalm is named by Cancel Bomb and is not otherwise defined. Air and Sea in Anti-Air and Anti-Sea match the leg types of those names.

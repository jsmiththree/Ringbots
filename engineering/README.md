# Prototype engineering

Build notes for this repo. The gameplay rules live in [docs/](../docs/README.md), transcribed from the design document, and in that document itself. This file is how the prototype gets built. It does not add rules, stats, or content.

The Godot 4.8 project is `godot/`. It has no gameplay scenes yet.

The playable prototype is GDScript, including `CombatClock`. The group needs a browser build, and Godot 4 cannot export C# to the web. Community C# web builds need a custom engine and are not a path for this project. See [hosting.md](hosting.md) for the public URL.

## What the first build is for

Prove `CombatClock`. No menu, room, or Ringbot yet. A test calls the class directly: add a participant, submit an order, tick.

## CombatClock

The class is `CombatClock`. The file is `combat_clock.gd`.

`CombatClock` is the only object that advances combat time. Views, menus, and policies do not. "Authority" is that job, not a second class name.

Each participant is either waiting or committed.

- Waiting means it needs an order. Time does not advance while any blocking participant is still waiting.
- Committed means an order has been accepted. The participant then spends start-up, an active window, and wind-down. Those are the source's `STU`, `ATV`, and `WND`. Wind-down returns it to waiting.

Anyone already committed keeps the time they had left. A pause stops the whole fight, and the resume continues from that point. `CombatClock` is also the only thing that resolves hits, interrupts, and the return to waiting. Those are simulation results, not orders.

`CombatClock` has no camera, no sprite, and no notion of which person is sitting at the machine.

## Orders

Outsiders change the fight by submitting an order: which participant, and which action. The action carries its three durations and the work to do when the active window opens and closes.

The first order source is a local menu. While time is frozen it selects a part, then an action, matching the flow figure in [combat-flow.md](../docs/combat-flow.md):

- Head: Attack.
- Left arm: Attack, Brace, or Parry.
- Right arm: Attack, Brace, or Parry.
- Legs: Move.

A CPU policy is a second order source that submits on its own. A later human is a third. All three produce the same kind of order. The part menu is one provider of orders, not part of `CombatClock`.

## Who blocks time

Blocking is a property of the participant, set by whoever owns it.

- A participant owned by a human blocks. Time stays paused until an order arrives for every blocking participant.
- A participant owned by the CPU does not block. Its policy submits an order immediately, so the fight does not wait on a menu.

When two of yours are waiting, you choose which to order first. Both orders are collected before time runs. A second human works the same way during that same pause, and can order only the participants they own.

There is no special "the player" inside `CombatClock`. Adding someone is registering their participants and pointing an order source at them.

## What stays outside CombatClock

| Hook | First stand-in | Can change later without touching phases |
| --- | --- | --- |
| Who is fighting | One test participant, then a second | Ringbots, and anything else that can wait and commit |
| Who may freeze time | Human-owned participants block | A different mode can change the flag |
| How an order is chosen | Local part menu, then an instant CPU policy | Another local controller, a decision tree, a remote source |
| What an action does | Attack, Brace, Parry, Move with fixed durations | The eight action categories, techniques, real formulas |
| How the fight is drawn | Disposable top-down markers and a phase readout | Another camera or body |

Build this split while there is still one participant. The menu and the marker can be thrown away. The pause rule and the phase timing in `CombatClock` stay.

## Build order

1. `CombatClock` in `combat_clock.gd`, one participant, and a test that submits an order. No scene.
2. A readout that shows waiting versus start-up, active, and wind-down, so the pause is obvious.
3. A second participant on the same `CombatClock`. One reaches waiting while the other is mid-phase. Both of yours waiting means choosing which order to give first.
4. An instant policy on the participant you do not control, so its waiting never opens a menu.

Stop there until the pause and the resume are obvious. Then replace stub actions. Do not start with stats, techniques, armour, line of sight, win conditions, or a controller map.

## Multiplayer, later

No sockets, latency, or replication in this build. The seam is already the order source.

The way to try a second person before any network code is another local source, even a second controller on the same machine, owning the other side. If that source can submit orders without changes to `CombatClock`, a remote source can send those same orders later. The transport stays outside `CombatClock`.

## Stand-ins

Durations on Attack, Brace, Parry, and Move are fixed numbers chosen for the prototype. The design document lists inputs for these times and does not yet give formulas. Those numbers live with the stub actions, not in the transcribed rules.

The eight action categories, techniques, status conditions, and derived combat values stay in `docs/` until `CombatClock` is worth extending.

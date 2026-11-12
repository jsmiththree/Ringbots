# Prototype engineering

Build notes for this repo. The gameplay rules live in [docs/](../docs/README.md), transcribed from the design document, and in that document itself. This file is how the prototype gets built. It does not add rules, stats, or content.

The Godot 4.8 project is `godot/`. The clock and its test live in `godot/combat/`. `scenes/fight.tscn` is two cubes on the debug grid, so the pause can be watched. The title scene remains at `scenes/main_menu.tscn`.

The playable prototype is GDScript, including `CombatClock`. The group needs a browser build, and Godot 4 cannot export C# to the web. Community C# web builds need a custom engine and are not a path for this project. See [hosting.md](hosting.md) for the public URL.

## What the first build is for

Prove `CombatClock`, then play a fight between two people. CPU logic and story wait until that fight is worth keeping. The clock itself is still proven by a test that calls the class directly: add a participant, submit an order, tick. No menu, room, or Ringbot in that test.

## CombatClock

The class is `CombatClock`. The file is `combat_clock.gd`.

`CombatClock` is the only object that advances combat time. Views, menus, and policies do not. "Authority" is that job, not a second class name.

Each participant is either waiting or committed.

- Waiting means it needs an order. Time does not advance while any blocking participant is still waiting.
- Committed means an order has been accepted. The participant then spends start-up, an active window, and wind-down. Those are the source's `STU`, `ADR`, and `WND`. Wind-down returns it to waiting.

Anyone already committed keeps the time they had left. A pause stops the whole fight, and the resume continues from that point. `CombatClock` is also the only thing that resolves hits, interrupts, and the return to waiting. Those are simulation results, not orders.

`CombatClock` has no camera, no sprite, and no notion of which person is sitting at the machine.

## Schedule

`CombatClock` keeps one timeline. A participant is waiting, or committed to one action. Actions are not queued. Two commitments share the same frames, and a pause leaves every commitment at the time it had left.

An order names a participant and carries the three lengths: start-up, active, and wind-down. It also carries a payload the clock does not read. The clock runs the order's work when the active window opens, and again if that same commitment finishes its active length. Each call receives the clock and the participant id. It may return nothing, one `CombatResult`, or an array of them.

A result cancels a participant back to waiting, or replaces the time left before waiting. A replacement is wind-down for the given number of frames. The clock writes the change, then tells listeners. The signals are `paused`, `order_accepted`, `phase_changed`, `result_applied`, and `returned_to_waiting`. `waiting_ids` lists the blocking participants that still need an order.

`CombatOrder` and `CombatResult` sit beside `combat_clock.gd`. The test adds a participant, submits an order, and ticks. It also uses a second blocking participant, because that is what holds the pause.

## Orders

Outsiders change the fight by submitting an order: which participant, and which action. The action carries its three durations and the work to do when the active window opens and closes.

The first order source is a local menu. While time is frozen it selects a part, then an action, and the prompt shows only that step. The same four keys do both. P1 uses Q, W, E, and R. P2 uses U, I, O, and P. The fourth key returns to the part step. The choices match the flow figure in [combat-flow.md](../docs/combat-flow.md):

- Head: Attack.
- Left arm: Attack, Brace, or Parry.
- Right arm: Attack, Brace, or Parry.
- Legs: Move.

The first two order sources are humans. Each one orders only the participants they own. A CPU policy is a later source that submits on its own. All of them produce the same kind of order. The part menu is one provider of orders, not part of `CombatClock`.

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
| How an order is chosen | Four keys per human. Part, then that part's action | A CPU policy, then a remote source |
| What an action does | Attack, Brace, Parry, Move with fixed durations | The eight action categories, techniques, real formulas |
| How the fight is drawn | Two colored cubes on the debug grid. The phase line sits on the cube. The current step sits at the bottom of the screen | The joint tree in Ringbot body |

Build this split while there is still one participant. The menu and the marker can be thrown away. The pause rule and the phase timing in `CombatClock` stay.

## Ringbot body

The body is a tree of `Node3D` joints. An `AnimationPlayer` keys a joint's rotation, and every child of that joint moves with it. Part meshes are those children. The clip does not key the mesh.

Every joint stays in the tree. A clip only keys the joints for the parts that are slotted. A joint with no mesh is not drawn, and it stays at its scene rotation unless a clip writes it.

The first body is one base set: body, head, both arms, and one leg set, built from untextured stretched cubes. Each mesh shares the rest orientation of its joint, so a swap is parenting a different child there. More parts come later, as movement options or as features on the same joints. An arm cannon or an arm sword is another mesh on the arm. Wheels, treads, and a multi-leg set are their own joints and their own clips. The body, head, and arms stay on the shared joints.

This stays outside `CombatClock`. The two cubes stand in until the pause and the resume are obvious. The debug grid is tiled on the floor and walls. On a cube it is drawn once per face, and each surface gets its own albedo color.

## Build order

1. `CombatClock` in `combat_clock.gd`, one participant, and a test that submits an order. No scene.
2. A readout that shows waiting versus start-up, active, and wind-down, so the pause is obvious.
3. A second participant on the same `CombatClock`. One reaches waiting while the other is mid-phase.
4. A second human owning that other participant, with their own order source. Both sides block, so time stays paused until each person has ordered.

Stop there and play it. CPU logic, story, stats, techniques, armour, line of sight, win conditions, and a controller map wait until the fight is worth keeping.

## Two humans

The second person is another order source on the same `CombatClock`. No sockets, latency, or replication belong in the clock.

Two controllers on the same machine are enough to play the fight. A remote source can send those same orders later, when the group is testing from the browser. The transport stays outside `CombatClock`.

## Stand-ins

Durations on Attack, Brace, Parry, and Move are fixed numbers chosen for the prototype. The design document lists inputs for these times and does not yet give formulas. Those numbers live with the stub actions, not in the transcribed rules.

The eight action categories, techniques, status conditions, and derived combat values stay in `docs/` until `CombatClock` is worth extending.

# Prototype engineering

Build notes for this repo. The gameplay rules live in [docs/](../docs/README.md), transcribed from the design document, and in that document itself. This file is how the prototype gets built. It does not add rules, stats, or content.

The Godot 4.8 project is `godot/`. The clock and its test live in `godot/combat/`. The project opens on `scenes/main_menu.tscn`. That screen shows the logo at its own size. Enter or a click loads `scenes/fight.tscn`. The fight is one cube on the debug grid. A camera controller keeps a spring arm on that cube. Right-drag orbits it, and the wheel zooms, within distance and pitch limits. The second person comes back after that view is comfortable.

The playable prototype is GDScript, including `CombatClock`. The group needs a browser build, and Godot 4 cannot export C# to the web. Community C# web builds need a custom engine and are not a path for this project. See [hosting.md](hosting.md) for the public URL.

## What the first build is for

Prove `CombatClock`, then play a fight between two people. CPU logic and story wait until that fight is worth keeping. The clock itself is still proven by a test that calls the class directly: add a participant, submit an order, tick. No menu, room, or Ringbot in that test.

## CombatClock

The class is `CombatClock`. The file is `combat_clock.gd`.

`CombatClock` is the only object that advances combat time. Views, menus, and policies do not. "Authority" is that job, not a second class name.

Each participant is either waiting or committed.

- Waiting means it needs an order. Time does not advance while any participant that holds time is still waiting.
- Committed means an order has been accepted. The participant then spends start-up, an active window, and wind-down. Those are the source's `STU`, `ADR`, and `WND`. Wind-down returns it to waiting.

Anyone already committed keeps the time they had left. A pause stops the whole fight, and the resume continues from that point. `CombatClock` is also the only thing that resolves hits, interrupts, and the return to waiting. Those are simulation results, not orders.

`CombatClock` has no camera, no sprite, and no notion of which person is sitting at the machine.

## Schedule

`CombatClock` keeps one timeline. A participant is waiting, or committed to one action. Actions are not queued. Two commitments share the same frames, and a pause leaves every commitment at the time it had left.

An order names a participant and carries the three lengths: start-up, active, and wind-down. It also carries a payload the clock does not read. The clock runs the order's work when the active window opens, and again if that same commitment finishes its active length. Each call receives the clock and the participant id. It may return nothing, one `CombatResult`, or an array of them.

A result cancels a participant back to waiting, or replaces the time left before waiting. A replacement is wind-down for the given number of frames. The clock writes the change, then tells listeners. The signals are `paused`, `order_accepted`, `phase_changed`, `result_applied`, and `returned_to_waiting`. `waiting_ids` lists the participants that hold time and still need an order.

`CombatOrder` and `CombatResult` sit beside `combat_clock.gd`. The test adds a participant, submits an order, and ticks. It also uses a second participant that holds time, because that is what holds the pause.

## Orders

Outsiders change the fight by submitting an order: which participant, and which action. The action carries its three durations and the work to do when the active window opens and closes.

The first order source is a local menu. While time is frozen, a horizontal row of buttons shows the current step. Choosing a part puts that name on a label and swaps the row to that part's actions. Back returns to the parts. The parts follow the flow figure in [combat-flow.md](../docs/combat-flow.md):

- Head: no action yet. The placeholder attack is gone.
- Left arm: Attack. A touch. Each arm has its own range and pushback strength.
- Right arm: Attack. A touch. Each arm has its own range and pushback strength.
- Legs: Move.

The first two order sources are humans. Each one orders only the participants they own. A CPU policy is a later source that submits on its own. All of them produce the same kind of order. The part menu is one provider of orders, not part of `CombatClock`.

## Who holds time

Holding time is a property of the participant, set by whoever owns it.

- A participant owned by a human holds time. Time stays paused until an order arrives for every participant that holds time.
- A participant owned by the CPU does not hold time. Its policy submits an order immediately, so the fight does not wait on a menu.

When two of yours are waiting, you choose which to order first. Both orders are collected before time runs. A second human works the same way during that same pause, and can order only the participants they own.

There is no special "the player" inside `CombatClock`. Adding someone is registering their participants and pointing an order source at them.

## What stays outside CombatClock

| Hook | First stand-in | Can change later without touching phases |
| --- | --- | --- |
| Who is fighting | One test participant, then a second | Ringbots, and anything else that can wait and commit |
| Who may freeze time | Human-owned participants hold time | A different mode can change the flag |
| How an order is chosen | Buttons along the bottom. Part, then that part's action | A CPU policy, a replay, then a remote source |
| What an action does | Kinds are move, touch, ranged, and reaction. The arm attack is a touch. Pushback is a reaction on the bot that was hit. Move stores a destination; start-up is the turn and active time is the slide | Variants on those kinds, then the eight action categories, techniques, and real formulas |
| How the fight is drawn | One cube on the debug grid. A camera controller follows the subject group. Its spring arm orbits and zooms within a minimum pitch and a distance range. The fight scene does not move the camera | The joint tree in Ringbot body |

Build this split while there is still one participant. The menu and the marker can be thrown away. The pause rule and the phase timing in `CombatClock` stay.

## Ringbot body

The body is a tree of `Node3D` joints. An `AnimationPlayer` keys a joint's rotation, and every child of that joint moves with it. Part meshes are those children. The clip does not key the mesh.

Every joint stays in the tree. A clip only keys the joints for the parts that are slotted. A joint with no mesh is not drawn, and it stays at its scene rotation unless a clip writes it.

The first body is one base set: body, head, both arms, and one leg set, built from untextured stretched cubes. Each mesh shares the rest orientation of its joint, so a swap is parenting a different child there. More parts come later, as movement options or as features on the same joints. An arm cannon or an arm sword is another mesh on the arm. Wheels, treads, and a multi-leg set are their own joints and their own clips. The body, head, and arms stay on the shared joints.

This stays outside `CombatClock`. The one cube stands in until the pause and the resume are obvious. The debug grid is tiled on the floor. On a cube it is drawn once per face, and each surface gets its own albedo color.

## Build order

1. `CombatClock` in `combat_clock.gd`, one participant, and a test that submits an order. No scene.
2. A readout that shows waiting versus start-up, active, and wind-down, so the pause is obvious.
3. A second participant on the same `CombatClock`. One reaches waiting while the other is mid-phase.
4. A second human owning that other participant, with their own order source. Both sides hold time, so time stays paused until each person has ordered.

Stop there and play it. CPU logic, story, stats, techniques, armour, line of sight, win conditions, and a controller map wait until the fight is worth keeping.

## Two humans

The second person is another order source on the same `CombatClock`. No sockets, latency, or replication belong in the clock.

Two controllers on the same machine are enough to play the fight. A remote source can send those same orders later, when the group is testing from the browser. The transport stays outside `CombatClock`.

## Replays

A finished fight can be watched again in full, frame for frame, with the decision pauses left out. The replay is another order source. It submits the recorded orders when the clock pauses, then lets time run. The people who first played it are not in that room.

What gets saved is the starting state and each order a player, CPU, or remote chose, stamped with the simulation frame it was accepted on. The stamp counts frames `tick` actually advanced. Time spent choosing a part is not a frame, so it is not in the file. The payload is that choice: a move is the kind, the part, and the destination, and a touch is the kind, the part, and the aim yaw. The key presses that only moved the menu stay out of the file. An order a hook submits is not a choice. Playback submits the saved choices and the hooks build those reactions again.

Playback ticks one frame at a time, the same way a live fight does while it is running. Boot time and hitstop are combat frames, so they stay in the watch. Anything that moves a participant has to come from an order and from `tick`. A later physics body, or a random roll with no seed, would make the same file play differently.

The game keeps those files so a fight can be saved, opened again, and handed to someone else. That library waits. The clock does not grow a second timeline for it.

## Ground move

Choosing Move aims on the floor. The outline is the reach in every direction. The pointer shows a line and a circle, and that point stays inside the outline. A click commits the point. Back cancels.

The bot turns first, then moves straight. Turn rate and travel rate are separate fields on a move profile, so a later part can fill them. The stand-in profile turns 15 degrees a frame, and at a travel rate of 1 it can cover 4 meters in 28 frames when it is already facing that way. Turning still shortens the reach, and the profile removes 30 percent of that front-to-back drop so the rear point is skimmed into an arc. The forward point stays. The outline and the committed point use that same reach. A shorter point uses the same speed and fewer frames. The order payload is the input: the kind, the part, and the destination. The frame counts are derived from that point and the leg profile. Start-up is the turn. Active time is the slide. Wind-down is 0 until a recovery is chosen.

The aim marker is its own scene. The fight tells it the center and the reach, and does not draw the ring. The clock does not know the floor. Each step comes from that order and from `tick`.

## Touch

An arm attack is a touch. Choosing it aims on the floor, and a click commits a direction. Back cancels. The range and the pushback strength are fields on that arm, so the two arms can differ. The stand-in range is 2 meters from the attacker's center.

Two cones are drawn. The dotted translucent cone is the arc the bot can face during the attack's start-up, using its turn rate. The translucent solid cone is the attack's Scope, centered on the chosen facing, with a solid line down that center. That center stays inside the turn arc. The Scope cone's edges can hang past it, so a target can be caught off-center when the bot cannot turn far enough to face it. The stand-in Scope is 30 degrees off the chosen facing. The source names Scope and Centering, and Intent uses Centering, and it gives no angle and no falloff. While aiming, one bot inside that Scope and in range is the target. If several qualify, the one closest to the center line is taken, and if those angles match, the closer bot is taken. That bot is drawn with a red ring around its base. The hit uses that same choice, so only the targeted bot is pushed, still at full strength. Targeting a part waits until the center line can sit on the bot.

The order payload is the input: the kind, the arm, and the aim yaw. The range, Scope, and strength stay on the arm. When the active window opens, the hit is read from that payload. A click on empty ground commits that direction anyway.

Pushback is a reaction on the bot that was hit. That bot's profile turns the strength into meters and a slide speed. The stand-in moves 1 meter per point of strength, at 0.125 meters a frame. The hook puts the resulting destination on the reaction order, and the slide reads that order. A replay does not store the reaction. The clock does not know the range or the strength.

## Stand-ins

The touch timings and the pushback conversion are numbers chosen for the prototype. The design document lists inputs for these and does not yet give formulas. Those numbers live on the profiles, not in the transcribed rules. The move rates above are the same kind of stand-in.

The eight action categories, techniques, status conditions, and derived combat values stay in `docs/` until `CombatClock` is worth extending.

---
name: playable-gdscript
description: >-
  Keep the Ringbots playable build in GDScript, including CombatClock. Use
  when the user or the work mentions C#, .NET, GDScript, web export, a
  browser build, or a progressive web app.
---

# Playable build is GDScript

Read [engineering/README.md](../../../engineering/README.md). The decision is already made.

The group plays the prototype in a browser. Godot 4 cannot export C# to the web. Community workarounds are custom engine builds and are rejected. Do not research them again. Do not propose C# for `CombatClock` or for anything that has to ship in that build.

`CombatClock` is the class. The file is `combat_clock.gd`.

GDScript is the whole playable prototype, not only the engine-facing parts. A desktop-only C# split does not help people who open a link.

# Ringbots

A Godot prototype of a top-down combat game. Ringbots fight in real time, and time freezes when one you control is ready for an order.

The design is written down. The Godot project does not have gameplay yet. The first thing to build is the combat clock.

## Where to read

| Path | What it is |
| --- | --- |
| [docs/](docs/README.md) | Gameplay rules: parts, actions, techniques, and the combat loop. Transcribed from the [design document](https://docs.google.com/document/d/1EBi1aE6UWebbCDr_MCTRNsiSxO9PE6tPFMGpxAtwaiY/edit). That document stays the source. |
| [engineering/](engineering/README.md) | How this repo builds the prototype. The clock, orders, and what is being left out on purpose. |
| [godot/](godot/) | Godot 4.8 project. Open `godot/project.godot`. |

`docs/` describes the game. `engineering/` describes the build. The root of the repo is only the map.

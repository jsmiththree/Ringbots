---
name: public-hosting
description: >-
  Host the Ringbots browser build at ringbots.bingus.gg on the existing
  bingus Cloudflare tunnel and Caddy, using the Mealz pattern. Use when the
  user mentions hosting, deploying, publishing, the public URL, bingus.gg,
  Caddy, Cloudflare, the tunnel, or a web build for the group.
---

# Public hosting

Read [engineering/hosting.md](../../../engineering/hosting.md) and follow it. Do not re-investigate MealPlanner or the tunnel.

The public URL is **https://ringbots.bingus.gg**. The hostname is already on the **bingus** tunnel. Do not create a second tunnel. Do not point DNS at the home IP.

This repo owns `caddy/ringbots.caddy` and the web export that file serves. Never add or edit the board Caddyfile, cloudflared, Docker compose, or any other app's config. Those live in the home-server stack.

When the user asks to publish, run from the repo root:

```powershell
powershell -NoProfile -File scripts\refresh-public.ps1
```

That script exports Web, copies this site file to `/srv/caddy/apps/ringbots.caddy`, and copies `build/web/` to `/srv/caddy/apps/ringbots-web`, then reloads the existing Caddy. The web files have to sit in that directory because it is the one already mounted into Caddy. Do not add a volume or edit the board's service config to make another path visible. Use the Godot binary `D:\Projects\Godot\Godot_v*_win64.exe`.

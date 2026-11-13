# Public build

The group plays by opening a link. They do not install Godot. The hostname is already reserved. A local web export exists at `build/web/`. The public page opens on the logo. Enter or a click starts the fight.

This repo owns only its own site file, `caddy/ringbots.caddy`, and the files that site serves. The board Caddyfile, cloudflared, and every other app stay in the home-server stack. Do not copy those configs here, and do not edit them from this project.

## URL

**https://ringbots.bingus.gg**

```
Internet → Cloudflare (HTTPS) → bingus-cloudflared → bingus-caddy :80 → static web export
```

This is the Mealz pattern (`mealz.bingus.gg` in `D:\Projects\Godot\MealPlanner`). Ringbots has no API and no database. The public site is the Godot web export only.

The hostname is already on the existing **bingus** tunnel. Do not create a second tunnel or a Ringbots `cloudflared`. The origin should match Mealz: HTTP, `http://caddy:80`. DNS is a proxied CNAME to that tunnel. Do not point an A record at the home IP.

Caddy on the zimaboard serves this hostname because it imports `/srv/caddy/apps/*.caddy`, and that directory is already mounted into the container. Publishing copies `caddy/ringbots.caddy` to `/srv/caddy/apps/ringbots.caddy` and the export to `/srv/caddy/apps/ringbots-web`, then reloads the existing Caddy. The files have to live under that mount. This project does not add a volume or edit the board's service config. The board must stay on. This PC can sleep after that.

The export is produced from `godot/` with the Web preset, written to `build/web/index.html`. The export opens on the logo. Enter or a click starts the fight.

## Publish

From the repo root:

```powershell
powershell -NoProfile -File scripts\refresh-public.ps1
```

The script exports Web, copies `caddy/ringbots.caddy` and `build/web/` to the board, and reloads Caddy. It does not start a tunnel, bind port 80, or write any file except `/srv/ringbots` and `/srv/caddy/apps/ringbots.caddy` plus `/srv/caddy/apps/ringbots-web`.

| | |
| --- | --- |
| Site file in this repo | `caddy/ringbots.caddy` |
| Installed on the board | `/srv/caddy/apps/ringbots.caddy` |
| Files Caddy serves | `/srv/caddy/apps/ringbots-web` |
| Public URL | `https://ringbots.bingus.gg` |

The site block does not bind `:80`. Headers on the static files:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cache-Control: no-cache, must-revalidate` and `CDN-Cache-Control: no-store` on `index.html`, `index.js`, `index.wasm`, `index.pck`, and the other volatile export files

Export with Godot's web template for the editor in `D:\Projects\Godot\Godot_v*_win64.exe`. Use the Compatibility renderer so phone browsers can run it, as Mealz does. Single-threaded export is the default. Keep it unless a build actually needs threads.

Cloudflare Access is not on this hostname. Mealz gates `mealz.bingus.gg` because that app has no login. Add Access only if this link needs the same kind of gate.

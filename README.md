# maybeit.work

![ci](https://github.com/nineW0nW0n/maybeitwork-site/actions/workflows/ci.yml/badge.svg)

> maybe it works.

A status page disguised as an instrument. On load, a scientific readout taps
a handful of service endpoints while a dark void grows at center, consuming
a field of drifting dots. The void's ring reports health — red-to-green as
things come up — and once it settles, the headline flips from `maybeit.work`
to `it.does`.

Self-aware, faintly uncertain, never corporate. The domain is the joke.

## What it is

One HTML file. No framework, no build step, no CDN. The void/particle field
is a hand-tuned `<canvas>` render loop; everything else — layout, headline,
status bar, grain, scanlines — is DOM elements animated with CSS
`transform`/`opacity` only.

- **Fonts** — Inter + IBM Plex Mono, self-hosted as inline `woff2`. Nothing
  leaves the page over the network.
- **Reduced motion** — honored. Skips straight to the settled frame and
  freezes; `REPLAY` always overrides it.
- **No-JS fallback** — plain readable headline + service list if scripts
  fail or are disabled. Nothing waits on JS to become visible.
- **Status bar** — currently staged demo data (`SITE` / `VPS01` / `VPS02` /
  `VPS03`). Real checks land later; the page makes zero network requests
  until then.

## Run it

```sh
python3 -m http.server 8000
# open http://localhost:8000/index.html
```

No install, no dependencies — it's one file.

## CI

Four checks gate every push, since `biome` alone can't see inside an HTML
file's inline `<style>`/`<script>`:

| Check | Catches |
|---|---|
| `yamllint` | the workflow config itself |
| `biome` | any standalone `.js`/`.css`/`.json` |
| `scripts/check-rails.sh` | CDN fonts, external requests, layout-property keyframes, missing reduced-motion |
| `html-validate` | broken markup |

## Deploy

`maybeit.work` is a Cloudflare Worker (Custom Domain route, no Tunnel/
Dokploy involved), not this repo. `index.html` here is the design
source of truth — the homelab repo's `worker/status/` keeps a plain
committed copy (`src/page.html`) and serves it, plus the `/status.json`
endpoint this page fetches on load. See that repo's `worker/status/
CLAUDE.md` for the actual pipeline — nothing here should re-derive those
rules. Changes here don't auto-deploy; they need re-copying over there.

---

Built with [Claude Code](https://claude.com/claude-code). Break it freely,
revert freely — that's the point.

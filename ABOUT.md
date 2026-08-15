# About

`maybeit.work` is what happens when a domain name becomes a dare.

It's a status page cosplaying as a physics demo. A void grows in the
middle of the screen, eating a field of drifting particles, while a
readout pretends to check services no one's paged for yet. When the
ring goes green and the void settles, the headline confesses:
`maybeit.work` becomes `it.does`. Every load, the joke resolves itself
in real time — that's the whole bit.

## Why this exists

Not a product. Not a startup. A place to find out what Claude Design
and Claude Code do when you let them build something with more craft
than content. One page, animated, self-aware, allowed to break.

## Rules of the house

- **One file.** `index.html`, inline `<style>` and `<script>`, no
  build step. If it can't survive a `python3 -m http.server`, it
  doesn't ship.
- **No phoning home.** No CDN, no Google Fonts, no analytics. Fonts
  are self-hosted `woff2`. The page owes the network nothing.
- **Motion is earned.** CSS `transform`/`opacity` only — except the
  particle void, which gets a `<canvas>` exception because you can't
  fake gravity with `div`s. `prefers-reduced-motion` is honored, not
  an afterthought.
- **Works with JS off.** Because someday, somewhere, it will be.

## Status

Actively under construction, on purpose, in public. The status bar
currently reports staged demo data — real health checks are coming,
the void just doesn't know it yet.

See [README.md](README.md) for how to run it and what actually gates
a push. See [CLAUDE.md](.claude/CLAUDE.md) for the rails nobody's
allowed to break, including the robot.

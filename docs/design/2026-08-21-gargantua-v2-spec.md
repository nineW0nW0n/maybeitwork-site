# maybeit.work — Gargantua v2: two instruments, one object

Status: draft for Ex's sign-off, 2026-08-21. Supersedes the WebGL plan
(reverted the same day — too heavy). No build until this is approved.

## 0. One sentence

A black hole with an oversized accretion disk, believably *there* behind
the glass of a monitor, reporting the health of three VPS nodes — seen in
visible light (dark mode) or as a false-colour sensor feed (light mode).

Priority order, always: **object first, glass second, smoke last.**

## 1. Locked decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Scope | Evolve the existing page: keep boot → wave → race → feed → pulse, the particle infall, the bottom bar, the frame. Replace the disc. |
| 2 | Rendering | Image plates (alpha masks) + CSS. No WebGL, no per-frame canvas for the disk. Particle field stays Canvas 2D. |
| 3 | Motion | `transform` / `opacity` only. Blur, glow, lensing are baked into plates. |
| 4 | Two modes | Dark = visible light, what an eye would see. Light = false-colour multiwavelength sensor. Same object, two instruments. |
| 5 | Dark palette | Shadow `#000` (dead OLED). Space `#0A0B10` (TN-panel black). Disk natural ramp: ember `#7A1E12` → `#E0521F` → gold `#F5A623` → white-hot `#FFF4E0`. |
| 6 | Light palette | Four stops: paper `#F2F2F2` (chrome), field `#C9CCD4` (sensor panel), slate `#4A4E69` (ink, contours, labels), white `#FFFFFF` (hot). One accent for the saturated warning: `#C8401E`. |
| 7 | Status ↔ disk | Three concentric bands = VPS00 (inner) / VPS01 / VPS02 (outer). Band orbital speed tracks node load. |
| 8 | Status, dark | ok = white-gold band · hot = band cools to red · lost = band dark, visible gap · blind = disk dim, nebula only. |
| 9 | Status, light | ok = clean white band · hot = **saturated** (blooming, clipped) · lost = **no signal** (static noise in the band) · blind = whole feed drops to calibration pattern. |
| 10 | Headline | ok `it.does` · hot `it.somewhat` · lost `it.doesn't` · blind `maybeit.work` (never flips). Only these four strings are not uppercase. |
| 11 | Caps | Every other visible string uppercase via CSS `text-transform`; source text stays sentence case for screen readers. |
| 12 | Data | `/status.json` v2: `{ polledAt, nodes: [{ name, up, lastSeen, load, cpu, mem, swap, disk }] }`. Page accepts legacy bare array. Worker PR to be redone. |
| 13 | Refresh | Manual only. `AGAIN` re-fetches then replays. No polling loop. |
| 14 | Honesty | Blind = fetch failed or `polledAt` > 5 min. Never fake health. Every on-screen number is live data or an obvious shrug (`MASS UNKNOWN`). |
| 15 | Size | One self-contained file. ~500 KB acceptable if spent on plates. |
| 16 | Mobile | Gargantua big, cropped off-centre by the frame, minimal readout (§6). |
| 17 | Theme switch | Animated as a sensor channel change (§7). `LIGHT / DARK / AUTO`, persisted. |
| 18 | Critics | Five critics, each ≥ 9/10 with zero must-fix, ≤ 5 rounds (§9). |
| 19 | Build | Vite, multi-file output on Cloudflare Workers Static Assets (free tier). See §10. Rail 1 becomes "self-hosted, same-origin, zero third-party" — no longer "one file". |

## 2. The object — what makes it *there*

In priority order. Anything below may be cut; nothing here may.

1. **Occlusion.** Shadow covers stars, particles, nebula, far disk. Near disk covers the shadow's lower rim. Lensed arcs sit behind the near disk and over the shadow.
2. **Parallax.** Mouse (desktop) / gyro (phone), eased, tiny: nebula 2 px, disk 5 px, shadow 6 px, dirt 0 px, dust 10 px opposite. Dirt not moving while the object does is the strongest "beyond the glass" cue.
3. **Differential rotation.** Inner band fastest. Periods 40–90 s. Doppler limb fixed on the left, so the light source stays put while bands turn.
4. **Scale.** Desktop: shadow radius ≈ 33 % of the short edge, disk major axis ≈ 85 % of viewport width, clipped at the edges. Bigger than real. Mobile: §6.
5. **Sharp rim.** Shadow edge and photon ring are vector (CSS circle, SVG stroke). Wisps, glow, nebula are raster. Hard edges vector, soft things raster — the 4K rule.
6. **Slow.** Glow breathes over ~6 s. The object never flickers. Only the glass does, rarely.

Tests any build must pass before critics see it:

- **Squint test** — blur a screenshot 10 px: still a black hole with a disk and a lensed arc.
- **Freeze test** — one frame with every glass/artifact layer hidden: reads as a photograph, not a diagram.

## 3. Plates

Alpha-only images unless noted. Coloured by CSS (`background-color` under
`mask-image`). Soft by nature, so ~1024 px sources upscale clean. Produced
offline, never rendered at runtime. Detailed spec: `handoff/plates.md`.

| Plate | Mode | Notes |
|---|---|---|
| ring | both | photon ring glow (the crisp line itself is SVG) |
| disk-00 / disk-01 / disk-02 | both | near-disk band footprints, baked falloff, tilt ~75° |
| arc-top / arc-bottom | both | lensed far-disk images, baked |
| wisps-a / wisps-b | both | tileable streak noise, ellipse-shaped, two phases |
| doppler | both | one-sided soft gradient, `screen` / `multiply` |
| nebula | dark | far background, low contrast, RGB not alpha |
| nebula-lensed | dark | nebula smeared into a ring hugging the shadow |
| contours | light | isophote lines over the disk footprint |
| noise | light | static for the no-signal band |
| clip | light | clipped-pixel pattern for the saturated band |
| calib | light | calibration pattern for blind |
| dirt | both | glass smudges, fibres; `screen` dark / `multiply` light |
| dust | dark | 5–8 bokeh discs, near field |

Budget ≈ 250–350 KB encoded.

## 4. The glass — monitor artifacts

Cap: three artifact types perceptible at once, each ≤ 3–6 % opacity.

- Chromatic aberration: ring + arcs duplicated twice, ±1 px, R/B tint, `screen`, ≤ 30 %.
- Phosphor stripes over the disk region, ~4 %. Existing scanlines stay.
- Interlace flicker: disk group opacity 1 → 0.96 → 1, `steps()`, irregular period.
- Rolling sync bar: one faint band, `translateY` across the frame every 8–12 s.
- Acquisition glitch: on status change / `AGAIN`, 120 ms slice jitter (3–4 `clip-path` slices, `translateX` ±2 px).
- Dirt on glass: fixed to viewport, zero parallax, same plate every load.
- Nearfield dust: slow independent drifts, crossing the disk occasionally. Dark mode only; off under reduced motion.
- Vignette + 1 px inner frame highlight. No barrel distortion.

Sensor mode keeps aberration, stripes, dirt (as dark specks). No dust, no sync bar.

## 5. Labels — desktop

**live** = real data · **true** = static fact · **theatre** = obvious shrug.

Top rule: `FEED 01 · VISIBLE` / `FEED 02 · SENSOR` (true, left) · `Welcome. Thank you for testing this site. Now go away.` (theatre, centre) · `UTC 21:31:07` (live, right).

Reticle, leader lines 1 px: `000 · 090 · 180 · 270` (true) · `PHOTON RING` (true) · `BAND 00 / VPS00`, `BAND 01 / VPS01`, `BAND 02 / VPS02` (live; suffix `· SATURATED` when hot, `· NO SIGNAL` when lost) · `INCL 75°` (true).

Left margin, sensor mode only: `REL. INTENSITY` bar `0 — 1` (true).

Right margin: `MASS  UNKNOWN` · `SPIN  ASSUMED` · `RANGE  ---` (theatre).

Centre: `KNOCKING_` boot (theatre) · headline (live) · `NO SIGNAL` stamp across the feed when blind (live).

Bottom bar: `LIGHT / DARK / AUTO` · `VPS00  L02 C01 M06 S00 D02` ×3 (live; L load · C cpu · M mem · S swap · D disk, 0–10; legend on hover/long-press) · `POLLED 14S AGO` · `RTT 212MS` · `1440×900 @2×` · `AGAIN`.

Hidden: screen-reader sentence — `ALL 3 NODES OPERATING NORMALLY.` / `VPS02 SATURATED.` / `VPS01 NO SIGNAL SINCE 22:14 UTC.` / `NO SIGNAL.`

Cut on purpose: frame counter, coordinates, fake Kelvins, accretion rate — any number dressed as a measurement.

## 6. Mobile (< 1200 px)

Cropped by the sensor, not shrunk. Shadow radius ~110–130 px at 375 px wide, centre ≈ x 62 %, y 42 %. Near disk sweeps off both edges; lensed arc above. Portrait-tall shows more lower arc; landscape phones use the desktop composition scaled.

Labels, seven things total: headline · one leader label on the nearest band `BAND 02 / VPS02` (+ state suffix) · `NO SIGNAL` stamp when blind · two corner brackets on the open side · bottom row: three node dots (band colours), `POLLED 14S`, theme glyph, `AGAIN` · screen-reader sentence.

No clock, no RTT, no theatre labels, no top message. Sensor mode: grey field full-bleed, paper chrome only in the bottom bar.

## 7. Theme switch — channel change

1. 0 ms: interlace flicker on the disk group, two frames.
2. 0–350 ms: mode plates crossfade (`opacity`); shared plates re-tint via CSS variables.
3. 0–350 ms: `--bg`, `--ink`, band tints transition (one-shot repaint, acceptable).
4. ~120 ms: `FEED 01 · VISIBLE` ↔ `FEED 02 · SENSOR` with a 3-frame character scramble.
5. Midpoint: dirt blend mode flips; dust out (to sensor) / in (to visible).

Reduced motion: instant swap. `AUTO` system changes use the same sequence.

## 8. Delegation plan

Each task = fresh implementer subagent + task review (spec + quality) + controller ledger, as in the previous run. Media is produced by a different lane than code.

| # | Task | Who | Output |
|---|---|---|---|
| 0 | Spec sign-off | Ex | this file approved |
| 1 | Reference frames | **Claude Design** (`handoff/claude-design-prompt.md`) | artboards: desktop × {visible, sensor} × {ok, hot, lost, blind}; mobile × {visible, sensor} × {ok, lost}; theme-switch midframe. Ex picks. |
| 2 | Plate pipeline | agent, opus | `tools/plates/` offline renderer (headless shader capture or Python), emits the §3 set to spec; checked-in outputs; not shipped as code |
| 3 | Worker contract v2 | agent, sonnet | redo PR in homelab repo (`src/shape.js`, tests, CLAUDE.md) — not merged |
| 4 | Page modules + build | agent, sonnet | Vite scaffold per §10, `status.js`, `theme.js` (+ tests), CI builds `dist/` |
| 5 | Disk composition | agent, opus | layer stack, masks, tints, differential rotation, parallax, occlusion order; squint + freeze tests pass |
| 6 | Glass layer | agent, sonnet | §4 artifacts, dirt, dust, glitch, channel-change transition |
| 7 | Labels, reticle, mobile crop | agent, opus | §5, §6; caps via CSS; SR sentence |
| 8 | Critics loop | 5 agents × ≤ 5 rounds | §9 |
| 9 | Definition of done + deploy hand-off | controller | CLAUDE.md checklist by hand; worker repo PR: `[assets]` binding + `dist/` vendored; Ex approves prod |

Claude Design's role: composition, chrome, typography, label placement, the two palettes in situ — reference frames that lock taste before code. It is **not** the plate renderer: plates need baked lensing, tileable noise and exact alpha, which come from the offline renderer in task 2. Claude Design frames may be used as visual targets for task 2's tuning.

## 9. Critics

Five, in parallel, each scores 1–10 with must-fix and nice-to-have lists, from screenshots (both modes × 1440 / 375 × four states), a 10 px-blurred set, an artifacts-hidden set, and source access. Told: "fine" is a 6; ≥ 9 means wowed.

1. **Presence** — is something physically there behind the glass? Occlusion, parallax, scale, rim, rotation. Owns the squint and freeze tests.
2. **Art director** — composition, type, restraint; palette discipline; would it hang next to lazy.so / evervault.
3. **Motion & perf** — 60 fps at 375, compositor-only, reduced motion, artifact budget respected, file size.
4. **Honesty & a11y** — every state truthful, SR sentence, no-JS, contrast, focus, 44 px targets, caps via CSS not source.
5. **Brand & wit** — self-aware, faintly uncertain, never corporate; theatre labels land as shrugs, not lore.

Gate: all five ≥ 9, zero must-fix. Cap 5 rounds; leftovers listed in the final report.

## 10. Build and hosting — maximum fidelity on the free tier

**Decision:** Vite build → `dist/` with `index.html`, one JS module, one
CSS file, fonts and plates as separate hashed binary files. Served by the
existing Cloudflare Worker through **Workers Static Assets** (free: no
request limits on assets, edge-cached, `immutable` cache headers on hashed
files). The Worker keeps `/status.json` and `/debug` with
`run_worker_first` for those two routes only. No Pages project, no second
deploy pipeline.

Why not one inlined file: base64 costs +33 % on every plate and defeats
the browser cache; ~500 KB of inline data is re-parsed on every visit and
pushes the Worker script toward the free-tier 3 MB compressed limit. Binary
WebP served as files is smaller, cached once, and lets plates load in
priority order (ring and disk first, nebula and dirt after first paint).
Fidelity goes up, weight goes down.

Rail changes this implies (to be written into `.claude/CLAUDE.md` in task 4):

- Rail 1 → "Self-hosted and same-origin. Every byte the page loads comes
  from `dist/` on this origin; zero third-party requests. No runtime
  dependency."
- Rail 2 unchanged in spirit: the only non-asset request is `/status.json`
  on load and on `AGAIN`.
- Content still survives JS failure; CSS still animates `transform` /
  `opacity` only.

Layout of `dist/` (hashed names illustrative):

```
dist/
  index.html
  assets/main-a1b2c3.js
  assets/main-d4e5f6.css
  assets/inter-….woff2  plexmono-400-….woff2  plexmono-500-….woff2
  plates/ring-….png  disk-00-….png … nebula-….webp … dirt-….png
```

Loading order: `<link rel="preload">` for ring, disk-00/01/02, arc-top,
fonts. Everything else lazy after first paint. Target: first meaningful
frame (shadow + ring + near disk) under 150 KB on the wire.

Worker repo changes (task 9, separate PR, Ex approves prod):

- `wrangler.toml`: `[assets] directory = "./dist" binding = "ASSETS"
  run_worker_first = ["/status.json", "/debug"]`.
- `index.js`: drop the `page.html` Text import; non-API paths fall through
  to `env.ASSETS.fetch(request)`. CSP stays strict: `default-src 'none';
  script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self';
  connect-src 'self'` — `'unsafe-inline'` can finally go, because nothing
  is inline any more.
- `dist/` is vendored into the worker repo by CI artifact copy, as
  `page.html` is today.

Tooling: Vite 8, Vitest 4 (jsdom), Biome 2.5, html-validate on
`dist/index.html`, `scripts/check-rails.sh dist/` (third-party-URL grep
over every emitted file). CI: `npm ci → lint → test → build → rails →
validate → upload dist/ artifact`.

## 11. Out of scope

Polling, analytics, third-party requests, Cloudflare Pages, WebGL, per-metric history, more than three nodes, barrel distortion, fake measurements.

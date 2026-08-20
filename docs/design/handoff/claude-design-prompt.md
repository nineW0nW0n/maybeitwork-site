# Claude Design brief — maybeit.work "Gargantua v2" reference frames

Paste this whole file as the prompt. Attach `style.md` from this folder.
Output: one canvas, artboards named exactly as listed in §4.

## 1. What this is

maybeit.work is a one-page status site for three small servers (VPS00,
VPS01, VPS02). The domain is the joke — "maybe it works." The hero is a
black hole with an oversized accretion disk, seen *through a monitor*:
a believable object behind glass, with sparse tactical telemetry around it.
Self-aware, faintly uncertain, never corporate. Tasteful, tactical,
cyberpunk-adjacent without neon.

You are designing **reference frames**, not the final assets. They lock
composition, palette in situ, typography, label placement and the two
modes before any code is written. A separate renderer produces the disk
image plates later and will tune toward your frames.

## 2. The object — non-negotiable reads

- Shadow: a perfect circle, dead black `#000`. Radius ≈ 33 % of the
  viewport's short edge on desktop.
- Accretion disk: thin, tilted ~75° from face-on, so it reads as a flat
  ellipse through the shadow's equator. Major axis ≈ 85 % of viewport
  width on desktop — clipped by the edges. Bigger than real.
- Lensing: the far side of the disk appears as an arc **over the top** of
  the shadow and a thinner arc **under** it. This is the signature. A flat
  ellipse alone is wrong.
- Photon ring: a thin bright line hugging the shadow's edge.
- Doppler: the left limb is brighter/whiter than the right.
- Three concentric bands in the disk: inner = VPS00, middle = VPS01,
  outer = VPS02. Fine filaments streaming along the orbit; wisps live
  inside the disk footprint only — no smoke in space.
- Layer order, strictly: stars/nebula → lensed arcs → shadow → near disk
  (which covers the shadow's lower rim) → photon ring → glass artifacts →
  labels.

Priority: object first, glass second, smoke last. If the frame reads as
"nice CRT effect" before it reads as "a black hole is there," it's wrong.

## 3. Two modes = two instruments

**Dark — visible light.** What an eye would see. Space `#0A0B10` with a
faint, far, low-contrast nebula behind; a sparse star field; shadow `#000`
blacker than space. Disk in the natural ramp (style.md). Dust motes in the
near field, a smudge or two on the glass catching the disk's light.

**Light — false-colour sensor feed.** Paper chrome `#F2F2F2` around a grey
sensor field `#C9CCD4`. Four stops only: paper, field, slate `#4A4E69`,
white. White is hot. Isophote contour lines over the disk, a faint pixel
grid, an intensity legend `REL. INTENSITY 0 — 1`. No nebula, no dust.
Accent `#C8401E` appears only on a saturated (hot) band.

## 4. Artboards (exact names)

Desktop 1440 × 900:
- `D-VIS-OK`, `D-VIS-HOT`, `D-VIS-LOST`, `D-VIS-BLIND`
- `D-SEN-OK`, `D-SEN-HOT`, `D-SEN-LOST`, `D-SEN-BLIND`
- `D-SWITCH-MID` — midframe of the dark→light channel change (§7)

Mobile 390 × 844:
- `M-VIS-OK`, `M-VIS-LOST`, `M-SEN-OK`, `M-SEN-LOST`

Status per frame:
| state | dark (visible) | light (sensor) | headline |
|---|---|---|---|
| OK | all bands white-gold | all bands clean white | `it.does` |
| HOT | VPS01 band cooled to red | VPS01 band saturated: blooming, clipped pixels, accent | `it.somewhat` |
| LOST | VPS01 band dark, visible gap | VPS01 band is static noise | `it.doesn't` |
| BLIND | disk dim, nebula only, `NO SIGNAL` stamp | field drops to a calibration pattern, `NO SIGNAL` stamp | `maybeit.work` |

## 5. Labels — desktop (exact strings, exact casing)

All uppercase except the headline. Mono for everything but the headline.

Top rule: left `FEED 01 · VISIBLE` (dark) / `FEED 02 · SENSOR` (light) ·
centre `WELCOME. THANK YOU FOR TESTING THIS SITE. NOW GO AWAY.` · right
`UTC 21:31:07`.

Reticle with 1 px leader lines: `000 · 090 · 180 · 270` tick labels ·
`PHOTON RING` · `BAND 00 / VPS00` · `BAND 01 / VPS01` · `BAND 02 / VPS02`
(suffix ` · SATURATED` in HOT, ` · NO SIGNAL` in LOST) · `INCL 75°`.

Left margin (sensor only): `REL. INTENSITY` bar, `0 — 1`.

Right margin: `MASS  UNKNOWN` · `SPIN  ASSUMED` · `RANGE  ---`.

Centre: headline over the shadow, Inter 600, tight tracking, colour
`#F2F2F2` on dark / `#F2F2F2` on the `#000` shadow in both modes.
`NO SIGNAL` stamp across the feed in BLIND.

Bottom bar, one baseline: `LIGHT / DARK / AUTO` (active one boxed) ·
`VPS00  L02 C01 M06 S00 D02` · `VPS01  L02 C01 M04 S00 D02` ·
`VPS02  L03 C03 M05 S01 D07` · `POLLED 14S AGO` · `RTT 212MS` ·
`1440×900 @2×` · `AGAIN` (boxed).

Corner crosshairs at the four corners of the band between the top and
bottom rules, as in the current site.

## 6. Mobile (390 × 844)

Cropped, not shrunk. Shadow radius ~120 px, centre at ≈ x 62 %, y 42 %.
Disk sweeps off both edges; lensed arc above. Only these elements:
headline · one leader label `BAND 02 / VPS02` (+ suffix) · `NO SIGNAL`
stamp in LOST/BLIND frames · two corner brackets on the open side ·
bottom row: three node dots in band colours, `POLLED 14S`, a theme glyph,
`AGAIN`. Nothing else. Sensor mode: grey field full-bleed, paper only in
the bottom bar.

## 7. `D-SWITCH-MID`

Halfway through dark→light: shared layers at mid-tint, nebula at 50 %
fading out, contours at 50 % fading in, the top-left label mid-scramble
(`FEED 0▮ · SE▮SOR`), disk group at 0.9 opacity (interlace flicker).

## 8. Glass — keep it under 6 %

Chromatic fringe on the ring and arcs (±1 px red/blue), fine phosphor
stripes over the disk only, a subtle vignette, one smudge and two fibres
on the glass (dark: catching light; light: dark specks). At most three
artifact types readable at once. No barrel distortion, no heavy scanlines,
no glow on text.

## 9. Taste rails

- One accent colour per mode. No cyan, no magenta, no gradients on chrome.
- Labels 10–11 px mono caps, letterspaced, slate/ink3 at ~75 % opacity.
  They point at the object and never cover it.
- Every number shown is either real data or an obvious shrug. No fake
  Kelvins, no "accretion rate."
- Restraint wins ties. Reference tone: lazy.so's negative space,
  evervault.com's hairline precision — plus one very large, very real
  object.

## 10. Two tests your frames must pass

- Squint: blurred 10 px, still a black hole with a disk and a lensed arc.
- Freeze: hide every glass artifact and label — it reads as a photograph,
  not a diagram.

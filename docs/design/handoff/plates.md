# Plate spec — offline renderer (task 2)

Produced once, offline, by `tools/plates/` (headless shader capture or a
Python/numpy pipeline). Never rendered at runtime. Outputs are checked in
and inlined into the page as data URIs.

## Common

- Format: PNG-8 alpha or lossless WebP for masks; lossy WebP q80 for the
  two RGB nebula plates. Target ≤ 350 KB encoded total.
- Canvas: 1024 × 1024 px for disk plates, shadow centred, shadow radius
  `rs = 160 px` → 1 unit. All geometry in shadow radii.
- Geometry: disk plane tilted 75° from face-on, camera on the axis. Bands
  at r ∈ [1.5, 2.3], [2.3, 3.3], [3.3, 4.5].
- Lensing baked: primary image (near disk + far-side arc over the top),
  secondary image (thin arc under). Doppler beaming: approaching limb on
  the LEFT ×1.6, receding ×0.5 — baked as a separate plate so CSS can
  scale it, not baked into band masks.
- Alpha plates carry **only coverage/intensity**. No colour. Colour is CSS.
- Soft edges everywhere except nothing: the shadow rim and the photon
  ring line are NOT in the plates (vector in the page). Plates stop ~3 px
  outside the rim with a feathered edge so the vector rim sits on top.
- Noise is seeded; re-running the tool produces identical files.

## Plates

| file | type | content |
|---|---|---|
| `ring.png` | alpha | photon-ring glow, radial falloff 1.0–1.35 rs, peak at 1.02 |
| `disk-00.png` | alpha | band 0 footprint incl. its lensed arc portions, baked radial falloff (inner edge hotter) |
| `disk-01.png` | alpha | band 1 footprint, same |
| `disk-02.png` | alpha | band 2 footprint, same |
| `arc-top.png` | alpha | far-side primary arc over the shadow, all bands merged, low intensity |
| `arc-bottom.png` | alpha | secondary arc under the shadow, thinner, lower |
| `wisps-a.png` | alpha | filament noise mapped to the disk footprint, stretched along orbit (anisotropy ≥ 6:1), tileable in angle so rotation loops |
| `wisps-b.png` | alpha | same, different seed/phase |
| `doppler.png` | alpha | one-sided soft gradient over the disk footprint, left bright |
| `nebula.webp` | RGB | 768 × 768, far background, low contrast (≤ 12 % luminance range), desaturated warm/blue, no hard stars |
| `nebula-lensed.webp` | RGB | the nebula smeared into an Einstein-ring band 1.0–1.6 rs |
| `contours.png` | alpha | isophote lines over the disk footprint, 1 px, 6–8 levels |
| `noise.png` | alpha | 256 × 256 tileable static (for the no-signal band, masked by `disk-NN`) |
| `clip.png` | alpha | clipped-pixel pattern: blocky saturation cells, for the saturated band |
| `calib.png` | alpha | calibration pattern (bars + crosshair grid), full-field, for blind |
| `dirt.png` | alpha | 1024 × 1024 viewport overlay: 1 smudge, 2–3 fibres, faint fingerprint edge, gaussian-soft |
| `dust.png` | alpha | 5–8 bokeh discs on a 512 × 512 sheet, soft rims, varied sizes |

## Acceptance

- Composite test in a scratch HTML: stack per spec §2 layer order, tint
  with style.md dark ramp → matches `D-VIS-OK` reference frame on a
  squint; with light four-stop palette → matches `D-SEN-OK`.
- Rotating `wisps-a/b` 360° shows no seam.
- Sum of encoded sizes ≤ 350 KB; each ≤ 60 KB.
- No plate contains colour except the two nebula files.

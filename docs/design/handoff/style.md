---
project: maybeit.work
version: gargantua-v2
modes:
  dark:
    name: "FEED 01 · VISIBLE"
    space: "#0A0B10"        # TN-panel black, the field
    shadow: "#000000"       # dead OLED black, the hole only
    ink: "#EDEDF2"
    ink3: "#8B90A8"
    onShadow: "#F2F2F2"     # headline over the shadow
    disk:                   # natural ramp, cold → hot
      ash: "#2A2A33"
      ember: "#7A1E12"
      orange: "#E0521F"
      gold: "#F5A623"
      white: "#FFF4E0"
    status:
      ok: "#F5A623"         # readout text; bands use the ramp
      hot: "#E8715E"
      lost: "#6B6E80"
  light:
    name: "FEED 02 · SENSOR"
    paper: "#F2F2F2"        # chrome only
    field: "#C9CCD4"        # the sensor panel
    shadow: "#000000"
    slate: "#4A4E69"        # ink, contours, labels
    ink3: "#5A5E77"
    white: "#FFFFFF"        # hot
    accent: "#C8401E"       # saturated band only
    status:
      ok: "#4A4E69"
      hot: "#C8401E"
      lost: "#8B8EA0"
typography:
  headline: { family: Inter, weight: 600, tracking: -0.035em, case: as-is }
  label:    { family: "IBM Plex Mono", weight: 400, size: 10-12px, tracking: 0.08-0.12em, case: uppercase }
  numbers:  tabular
geometry:
  tilt_deg: 75
  shadow_radius_desktop: "33% of short edge"
  disk_major_axis_desktop: "85% of viewport width, clipped"
  mobile_shadow_radius_px: 120
  mobile_center: { x: "62%", y: "42%" }
  bands:                    # in shadow radii
    - { node: VPS00, r: [1.5, 2.3] }
    - { node: VPS01, r: [2.3, 3.3] }
    - { node: VPS02, r: [3.3, 4.5] }
motion:
  orbit_periods_s: [40, 60, 90]   # inner → outer, scaled by node load
  glow_breath_s: 6
  parallax_px: { nebula: 2, disk: 5, shadow: 6, dirt: 0, dust: -10 }
  artifact_opacity_max: 0.06
  allowed_properties: [transform, opacity]
spacing: [4, 8, 12, 16, 24, 32, 48, 64]
radius: { none: 0, sm: 4 }
---

# Style notes

- **Object first, glass second, smoke last.** Every decision is tested
  against "does the black hole feel more there?"
- Hard edges vector, soft things raster. The shadow rim and photon ring
  are crisp at any DPR; glow, wisps, nebula are soft plates.
- Shadow is blacker than space. That half-stop between `#000` and
  `#0A0B10` is the most important contrast on the page.
- Light mode is not an inverted dark mode. It is a different instrument
  with four colours. White is hot; the field is grey so white can be hot.
- Labels are instrument etching: thin, caps, letterspaced, pointing at
  things. They never sit on the object.
- One accent per mode, used only for the warning state.
- Theatre labels (`MASS UNKNOWN`) are shrugs, not lore. Never a fake
  number.
- Never pure white paper behind the disk; never neon; never text glow
  beyond the existing faint HUD bloom.

# CLAUDE.md — maybeit.work

> Audience: Claude Code, first. Ex, second. Every rule exists to make the
> agent reliable, not because it reads nicely.

Map, not manual. This project is one HTML file, so the per-directory
`CLAUDE.md` pattern is deliberately minimal here — don't cargo-cult it in.
Skill routing lives in `skills.md`; read that before any design or build
work.

## What / where / when / why / how

- **What**: `maybeit.work` — a single-page animated landing site. One
  self-contained HTML file, no build step.
- **Where**: built locally, deployed to the homelab (`vps01` or `vps02`)
  via Dokploy, behind the existing Cloudflare Tunnel.
- **When**: active build, non-production. Nothing depends on it. Break it
  freely, revert freely — that's the point.
- **Why**: learn how Claude Design and Claude Code work together. Craft
  and motion matter more than volume of content.
- **Brand**: the domain is the joke. `maybeit.work` reads as "maybe it
  works." Self-aware, playful, faintly uncertain, never corporate. The
  site should feel like something that knows it might not work and shipped
  anyway. Lean into it; don't explain it.
- **How**: edit `index.html`, verify in a real browser, commit, deploy
  through the homelab pipeline.

## Read before design work

`skills.md` maps the five installed skills to the stages of this build,
and — more importantly — says when *not* to run them. Read it before
starting design, theming, or assembly. Don't guess at which skill applies.

## Hard rails — never break these

1. **One self-contained file.** `index.html` with `<style>` and
   `<script>` inline. No bundler, no build step, no npm dependency
   shipped in the page.
2. **No external runtime requests.** No CDN scripts, no Google Fonts, no
   remote assets. System font stack, or a font inlined into the file.
   The page must render fully with no network beyond its own HTML.
3. **Animation is DOM elements + CSS.** No video, GIF, or Lottie standing
   in for motion. Movement comes from transforms on real elements.
   **Scoped exception (2026-08-15):** the hero's particle/disc field
   (design handoff `Light Void`) is `<canvas>` + a JS render loop —
   approved by Ex as the one deliberate exception, because the effect
   (particles infalling into a disc, corona, gravity wave) isn't
   reproducible with a fixed set of DOM nodes. Keep the exception scoped
   to that one component: canvas draws particles/disc/corona only; the
   headline, boot readout, bottom bar, crosshairs, overlays stay real DOM
   + CSS per rules 4 and 5. Don't let this exception justify canvas
   elsewhere on the page.
4. **Animate `transform` and `opacity` only.** Never animate `width`,
   `height`, `top`, `left`, or `margin` — those recalculate layout every
   frame and visibly stutter on phones. This single rule decides more of
   how the site *feels* than any design choice. (The canvas exception in
   rule 3 draws its own pixels and isn't bound by this — but still must
   honor `prefers-reduced-motion`, see rule 7.)
5. **JS only where CSS genuinely can't reach.** `IntersectionObserver`
   for scroll triggers is fine. A motion library is not — CSS-first was
   chosen deliberately, not by default. The canvas render loop (rule 3
   exception) is the other approved case.
6. **Content must survive JS failing.** Never park text at `opacity: 0`
   waiting for a script to reveal it. Either JS hides it on load before
   revealing, or the reveal is pure CSS. A blank page when one script
   errors is the exact failure this prevents.
7. **`prefers-reduced-motion: reduce` is honored.** Every animation has a
   reduced variant or is disabled outright. Not a later polish pass.
8. **Mobile is the default viewport.** Design at 375px first, scale up.
9. **No tracking, no analytics, no forms collecting personal data.** It's
   a learning site; keep the surface clean.
10. **Deploying inherits the homelab's rails** — `mem_limit`,
    `network_mode: host` on cloudflared, one tunnel token per node. Read
    that repo's `CLAUDE.md`; never re-derive those rules here.

## The loop

```sh
biome ci .    # covers standalone .js/.css/.json only
```

**Biome does not parse HTML.** Inline `<style>` and `<script>` inside
`index.html` are not linted by it. Never report "lint passed" as though
it covered the page — for this project it mostly didn't. The checklist
below is the real gate.

**Definition of done — every line actually checked, not assumed:**

- Opens in a browser with a clean console. No errors, no failed requests.
- JS disabled → all content still readable (rail 6).
- `prefers-reduced-motion: reduce` → no motion, nothing broken (rail 7).
- 375px wide → no horizontal scroll, nothing clipped, tap targets usable.
- Scrolled top to bottom → no jank, no layout shift, no animation that
  fires twice or never fires.
- Screenshotted and actually looked at before calling it done.

You have browser tools. Drive the page with them. A green console is not
the same as a page that looks right.

## Failure log

One line per real mistake, imperative, the moment it happens. Empty until
something actually goes wrong — don't pre-fill it with guesses.

## Structure

One file today. Add a directory `CLAUDE.md` only if this grows real
subdirectories (`assets/`, split sections) — not before. If `index.html`
passes ~1500 lines, say so and propose a split; never split silently.

## When you're unsure

Ask before: adding any dependency, adding a build step, relaxing the
single-file constraint, or touching homelab deploy config.

Ex is not an engineer. Before a non-trivial change, explain in plain
terms what and why in 1-3 sentences — before doing it, not after.

Design taste is Ex's call, not yours. Show options and let him pick;
don't silently choose a direction and present it as the only one.

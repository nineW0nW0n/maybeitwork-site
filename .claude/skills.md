# skills.md — which skill, when

Three skills are installed for this project (two others, `brand-guidelines`
and `theme-factory`, turned out not to apply — see below).

> **Verify this file before trusting it.** The mapping below is inferred
> from skill *names*, not from reading the skills themselves — they
> weren't visible in the session that wrote this. Run `find-skills` once
> at the start, confirm each skill's real description and trigger
> conditions, and if reality differs from this file, correct this file in
> the same turn and say what changed.

## The five (as originally installed)

| Skill | Assumed purpose | Stage |
|---|---|---|
| `find-skills` | Discovery — what exists, what each actually does | first, once |
| ~~`brand-guidelines`~~ | **Wrong fit (corrected 2026-08-15).** This is Anthropic's own corporate color/font kit for docs and slides — it applies *Anthropic's* brand, not a tool for defining a project's own voice. Not useful here. | skip |
| ~~`theme-factory`~~ | **Wrong fit (corrected 2026-08-15).** 10 canned presets for slide decks (Ocean Depths, Sunset Boulevard, ...) — not a token generator. We have real tokens already (see below). Not useful here. | skip |
| `frontend-design` | Layout, hierarchy, component and motion design quality | 1 |
| `web-artifacts-builder` | Assembling the self-contained HTML artifact | 2 |

Identity is already written down in `CLAUDE.md`'s Brand line — self-aware,
playful, faintly uncertain, never corporate, the domain as the joke.

Tokens are already specified in the design handoff (`maybeit-work-design-spec.md`
/ the zip README, gitignored, kept local) — exact hex values for light/dark,
Inter + IBM Plex Mono, spacing, and a beat-by-beat motion timing table. That
handoff *is* the theme-factory output for this project; don't run a preset
picker over it.

## The pipeline — full build or full redesign only

Run in order. Each stage's output is the next stage's input. This is the
nesting case Ex asked about — it applies here and mostly nowhere else.

0. **`find-skills`** — confirm the two real skills below do what this
   file claims. Once per project, not per task.
1. **Identity** (no skill) — the wordplay `maybeit.work` / "maybe it
   works," self-aware, playful, faintly uncertain, never corporate.
   Already settled in `CLAUDE.md`.
2. **Tokens** (no skill) — colour scale, type scale, spacing, motion
   timing. Already settled in the design handoff doc, confirm with Ex
   only where it's ambiguous (e.g. the canvas-vs-rail call already made).
3. **`frontend-design`** — design the actual sections using those tokens.
   Layout, hierarchy, what moves, why it moves, and in what order.
4. **`web-artifacts-builder`** — assemble into the single self-contained
   `index.html`. This is construction; the design decisions should
   already be settled before it runs.

Pass each stage's output forward explicitly. Don't let stage 3 re-invent
a palette stage 2 already produced — that's how a pipeline quietly stops
being a pipeline.

## When NOT to run the pipeline

Most tasks are not a full build. Running the whole pipeline to change a
button colour wastes tokens and reopens decisions that were already
settled.

| Task | Use |
|---|---|
| Copy edit, typo, wording | none |
| Tweak one animation's duration or easing | none — the tokens exist |
| Add a section in the established style | `frontend-design` only |
| Change the palette or type scale | edit the tokens directly, then apply forward |
| Rethink voice, naming, personality | edit `CLAUDE.md`'s Brand line, then apply forward |
| Rebuild or restructure the whole page | full pipeline |
| Genuinely unsure which applies | `find-skills` |

Rule of thumb: **enter at the stage that owns the decision being changed,
then run forward from there.** Never re-run a stage whose output you
already have and aren't changing.

## Hard rails beat skill recommendations

A skill suggesting something this project forbids doesn't override the
project. Common collisions to expect:

- **A CDN font, icon set, or animation package** conflicts with hard
  rails 1, 2, and 5. Adapt the idea — inline it, or rebuild it CSS-first.
  Never quietly add the dependency because a skill suggested it.
- **Any proposed motion** must still animate only `transform`/`opacity`
  and honor `prefers-reduced-motion` (rails 4 and 7).
- **`web-artifacts-builder` output** must remain one file making zero
  external requests (rails 1 and 2).

If a skill's recommendation and a hard rail genuinely can't be
reconciled, the rail wins. Name the two things in conflict and ask —
don't resolve it silently in either direction.

## Keeping this file honest

- Correct the table the moment `find-skills` shows something different.
- If a skill turns out to be useless for this project, say so here rather
  than leaving it listed and unused.
- If a sixth skill gets installed and earns a place in the pipeline, add
  it with its stage. If it doesn't, don't list it.

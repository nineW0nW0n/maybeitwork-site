# skills.md — which skill, when

Five skills are installed for this project.

> **Verify this file before trusting it.** The mapping below is inferred
> from skill *names*, not from reading the skills themselves — they
> weren't visible in the session that wrote this. Run `find-skills` once
> at the start, confirm each skill's real description and trigger
> conditions, and if reality differs from this file, correct this file in
> the same turn and say what changed.

## The five

| Skill | Assumed purpose | Stage |
|---|---|---|
| `find-skills` | Discovery — what exists, what each actually does | first, once |
| `brand-guidelines` | Identity: voice, personality, brand rules | 1 |
| `theme-factory` | Design tokens: palette, type scale, spacing, motion timing | 2 |
| `frontend-design` | Layout, hierarchy, component and motion design quality | 3 |
| `web-artifacts-builder` | Assembling the self-contained HTML artifact | 4 |

## The pipeline — full build or full redesign only

Run in order. Each stage's output is the next stage's input. This is the
nesting case Ex asked about — it applies here and mostly nowhere else.

1. **`find-skills`** — confirm the four below do what this file claims.
   Once per project, not per task.
2. **`brand-guidelines`** — establish identity before any visual work.
   The brand is the wordplay: `maybeit.work` / "maybe it works."
   Self-aware, playful, faintly uncertain, never corporate. Everything
   downstream expresses this, so don't skip ahead to colours.
3. **`theme-factory`** — turn that identity into tokens: colour scale,
   type scale, spacing rhythm, and motion timing. Durations and easing
   curves are design decisions here, not defaults chosen later in code.
4. **`frontend-design`** — design the actual sections using those tokens.
   Layout, hierarchy, what moves, why it moves, and in what order.
5. **`web-artifacts-builder`** — assemble into the single self-contained
   `index.html`. This is construction; the design decisions should
   already be settled before it runs.

Pass each stage's output forward explicitly. Don't let stage 4 re-invent
a palette stage 3 already produced — that's how a pipeline quietly stops
being a pipeline.

## When NOT to run the pipeline

Most tasks are not a full build. Running five skills to change a button
colour wastes tokens and reopens decisions that were already settled.

| Task | Use |
|---|---|
| Copy edit, typo, wording | none |
| Tweak one animation's duration or easing | none — the tokens exist |
| Add a section in the established style | `frontend-design` only |
| Change the palette or type scale | `theme-factory`, then apply forward |
| Rethink voice, naming, personality | `brand-guidelines`, then forward |
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

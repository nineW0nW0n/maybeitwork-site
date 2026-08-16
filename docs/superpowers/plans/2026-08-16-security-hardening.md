# maybeit.work Security Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every finding from the 2026-08-16 security audit of
`nineW0nW0n/maybeitwork-site`, and re-sync the vendored copy of the page that
the Cloudflare Worker serves.

**Architecture:** Five independent tasks, each one commit. Tasks 1–2 harden
the GitHub Actions supply chain (`.github/workflows/ci.yml`). Tasks 3–4 harden
the page's own JavaScript (`index.html`) — one input-validation fix, one
removal of the file's single `innerHTML` sink, plus a grep rail so the sink
cannot come back. Task 5 crosses into the homelab repo to re-copy the page
into the Worker and add one missing response header.

**Tech Stack:** Plain HTML/CSS/JS in one self-contained file, no build step.
GitHub Actions for CI. Cloudflare Workers (`wrangler`) for the deploy, in a
different repository.

**Spec:** This plan implements the findings in the security audit performed in
session `a7157f29-ee82-4836-a7a4-bd5acd2839ad` on 2026-08-16. There is no
separate spec document; the "Audit findings" section below is the spec, and it
carries everything the executor needs.

---

## Handoff — read this first

**Model note:** this plan is written for a Sonnet session with **zero prior
context**. Everything needed is in this file. Do not go looking for the audit
transcript; it is gone.

**Two repositories are involved.**

| Repo | Path | Role in this plan |
|---|---|---|
| `nineW0nW0n/maybeitwork-site` | `~/maybeitwork_site` | Tasks 1–4. Public. Design source of truth for the page. |
| `nineW0nW0n/homelab-but-the-home-is-silent` | `~/homelab-but-the-home-is-silent` | Task 5 only. The Cloudflare Worker that actually serves `maybeit.work`. |

**Before you touch either repo, read its instructions:**

- Site repo: `~/maybeitwork_site/.claude/CLAUDE.md`. Its hard rails and its
  "Definition of done" checklist govern Tasks 1–4.
- Homelab repo: `~/homelab-but-the-home-is-silent/.claude/CLAUDE.md` **and**
  `~/homelab-but-the-home-is-silent/worker/status/CLAUDE.md`. Both govern
  Task 5. Root wins if they conflict.

**Things that will bite you if nobody tells you:**

1. `~/maybeitwork_site/index.html` and
   `~/homelab-but-the-home-is-silent/worker/status/src/page.html` are
   **byte-identical copies of each other** — a deliberate copy-paste vendoring,
   not a submodule. Verified identical at the time this plan was written. Any
   change to `index.html` in Tasks 3 or 4 is not live on `maybeit.work` until
   Task 5 re-copies it.
2. Pushing to `main` in the **homelab** repo with anything under
   `worker/status/**` changed **auto-deploys the live site** via
   `.github/workflows/deploy-worker.yml`. Task 5 is a production deploy. Treat
   it as one.
3. The homelab repo's `main` is protected against deletion and force-push by a
   GitHub ruleset. You cannot rewrite history there. Plan on `git revert`.
4. The homelab repo has a real `pre-commit` gate (`pre-commit run --all-files`)
   and its `validate.yml` runs it in CI. The site repo has **no** pre-commit; its
   gate is the four CI jobs plus a manual browser check.
5. **Biome does not parse HTML.** `biome ci .` in the site repo lints nothing
   but `biome.json` itself. Never report "lint passed" as coverage of
   `index.html`. The real gate for `index.html` is `scripts/check-rails.sh`,
   `html-validate`, and your own eyes in a browser.
6. `index.html` is 742 lines but ~137 KB — most of it is two base64 `woff2`
   fonts on single enormous lines. Any `grep` you run against it should be
   piped through `grep -v base64` first or the output will be unreadable.

**Out of scope — do not touch.** There is a separate open security item Ex owns
personally (a GitHub garbage-collection request on the homelab repo). It is not
in this plan and no task here affects it.

## Audit findings this plan closes

| # | Severity | Finding | Task |
|---|---|---|---|
| 1 | MED | `ci.yml` runs `npx --yes @biomejs/biome` and `npx --yes html-validate`, both resolving `latest` on every run; `pip install yamllint` likewise. Compromised publish executes in the runner. | 1 |
| 2 | MED | `ci.yml` has no `permissions:` block, so `GITHUB_TOKEN` gets the repo default (read/write) and is handed to finding 1's unpinned code. | 1 |
| 3 | LOW-MED | Actions pinned to mutable tags (`actions/checkout@v4`, `setup-node@v4`, `setup-python@v5`). | 1 |
| 7 | INFO | No secret scanning in the site repo's CI. History is clean today; nothing stops a future slip in a public repo. | 2 |
| 6 | LOW | `/status.json` validator accepts `NaN` and `Infinity` — `typeof NaN === 'number'` is `true`. Renders `LNaN`. Cosmetic, not exploitable. | 3 |
| 4 | LOW | `index.html` has exactly one `innerHTML` sink. Safe today by construction, enforced by nothing. One future edit that puts a label in that template turns a spoofed `/status.json` into stored XSS. | 4 |
| 5 | — | **Already fixed, verify only.** The Worker already sends a full CSP plus `x-content-type-options` and `referrer-policy` on the page response. `/status.json` is missing `nosniff`. | 5 |

Findings 1, 2, 3 and 7 are the repo's actual attack surface. Do those first.

## Global Constraints

Copied verbatim from the two repos' instructions. Every task's requirements
implicitly include this section.

- **Site repo, rail 1:** one self-contained file. `index.html` with inline
  `<style>` and `<script>`. No bundler, no build step, no npm dependency
  shipped in the page. **Do not add a test framework or a test file to the site
  repo.** Checks in this plan are one-liners you run, not files you commit.
- **Site repo, rail 2:** no external runtime requests. The single allowed
  exception is one same-origin `GET /status.json` on load, with an ~800 ms
  `AbortController` timeout, validated before use, failing silently to the
  built-in fallback values.
- **Site repo, rail 6:** content must survive JS failing. Never park text at
  `opacity: 0` waiting for a script.
- **Site repo, rail 7:** `prefers-reduced-motion: reduce` is honored.
- **Site repo, rail 8:** mobile is the default viewport; design at 375px first.
- **Site repo:** if `index.html` passes ~1500 lines, say so and propose a
  split; never split silently. It is at 742 now — no action.
- **Both repos:** pin exact versions and commits. Never `latest`, never a
  floating tag.
- **Both repos:** never print secret material in full — tokens, key contents,
  `.env` values. Redact as `***redacted***`.
- **Commit style:** conventional commits, atomic, one task per commit. Prose in
  commit messages is normal English, not compressed.
- **Ex is not an engineer.** Before a non-trivial change, explain in plain terms
  what and why in 1–3 sentences — before doing it, not after.

**Exact pinned versions resolved 2026-08-16.** Use these values literally; do
not re-resolve them to something newer without saying so.

| Thing | Pin | Comment to write next to it |
|---|---|---|
| `@biomejs/biome` | `2.5.8` | must match `biome.json`'s `$schema` |
| `html-validate` | `11.6.2` | |
| `yamllint` | `1.38.0` | |
| `actions/checkout` | `11d5960a326750d5838078e36cf38b85af677262` | `# v4.4.0` |
| `actions/setup-node` | `49933ea5288caeca8642d1e84afbd3f7d6820020` | `# v4.4.0` |
| `actions/setup-python` | `a26af69be951a213d495a4c3e4e4022e16d87065` | `# v5.6.0` |
| `gitleaks/gitleaks-action` | `ff98106e4c7b2bc287b24eaf42907196329070c7` | `# v2.3.9` |
| `gitleaks` binary (fallback) | `v8.30.1` | |

## File Structure

**Site repo — `~/maybeitwork_site`:**

- Modify `.github/workflows/ci.yml` — Tasks 1 and 2. The whole CI gate. Both
  tasks rewrite it in full; Task 2's version is Task 1's plus one job.
- Modify `index.html` — Tasks 3 and 4. Task 3 edits one line inside the
  `/status.json` validator. Task 4 edits the `Scene` class's `set()` method and
  its one metric-rendering caller, and the constructor.
- Modify `scripts/check-rails.sh` — Task 4. Adds one grep so the removed
  `innerHTML` sink cannot silently return.
- Create `docs/superpowers/plans/2026-08-16-security-hardening.md` — this file.
  This is the repo's first `docs/` directory. Do **not** create a
  `docs/CLAUDE.md`; the site repo's instructions say not to add structure
  speculatively, and one plan file does not justify it.

**Homelab repo — `~/homelab-but-the-home-is-silent`:**

- Modify `worker/status/src/page.html` — Task 5. Replaced wholesale by a copy
  of the site repo's `index.html`. Never hand-edited.
- Modify `worker/status/src/index.js` — Task 5. Adds `nosniff` to the
  `/status.json` response and updates one now-load-bearing comment.

---

### Task 1: Pin the CI supply chain and drop `GITHUB_TOKEN` to read-only

Closes findings 1, 2, 3.

**Files:**
- Modify: `~/maybeitwork_site/.github/workflows/ci.yml` (whole file)
- Test: none — this repo has no test runner. `actionlint` and a real CI run are
  the check.

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: a `ci.yml` with jobs named `yamllint`, `biome`, `rails`,
  `html-validate`, a top-level `permissions:` block, and every `uses:` pinned to
  a 40-character commit SHA. Task 2 appends a fifth job to exactly this file.

**Plain-terms explanation to give Ex before starting:** CI currently downloads
whatever the newest version of three tools happens to be, every single run, and
runs them with a GitHub token that can write to the repo. Pinning the versions
and making the token read-only means a bad release of someone else's tool
cannot touch this repo.

- [ ] **Step 1: Confirm the starting state and that the pins are real**

```bash
cd ~/maybeitwork_site
git status --short
git log --oneline -1
grep -n "npx --yes\|pip install\|uses:" .github/workflows/ci.yml
```

Expected: working tree clean. The grep prints three unpinned installs
(`pip install yamllint`, `npx --yes @biomejs/biome ci .`,
`npx --yes html-validate index.html`) and seven `uses:` lines on floating tags —
`actions/checkout@v4` appears four times, once in every job.

- [ ] **Step 2: Verify each pinned SHA actually points at the tag it claims**

```bash
gh api repos/actions/checkout/git/ref/tags/v4 --jq .object.sha
gh api repos/actions/setup-node/git/ref/tags/v4 --jq .object.sha
gh api repos/actions/setup-python/git/ref/tags/v5 --jq .object.sha
```

Expected, in order:

```
11d5960a326750d5838078e36cf38b85af677262
49933ea5288caeca8642d1e84afbd3f7d6820020
a26af69be951a213d495a4c3e4e4022e16d87065
```

If any value differs, the tag has moved since this plan was written. **Stop and
tell Ex.** Do not silently adopt the new SHA — a moved tag on an official action
is exactly the event finding 3 is about.

- [ ] **Step 3: Write the complete new `ci.yml`**

Replace `~/maybeitwork_site/.github/workflows/ci.yml` with this file in full:

```yaml
---
name: ci

on:
  push:
    branches: [main]
  pull_request:

# Read-only by default. No job here writes to the repo, and CI runs
# third-party tooling, so the token it runs under gets nothing.
permissions:
  contents: read

jobs:
  yamllint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262  # v4.4.0
      - uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065  # v5.6.0
        with:
          python-version: "3.12"
      # Pinned exactly. An unpinned install runs whatever was published
      # most recently, in a runner holding this repo's token.
      - run: pip install yamllint==1.38.0
      - run: yamllint --strict .

  biome:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262  # v4.4.0
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v4.4.0
        with:
          node-version: "22"
      # Version must match biome.json's $schema. Covers standalone
      # .js/.css/.json only -- index.html's inline <style>/<script> are
      # not parsed by biome, see the rails job below.
      - run: npx --yes @biomejs/biome@2.5.8 ci .

  rails:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262  # v4.4.0
      - run: sh scripts/check-rails.sh

  html-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262  # v4.4.0
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020  # v4.4.0
        with:
          node-version: "22"
      - run: |
          if [ -f index.html ]; then
            npx --yes html-validate@11.6.2 index.html
          else
            echo "no index.html yet — nothing to validate"
          fi
```

- [ ] **Step 4: Verify the file lints and nothing floats**

```bash
cd ~/maybeitwork_site
yamllint --strict .github/workflows/ci.yml
grep -cE "uses: [^@]+@[0-9a-f]{40}" .github/workflows/ci.yml
grep -nE "@v[0-9]|--yes [^@]+ |pip install yamllint$" .github/workflows/ci.yml
```

Expected: `yamllint` prints nothing and exits 0. The count is `7` — four
`checkout`, two `setup-node`, one `setup-python`. The last grep prints nothing
and exits 1 — no floating tag, no unpinned install survives.

If `yamllint` is not installed locally, install it pinned:
`pip install --break-system-packages yamllint==1.38.0`.

- [ ] **Step 5: Verify the workflow is still structurally valid**

```bash
cd ~/maybeitwork_site
actionlint .github/workflows/ci.yml
```

Expected: no output, exit 0.

If `actionlint` is not installed, run it through Docker instead:
`docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:1.7.7 -color`.
If neither is available, say so plainly in your summary and rely on the real CI
run in Step 7 — do not claim the workflow was linted when it was not.

- [ ] **Step 6: Commit**

```bash
cd ~/maybeitwork_site
git add .github/workflows/ci.yml
git commit -m "ci: pin every action and tool version, drop token to read-only

CI resolved @biomejs/biome, html-validate and yamllint to whatever was
published most recently, on every run, and handed them a GITHUB_TOKEN with
the repository default permissions. A compromised release of any of the
three would have executed with write access to this repo.

Pins all three to exact versions, pins the three official actions to commit
SHAs rather than mutable tags, and adds a top-level read-only permissions
block. Biome is pinned to 2.5.8 to match biome.json's \$schema.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
```

- [ ] **Step 7: Push and confirm all four jobs pass**

```bash
cd ~/maybeitwork_site
git push
sleep 45
gh run list --limit 1
gh run watch "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
```

Expected: all four jobs green. If a job fails, read the log with
`gh run view --log-failed` before changing anything.

**Rollback:**

```bash
cd ~/maybeitwork_site
git revert --no-edit HEAD
git push
```

`main` in the site repo is not force-push protected, but revert anyway — it
leaves the audit trail intact and re-triggers CI so you can see green again.
Confirm with `git log --oneline -2` showing the revert on top.

**Plan B — if a pin turns out to be wrong:**

- *A pinned npm version does not exist* (`npm ERR! No matching version`): run
  `npm view @biomejs/biome versions --json` (or `html-validate`) and pick the
  newest version that is **not** a prerelease. If you change the Biome pin, you
  **must** also change `biome.json`'s `$schema` URL to the same version in the
  same commit — a mismatch between them is a known past failure in this
  codebase's sibling repo.
- *`pip install yamllint==1.38.0` fails on the runner's Python*: drop to
  `yamllint==1.35.1`, which supports older Pythons, and pin
  `python-version: "3.11"` alongside it.
- *An official action's SHA no longer resolves* (repo re-tagged or force-pushed
  a release branch): pin to the SHA of the newest release tag you can verify via
  `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, then
  `gh api repos/<owner>/<repo>/git/ref/tags/<tag> --jq .object.sha`. Note the
  substitution in your summary.
- *Pinning proves impossible for one tool inside 15 minutes*: land the
  `permissions: contents: read` block and the SHA pins on their own — those are
  independent of the npm pins and carry most of the risk reduction. Leave the
  one unpinnable tool as a stated follow-up rather than blocking the other two
  findings.

---

### Task 2: Add secret scanning to CI

Closes finding 7.

**Files:**
- Modify: `~/maybeitwork_site/.github/workflows/ci.yml` (append one job)
- Test: none — a deliberate fake secret, scanned and then removed, is the check.

**Interfaces:**
- Consumes: the `ci.yml` produced by Task 1. If Task 1 has not landed, stop and
  do it first — this task's diff assumes the pinned, `permissions:`-bearing
  file.
- Produces: a fifth job named `gitleaks` in the same file. No later task depends
  on it.

**Plain-terms explanation to give Ex before starting:** this repo is public and
has nothing stopping a password or API key from being committed by accident. The
homelab repo already has this check; the site repo does not. One CI job closes
the gap. Nothing is wrong today — I scanned the full history and it is clean.

- [ ] **Step 1: Confirm the history really is clean before adding the gate**

```bash
cd ~/maybeitwork_site
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:v8.30.1 \
  detect --source=/repo --redact --no-banner
```

Expected: `no leaks found`. If it reports a finding, **stop and tell Ex** —
adding the CI job on top of a real leak turns every future push red and buries
the actual problem. Note that the two base64 `woff2` fonts inside `index.html`
are long high-entropy strings and are a plausible false positive; if the finding
is one of those, that is what `.gitleaksignore` is for, but check with Ex before
adding one.

- [ ] **Step 2: Add the `gitleaks` job to `ci.yml`**

Append this job to the end of `.github/workflows/ci.yml`, at the same
indentation as the existing `html-validate` job:

```yaml

  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262  # v4.4.0
        with:
          # gitleaks scans history, not just the tip commit -- a shallow
          # clone silently scans one commit and reports clean.
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@ff98106e4c7b2bc287b24eaf42907196329070c7  # v2.3.9
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The action is free for public repositories; no `GITLEAKS_LICENSE` is needed. The
`GITHUB_TOKEN` here is the read-only one from Task 1's `permissions:` block.

- [ ] **Step 3: Verify the file still lints**

```bash
cd ~/maybeitwork_site
yamllint --strict .github/workflows/ci.yml
actionlint .github/workflows/ci.yml
```

Expected: both silent, exit 0.

- [ ] **Step 4: Prove the job actually catches something**

This is the step that separates a working gate from a decorative one. Create a
throwaway file with a fake credential, scan locally, then delete it.

```bash
cd ~/maybeitwork_site
printf 'aws_secret_access_key = "AKIAIOSFODNN7EXAMPLE"\n' > /tmp/leak-probe.txt
cp /tmp/leak-probe.txt ./leak-probe.txt
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:v8.30.1 \
  detect --source=/repo --no-git --redact --no-banner; echo "exit=$?"
rm -f ./leak-probe.txt /tmp/leak-probe.txt
git status --short
```

Expected: the scan reports at least one finding and `exit=1`. `git status`
afterwards shows only the modified `ci.yml` — the probe file is gone. If the
scan exits 0, the gate does not work; do not commit it, and report that.

- [ ] **Step 5: Commit**

```bash
cd ~/maybeitwork_site
git add .github/workflows/ci.yml
git commit -m "ci: add gitleaks secret scanning

This repository is public and had no secret scanning at all, while the
homelab repo it deploys from has had it via pre-commit for some time. The
history is clean today -- verified with a full gitleaks scan before adding
the job -- so this is a gate against a future accident, not a remediation.

fetch-depth: 0 is required; a shallow clone makes gitleaks scan a single
commit and report clean.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
```

- [ ] **Step 6: Push and confirm five jobs pass**

```bash
cd ~/maybeitwork_site
git push
sleep 45
gh run watch "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
```

Expected: five green jobs, `gitleaks` among them.

**Rollback:**

```bash
cd ~/maybeitwork_site
git revert --no-edit HEAD
git push
```

**Plan B — if `gitleaks-action` will not run:**

- *The action demands a `GITLEAKS_LICENSE`*: it should not on a public repo, but
  if it does, drop the action entirely and run the pinned container instead.
  Replace the `uses:` step with:

```yaml
      - run: |
          docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:v8.30.1 \
            detect --source=/repo --redact --no-banner
```

  This is arguably the better version anyway — one fewer third-party action, and
  the same pin discipline as Task 1. Prefer it if you hit any friction at all.
- *The full-history scan is slow or flaky on a 13-commit repo*: it will not be,
  but if it is, scan the working tree only with `--no-git` and say in your
  summary that history coverage was traded away.
- *A base64 font trips a false positive that cannot be tuned out*: add a
  `.gitleaksignore` with the specific finding fingerprint the scan prints — not
  a broad path exclusion of `index.html`, which would disable the check for the
  one file most likely to carry a mistake. Ask Ex before committing it.

---

### Task 3: Reject non-finite numbers from `/status.json`

Closes finding 6.

**Files:**
- Modify: `~/maybeitwork_site/index.html:201`
- Test: a `node -e` one-liner. **Do not create a test file** — site repo rail 1.

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: nothing later tasks depend on, except that Task 5 copies the
  resulting `index.html` wholesale.

**Plain-terms explanation to give Ex before starting:** the page checks that the
numbers coming back from the status endpoint are numbers, but JavaScript counts
`NaN` and `Infinity` as numbers. If the endpoint ever returned one, the status
bar would print `LNaN` instead of falling back to the built-in values. One word
fixes it. This is a display bug, not a security hole.

- [ ] **Step 1: Confirm the current line**

```bash
cd ~/maybeitwork_site
sed -n '199,205p' index.html
```

Expected output includes:

```
    const isNum = v => typeof v === 'number';
```

If the line number has drifted, find it with
`grep -n "const isNum" index.html` and use whatever it reports.

- [ ] **Step 2: Prove the current check is wrong**

```bash
node -e '
const isNum = v => typeof v === "number";
console.assert(isNum(NaN) === true, "expected NaN to slip through");
console.assert(isNum(Infinity) === true, "expected Infinity to slip through");
const quant = pct => Math.max(0, Math.min(10, Math.round(pct / 10)));
console.log("NaN renders as:", "L" + String(quant(NaN)).padStart(2, "0"));
'
```

Expected: prints `NaN renders as: LNaN`, no assertion failures. That is the bug,
reproduced.

- [ ] **Step 3: Make the change**

Replace this exact line in `index.html`:

```javascript
    const isNum = v => typeof v === 'number';
```

with:

```javascript
    // Number.isFinite, not `typeof === 'number'` -- the latter accepts NaN
    // and Infinity, which quant() then renders as the literal string "LNaN".
    const isNum = v => Number.isFinite(v);
```

- [ ] **Step 4: Prove the new check is right**

```bash
node -e '
const isNum = v => Number.isFinite(v);
console.assert(isNum(NaN) === false, "NaN must be rejected");
console.assert(isNum(Infinity) === false, "Infinity must be rejected");
console.assert(isNum(-Infinity) === false, "-Infinity must be rejected");
console.assert(isNum("41") === false, "strings must still be rejected");
console.assert(isNum(null) === false, "null must still be rejected");
console.assert(isNum(0) === true, "0 must still pass");
console.assert(isNum(41) === true, "41 must still pass");
console.assert(isNum(-3.5) === true, "negatives must still pass");
console.log("ok");
'
```

Expected: prints `ok`, no `Assertion failed` lines. Any assertion failure means
stop.

- [ ] **Step 5: Confirm the page still validates and the rails still pass**

```bash
cd ~/maybeitwork_site
sh scripts/check-rails.sh
npx --yes html-validate@11.6.2 index.html
```

Expected: `check-rails.sh` prints its informational line count and exits 0;
`html-validate` reports no errors.

- [ ] **Step 6: Commit**

```bash
cd ~/maybeitwork_site
git add index.html
git commit -m "fix: reject NaN and Infinity from /status.json

The validator checked typeof v === 'number', which is true for NaN and
Infinity. A status endpoint returning either would pass validation, replace
the built-in fallback values, and render the literal string LNaN in the
status bar rather than falling back silently as the data contract promises.

Number.isFinite rejects both while still rejecting strings and null.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
```

**Rollback:**

```bash
cd ~/maybeitwork_site
git revert --no-edit HEAD
```

**Plan B:** there is no plausible failure mode for this change — `Number.isFinite`
is a strict subset of the old predicate, so nothing that passed before and should
still pass can now fail. If somehow a real `/status.json` response starts failing
validation after this, that means the endpoint is genuinely emitting `NaN`, which
is a bug in `worker/status/src/poll.js` in the homelab repo, not here. In that
case leave this change in place and report the endpoint bug — do not widen the
validator to accept `NaN` again.

---

### Task 4: Remove the only `innerHTML` sink and add a rail against its return

Closes finding 4.

**Files:**
- Modify: `~/maybeitwork_site/index.html` — the `Scene` constructor (~line 630),
  the `set()` method (~line 655), and the metric-rendering block (~line 722)
- Modify: `~/maybeitwork_site/scripts/check-rails.sh`
- Test: a browser check against a stubbed `/status.json`. **Do not create a test
  file** — site repo rail 1.

**Interfaces:**
- Consumes: Task 3's `index.html`. Land Task 3 first so the two edits do not
  collide in the same region of the file.
- Produces: an `index.html` where `set()` accepts only `'text'` and CSS property
  names, with no `'html'` branch. Task 5 copies the result.

**Plain-terms explanation to give Ex before starting:** the page builds the
`L07 C04 M03` readout by assembling an HTML string and injecting it. Right now
that string only ever contains our own colours and numbers, so there is no way
in — but nothing enforces that. If someone later drops a node name into it, a
tampered status endpoint could inject code into the page. Building the same
readout out of real elements instead removes the possibility entirely, and one
line in the rails script stops it coming back.

- [ ] **Step 1: Confirm the sink and its only caller**

```bash
cd ~/maybeitwork_site
grep -vE base64 index.html | grep -nE "innerHTML|'html'"
```

Expected: two hits — the `else if (prop === 'html') el.innerHTML = v;` line
inside `set()`, and one `this.set(val, 'html', html);` call. If there is a third,
**stop and re-audit** — this plan assumes exactly one caller.

- [ ] **Step 2: Confirm no untrusted value reaches the template**

```bash
cd ~/maybeitwork_site
grep -vE base64 index.html | grep -nE "\.name"
```

Expected: exactly one hit, inside the `/status.json` validator. The `name` field
is validated but never rendered — the `VPS00`/`VPS01`/`VPS02` labels are literal
text in the HTML. This is why the finding is LOW and not HIGH. If `.name` now
appears inside a template literal, the severity changes and you should tell Ex
before continuing.

- [ ] **Step 3: Add a second `WeakMap` to the `Scene` constructor**

Find this block in `index.html`:

```javascript
class Scene {
  constructor() {
    this.els = {};
    ['cv','scan','grain','boot','h1','h2','bar','pct','tl','td','d0','d1','d2','d3','v0','v1','v2','v3'].forEach(id => {
      this.els[id] = document.getElementById(id);
    });
    this._w = new WeakMap();
  }
```

Replace the `this._w = new WeakMap();` line with:

```javascript
    this._w = new WeakMap();
    this._m = new WeakMap(); // metric <span>s per value element, built once
```

- [ ] **Step 4: Delete the `'html'` branch from `set()`**

Find this method:

```javascript
  set(el, prop, v) {
    if (!el) return;
    let m = this._w.get(el); if (!m) { m = {}; this._w.set(el, m); }
    if (m[prop] === v) return;
    m[prop] = v;
    if (prop === 'text') el.textContent = v;
    else if (prop === 'html') el.innerHTML = v;
    else el.style[prop] = v;
  }
```

Replace it in full with:

```javascript
  // No 'html' branch, deliberately: this class must never have a way to
  // write markup. The metric readout builds real <span>s instead, see
  // chrome(). scripts/check-rails.sh greps for innerHTML to keep it that way.
  set(el, prop, v) {
    if (!el) return;
    let m = this._w.get(el); if (!m) { m = {}; this._w.set(el, m); }
    if (m[prop] === v) return;
    m[prop] = v;
    if (prop === 'text') el.textContent = v;
    else el.style[prop] = v;
  }
```

- [ ] **Step 5: Replace the metric-rendering block**

Find this block (inside `chrome()`, in the `SERVICES.forEach` loop, after the
`if (t < race) { ... return; }` early return):

```javascript
      const html = METRIC_KEYS.map(([letter, key]) => {
        const target = quant(s[key]);
        let n;
        if (t < top) n = 10 * eo(seg(t, race, top));
        else n = 10 - (10 - target) * eo(seg(t, top, land));
        const v10 = Math.round(n);
        const color = v10 <= 0 ? T.ink3 : v10 >= 8 ? T.badHex : T.okHex;
        return `<span style="color:${color}">${letter}${String(v10).padStart(2, '0')}</span>`;
      }).join(' ');
      this.set(val, 'html', html);
      this.set(val, 'opacity', '1');
```

Replace it in full with:

```javascript
      // Five real <span>s, built once and then only ever written through
      // textContent/style. The TAPPING branch above sets textContent on
      // `val`, which wipes them, so re-create whenever they're gone --
      // firstElementChild is the cheap way to notice.
      let spans = this._m.get(val);
      if (!spans || val.firstElementChild !== spans[0]) {
        val.textContent = '';
        spans = METRIC_KEYS.map((_, j) => {
          if (j) val.appendChild(document.createTextNode(' '));
          return val.appendChild(document.createElement('span'));
        });
        this._m.set(val, spans);
      }
      METRIC_KEYS.forEach(([letter, key], j) => {
        const target = quant(s[key]);
        let n;
        if (t < top) n = 10 * eo(seg(t, race, top));
        else n = 10 - (10 - target) * eo(seg(t, top, land));
        const v10 = Math.round(n);
        const txt = `${letter}${String(v10).padStart(2, '0')}`;
        if (spans[j].textContent !== txt) spans[j].textContent = txt;
        spans[j].style.color = v10 <= 0 ? T.ink3 : v10 >= 8 ? T.badHex : T.okHex;
      });
      this.set(val, 'opacity', '1');
```

The separator text nodes reproduce the old `.join(' ')` exactly — without them
the five readings run together as `L07C04M03S00D05`. Watch for that in Step 8;
it is the most likely way this task goes subtly wrong.

- [ ] **Step 6: Confirm no `innerHTML` remains**

```bash
cd ~/maybeitwork_site
grep -vE base64 index.html | grep -nE "innerHTML|outerHTML|insertAdjacentHTML|document\.write"
echo "exit=$?"
```

Expected: no output, `exit=1`.

- [ ] **Step 7: Add the rail so it cannot come back**

Open `~/maybeitwork_site/scripts/check-rails.sh`. Find the block that starts
with the comment `# Rail 7: reduced-motion must be honored somewhere in the
file.` and insert this **immediately before** it:

```sh
# Security: no markup-writing sinks. The metric readout used to assemble an
# HTML string and inject it -- safe only because nothing untrusted reached
# the template, which nothing enforced. It builds real <span>s now. Keep it
# that way: there is no reason this page ever needs to write markup.
if grep -vE 'base64' "$FILE" | grep -Eq 'innerHTML|outerHTML|insertAdjacentHTML|document\.write'; then
  fail "markup-writing sink found (innerHTML/outerHTML/insertAdjacentHTML/document.write) — use textContent and real elements"
fi
```

- [ ] **Step 8: Prove the rail fails when it should**

```bash
cd ~/maybeitwork_site
sh scripts/check-rails.sh; echo "clean exit=$?"
cp index.html /tmp/index.html.bak
printf '<script>document.body.innerHTML = "x"</script>\n' >> index.html
sh scripts/check-rails.sh; echo "dirty exit=$?"
cp /tmp/index.html.bak index.html
rm -f /tmp/index.html.bak
sh scripts/check-rails.sh; echo "restored exit=$?"
git diff --stat
```

Expected: `clean exit=0`, then the dirty run prints
`FAIL: markup-writing sink found ...` with `dirty exit=1`, then
`restored exit=0`. `git diff --stat` shows `index.html` and
`scripts/check-rails.sh` modified and nothing else — confirm `index.html`'s line
count did not grow by one from the probe.

A rail that passes but never fails is the exact class of mistake this repo's
sibling has hit three times. Do not skip this step.

- [ ] **Step 9: Verify the page still renders correctly in a real browser**

`check-rails.sh` cannot see whether the readout still looks right. This step is
the actual gate.

```bash
cd ~/maybeitwork_site
cat > status.json <<'EOF'
[
  {"name":"VPS00","load":24,"cpu":18,"mem":41,"swap":0,"disk":63},
  {"name":"VPS01","load":95,"cpu":88,"mem":91,"swap":0,"disk":97},
  {"name":"VPS02","load":33,"cpu":28,"mem":52,"swap":5,"disk":71}
]
EOF
python3 -m http.server 8000 >/tmp/site-server.log 2>&1 &
echo "$!" > /tmp/site-server.pid
```

Then, using the Chrome browser tools, open `http://localhost:8000/index.html`,
wait about 6 seconds for the animation to settle, and evaluate:

```javascript
(() => {
  const v = document.getElementById('v1');
  const spans = [...v.querySelectorAll('span')];
  return {
    text: v.textContent,
    spanCount: spans.length,
    labels: spans.map(s => s.textContent),
    allWellFormed: spans.every(s => /^[LCMSD]\d\d$/.test(s.textContent)),
    hasSpaces: /\s/.test(v.textContent),
    noMarkupLeak: !v.innerHTML.includes('&lt;'),
    reds: spans.filter(s => s.style.color).length
  };
})()
```

Expected: `spanCount` is `5`, `labels` reads roughly
`["L10","C09","M09","S00","D10"]` (VPS01 is deliberately in the danger band in
the stub), `allWellFormed` is `true`, `hasSpaces` is `true`, `noMarkupLeak` is
`true`, `reds` is `5`. `text` should read like `L10 C09 M09 S00 D10` — **with
spaces**. If the spaces are missing, Step 5's text nodes were dropped.

Also check by eye, per the repo's definition of done:

- Console is clean — no errors, no failed requests.
- Click `REPLAY`. The readout re-runs and lands correctly a second time; the
  spans are not duplicated or blanked.
- Click the theme toggle. Colours change and the readout stays readable.
- Resize to 375px wide. The readout collapses to `OK` / `DNGR` per node with no
  horizontal scroll, then widens back to five spans above 600px. **This is the
  path that wipes and rebuilds the spans — exercise it in both directions.**
- Enable `prefers-reduced-motion: reduce` and reload. The page skips to the
  settled frame; the readout is present and correct.
- Screenshot it and actually look at it.

Then clean up — the stub must not be committed:

```bash
cd ~/maybeitwork_site
kill "$(cat /tmp/site-server.pid)" 2>/dev/null
rm -f status.json /tmp/site-server.pid /tmp/site-server.log
git status --short
```

Expected: only `index.html` and `scripts/check-rails.sh` show as modified.
`status.json` must not appear.

- [ ] **Step 10: Run the remaining gates**

```bash
cd ~/maybeitwork_site
sh scripts/check-rails.sh
npx --yes html-validate@11.6.2 index.html
npx --yes @biomejs/biome@2.5.8 ci .
```

Expected: all three exit 0. Biome finding nothing to lint is a pass, not a skip.

- [ ] **Step 11: Commit**

```bash
cd ~/maybeitwork_site
git add index.html scripts/check-rails.sh
git commit -m "refactor: build the metric readout from real elements, not an HTML string

The status readout assembled a string of <span style=color:...> and wrote it
through innerHTML. It was safe -- the template interpolated only theme
constants and Math.round output, and the name field from /status.json is
validated but never rendered -- but nothing enforced that. One later edit
placing a node label in the template would have turned a tampered or spoofed
/status.json into stored XSS.

Builds five spans once per value element and writes textContent and
style.color instead. Separator text nodes reproduce the previous join(' ').
Removes the 'html' branch from Scene.set entirely, so the class no longer
has any way to write markup, and adds a check-rails.sh grep for innerHTML,
outerHTML, insertAdjacentHTML and document.write so it cannot return
unnoticed. The grep was verified to fail on a deliberately reintroduced sink,
not just to pass on a clean file.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
```

- [ ] **Step 12: Push and confirm CI is green**

```bash
cd ~/maybeitwork_site
git push
sleep 45
gh run watch "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
```

**Rollback:**

```bash
cd ~/maybeitwork_site
git revert --no-edit HEAD
git push
```

If Task 5 has already shipped by the time you roll back, the Worker is serving
the new page and you must revert there too — see Task 5's rollback.

**Plan B — if the DOM rewrite misbehaves:**

- *The readout flickers, blanks, or duplicates on `REPLAY` or across the 600px
  breakpoint*: the rebuild guard is the suspect. Replace
  `if (!spans || val.firstElementChild !== spans[0])` with an unconditional
  rebuild — `val.textContent = ''` and re-create the spans every frame. It is
  wasteful (15 nodes per frame across three services) but correct, and this page
  has budget to spare. Add a `ponytail:` comment naming the cost.
- *Spacing between the five readings looks wrong and text nodes do not fix it*:
  set `letter-spacing`/`word-spacing` aside and instead give the `.hud-val`
  element `display: inline-flex; gap: 4px` in the inline `<style>` block, and
  drop the separator text nodes. Verify at 375px and 1440px both — this changes
  layout, which the repo's rail 4 is sensitive about, so check for jank.
- *The whole rewrite proves messier than expected*: fall back to keeping the
  string template but escaping the sink shut — assert the interpolated values
  are safe by construction with
  `const v10 = Math.max(0, Math.min(10, Math.round(n) || 0));` and leave
  `innerHTML` in place. **This is strictly worse** and does not close the
  finding, so if you take it, do **not** add the `check-rails.sh` grep (it would
  fail), and say plainly in your summary that finding 4 remains open.
- *`check-rails.sh` cannot express the grep cleanly under `set -eu`*: the
  `if grep -q ...; then fail ...; fi` form given above is already the safe shape.
  Do not use the `grep ... && fail ... || true` shape the rail-4 keyframes check
  uses — it is harder to read and its exit-code handling is what makes that
  check fragile.

---

### Task 5: Re-sync the vendored page into the Worker and add `nosniff` to `/status.json`

Closes finding 5's remaining gap and ships Tasks 3–4 to production.

**Files:**
- Modify: `~/homelab-but-the-home-is-silent/worker/status/src/page.html`
  (replaced wholesale)
- Modify: `~/homelab-but-the-home-is-silent/worker/status/src/index.js`
- Test: `npm test` in `worker/status` (`node --test`, no framework)

**Interfaces:**
- Consumes: the `index.html` produced by Tasks 3 and 4. **Both must have landed
  and be pushed before this task starts.**
- Produces: a deployed Worker. Nothing depends on it afterwards.

**Plain-terms explanation to give Ex before starting, and get a yes:** this is
the step that actually puts the two page fixes on the live site. Pushing it
deploys `maybeit.work` automatically. The other change is one line adding a
header that tells browsers not to guess at the content type of the status data.
**Ask before pushing. This is the only task in the plan that touches
production.**

**Finding 5 status, so you do not redo work:** the Worker already sets a full
Content-Security-Policy plus `x-content-type-options: nosniff` and
`referrer-policy: no-referrer` on the *page* response — that was done in a
previous session and is correct as-is. **Do not rewrite `PAGE_HEADERS`.** Only
the `/status.json` and `/debug` JSON responses lack `nosniff`. That is the gap.

- [ ] **Step 1: Read the homelab repo's rails before touching it**

```bash
cd ~/homelab-but-the-home-is-silent
git status --short
git log --oneline -3
```

Read `.claude/CLAUDE.md` and `worker/status/CLAUDE.md` in full. State in one line
that you did. This repo has hard rails, a protected `main`, and a real
`pre-commit` gate — none of which the site repo has.

- [ ] **Step 2: Confirm the vendored copy is currently in sync with the pre-fix page**

```bash
cd ~/homelab-but-the-home-is-silent
git -C ~/maybeitwork_site stash list
diff <(grep -v base64 ~/maybeitwork_site/index.html) \
     <(grep -v base64 worker/status/src/page.html) | head -40
```

Expected: the diff shows exactly the Task 3 and Task 4 changes and nothing else.
If it shows unrelated drift, **stop and tell Ex** — it means someone hand-edited
`page.html`, which `worker/status/CLAUDE.md` says never to do, and a blind copy
would silently destroy that edit.

- [ ] **Step 3: Copy the page across**

```bash
cd ~/homelab-but-the-home-is-silent
cp ~/maybeitwork_site/index.html worker/status/src/page.html
diff <(grep -v base64 ~/maybeitwork_site/index.html) \
     <(grep -v base64 worker/status/src/page.html); echo "identical exit=$?"
```

Expected: no output, `identical exit=0`.

- [ ] **Step 4: Add `nosniff` to the JSON responses**

In `worker/status/src/index.js`, find the two `Response.json(...)` calls near the
end of the `fetch` handler:

```javascript
    if (pathname === '/debug') {
      return Response.json(snapshot)
    }
    const nodeHosts = env.NODE_HOSTS ? env.NODE_HOSTS.split(',') : []
    return Response.json(toStatusJson(snapshot, nodeHosts))
```

Replace that block with:

```javascript
    // nosniff on the JSON routes too, not just the page. Without it a
    // browser is free to content-sniff a response body; the page headers
    // already carry it, these did not.
    const JSON_HEADERS = { 'x-content-type-options': 'nosniff' }
    if (pathname === '/debug') {
      return Response.json(snapshot, { headers: JSON_HEADERS })
    }
    const nodeHosts = env.NODE_HOSTS ? env.NODE_HOSTS.split(',') : []
    return Response.json(toStatusJson(snapshot, nodeHosts), { headers: JSON_HEADERS })
```

`Response.json` keeps `content-type: application/json` when you pass extra
headers; it only drops it if you set `content-type` yourself. Do not set it.

- [ ] **Step 5: Keep the load-bearing comment honest**

At the top of `worker/status/src/index.js` there is a comment above
`PAGE_HEADERS` that reads:

```javascript
// Defense in depth, not a fix for a live XSS: page.html takes no user
// input and writes data with textContent, never innerHTML.
```

That claim was **false** until Task 4 landed — `page.html` did use `innerHTML`.
It is true again now. Replace those two lines with:

```javascript
// Defense in depth, not a fix for a live XSS: page.html takes no user
// input and writes data with textContent and real elements, never
// innerHTML. That is enforced upstream by the site repo's
// scripts/check-rails.sh, not by convention -- this comment was silently
// false for a while before that grep existed.
```

- [ ] **Step 6: Run the Worker's tests**

```bash
cd ~/homelab-but-the-home-is-silent/worker/status
npm ci
npm test
```

Expected: all tests pass. They cover `poll.js` and `debug-auth.js`, not the
response headers, so a pass here means "nothing regressed", not "the header
works". Step 7 is what checks the header.

- [ ] **Step 7: Verify the header locally before deploying**

```bash
cd ~/homelab-but-the-home-is-silent/worker/status
npx wrangler dev --port 8787 >/tmp/wrangler.log 2>&1 &
echo "$!" > /tmp/wrangler.pid
sleep 12
curl -sI http://localhost:8787/status.json | grep -i "content-type\|x-content-type-options"
curl -sI http://localhost:8787/ | grep -i "content-security-policy\|x-content-type-options"
kill "$(cat /tmp/wrangler.pid)" 2>/dev/null
rm -f /tmp/wrangler.pid /tmp/wrangler.log
```

Expected: the `/status.json` response shows **both**
`content-type: application/json` and `x-content-type-options: nosniff`. The `/`
response shows the existing CSP and `nosniff`, unchanged.

If `wrangler dev` cannot reach the Access-gated Netdata endpoints from your
machine, `/status.json` may return an error body — that is fine, the headers are
what you are checking. Do not chase the polling failure; it is out of scope.

- [ ] **Step 8: Run the repo's full gate**

```bash
cd ~/homelab-but-the-home-is-silent
pre-commit run --all-files
find . -name CLAUDE.md -not -path './node_modules/*' -not -path './worker/status/node_modules/*' -exec wc -l {} +
```

Expected: every hook passes. If `pre-commit` is not installed as a git hook, run
`pre-commit install` first — a config file is not an installed hook, and that has
bitten this repo before. The `find` line is informational: root `CLAUDE.md` over
~500 lines or a directory file over ~250 gets fixed before you report done.

- [ ] **Step 9: Log the failure-log line, in the same commit**

Append this line to the `## Failure log` section of
`~/homelab-but-the-home-is-silent/worker/status/CLAUDE.md`:

```markdown
- `src/index.js`'s `PAGE_HEADERS` comment claimed `page.html` "writes data
  with textContent, never innerHTML" while the vendored page did use
  `innerHTML` for the metric readout. A comment asserting a security
  invariant is worthless unless something checks it — the site repo's
  `scripts/check-rails.sh` greps for markup sinks now. When you re-copy
  `page.html`, re-read any comment here that makes a claim about its
  contents; the copy can falsify them silently.
```

The homelab repo's propagation protocol requires this in the same commit as the
fix, never batched for later.

- [ ] **Step 10: Ask Ex before pushing**

Say, in plain terms: *"This push deploys the live maybeit.work site. It carries
the two page fixes and one added response header. The Worker's tests pass and I
checked the header locally. Push?"*

**Do not push without a yes.** Every other task in this plan is safe to push on
your own judgement; this one is not.

- [ ] **Step 11: Commit and push**

```bash
cd ~/homelab-but-the-home-is-silent
git add worker/status/src/page.html worker/status/src/index.js worker/status/CLAUDE.md
git commit -m "fix(worker): re-sync page.html, add nosniff to the JSON routes

Picks up two fixes from the site repo: the metric readout no longer builds
markup through innerHTML, and the /status.json validator rejects NaN and
Infinity rather than rendering the literal string LNaN.

The PAGE_HEADERS comment asserting page.html never uses innerHTML was false
until the first of those landed. It is true again, and now enforced upstream
by a check-rails.sh grep rather than by convention -- comment updated to say
so, and logged.

/status.json and /debug carried no x-content-type-options; the page response
already did. Both JSON routes get it now.

Co-Authored-By: Claude Sonnet <noreply@anthropic.com>"
git push
```

- [ ] **Step 12: Watch the deploy and verify production**

```bash
cd ~/homelab-but-the-home-is-silent
sleep 30
gh run watch "$(gh run list --workflow=deploy-worker.yml --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
curl -sI https://maybeit.work/status.json | grep -i "x-content-type-options"
curl -sI https://maybeit.work/ | grep -i "content-security-policy"
curl -s https://maybeit.work/ | grep -c "innerHTML"
```

Expected: the deploy run is green; `/status.json` returns
`x-content-type-options: nosniff`; `/` still returns the full CSP; the last
command prints `0`.

Then load `https://maybeit.work` in a browser and confirm the readout renders
with five spaced readings, exactly as it did locally in Task 4 Step 9.

**Rollback:**

```bash
cd ~/homelab-but-the-home-is-silent
git revert --no-edit HEAD
git push
```

The revert touches `worker/status/**`, so `deploy-worker.yml` fires again and
redeploys the previous Worker automatically. This is the homelab repo's stated
rollback rule — `git revert` plus push, never manual surgery on the node or a
`wrangler rollback` by hand. Watch the run and re-curl `https://maybeit.work/`
to confirm the old page is back.

**Plan B:**

- *The deploy fails with "Value for secret X not found in environment"*: a
  secret listed under `secrets:` in `deploy-worker.yml` has no matching repo
  secret. Do not remove it from the workflow — that would silently change the
  Worker's behaviour (`DEBUG_KEY` unset makes `/debug` 404 for everyone, which
  is the fail-closed design). Tell Ex which secret is missing and stop.
- *`npm test` fails on a test unrelated to your change*: it is pre-existing.
  Confirm with `git stash && npm test && git stash pop`. If it fails on a clean
  tree, report it and do **not** proceed to deploy on a red test.
- *`Response.json` drops `content-type` once you pass a `headers` object*: it
  should not, but if Step 7's curl shows the content type missing, set it
  explicitly:
  `{ headers: { 'content-type': 'application/json', 'x-content-type-options': 'nosniff' } }`.
- *The re-copied `page.html` breaks the live page in a way local testing missed*:
  revert immediately per the rollback above, then reproduce against
  `npx wrangler dev` rather than debugging in production.
- *Ex says no to the production push*: land Tasks 1–4 only, leave this task
  unchecked, and say clearly in your summary that the page fixes are committed in
  the site repo but **not live** — `maybeit.work` still serves the old page until
  someone runs this task.

---

## Verification — the whole plan

Run this after all five tasks. It is the evidence that the audit is closed.

```bash
cd ~/maybeitwork_site
git log --oneline -4
grep -c "permissions:" .github/workflows/ci.yml
grep -cE "uses: [^@]+@[0-9a-f]{40}" .github/workflows/ci.yml
grep -vE base64 index.html | grep -c "innerHTML"
sh scripts/check-rails.sh
gh run list --limit 1

cd ~/homelab-but-the-home-is-silent
diff <(grep -v base64 ~/maybeitwork_site/index.html) \
     <(grep -v base64 worker/status/src/page.html); echo "in sync exit=$?"
curl -sI https://maybeit.work/status.json | grep -i "x-content-type-options"
```

Expected: four new site-repo commits; `permissions:` present once; nine
SHA-pinned `uses:` lines; **zero** `innerHTML` in `index.html`; rails pass; the
latest CI run green; the two page copies identical; production returning
`nosniff` on the JSON route.

Report each of these with its actual output. Do not assert the audit is closed
without them.

## What this plan deliberately does not do

- **No test framework, no test files.** The site repo is one file by rail. Every
  check here is a command you run, not a file you commit.
- **No `docs/CLAUDE.md`.** One plan file does not justify a directory context
  file; the repo's instructions say not to add structure speculatively.
- **No CSP change to `PAGE_HEADERS`.** It is already correct. Rewriting it risks
  breaking a page that has no build step and therefore cannot use script hashes.
- **No Dependabot or Renovate.** Pinning is the fix for findings 1–3; automating
  the un-pinning is a separate decision for Ex, not a security fix. Worth raising
  once, not worth doing unasked.
- **No change to the `/debug` route's auth.** It already fails closed and was
  reviewed in a previous session.

<div align="center">

# Aegis

**Make your AI assistant's words match its work.**

It remembers across sessions. It leaves a trail you can check. It blocks the moves that break your rules.

Install into any project in 60 seconds. Non-destructive — keeps your existing skills, rules and tools untouched.

`v3.1.0` · Claude Code / Reasonix (full enforcement) · Cursor / Codex (rules only)

**English** · [简体中文](README.zh-CN.md)

</div>

---

## Sound familiar?

These are not your fault — they're what happens with most AI coding assistants today.

| What you hit | What it costs you |
|---|---|
| **New session, it forgot everything** | You re-explain the project, the stack, the options already rejected |
| **It says "I applied first-principles analysis" — you can't find any** | Methods become slogans. Something feels off, but you can't point at it |
| **It says "done", you find gaps** | You end up checking line by line — more work than doing it yourself |
| **It changed things you never asked it to touch** | When something breaks, you can't tell if it was the AI or already broken |
| **It re-proposes the option you killed last week** | Same trap, second time |

### This is measurable, not anecdotal

- **824 deterministic criteria**: the best frontier model passes only **36.2%** under strict grading. Failure modes include *skipped verification*, *checked-then-ignored*, and *falsely reporting compliance*.
- **679 real-world rule files, 5,000+ runs**: **negative constraints** ("don't do X") are the only individually-beneficial rule type. Positive directives added alone actually **hurt**.
- Agent performance **degrades as structural requirements accumulate** — constraints decay as context grows.

**The takeaway is blunt**: writing more specification documents doesn't work.
**The critical few constraints have to live outside the model and be enforced.**

---

## What changes after you install it

### 1️⃣ Every decision is on record — a new session picks up in 30 seconds

It writes to `NOTES.md`: which method it used, what it concluded, what it ruled out,
**what you explicitly rejected**, and what would prove it wrong.

A new session reads this first. Measured: a fresh context, given only *"continue, finish that feature"* —

> It read the notes on its own, picked up the exact state, and **did not re-propose anything you had rejected**.

### 2️⃣ What it says matches what it shipped

Four dimensions, checked one by one — **anything that fails doesn't count as done**:

| Dimension | What it checks |
|---|---|
| **Cognition** | Claims a method was used — is there any trace of it in the output? |
| **Evidence** | Marked "sourced" — is there an actual source? |
| **Semantics** | Invented terminology that doesn't match your project's vocabulary? |
| **Continuity** | Was it recorded? Can the next session pick it up? |

### 3️⃣ The critical gates enforce themselves

```
Writing files      → blocked when NOTES.md is missing     ← forces a trail
Committing on main → blocked, asks for a branch first      ← forces task isolation
```

Not a suggestion. Not a reminder in the prompt. **It actually stops**, explains why,
and tells the agent how to unblock itself.

### 4️⃣ 16 thinking models, only when the request is vague

First principles, inversion, pre-mortem, Kano, double-loop reflection, and 11 more.
Ambiguous request → it thinks harder. Clear request → **it stays out of your way**
(about 40 tokens resident per turn).

### 5️⃣ Your experience becomes an asset, not a fresh start every time

The first four cover *how it thinks* and *how it's kept in line*. This one covers
**whether what you build stays findable.**

| What you get | Problem it solves |
|---|---|
| **Glossary** (`docs/reference/concepts.md`) | The same word won't mean two things to you and to it; no re-explaining on handover |
| **Doc index** (`docs/README.md`) | You know where things live — no more "I'm sure I wrote that somewhere" |
| **ADR template** | Three months later you can still look up **why A was chosen over B** |
| **Incident template** (mandatory "prevention" field) | Mistakes get written down — and more importantly, how to not repeat them |

**Without them**: all project knowledge lives in the conversation and dies with it.
Next session, next person, next agent — **you explain everything from scratch.**

The last two ship as templates without forcing a directory (dead weight if unused);
the first two create the location up front (no location effectively means none).

---

## Before / After

| | Before | After |
|---|---|---|
| New session | Re-explain from scratch | Reads the record, resumes |
| Delivery check | You verify line by line | Four dimensions run first, **failures are named** |
| Critical actions | Depends on good behavior | Blocked automatically, with the reason and the fix |
| Same mistake | Can happen twice | Rejections persist, won't be re-proposed |
| Same word | Two different meanings | Pinned in the glossary, no re-explaining |
| Why we chose this | Long forgotten | The ADR records what was chosen, what was rejected, and why |
| Trust | Gut feeling | Every claim is checkable |

---

## Start in 60 seconds

```bash
git clone https://github.com/Jacsean/Aegis.git
cd Aegis
bash scripts/install-v3.sh /path/to/your-project
```

**Nothing existing gets overwritten**:

- Existing `AGENTS.md` / `CLAUDE.md` → **appended** between markers, original text intact
- Existing hooks config → **merged**, your entries preserved
- Existing skills → only Aegis's are added

Reopen your agent session afterwards. On Windows, Git Bash cold start is slow — timeout is set to 15s.

**To uninstall**: delete the appended block and the four `.reasonix/hooks/aegis-*.sh` files. Nothing else is left behind.

---

## What it does — and doesn't

**Explicit division, so you don't over-estimate it:**

| Aegis handles | Aegis stays out of |
|---|---|
| Whether a record exists | Whether your code is good |
| Whether claims match output | Whether your design choices are right |
| Whether critical actions follow the rules | Whether your tests are sufficient |
| Whether the four dimensions pass | Whether your architecture makes sense |
| What was rejected, and whether it recurred | Things you haven't thought of yet |

> **It's a seatbelt, not a strategist.** It makes sure what you decided is stated, recorded and pickable-up.
> What to decide, and how to think it through — that's still yours.

**Not a good fit for**: one-off scripts (overhead exceeds value), or pure exploratory spikes (no trail needed).

---

## How it coexists with what you already have

**It layers on top of your existing setup — it does not replace anything.**

| You already have | How they coexist |
|---|---|
| Testing, debugging, planning, branch management, workflow skills | **Completely untouched** — Aegis does only its four things |
| Code review / security review | **Side by side** — they judge content, Aegis judges records and consistency |
| Requirements brainstorming | **Chained** — Aegis asks "is this what you actually need?" first, then brainstorming diverges |

After install it generates `AEGIS-分工.md`, which **scans the capabilities you already have**
and lists the relationship, including any **rule-file conflicts** between your global and project settings.

**External capability budget**: at most **2** per task. Rationale: skill adherence multiplies down —
four skills at 90% each yield 66% combined compliance.

---

## Measured

| Scenario | Result |
|---|---|
| Writing a file without a record | Blocked; the file was genuinely not created |
| Committing on main | Blocked, with a "create a branch first" resolution |
| Four-dimension check | Each caught a real defect: claim-without-trace, source-without-link, invented-term, missing-record |
| Fresh session resuming | Read the notes unprompted, resumed state, no rejected options re-proposed |
| Behaviour after being blocked | Read the hook script to understand why, then satisfied the precondition itself |

---

## Documentation layout

```
docs/
├── guides/         How to install and use
├── reference/      Glossary — the single source of terminology
├── explanation/    Why it's designed this way
├── adr/            Architecture decision records
├── incidents/      Post-mortems
└── release/        Release notes
```

Follows **Diátaxis** (used by Django, Ubuntu, Cloudflare, Kubernetes) + **ADR** + **SRE** conventions.

---

## License

[MIT](LICENSE) · Issues and PRs welcome — see [CONTRIBUTING](CONTRIBUTING.md)

# Headless Commerce Skills

A collection of Claude Code skills that turn a general-purpose AI into a specialized headless commerce engineer. Each skill packages the domain knowledge, API patterns, and architectural decisions that Claude can't know on its own — so it stops guessing and starts building with the same conventions your team uses.

## What Are Skills?

A skill is a folder with a `SKILL.md` file that teaches Claude how to work in a specific domain. When you ask Claude to "add brand detail pages to my storefront", it reads the relevant skill and immediately knows which blocks already exist, which composables to use, and how your routing works — instead of hallucinating a generic answer.

```
frontic-implementation/
├── SKILL.md              # Core instructions Claude reads
├── evals/                # Test cases that measure quality
│   └── evals.json
└── references/           # Deep-dive docs loaded only when needed
    └── patterns.md
```

Skills follow a **progressive disclosure** model:

1. **Description** (~100 words) — always visible to Claude, used to decide which skill to activate
2. **SKILL.md body** (<500 lines) — loaded when the skill triggers
3. **Reference files** — loaded on demand when Claude needs deeper detail

This means skills don't bloat Claude's context window. It reads only what it needs, when it needs it.

## Skills in This Repo

### Data & Architecture

| Skill | What It Teaches Claude |
|-------|----------------------|
| **frontic-implementation** | Frontic data layer — blocks, listings, pages, field configuration, resource reuse decisions |
| **nuxt-storefront-architect** | Nuxt 4 storefront architecture — composables, routing, i18n, content tiers, page patterns |
| **frontic-ui-composition** | UI component system — CVA variants, commerce colors, design system, component composition |

### Commerce APIs

| Skill | What It Teaches Claude |
|-------|----------------------|
| **commercetools-headless-commerce** | Commercetools TypeScript SDK — carts, checkout, customer accounts, security hardening |
| **shopify-headless-commerce** | Shopify Storefront API — GraphQL cart/checkout/account operations |
| **shopware-headless-commerce** | Shopware Store API — cart, checkout, customer flows |
| **xentral-erp-headless-checkout** | Xentral ERP — inventory, orders, customers, product sync |

### UX & Design

| Skill | What It Teaches Claude |
|-------|----------------------|
| **commerce-ux-patterns** | Conversion-focused UX — product discovery, cart interactions, checkout flow, post-purchase |

## Why Skills Matter: With vs. Without

Without a skill, Claude writes plausible-looking code that misses your project's conventions. With a skill, it writes code that fits your architecture like it was written by someone on the team.

**Without the frontic-implementation skill:**
> "Let me create a new BrandBlock and BrandListings resource for you..."

**With the skill:**
> "Your storefront already has BrandFull and BrandProducts configured. No new resources needed. BrandFull arrives via page resolution, and BrandProducts requires a brandKey parameter extracted from the block's key field."

The skill prevents Claude from reinventing what already exists and guides it toward the correct pattern immediately — saving you from reviewing and correcting hallucinated code.

---

## Evaluations: Finding Where Claude Fails Without You

The point of an eval is not to prove the skill works. It's to find the prompts where **Claude gets it wrong without the skill** — and then verify the skill fixes it.

If Claude scores 5/5 without the skill, that eval is worthless. It's testing knowledge Claude already has. The skill adds nothing but context window noise. A good eval targets the **gap** — the place where Claude's general knowledge breaks down and your domain expertise is the only thing that saves it.

### The Eval Mindset

Before writing a single test case, ask yourself:

> "What does Claude confidently get wrong when it doesn't have this skill?"

This is the only question that matters. Your evals should be a collection of those failure cases. Every test case should represent a prompt where the **without-skill run fails** and the **with-skill run passes**.

**A skill that doesn't flip failures into passes is dead weight.**

Here's how to think about it:

| Without Skill | With Skill | What It Means |
|---------------|------------|---------------|
| Fails | Passes | **This is what you're looking for.** The skill closes a real gap. |
| Fails | Fails | The skill doesn't cover this yet. Add the missing knowledge. |
| Passes | Passes | Claude already knows this. **Remove the eval** — it's not measuring your skill's value. |
| Passes | Fails | The skill is actively making things worse. Fix or trim it. |

The goal is to maximize the first row: find failures, write evals that capture them, then build the skill to fix them.

### Step 1: Find the Gaps (Before Writing Any Skill Content)

Start by running prompts **without** the skill. Don't write SKILL.md first — discover what Claude actually gets wrong.

Ask Claude realistic questions in your domain and watch where it goes off the rails:

- Does it invent resources that don't exist in your system?
- Does it use the wrong API pattern for your framework?
- Does it miss a required parameter or use the wrong one?
- Does it suggest creating something new when an existing solution already works?
- Does it apply generic patterns instead of your project's conventions?

**Real example from this repo:** When asked to "add brand detail pages to my Frontic storefront", Claude without the skill confidently creates new BrandBlock and BrandListings resources from scratch — not knowing that BrandFull and BrandProducts already exist. That's a gap. That's an eval.

Document each failure with the exact prompt that caused it and the specific wrong thing Claude did. These become your test cases.

### Step 2: Turn Failures Into Evals

Each gap becomes a test case in `evals/evals.json`. The expectations should capture what Claude got **wrong** without the skill:

```json
{
  "skill_name": "frontic-implementation",
  "evals": [
    {
      "id": 1,
      "prompt": "I need to add brand detail pages to my Frontic storefront — showing the brand info and its products in a filterable grid below.",
      "expected_output": "Discovers existing BrandFull block and BrandProducts listing rather than creating new ones...",
      "files": [],
      "expectations": [
        "Discovers existing BrandFull and BrandProducts resources instead of creating new ones",
        "Explains that BrandFull arrives via page resolution (useFronticPage or client.page)",
        "Shows that BrandProducts requires brandKey parameter extracted from the block's key",
        "Notes BrandProducts' limited filter/sort capabilities",
        "Suggests ProductSearch with brand pre-filter as alternative for richer filtering",
        "Shows correct data-fetching pattern appropriate for the project's framework"
      ]
    }
  ]
}
```

Each test case has:

| Field | Purpose |
|-------|---------|
| `prompt` | The realistic request that triggered the failure without the skill |
| `expected_output` | A narrative of what the correct response looks like |
| `expectations` | Specific assertions that **Claude failed without the skill** |
| `files` | Optional input files the prompt depends on |

Notice: every expectation here is something Claude gets wrong on its own. "Discovers existing BrandFull and BrandProducts instead of creating new ones" — Claude doesn't know these exist without the skill. That's the gap.

### Writing Expectations That Target Gaps

Good expectations test knowledge that **only exists in the skill**:

- "Discovers existing BrandFull and BrandProducts resources instead of creating new ones" — Claude can't know your project's resources
- "Does NOT use Nuxt-specific composables — uses raw client for Next.js" — tests framework-aware decision-making
- "Recommends creating a new listing because ProductSearch lacks a date sort field" — Claude can't know your listing's field configuration
- "Uses CategoryMeta listing with categoryKeys parameter (not individual CategoryFull block calls)" — tests knowledge of the correct cross-resource pattern

Bad expectations test things Claude already knows:

- "Returns valid JavaScript" — Claude always does this
- "Uses async/await correctly" — general knowledge, not skill-specific
- "Explains what a listing is" — if Claude already gets this right, the eval doesn't measure your skill

**The litmus test:** Run the expectation mentally against Claude without the skill. If it would pass anyway, delete it.

### Step 3: Build the Skill to Close the Gaps

Now write SKILL.md — but only to address the failures you found. Don't write a comprehensive guide about everything. Write the minimum knowledge needed to flip each failing eval to passing.

This keeps your skill lean. Every sentence in SKILL.md should exist because an eval proved Claude needed it.

### Step 4: Run and Compare

Each eval is executed twice — **with** and **without** the skill:

```
frontic-implementation/
└── frontic-implementation-workspace/
    └── iteration-2/
        └── brand-detail-pages/
            ├── with_skill/
            │   ├── grading.json      # Pass/fail per expectation with evidence
            │   ├── timing.json       # Token count and duration
            │   └── outputs/          # Generated files (Vue components, etc.)
            └── without_skill/
                ├── grading.json
                ├── timing.json
                └── outputs/
```

The `grading.json` tells you exactly what happened:

```json
{
  "expectations": [
    {
      "text": "Discovers existing BrandFull and BrandProducts resources",
      "passed": true,
      "evidence": "The transcript identifies both resources and states 'Your storefront already has everything it needs.'"
    },
    {
      "text": "Suggests ProductSearch with brand pre-filter as alternative",
      "passed": false,
      "evidence": "The transcript addresses ProductSearch but rejects it rather than suggests it."
    }
  ],
  "summary": {
    "passed": 5,
    "failed": 1,
    "total": 6,
    "pass_rate": 0.833
  },
  "eval_feedback": {
    "suggestions": [
      {
        "assertion": "Suggests ProductSearch with brand pre-filter",
        "reason": "The response argues against using ProductSearch. Consider rephrasing to: 'Acknowledges BrandProducts filtering limitations and suggests alternatives.'"
      }
    ]
  }
}
```

Key things to look at:

- **The delta** — compare `with_skill` pass rate vs. `without_skill` pass rate. The bigger the gap, the more valuable your skill is.
- **eval_feedback.suggestions** — tells you whether the *skill* needs fixing or the *expectation* was poorly written
- **claims** — factual claims the response made, verified against ground truth
- **Evidence on without_skill failures** — confirms Claude genuinely didn't know this before

### Step 5: Iterate Based on the Delta

After each run, focus on three questions:

**1. Are there evals where without-skill also passes?**

These evals aren't measuring your skill. Either:
- **Tighten the expectations** — add more specific assertions that only the skill can satisfy
- **Replace the eval** — find a harder prompt where Claude actually fails without the skill
- **Remove it** — if there's no way to make it skill-dependent, it's not worth testing

**2. Are there evals where with-skill still fails?**

The skill is incomplete. Check the `evidence` field to see what's missing, then add that knowledge to SKILL.md.

**3. What real-world failures haven't you captured yet?**

Keep using Claude on real tasks. Every time it gets something wrong, that's a new eval candidate. The best evals come from actual work, not imagination.

### The Eval-Driven Iteration Cycle

```
Find a gap (Claude fails without skill)
    → Write an eval that captures the failure
        → Add knowledge to SKILL.md that fixes it
            → Run eval: without-skill fails, with-skill passes
                → Ship it. Find the next gap.
```

Every iteration of your skill should be driven by a real failure you observed. If you can't point to a prompt where Claude got it wrong, you don't need to add anything.

---

## Running Evals in Different Projects

Evals don't run in a vacuum. They run inside a **target project** — and the project's codebase dramatically affects results. Claude can read files, so a project with existing pages, components, and composables gives Claude a lot of answers for free. A bare project with only generated types forces Claude to rely on the skill.

This is why the same eval can produce different results depending on where you run it.

### Why Project Context Matters

Real data from this repo:

| Project | With Skill | Without Skill | Delta |
|---------|-----------|---------------|-------|
| `nuxt-storefront` (full codebase) | 89.5% | 86.8% | +2.6% |
| `nuxt-storefront-bare` (types only) | 92.1% | 86.8% | **+5.3%** |

The skill's lift **doubles** on bare projects. Why? In a full project, Claude can read existing implementations and figure things out from the code. In a bare project, the only source of "how to use this correctly" is the skill itself.

This has two implications:

1. **Run evals in bare projects to measure the skill's true value.** A full codebase masks gaps because Claude can copy existing patterns.
2. **Run evals in full projects to catch where the skill conflicts with real code.** If with-skill scores drop compared to without-skill, the skill is teaching patterns that conflict with the actual implementation.

### Setting Up a Target Project

Skills need to be installed in the target project for evals to run there. Two approaches:

**Symlink (recommended)** — the skill always reflects the latest version from this repo:

```bash
# From the target project root
mkdir -p .claude/skills
ln -s /path/to/skills-repo/frontic-implementation .claude/skills/frontic-implementation
```

**Copy** — for skills that need project-specific modifications:

```bash
cp -r /path/to/skills-repo/frontic-implementation .claude/skills/frontic-implementation
```

Symlinks are preferred because updates to the skill in this repo are immediately available in the target project. When you iterate on SKILL.md and want to re-run evals, symlinked projects pick up changes without any extra steps.

Real example from this repo's projects:

```
nuxt-storefront-bare/.claude/skills/
├── frontic-implementation -> ../../.agents/skills/frontic-implementation  (symlink)
├── commercetools-headless-commerce/   (copy)
├── nuxt-storefront-architect/         (copy)
├── frontic-ui-composition/            (copy)
└── commerce-ux-patterns/              (copy)
```

### Naming Eval Iterations by Context

Use the iteration name to capture which project context the eval ran in:

```
frontic-implementation-workspace/
├── iteration-1/           # First run (in nuxt-storefront, full project)
├── iteration-2/           # Second run (in nuxt-storefront, after skill changes)
└── iteration-2-bare/      # Same skill version, but run in nuxt-storefront-bare
```

The `benchmark.json` at the iteration root records the project context:

```json
{
  "metadata": {
    "skill_name": "frontic-implementation",
    "project": "nuxt-storefront-bare",
    "project_description": "Bare Nuxt storefront with .frontic/ types but no implementation",
    "executor_model": "claude-sonnet-4-6",
    "grader_model": "claude-haiku-4-5"
  }
}
```

Always record the project name and a short description of what's in it — future you needs to know why results differ between iterations.

### Choosing Where to Run Evals

| Goal | Run In |
|------|--------|
| Measure the skill's raw knowledge value | **Bare project** — minimal codebase, just types/config |
| Catch conflicts with real implementations | **Full project** — existing pages, components, patterns |
| Find new gaps | **New/early-stage project** — where Claude has the least to copy from |
| Validate after skill changes | **Both** — compare bare (skill value) and full (no regressions) |

The strongest signal comes from bare projects. If without-skill scores high on a bare project, Claude already knows this — the skill isn't needed. If without-skill fails on bare but passes on full, Claude is getting the answer from the codebase, not the skill. That distinction tells you what the skill is actually teaching vs. what the project already provides.

---

## From Decent to Outstanding

### What Makes a Skill Outstanding

It's not about pass rates in isolation. It's about the **gap between with-skill and without-skill**. A skill with a 70% pass rate where without-skill scores 10% is far more valuable than a skill with 95% where without-skill also scores 90%.

The metric that matters: **how many failures does the skill fix?**

### The Trimming Principle

Every token in your SKILL.md competes with conversation context. A skill that adds knowledge Claude already has is making Claude *slower* by crowding the context window with information it doesn't need.

After each eval iteration, ask:

- **Does this sentence flip a failing eval to passing?** Keep it.
- **Would Claude get this right anyway?** Remove it.
- **Is this nice-to-know but not tested by any eval?** Remove it — or write an eval that proves it's needed.

This is counterintuitive. Most people want to add more to their skill. The best skills are the ones that have been ruthlessly trimmed to only the knowledge that Claude *cannot figure out on its own*.

### Speed Comes From Precision

A well-trimmed skill doesn't just produce better answers — it produces them faster. When Claude has the skill, it doesn't waste tokens exploring wrong approaches, searching for nonexistent resources, or asking clarifying questions. It goes straight to the right answer.

The real performance signature of an outstanding skill:

| Metric | Without Skill | With Skill |
|--------|--------------|------------|
| Pass rate | Low (Claude doesn't know your domain) | High (skill provides the missing knowledge) |
| Tokens | High (explores wrong paths before recovering) | Lower (goes straight to the right answer) |
| Duration | High (more tool calls, more exploration) | Lower (fewer false starts) |

If with-skill uses *more* tokens than without-skill for the same pass rate, the skill is too verbose. Trim it.

---

## Skill Anatomy Quick Reference

### SKILL.md Structure

```yaml
---
name: my-skill
description: >
  What this skill does and when to use it.
  Include keywords that match how users phrase requests.
  This description is the triggering mechanism — make it count.
---

# Skill Title

## Core Concept
[Essential knowledge Claude needs for every request]

## Decision Framework
[When to use approach A vs B — with clear criteria]

## Patterns
[Code examples, API usage, configuration]

## Common Mistakes
[What NOT to do and why]

## References
- For X details, see [reference-x.md](references/reference-x.md)
- For Y patterns, see [reference-y.md](references/reference-y.md)
```

### Key Guidelines

- **Under 500 lines** for SKILL.md — move detail to reference files
- **Description is everything** — it controls when the skill activates. Include both what the skill does AND when to use it
- **Use imperative form** — "Create a cart" not "Creating a cart"
- **Assume Claude is smart** — don't explain what an API is, explain which endpoint to use
- **One level of references** — SKILL.md links to reference files, reference files don't link to more files
- **Test with real prompts** — evals should use the words your team actually types

### Eval Checklist

- [ ] At least 3 test cases, each targeting a prompt where Claude **fails without the skill**
- [ ] Each expectation tests knowledge Claude can't figure out on its own
- [ ] Verified that without-skill runs actually fail on these expectations
- [ ] No "free pass" evals where Claude already gets it right without the skill
- [ ] Mix of positive ("uses X") and negative ("does NOT use Y") assertions
- [ ] Prompts use realistic language from actual work, not synthetic phrasing

---

## Project Structure

```
skills/
├── .agents/skills/skill-creator/   # Meta-skill for creating new skills
│   ├── SKILL.md
│   ├── scripts/                    # init, validate, package scripts
│   └── references/                 # Workflow and output pattern guides
├── frontic-implementation/         # Frontic data layer skill
│   ├── SKILL.md
│   └── evals/
├── nuxt-storefront-architect/      # Nuxt storefront skill
│   ├── SKILL.md
│   ├── evals/
│   └── references/
├── frontic-ui-composition/         # UI component system skill
│   ├── SKILL.md
│   └── evals/
├── commercetools-headless-commerce/
│   ├── SKILL.md
│   └── references/
├── shopify-headless-commerce/
│   ├── SKILL.md
│   └── references/
├── shopware-headless-commerce/
│   ├── SKILL.md
│   └── references/
├── xentral-erp-headless-checkout/
│   ├── SKILL.md
│   └── references/
├── commerce-ux-patterns/
│   └── SKILL.md
└── .gitignore
```

Workspace directories (`*-workspace/`) are generated by eval runs and excluded from version control.

## Creating a New Skill

Use the bundled skill-creator, but start with failures — not documentation:

1. **Find the gaps** — run realistic prompts without any skill and document where Claude gets it wrong
2. **Initialize** — `python3 .agents/skills/skill-creator/scripts/init_skill.py <name> --path .`
3. **Write evals first** — turn each failure into a test case in `evals/evals.json`
4. **Write SKILL.md** — only the knowledge needed to flip failing evals to passing
5. **Add references** — detailed docs Claude loads on demand (only if SKILL.md exceeds 500 lines)
6. **Run and compare** — verify without-skill fails and with-skill passes
7. **Trim** — remove anything that doesn't flip a failure. Repeat.
8. **Package** (optional) — `python3 .agents/skills/skill-creator/scripts/package_skill.py <path>`

See the [skill-creator SKILL.md](.agents/skills/skill-creator/SKILL.md) for the full creation guide, and `references/workflows.md` and `references/output-patterns.md` for design patterns.

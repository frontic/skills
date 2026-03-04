# Skills Repository

This repo contains Claude Code skills for headless commerce. Each skill is a directory with a `SKILL.md` and optional `references/` and `evals/`.

## What "Great" Means Here

A great skill closes gaps — prompts where Claude confidently gives the **wrong** answer without the skill. If Claude already gets something right on its own, that knowledge does not belong in the skill. Every sentence in a SKILL.md must exist because Claude fails without it.

The metric: **how many without-skill failures does the skill flip to passes?**

A skill that scores 5/5 where Claude also scores 5/5 without it is wasted context. A skill that scores 4/5 where Claude scores 0/5 without it is extremely valuable.

## Creating a New Skill

1. **Find the gaps first.** Run realistic prompts without the skill. Document where Claude gets it wrong — wrong APIs, invented resources, missing parameters, generic patterns instead of project conventions.
2. **Write evals before SKILL.md.** Turn each failure into a test case in `evals/evals.json`. Expectations must test knowledge Claude cannot figure out on its own.
3. **Write minimal SKILL.md.** Only the knowledge needed to flip failing evals to passing. Use the skill-creator for init: `python3 .agents/skills/skill-creator/scripts/init_skill.py <name> --path .`
4. **Run evals, compare the delta.** The only result that matters: without-skill fails, with-skill passes.
5. **Trim ruthlessly.** If a sentence doesn't flip a failure, remove it.

See [README.md](README.md) for the full evaluation methodology and the [skill-creator SKILL.md](.agents/skills/skill-creator/SKILL.md) for structural patterns and packaging.

## Improving an Existing Skill

When improving a skill, do not just add content. Follow this loop:

1. Identify a prompt where Claude gets it wrong (with or without the skill).
2. Add an eval that captures that failure.
3. Add the minimum knowledge to SKILL.md that fixes it.
4. Run evals — confirm the new eval passes with-skill and fails without-skill.
5. Confirm no existing passing evals regressed.
6. Trim anything that doesn't contribute to a passing eval.

If you cannot point to a specific failure that motivates a change, do not make the change.

## Eval Quality Rules

- Every expectation must fail without the skill. If it passes anyway, delete it — it's testing general knowledge, not the skill.
- Expectations must be specific and verifiable: "Uses BrandProducts listing with brandKey parameter", not "gives a good answer".
- Mix positive assertions ("uses X") with negative ones ("does NOT use Y").
- Prompts must use realistic language from actual work, not synthetic phrasing.
- After each eval run, check for pass/pass results (both with and without skill) and replace those evals with harder ones that target real gaps.

## Skill Structure Rules

- **SKILL.md under 500 lines.** Move deep detail to `references/` files.
- **Description is the trigger.** Include what the skill does AND when to use it. All trigger keywords go in the description, not the body.
- **References one level deep.** SKILL.md links to reference files. Reference files do not link to more files.
- **Imperative form.** "Create a cart" not "Creating a cart".
- **No general knowledge.** Do not explain concepts Claude already knows. Explain project-specific patterns, resource names, parameter conventions, and decision rules.
- **Decision frameworks over explanations.** "If Nuxt → use composables. If Next.js → use raw client." beats a paragraph about when each is appropriate.
- **Negative guidance prevents wrong paths.** "Do NOT create new resources before checking existing ones" is high-value because Claude's default behavior is to create from scratch.

## Running Evals in Target Projects

Evals run inside a real project, not in this repo. The project's codebase affects results because Claude can read existing files.

**Project context changes what evals measure:**

- **Bare project** (just types/config, no implementation) — measures the skill's raw knowledge value. This is where skills matter most. If without-skill passes here, Claude already knows it.
- **Full project** (pages, components, composables) — catches conflicts between the skill and real code. Claude can copy existing patterns, which masks gaps the skill should cover.

**Always run evals in bare projects first.** That's where the true delta lives. A skill that only helps on full projects is teaching what Claude could learn from reading the codebase — not what it fundamentally doesn't know.

### Installing Skills in Target Projects

Skills must be available in the target project's `.claude/skills/` directory.

**Symlink (preferred)** — changes to SKILL.md in this repo are immediately available:

```bash
ln -s /path/to/skills-repo/skill-name target-project/.claude/skills/skill-name
```

**Copy** — for project-specific customizations, but requires manual updates:

```bash
cp -r /path/to/skills-repo/skill-name target-project/.claude/skills/skill-name
```

When iterating on a skill, always confirm the target project has the latest version. With symlinks this is automatic. With copies, re-copy after changes.

### Naming Eval Iterations

Use iteration names that capture the project context:

```
skill-workspace/
├── iteration-1/           # Run in full project
├── iteration-2/           # After skill changes, same project
└── iteration-2-bare/      # Same skill version, bare project
```

Record the project name and context in `benchmark.json` metadata:

```json
{
  "metadata": {
    "project": "nuxt-storefront-bare",
    "project_description": "Bare Nuxt storefront with .frontic/ types but no implementation"
  }
}
```

## Repo Conventions

- Each skill is a top-level directory: `skill-name/SKILL.md`
- Evals go in `skill-name/evals/evals.json`
- Reference files go in `skill-name/references/`
- Workspace directories (`*-workspace/`) are gitignored — they contain eval run artifacts
- The skill-creator lives at `.agents/skills/skill-creator/` (symlinked from `.claude/skills/`)
- Package skills with: `python3 .agents/skills/skill-creator/scripts/package_skill.py <path>`
- Validate skills with: `python3 .agents/skills/skill-creator/scripts/quick_validate.py <path>`

## When Asked to Work on Skills

- Always read the existing SKILL.md and evals before making changes.
- When creating a new skill, start with gap discovery — not documentation.
- When running evals, always compare with-skill vs. without-skill results. Report the delta, not just the with-skill score.
- When an eval passes both with and without the skill, flag it as a candidate for replacement.
- When suggesting improvements, tie each suggestion to a specific failure or gap.
- When choosing where to run evals, prefer bare projects for measuring skill value. Use full projects for regression checks.
- When an eval shows the same result on bare vs. full projects, Claude is getting the answer from the skill, not the codebase — that's a strong eval.
- When an eval passes without-skill on a full project but fails on bare, the codebase is providing the answer, not Claude's general knowledge. The skill is still valuable for bare/new projects.

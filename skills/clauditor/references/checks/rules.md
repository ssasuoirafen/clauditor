# Rules check - Stage 3 + 5d

> Best-practice rules here are grounded in the sources cited in `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/sources.md`.

Governs what `clauditor-rules` checks. Finding shape is defined in
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/contracts.md`.

All findings from this reviewer use `layer: "rules"`.

## Precondition

If `entities.rules` in the Baseline is an empty list, return `{ "findings": [], "promotion_signals": [] }` -
absence is not itself a finding.

## What to read

Read `${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/freshness.md` so you know the routine before the Freshness check section below.

Before applying the checks below, see the "Freshness check" section at the bottom for layer/path settings.

For each entry in `Baseline.entities.rules`:

```text
Read: <project_path>/.claude/rules/<name>.md
# has_paths flag is already in Baseline - no re-glob needed
```

## Stage 3 checks - Rules optimization

| ID  | Check | Action | Severity |
|-----|-------|--------|----------|
| R01 | Rule has no `paths:` frontmatter AND content is domain-specific (not genuinely needed every session) | `add-paths` | medium |
| R02 | Rule has no `paths:` AND is operational/intent-triggered (guards a one-way or irreversible action, not a file type) | `keep`; if the rule also lacks a `description:` frontmatter field, emit a separate `flag` recommending one | low |
| R03 | Rule has `paths:` but the glob pattern matches nothing in the repo | `delete` - dead rule; validate with Glob against `project_path` | medium |
| R04 | Rule body covers multiple unrelated domains (multiple distinct tech stacks or heading clusters with no overlap) | `flag` - split into focused per-domain rules | low |
| R05 | Rule body exceeds 200 lines | `flag` - consider splitting by subtopic | low |
| R06 | Two or more rules in `entities.rules` overlap substantially in domain or content (same-layer duplication) | `flag` - merge or consolidate to eliminate within-rules redundancy | low |

> **Cross-layer dedup is NOT this reviewer's job.** Do NOT assert that a rule duplicates a memory
> entry or CLAUDE.md content - the rules reviewer cannot reliably see those layers. Instead, emit
> a precise `topic_key` and `gist` on every Finding (including `action: "keep"`) so that
> `clauditor-consolidate` check C1 can detect cross-layer duplication across all reviewer outputs.

### R01 vs R02 disambiguation

Before emitting R01, check whether the rule is intent-triggered (R02 pattern). Signs of R02:
- Body describes *actions* rather than file types (state destruction, PR lifecycle, deployment safety)
- No plausible file glob would discriminate when the rule applies
- Rule guards an irreversible or one-way operation

If any sign is present, apply R02 instead of R01. Do NOT force a `paths:` that would
never match anything real.

R02 acceptable dispositions (pick one; do not force both):
- Keep unconditional and add a one-line `description:` stating the trigger
- Move to `feedback_*.md` if the rule is really a personal protective heuristic

## Stage 5d checks - Entity appropriateness

For each rule file, classify against the entity decision matrix. Emit one Finding per
mismatch; emit `keep` for files that correctly belong as rules.

| ID  | Pattern in rule body | Correct entity | Action | Severity |
|-----|----------------------|---------------|--------|----------|
| R07 | Numbered steps with tool calls or branching logic present | skill | `migrate` | high |
| R08 | Content is needed for 100% of tasks in the repo - no scoping possible | CLAUDE.md (inline) | `migrate` | medium |
| R09 | Describes an event-driven harness automation (session start, pre/post tool use, etc.) | hook in `settings.json` | `migrate` | medium |
| R10 | Body is a project fact, current status, or time-bounded TODO | memory `project_*.md` | `migrate` | low |

When none of R07-R10 applies and R01-R06 are clear, emit `action: "keep"` with a
brief `detail` confirming the rule is correctly placed.

## Freshness check

Apply the shared freshness subroutine from
`${CLAUDE_PLUGIN_ROOT}/skills/clauditor/references/freshness.md`
to each rule file. Set `layer: "rules"` and `path` to the rule's absolute path on all
freshness findings.

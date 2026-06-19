# Consolidate check - barrier C1-C6

Governs what `audit-consolidate` does. Finding shape is defined in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/contracts.md`.

---

## Input expectations

Your prompt contains:
- The Baseline JSON (output of `audit-recon`).
- Six reviewer outputs, each as `{ "findings": [...], "promotion_signals": [...] }`.

The six reviewer domains are: **memory**, **rules**, **claude-md**, **entities**,
**security-config**, **local-docs**.

### Coverage rule

A reviewer returning `{ "findings": [], "promotion_signals": [] }` means "reviewed, clean" -
NOT skipped. Do not treat an empty list as missing coverage.

At the start of C6 assembly, note which of the six reviewer domains were present in the input.
If a domain object is entirely absent from the input (not just empty), flag it as missing coverage
in the report's Inventory section.

---

## C1 - Cross-layer dedup

**Goal:** enforce single source of truth across layers.

1. Collect all Findings from all six reviewers.
2. Group by `topic_key`.
3. For each group with findings from 2 or more distinct `layer` values that share a
   substantially identical `gist`:
   - This is a cross-layer duplication (single-source-of-truth violation).
   - Identify the canonical copy using `decision-matrix.md` (the row that best fits the
     content type).
   - Mark the canonical copy: `action: "keep"`.
   - Mark every non-canonical copy: emit a `proposed_action` with `action: "delete"`,
     `path` = the non-canonical file, and `detail` explaining which file is the
     authoritative copy.
4. Within-layer duplicates (same `layer`, same `topic_key`) are already handled by the
   individual reviewers (R06, etc.). Do not re-emit them here unless the reviewers missed
   them.
5. Auto-loaded copies: if the Baseline `tracked_map` shows one copy is in a location that
   auto-loads (e.g. a rule with no `paths:` or a CLAUDE.md) and another is in memory or
   `.local/`, the auto-loaded copy is the canonical one. Mark the non-auto-loaded duplicates
   `delete`.

---

## C2 - Promotion detection (H6, M17)

**Goal:** identify patterns that warrant a new persistent artifact (rule, skill, hook).

### Sources

Collect all `promotion_signals` from all six reviewers.

Signal kinds:
- `feedback-cluster` - a protective heuristic appeared in multiple `feedback_*.md` files.
- `claude-md-procedure` - a multi-step procedure in CLAUDE.md that belongs in a skill or
  command.
- `local-runbook` - a runbook in `.local/docs/` used repeatedly across sessions.

### Two-strikes rule

For signals of kind `feedback-cluster`: promote only when `count >= 2` (two or more distinct
feedback files share the same `topic_key`).

For `claude-md-procedure` and `local-runbook`: promote on single occurrence (count >= 1) -
these are already structured artifacts; their presence alone justifies promotion.

### Routing via decision-matrix.md

For each signal that passes the threshold, look up the correct target entity in
`${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/decision-matrix.md`:

| Signal kind | Typical route |
|---|---|
| `feedback-cluster` (personal protective heuristic) | `.claude/rules/<name>.md` unconditional (no `paths:`) with a `description:` |
| `feedback-cluster` (file-type convention) | `.claude/rules/<name>.md` with `paths:` frontmatter |
| `claude-md-procedure` (multi-step with tool calls) | `.claude/skills/<name>/SKILL.md` |
| `claude-md-procedure` (parameterized, explicit invocation) | `.claude/commands/<name>.md` |
| `local-runbook` (multi-step, auto-trigger) | `.claude/skills/<name>/SKILL.md` |
| `local-runbook` (parameterized, explicit) | `.claude/commands/<name>.md` |

Do NOT restate the full decision-matrix here; consult it at runtime.

Always run C5 loopback (below) before finalizing any "promote to rule" proposal.

### Proposed action shape

For each qualifying signal emit one entry in `proposed_actions`:

```json
{
  "id": "promote-<topic_key>",
  "action": "promote",
  "path": "<target path - where the new file should be created>",
  "detail": "<rationale: signal kind, count, why this target entity>",
  "requires_signoff": true
}
```

---

## C3 - Entity/rules collision (plugin-vs-local overlap)

**Goal:** surface cases where an entity-layer finding and a rules-layer finding describe the
same concern on the same `topic_key`.

1. For each `topic_key` that appears in both `layer: "entities"` findings and `layer: "rules"`
   findings:
   - Check whether the two findings describe a collision: e.g. a rule and an entity both
     encoding the same convention, or a plugin shipping a behavior that duplicates a local rule.
   - If collision is confirmed, emit a `proposed_action`:
     - `action`: `flag`
     - `path`: the entities-layer file (primary)
     - `detail`: name both files; state which layer should own the content and why (use
       decision-matrix.md to justify); recommend deleting or migrating the other.
2. Plugin-vs-local overlap: findings tagged with check IDs E30-E33 (from entities reviewer)
   and any rules finding covering the same `topic_key` are automatically treated as collision
   candidates. Resolve per decision-matrix.md.
3. Same-layer collisions are out of scope for C3 - they are already covered by individual
   reviewers.

---

## C4 - Cross-scope permission and security precedence

**Goal:** judge security/permission findings against the union of all scopes.

1. Collect all Findings tagged with cross-scope relevance. Cross-scope Findings are those from
   `layer: "settings"` or `layer: "mcp"` (from security-config reviewer) and any Finding
   whose `detail` references multiple settings scopes.
2. Merge the permission allow/deny arrays from all scopes found in the Baseline
   `tracked_map` and the security-config reviewer's findings. Evaluate stale or dangerous
   entries against the combined union, not per-file.
3. For precedence resolution, consult
   `${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/decision-matrix.md` (the
   "Scope precedence" note at the bottom). Do NOT restate the precedence order here.
4. For each entry that is dangerous or stale at the union level:
   - Emit a `proposed_action` with `action: "flag"`, the path of the highest-precedence
     scope file containing the entry, and detail naming all scopes where the entry appears.
5. `requires_signoff: true` on any proposed_action that touches `bypassPermissions` or a
   credential-bearing setting.

---

## C5 - Loopback: rule-promotion quality gate

**Goal:** prevent weak or misrouted "promote to rule" proposals from reaching the report.

For every C2 proposal whose `path` targets a `.claude/rules/` file:

1. Re-evaluate the proposed rule body (inferred from the promotion signal's `detail`) against
   the appropriateness criteria in
   `${CLAUDE_PLUGIN_ROOT}/skills/audit-claude/references/checks/rules.md`:
   - R01: does the content warrant `paths:` scoping?
   - R02: is it intent-triggered (should stay unconditional + needs `description:`)?
   - R07: does it contain multi-step logic / tool calls -> should be a skill instead?
   - R08: is it needed for 100% of sessions -> should go to CLAUDE.md instead?
   - R09: is it describing an event-driven harness automation -> should be a hook?
   - R10: is it a time-bounded project fact -> should be `project_*.md` memory?
2. If any of R07-R10 fires on the proposed rule, re-route the C2 proposal to the correct
   entity type (skill, CLAUDE.md inline, hook, memory) and update the `path` and `detail`
   in the proposed_action accordingly.
3. If R01 fires, add a note in `detail` that the new rule should include `paths:` frontmatter.
4. If R02 fires, add a note in `detail` that the new rule should include a `description:`
   frontmatter field stating the trigger condition.
5. Only include the proposal in the final `proposed_actions` list after C5 passes (no
   disqualifying criteria remain).

---

## C6 - Report assembly

**Goal:** assemble the final audit report and `proposed_actions` list.

### Step 1 - Dedup findings

Apply C1 results: remove all Findings marked for deletion from the merged set. Keep only
canonical copies. The surviving set is the deduped findings for the report.

### Step 2 - Build the entity-appropriateness table

From the deduped findings, extract all Findings with an entity appropriateness concern
(action in: `relabel`, `migrate`, `flag` with an entity mismatch). Format as the
"Entity appropriateness" table from `report-template.md`:

| File | Current type | Problem | Target type / action |

### Step 3 - Stamp dates

- `audit date`: the absolute calendar date of this consolidation run (today's date).
- `next review due`: 90 days after `audit date` (absolute calendar date, same format).

Do not use relative dates ("in 3 months"). Use ISO 8601 format: `YYYY-MM-DD`.

### Step 4 - Assemble the report

Fill the `report-template.md` structure. Omit sections that have no findings
(e.g. no hooks findings -> omit "Hooks audit"). Include:
- Inventory (from Baseline; note which reviewer domains were present in input).
- All audit sections that have at least one finding.
- Recommendations (Delete / Migrate / Merge / Local docs actions).

The report must contain `audit date` and `next review due` absolute dates in the Inventory line.

### Step 5 - Emit proposed_actions

After the markdown report, emit a fenced code block:

    ```json
    { "proposed_actions": [ ... ] }
    ```

Entries come from: C1 dedup deletions, C2 promotions (after C5 loopback), C3 collision
resolutions, C4 cross-scope flags. Each entry:

```json
{
  "id": "<unique short id>",
  "action": "delete|promote|flag|migrate",
  "path": "<abs path of the primary file>",
  "detail": "<what to do and why>",
  "requires_signoff": true | false
}
```

`requires_signoff: true` for: any delete, any promote, any change touching
`bypassPermissions`, credentials, or a file in a team-tracked location.
`requires_signoff: false` for: low-risk flags with no file modification (e.g. add `paths:`
to a rule that currently loads unconditionally).

### Step 6 - Coverage note

In the Inventory section of the report, list: "Reviewer domains present: memory, rules,
claude-md, entities, security-config, local-docs" (or flag any absent domain). This makes
the consolidation auditable.

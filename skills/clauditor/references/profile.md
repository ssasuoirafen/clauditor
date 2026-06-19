# User setup profile and principles

## User setup profile

**Read the user's `~/.claude/CLAUDE.md` first** and derive the conventions below from it - the generic defaults in this command are overridden by whatever the global file actually says. The profile most stages assume (this user's avotech / PureGym / personal setup):

1. **CLAUDE.md lives at project ROOT (`<project>/CLAUDE.md`), not `<project>/.claude/CLAUDE.md`.** Read/grep the root path everywhere this command says `.claude/CLAUDE.md`; treat `.claude/CLAUDE.md` as fallback only. If neither exists, that's a finding.
2. **Secrets in gitignored personal config.** The policy (which personal files are gitignored, why a hardcoded secret in a gitignored file is acceptable, why the same token lives in both `settings.json` `env` and `.mcp.json`) is in `~/.claude/CLAUDE.md` (Security + Gitignore strategy) - derive it there, don't restate it. **Audit checks:** confirm gitignore status with `git check-ignore <file>` (or read `.git/info/exclude` + committed `.gitignore`); flag a secret only when it sits in a **tracked** file (`git ls-files`); a secret in a gitignored file, and the `env`<->`.mcp.json` token duplication, are NOT findings (mechanics in 5f).
3. **Repo type changes gitignore expectations.** The per-repo-type policy (personal/avotech, deployment-target/rundeck, PureGym, and the neutral status of `.local/`) is in `~/.claude/CLAUDE.md` (Gitignore strategy) - derive it per project, don't restate it. **Audit checks:** a committed `.gitignore` naming AI-tooling (`.claude`/`CLAUDE.md`/`.mcp.json`/`superpowers`) is a finding (leaks internal tooling to the team) - cross-check by grepping the **committed** `.gitignore` for `.claude`, `CLAUDE`, `mcp`, `superpowers`, `AI`; do NOT flag `.local/` in a committed `.gitignore` and do NOT propose moving it (scratch dir, leaks nothing - see memory [[local-gitignore-placement]]).
4. **No git layer at all** (no `.git/`): gitignore-intent checks are moot, but a token-bearing `.mcp.json`/`settings.json`/key file with no protection is a **finding** - if the dir is ever `git init`-ed (or sits inside a parent repo), secrets commit in the clear. Recommend a preemptive `.gitignore`. Check whether a parent dir is a git repo that could capture this one.
5. **`.local/` is a multi-surface tree, not just `.local/docs/`.** Common subdirs: `docs/` (notes/analysis), `projects/` (active work trackers - **a first-class active-project surface, audit it like memory `project_*`**), `tasks/`, `sql/`, `scripts/`, `data/` (payloads - **may hold non-regenerable keys/certs, see Stage 6**), `reports/`, `prompts/`. All gitignored.
6. **Parent-scope memory loads too.** A project at `.../Projects/foo` also inherits memory at the parent path `.../Projects` (slug `c--Users-...-Projects`). Inventory both; the parent scope holds genuinely cross-project references (don't flag those as misplaced), but check for parent<->child duplication.

## Language

Determined per project, not hardcoded:

1. **Project `CLAUDE.md`** (root - profile #1) - language of sections and comments. If most content is in Russian, respond in Russian; if English, respond in English; if mixed, follow the dominant language.
2. **README** in the repo root (if present) - language of documentation.
3. **Git history** - check the last ~10 commits: language of commit messages.
4. **If context is indeterminate** - follow the user's `~/.claude/CLAUDE.md` (may specify a default language).

Files, code identifiers, paths, frontmatter keys (`name`, `paths`, `tools`) - always English, regardless of response language or document content.

## Principles

1. **Single source of truth.** Every rule/fact lives in one place. If a duplicate exists, remove the one that isn't auto-loaded.
2. **Targeted load > full-context blob.** Narrow normative rules shouldn't live in CLAUDE.md (it's always in context - bloating it is expensive). Options for **truly targeted** loading: rule with `paths:` frontmatter in `.claude/rules/` (native Claude Code path-scoped auto-load - loads only when matching file is touched); skill with triggers in `description` (auto-activation by context match). Note: `@<path>` reference inside CLAUDE.md is NOT targeted loading - it's an unconditional include because CLAUDE.md itself is always loaded. Use `@` only for documentation cross-linking, not for token-budget management.
3. **Memory is not a dump.** What goes there: narrow protective rules (against my mistakes in review/debugging), active projects, links to external resources. What does NOT go there: code rules, setup instructions, completed projects, project conventions (those belong in rule/CLAUDE.md).
4. **`.local/docs/` is canonical for working artifacts.** Personal analysis, notes, runbooks, drafts live in `.local/docs/`. `.claude/docs/` is wrong directory for docs - that path is reserved for Claude config. Team-wide docs only go to a team wiki if the project explicitly requires it.
5. **Entity matches launch method.** Command - user invokes manually (`/name`). Skill - auto-triggered by `description`. Agent - isolated context and tool allowlist. Rule - targeted normative rule, loaded by reference from CLAUDE.md. Hook - harness reaction to an event (shell, not an instruction). Don't confuse: skill for a manual button, command for auto-knowledge, rule for harness automation - all three are wrong.

   **Caveat (current Claude Code):** commands and skills are the *same underlying mechanism* - `.claude/commands/x.md` and `.claude/skills/x/SKILL.md` both create `/x` and run identically. The real split is **auto-trigger** (skill with a triggering `description`) vs **manual-only** (`disable-model-invocation: true`), not file location. The command-vs-skill guidance in Stage 5a/5c still holds - read it as "which invocation behavior do you want", not "two separate entity systems".

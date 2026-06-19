# Report template

Paste this structure into the final report. Fill in the placeholders. Omit sections that don't apply.

```markdown
## .claude/ audit - <project> - <date>

### Inventory
- Mode: interactive | read-only   ·   Repo type: personal/avotech/deployment-target/PureGym/no-git   ·   Project kind: consumer | MCP-producer | infra | web/app   ·   audit date: <abs date>   ·   next review due: <abs date>
- Memory: total N (feedback: F, project: P, reference: R); parent-scope: Np entries
- Rules: N files (P with `paths:`, U unconditional; cross-cut: how many are also linked via `@` from CLAUDE.md for documentation)
- Skills: K files
- Agents: M files (with `tools:` allowlist: X of M)
- Commands: C files
- Hooks: H entries (project: Hp, project-local: Hl, user-scope: Hu)
- MCP servers: S configured (in `.mcp.json`: Sm, in `settings.json` mcpServers: Ss)
- Settings: keys defined at each scope (env: <list>, permissions: <count>, model: <value or none>, statusLine: <yes/no>)
- Output styles: O custom; active = `<name or default>`
- Plugins: P enabled (commands shipped: Pc; name-collisions with own: Px; semantic overlaps: Po)
- .claude/docs/: A files
- .local/: docs B, projects Pj (active trackers), data D (key material? Y/N)

### Mismatches with reality
| In CLAUDE.md / config | In repo | Action |

### Memory cleanup outcomes (Stage 2)
| Entry | Category | Action |

### Entity appropriateness (Stage 5)
| File | Current type | Problem | Target type / action |
|---|---|---|---|
| `rules/foo.md` | rule | loads unconditionally but only relevant to `src/api/` | add `paths: ["src/api/**"]` |
| `skills/bar/SKILL.md` | skill | one-step manual flow with argument | reformat as command |
| `agents/baz.md` | agent | no `tools:` allowlist | add allowlist |

### Hooks audit (Stage 5e)
| Scope | Event | Matcher | Command | Issue |

### MCP audit (Stage 5f)
| Server | Source | Secrets | Used? | Action |

### Settings audit (Stage 5g)
| Scope | Key | Value | Issue |

### Secrets & gitignore audit (profile #2-4, Stage 5f/5g)
| File | Tracked? | Secret? | Verdict (leak / OK-gitignored / committed-gitignore-leak / no-git-unprotected) |

### Blast radius (Stage 5f)
| MCP server | Target (prod? unauth?) | Risk |

### Output styles audit (Stage 5h)
| File | Activated? | Action |

### Plugin audit (Stage 5j)
| Plugin | Ships (commands/skills) | Collision with own? | Action |

### Recommendations
**Delete (X entries):**
- ... (reason)

**Migrate (Y entries):**
- ... -> `.claude/rules/<rule>.md`

**Merge (Z groups):**
- A + B + C -> one file

**Local docs actions (W files):**
- `.local/docs/<doc>` - delete (closed ticket / superseded)
- `.local/docs/<doc>` - merge with `.local/docs/<other>` (overlapping scope)
- `.local/docs/<doc>` - update (stale identifiers, drift)
```

(If project explicitly designates a team wiki, append a separate "Wiki sync (optional)" block.)

After sign-off - execute approved recommendations as discrete sub-steps (one stage at a time, smallest atomic action per step: "delete file X", "add `paths:` to rule Y", "merge memory entries A+B into C"). Report status after each sub-step.

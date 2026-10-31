# Treecremental -- Agent Instructions

See `CLAUDE.md` and `docs/NAVIGATION.md` for the master configuration, cold-start resume protocol, and architectural rules.

## Quick Resume Checklist

1. Read `production/session-state/active.md` (`CHECKPOINT` region).
2. Read `project.yaml` to verify the current project stage (`planning`).
3. Consult `design/registry/entities.yaml` before referencing or adding any species, currency, loop, or upgrade ID.
4. Consult `docs/architecture/treecremental_design_doc.md` for the full itemized upgrade catalog, math formulas, and UI specifications.
5. Enforce all constraints in `.claude/rules/`: zero hardcoded numbers, zero offline mechanics, zero emojis, and zero AI-generated code artifacts.

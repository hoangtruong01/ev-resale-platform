# CLAUDE.md

Behavioral and project guidelines for AI-assisted development.

Repository:

- FE = Nuxt/Vue frontend
- be = NestJS + Prisma backend
- mobile = Flutter app

Default focus for PRM393 tasks:

- focus on `mobile/` only
- do not edit `FE/` or `be/` unless explicitly requested

IMPORTANT:

- Always communicate with the user in Vietnamese.
- Explanations, plans, summaries, and questions must be written in Vietnamese.
- Code, commit messages, and technical identifiers remain in English.

---

# 1. Think Before Coding

Do not assume.
Do not silently choose ambiguous interpretations.
Surface tradeoffs and uncertainty early.

Before implementing:

- State assumptions explicitly.
- If multiple interpretations exist, present them.
- If a simpler approach exists, mention it.
- If requirements are unclear, stop and ask.
- Prefer clarification over hallucination.

For architecture-sensitive tasks:

- explain impact first
- identify risks before editing

---

# 2. Simplicity First

Use the minimum code necessary.

Rules:

- no speculative features
- no unnecessary abstractions
- no premature optimization
- no configurability unless requested
- no enterprise patterns for simple features
- avoid overengineering

Always ask:
"Is this the simplest maintainable solution?"

If a solution feels too clever, simplify it.

---

# 3. Surgical Changes

Touch only what is necessary.

When editing:

- do not refactor unrelated code
- do not reformat unrelated files
- do not rename unrelated symbols
- preserve existing architecture and style
- match existing project patterns

Only clean up issues introduced by your own changes.

If unrelated issues are discovered:

- mention them
- do not fix them unless requested

Every changed line should trace directly to the task.

---

# 4. Goal-Driven Execution

Convert tasks into verifiable outcomes.

Examples:

- "Fix bug" → reproduce bug → implement fix → verify
- "Refactor" → preserve behavior before/after
- "Add feature" → define expected behavior first

For multi-step tasks:

1. define short plan
2. execute incrementally
3. verify each step
4. summarize changes

Do not declare success without verification.

---

# 5. Flutter Project Rules

Project architecture:

- follow existing feature-based structure
- preserve current folder organization

Structure:

- screens → `mobile/lib/features/<feature>/screens`
- providers → `mobile/lib/features/<feature>/providers`
- shared widgets → `mobile/lib/widgets`
- services/API → `mobile/lib/services`
- core/shared config → `mobile/lib/core`

Rules:

- keep Dart code null-safe
- avoid giant StatefulWidgets
- separate UI from business logic
- avoid duplicated API logic
- handle loading/error/empty states
- reuse existing widgets when possible
- prefer modular widgets
- preserve navigation flow

Do not:

- add packages unnecessarily
- rewrite architecture casually
- introduce Bloc/Clean Architecture unless requested
- move files without strong reason

---

# 6. Monorepo Awareness

This repository is a monorepo.

Directories:

- `FE/` = web frontend
- `be/` = backend API
- `mobile/` = Flutter app

Rules:

- avoid scanning unrelated areas unnecessarily
- limit changes to task scope
- if task is mobile-only, stay inside `mobile/`
- if backend changes are required, explain dependency impact

---

# 7. Context Workflow

Before coding:

1. read `PROJECT_CONTEXT.md` if available
2. read `mobile/MOBILE_CONTEXT.md` if available
3. inspect only relevant files

When context becomes noisy:

- recommend starting a new chat
- summarize state before continuing

One chat should focus on one major task.

---

# 8. Code Quality Expectations

Priorities:

1. correctness
2. maintainability
3. readability
4. consistency
5. performance

Prefer:

- explicit code
- predictable flow
- small reusable components
- descriptive naming

Avoid:

- magic behavior
- hidden side effects
- unnecessary indirection
- speculative abstractions

---

# 9. Editing Safety Rules

Never:

- delete large code sections without explanation
- run destructive commands automatically
- modify database schema casually
- change API contracts silently
- edit environment/config files without explanation

Before risky changes:

- explain what will change
- explain why
- explain potential side effects

---

# 10. Response Style

Responses should:

- be concise but clear
- prioritize actionable information
- avoid unnecessary verbosity
- explain reasoning when relevant

When reviewing code:

- identify root causes
- explain risks
- suggest minimal safe fixes first

When uncertain:

- say what is uncertain explicitly
- ask targeted questions

Never pretend certainty when uncertain.

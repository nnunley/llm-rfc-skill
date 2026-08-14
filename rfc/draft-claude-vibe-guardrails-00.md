# draft-claude-vibe-guardrails-00: Safe Vibe Coding with Mandatory TDD Guardrails

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

The vibe coding methodology is a lightweight, guardrailed process for small fixes and quick changes that trades rigor constraints for speed without sacrificing correctness. It enforces mandatory test-driven development (red/green/refactor), pre-flight architectural and scope checks, reusable component detection, and test infrastructure validation before code authorship. This document specifies the vibe process, its pre-flight gates, and its relationship to the RFC series' lightweight-path philosophy.

## Motivation

Vibe coding addresses a common tension in agent-driven development: small, bounded changes often do not warrant a full architectural review or elaborate planning cycle, yet skipping structure entirely produces brittle code and regressions. Existing fast-path workflows (fix immediately, commit, move on) sacrifice test discipline and architectural awareness; existing rigorous workflows (full requirements extraction, walking skeleton, three-tier auditing) are overkill for a typo fix or a one-line configuration change.

The vibe methodology sits between: it requires mandatory TDD and pre-flight checks before writing code, catching scope creep and architectural problems early, but avoids the heavyweight planning and auditing cycles of larger initiatives. It is designed for tasks bounded to 1—3 files in a single module, with test infrastructure already present.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals, as shown here.

- **Vibe task** — A small, bounded change: fix a bug, add a small feature, update a configuration, or refactor a localized code section.
- **RED/GREEN/REFACTOR** — The three-phase TDD cycle: RED (write a failing test defining expected behavior), GREEN (write minimal code to pass), REFACTOR (clean up while keeping tests green).
- **Pre-flight checks** — Validation gates run before code authorship: test infrastructure presence, existing test coverage, scope validation, architecture smell detection, and reusable component search.
- **Architecture smell** — Discrepancy between task conceptual simplicity and implementation effort, indicating deeper structural issues.
- **Reusable component** — Common functionality (toast notifications, modals, form validation, error handling, logging, permission checks, API calls, data formatting) already implemented elsewhere in the codebase.
- **Proof seam** — The architectural boundary where task correctness is verified: unit test (isolated component), integration test (multi-component), or end-to-end test (user-visible behavior).

## Specification

### Vibe Process Lifecycle

The vibe methodology MUST follow this four-step process:

**Step 1: Task Understanding**

If no task description is provided, ask the user: "What needs fixing or changing?" Once a task description is obtained:
- If the task is unclear, ask clarifying questions one at a time
- Focus on: what will change, what will stay the same, edge cases
- Do NOT over-question simple tasks (e.g., typo fixes)

**Step 2: Pre-flight Checks**

Before writing any code, the agent MUST perform and document the following checks. If any raise concerns, discuss with the user before proceeding:

1. **Test infrastructure check** — Determine if the project has a test framework and runner by examining:
   - Test directories (`test/`, `tests/`, `spec/`, `__tests__/`, etc.)
   - Test config files (`jest.config`, `vitest.config`, `pytest.ini`, `.rspec`, `phpunit.xml`, `Cargo.toml` with `[dev-dependencies]`, etc.)
   - Existing test files in the codebase
   
   If no test infrastructure exists, inform the user and ask: "There's no test setup in this project. Want me to set up a basic test framework first, or proceed without TDD?" If the user chooses to proceed without TDD, skip the RED phase but still execute GREEN and REFACTOR.

2. **Existing test coverage** — Determine if code in the affected area already has tests. If yes, note them—they inform the RED phase and catch regressions. If no, record this and proceed.

3. **Scope validation** — Count files and modules the change touches:
   - 1–3 files in the same module: proceed (good vibe territory)
   - 4+ files or crosses module boundaries: warn the user with exact count and module list, e.g., "This touches [N] files across [modules]. It might be bigger than a vibe task. Want to proceed, or would a more structured approach be better?"

4. **Architecture smell detection** — If the task is conceptually simple but investigation reveals high implementation effort, STOP and investigate deeper structural issues. Discuss findings with the user before proceeding.

5. **Reusable component search** — If the task involves common functionality (toast notifications, modals, form validation, error handling, logging, permission checks, API calls, data formatting), search the codebase for:
   - Existing components or utilities that already implement it
   - Partial implementations someone started but did not finish
   - Patterns used elsewhere for the same kind of work
   
   If found, inform the user and recommend using/extending existing code rather than building from scratch.

**Step 3: Implementation (Red/Green/Refactor)**

Mandatory TDD cycle. Execute strictly:

**RED — Write one failing test**

Write a single test that defines the expected behavior for the change. Run it. It MUST fail. If it does not:
- If the test passes: STOP. The feature or fix already exists, or your test is not testing what you think. Report findings and ask the user how to proceed.
- If the test fails in an unexpected way: STOP. The failure mode reveals an unknown issue. Report expected vs. actual behavior and ask the user how to proceed.

Only proceed to GREEN when the test fails in the expected way.

**GREEN — Write minimal code to pass**

Write the simplest code that makes the failing test pass. Resist:
- Adding error handling for cases not covered by the test
- Building abstractions "while you're in there"
- Fixing adjacent code that is not broken
- Adding features beyond what was asked

Run the test. It MUST pass. Run all existing tests in the affected area—ensure nothing broke.

**REFACTOR — Improve while keeping tests green**

Clean up. Look for:
- Duplicated logic that SHOULD be extracted
- Hard-coded values that belong in config or constants
- Inconsistent patterns where new code does not match conventions
- Naming that could be clearer
- Dead code the change made obsolete

Run all tests after refactoring. Everything MUST stay green.

**Repeat if needed**

If the task involves multiple behaviors, repeat the red/green/refactor cycle for each behavior, one at a time.

**Step 4: Post-fix Summary**

After the fix is complete, provide a brief summary:
- **What changed:** files modified, lines added/removed
- **Tests added:** the RED tests and what they verify
- **Refactoring done:** what was cleaned up in the REFACTOR step
- **Reusable components:** whether existing components were leveraged or new ones created

Suggest PAAD skills when genuinely relevant:
- If the change touched security-sensitive code (auth, permissions, input handling, secrets) → suggest `/paad:agentic-review`
- If the change touched UI components → suggest `/paad:agentic-a11y`
- If the change was significantly harder than expected → suggest `/paad:agentic-architecture`

### Vibe Task Lifecycle State Machine

```fsm
initial task_description
task_description -> unclear
unclear -> unclear            ; clarify one more question
unclear -> preflight          ; task understood
task_description -> preflight ; task clear from start
preflight -> test_check
test_check -> no_framework
test_check -> proceed
no_framework -> no_framework_decision
no_framework_decision -> red ; proceed without RED phase
no_framework_decision -> end ; abort task
proceed -> scope_check
scope_check -> oversized
oversized -> oversized_decision
oversized_decision -> end ; abort task
oversized_decision -> arch_check ; user accepts bigger scope
arch_check -> arch_smell
arch_smell -> end ; abort task
arch_check -> reuse_search ; no architecture issues
reuse_search -> found_reuse
found_reuse -> end ; recommend existing component
reuse_search -> red ; no existing component found
red -> red_pass_unexpected
red_pass_unexpected -> end ; feature already exists
red -> red_fail_unexpected ; test fails in unexpected way
red_fail_unexpected -> end ; unknown issue
red -> red_fail_expected ; test fails as expected
red_fail_expected -> green
green -> test_pass
test_pass -> green_all_pass
green_all_pass -> refactor
green_all_pass -> repeat_red ; multiple behaviors remain
refactor -> refactor_complete
refactor_complete -> summary
repeat_red -> red
summary -> end
terminal end
```

### Relation to the RFC Fast-Track Philosophy

The vibe methodology embodies the same philosophy as the RFC series' lightweight path (draft-ndn-authoring-rfcs-00): **non-negotiable guardrails scaled to stakes**. RFCs on the fast track require conformance evidence and scope review before publication, ensuring small, quick specifications still carry durable proof of claimed behavior. Vibe coding requires pre-flight checks and mandatory TDD before implementation, ensuring small, quick fixes still carry proof of correctness and architectural awareness.

Both systems reject the false choice between rigor and speed: rigor is not proportional to scope, it is proportional to risk. Small changes that touch security-sensitive or high-reuse code carry the same risk as large changes; both require evidence gates. Vibe coding keeps those gates lightweight (pre-flight checks + TDD in isolation) but non-negotiable.

## Alternatives Considered

### Direct implementation without pre-flight checks

Fix immediately, commit, move on. Fast but loses visibility into scope creep, architectural issues, and missing test infrastructure. Rejects this because scope creep and architecture smells compound rapidly; catching them early is cheaper.

### Full structured workflow (walking skeleton, three-tier auditing)

Extracting requirements, scoping iterations, running audits for every small fix is overkill for a typo or one-line change. Rejects this for task-scoped work because overhead outweighs benefit; reserve heavyweight workflows for larger initiatives.

### Test-driven development without pre-flight checks

Writing tests first ensures correctness but does not catch scope creep, architecture issues, or missing test infrastructure. Vibe methodology pairs TDD with pre-flight gates to ensure both correctness AND feasibility before authorship.

## Security Considerations

Pre-flight checks may reveal security-sensitive code paths (auth, permissions, input handling, secrets). The vibe process signals this to the user and recommends `/paad:agentic-review` before merging security-sensitive changes. The TDD requirement ensures security-relevant behavior is tested and cannot regress silently.

Test infrastructure itself may not exist or may be misconfigured; a project without tests cannot verify that a "fix" does not introduce a vulnerability. The infrastructure check surfaces this risk upfront, allowing the user to decide whether to proceed or invest in test setup first.

The pre-flight reusable component search may encounter sensitive components (authentication, secrets management, permission checking); implementation MUST respect existing patterns and abstraction boundaries to avoid weakening the security model.

## References

- Curtis "Ovid" Poe, PAAD (Practical Agent Architecture for Development): https://github.com/Ovid/paad at commit 149926aa231e (v1.11.0), vibe skill
- draft-ndn-authoring-rfcs-00 — The RFC process for human–LLM specification authoring (fast track, lightweight conformance gates)
- RFC 2119, RFC 8174 (BCP 14) — Formal requirement language conventions

## Changelog

- 2026-08-14: draft-00 created, documenting the vibe process from PAAD's vibe skill (Ovid/paad at commit 149926aa231e, v1.11.0). Captures the four-step process (task understanding, pre-flight checks, red/green/refactor, post-fix summary), pre-flight gates (test infrastructure, existing tests, scope, architecture smell, reusable components), and relationship to the RFC series' lightweight-path philosophy. Includes FSM for vibe task lifecycle.

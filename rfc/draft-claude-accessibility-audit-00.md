# draft-claude-accessibility-audit-00: Multi-Agent Accessibility Audit Process for User-Facing Code

**Status:** DRAFT
**Category:** Informational
**Authors:** Claude (drafting agent), Norman Nunley, Jr <nnunley@gmail.com>
**Date:** 2026-08-14

## Abstract

The multi-agent accessibility audit process is a systematic framework for comprehensive accessibility review of user-facing code across any platform — web, mobile (iOS/Android/React Native/Flutter), desktop, CLI, and games. It dispatches five specialist agents in parallel, each focused on a distinct disability category (screen readers, vision, motor, cognitive, and multimedia), verifies findings to eliminate false positives, maps issues to WCAG 2.2 criteria and platform-specific guidelines, and produces a structured report with concrete fixes and WCAG AA/AAA conformance ratings.

## Motivation

Accessibility testing has historically been either a compliance checkbox (automated checkers that catch obvious issues but miss context-dependent barriers) or ad-hoc expert review (deep but not systematic, easy to miss disability categories). Neither approach scales to complex products with multiple platforms, frameworks, and surfaces.

The multi-agent audit process addresses this by:

1. Dispatching five independent specialist agents in parallel, each with deep domain knowledge of a specific disability category, eliminating the blind spots of single-agent generalists.
2. Running verification on all findings to confirm the barrier exists in actual code and is not already handled by the platform, framework, or component library.
3. Mapping every finding to specific, actionable WCAG 2.2 criteria (with platform-specific equivalents via WCAG2ICT) and severity levels, making findings auditable and researchable.
4. Producing a persistent report with quick wins, critical vs. serious vs. moderate issues, and cross-platform coverage — serving as a durable record of the audit and a roadmap for remediation.

## Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals, as shown here.

- **Barrier** — An accessibility defect: code that prevents users with a specific disability from perceiving, navigating, understanding, or interacting with the interface.
- **Conformance level** — WCAG proficiency: Level A (minimum), Level AA (mainstream accessibility target), or Level AAA (enhanced accessibility).
- **Specialist agent** — An autonomous agent focused on one disability category (screen readers, vision, motor, cognitive, multimedia). Each agent reads a file manifest and reports findings at ≥60% confidence.
- **Verification** — A pass that confirms a specialist's finding reflects actual code behavior and is not handled elsewhere (platform API, framework feature, component library, or system-level setting).
- **Platform detection** — Classification of the project into one or more categories (web, iOS, Android, React Native, Flutter, desktop, CLI, game) based on file extensions and imports present in the repository.
- **Quick Win** — A fix with high impact and low effort, suitable for immediate remediation to improve overall conformance quickly.

## Specification

### Audit Lifecycle

The multi-agent accessibility audit follows this four-phase process:

#### Pre-flight Checks

Before dispatching specialists, the audit orchestrator MUST:

1. Verify the conversation has no prior substantive context (recommend fresh session if history exists, as audit consumes significant context).
2. Scan the repository for user-facing code indicators (file types and platform-specific patterns) across all supported platforms.
3. If no user-facing code is found, STOP and report to the user.

#### Phase 1: Reconnaissance

The orchestrator MUST execute:

1. **Platform detection** — Classify the project by file indicators (web: `.html`, `.jsx`, `.tsx`, `.vue`, etc.; iOS: `.swift`, `.storyboard`, etc.; Android: `.kt`, `.xml`, etc.; React Native: `.jsx`/`.tsx` with react-native imports; Flutter: `.dart` with flutter imports; desktop: Electron, Qt, WPF, etc.; CLI: any code producing terminal output; game: Unity, Unreal, Godot, etc.).
2. **Tech stack identification** — For each detected platform, identify frameworks, libraries, and tooling (e.g., React + Tailwind for web, SwiftUI vs UIKit for iOS, Compose vs View for Android).
3. **User-facing code inventory** — Collect all files producing UI or handling interaction, grouped by platform.
4. **Existing tooling audit** — Check for built-in or plugin-based accessibility tooling (eslint-plugin-jsx-a11y, Accessibility Inspector, espresso accessibility checks, SemanticsDebugger, pa11y, Lighthouse, etc.).
5. **Steering files scan** — Locate and read CLAUDE.md, AGENTS.md, or project-specific a11y guidelines.
6. **Scope estimation** — Classify as small (<20 files), medium (20–100 files), or large (100+ files).
7. **Manifest assembly** — Produce a grouped, annotated file list for each specialist.

#### Phase 2: Specialist Audit (Parallel)

The orchestrator MUST dispatch five core specialist agents simultaneously, plus one conditional platform-specific agent if applicable. Each agent receives:

- The file manifest (their audit scope)
- Detected platform(s) and tech stack
- Steering file contents with caveat: "These MAY be stale; if code contradicts them, flag as a finding."
- Existing a11y tooling notes
- Platform-specific guidance for their disability category

**Core specialists (MUST be dispatched):**

1. **Screen Reader & Assistive Tech** — Programmatic UI semantics: correct ARIA, semantic HTML, heading hierarchy, meaningful alt text, form labels, live regions, role/purpose clarity. For native platforms (iOS, Android, React Native, Flutter, desktop): correct accessibility labels, traits, hints, state annotations, custom actions, dynamic notifications.
2. **Visual & Color** — Contrast ratios (AA: 4.5:1 normal / 3:1 large; AAA: 7:1 / 4.5:1), color-independence, text scaling, magnification, focus indicators. Platform-specific: Dynamic Type, Bold Text, Increase Contrast, custom themes.
3. **Keyboard & Motor** — Complete keyboard operability, no focus traps, logical order, visible focus, skip links, adequate targets (44×44pt min), no gesture-only actions. Platform-specific: Full Keyboard Access, Switch Control, touch targets, one-handed modes.
4. **Cognitive & Learning** — Consistency, predictability, clear error messages, form labels, adequate time, help location, no cognitive tests, authentication accessibility.
5. **Multimedia & Temporal** — Captions on video, transcripts for audio, motion safety (<3 flashes/sec), auto-play controls, `prefers-reduced-motion`, no seizure triggers.

**Conditional specialist (dispatch if platform-specific a11y pitfalls detected):**

6. **Platform-Specific Patterns** — Framework-specific bugs: React (list keys, missing aria-live), Vue (v-html, dynamic aria), Angular (cdkTrapFocus), Svelte (reactive focus loss), SwiftUI (.accessibilityRepresentation), Compose (semantics gaps), Flutter (CustomPainter), React Native (FlatList), game engines (EventSystem).

For large scope (100+ files), partition files across two instances of each specialist.

#### Phase 3: Verification

After specialists complete, dispatch a single **Verifier** agent with all findings. The verifier MUST:

1. Read actual code at each reported file:line.
2. Confirm the barrier exists and is not handled by the platform, framework, component library, or system setting.
3. Drop false positives and findings below 60% confidence.
4. Confirm the correct WCAG criterion or platform guideline is cited.
5. Assign severity: Critical (complete barrier), Serious (major difficulty), Moderate (friction), Minor (best practice / AAA enhancement).
6. Note cross-specialist agreement (increases confidence).

#### Phase 4: Report

Write verified findings to `paad/a11y-reviews/a11y-<YYYY-MM-DD-HH-MM-SS>.md`. The report MUST include:

- Executive summary (2–3 sentences on overall posture and conformance level)
- Impact summary by user group (screen reader, low-vision, colorblind, motor-impaired, cognitive/learning, deaf/hard-of-hearing, vestibular/photosensitive)
- Critical, Serious, Moderate, and Minor findings (each with file:line, platform, barrier, criterion, fix, confidence, found-by agents)
- WCAG conformance checklist per principle (Perceivable, Operable, Understandable, Robust)
- Platform-specific guidelines table (if applicable)
- Quick Wins (top 5 fixes by impact/effort)
- Audit metadata (agents dispatched, platforms, scope, raw/verified counts, severity breakdown, conformance breakdown)

### Conformance Target

Projects are audited against **WCAG 2.2 AA via WCAG2ICT** (web platforms conforming to WCAG 2.2 directly; non-web platforms interpreted via WCAG2ICT mapping). AAA criteria are flagged as bonus recommendations. Platform-specific guidelines (Apple HIG Accessibility, Material Design Accessibility, Xbox Accessibility Guidelines) are applied as supplements when the platform is detected.

### Audit State Machine

The audit lifecycle state machine is:

```fsm
initial preflight
preflight -> phase1
preflight -> stop_nocode
phase1 -> specialists
specialists -> specialists   ; per-agent completion
specialists -> verification
verification -> report
report -> done
terminal stop_nocode
terminal done
note preflight: Context check, file scan for user-facing code
note phase1: Platform detection, tech stack ID, inventory, manifest assembly
note specialists: Five core agents + optional platform-specific agent run in parallel
note verification: Confirm findings, drop false positives, assign severity
note report: Write comprehensive report with findings, conformance checklist, quick wins
```

## Alternatives Considered

### Single generalist agent

A single accessibility expert agent could audit the entire codebase. This is faster but misses disability-category-specific pitfalls — a generalist cannot deeply know the intersection of screen reader APIs with every framework, or the nuances of vestibular disorders and motion safety. Specialist agents catch barriers that would be invisible to a generalist.

### Automated checkers only

Tools like axe-core, pa11y, and ESLint plugins catch obvious issues (missing alt text, low contrast, missing labels) deterministically but cannot reason about context. Barriers like "link text is 'Click here'" pass automated checks but fail for screen reader users. Specialist agents reason about context and user experience.

### Manual expert review

Accessibility auditors are highly trained but expensive and require deep project immersion. The specialist agent process automates the systematic parts (platform detection, file inventory, evidence gathering) while keeping the expert reasoning (verification, severity assignment, fix recommendations) in the LLM loop.

## Security Considerations

Findings transcripts in the report may contain file paths and code snippets. If the project is sensitive or private, restrict report distribution. The audit process reads files from the repository — treat audit access like code review access (standard authorization required).

Specialist agents may compose explanations from steering files; if steering files are untrusted, audit findings could reflect injected narratives. Mitigation: code review steering files before audit, same as specification review.

## References

- **Curtis "Ovid" Poe** — PAAD (Parallel Accessible Auditing Dispatcher) creator; agentic-a11y skill reviewed at commit 149926aa231e (v1.11.0)
  https://github.com/Ovid/paad
- **W3C WCAG 2.2** — Web Content Accessibility Guidelines Level 2.2
  https://www.w3.org/TR/WCAG22/
- **W3C WCAG2ICT** — Applying WCAG 2.2 to non-web information and communications technologies
  https://www.w3.org/TR/wcag2ict-20/
- **Apple Human Interface Guidelines: Accessibility**
  https://developer.apple.com/design/human-interface-guidelines/accessibility
- **Material Design: Accessibility** — Android design guidelines
  https://material.io/design/usability/accessibility.html
- **Xbox Accessibility Guidelines**
  https://xbox.com/en-US/developers/design
- **draft-claude-adversarial-review-00** — Parallel adversarial review methodology; finding aggregation and severity assignment model
- **draft-ndn-authoring-rfcs-00** — RFC specification and authoring process; evidence structures and conformance corpus model

## Changelog

- 2026-08-14: draft-00 created, documenting the multi-agent accessibility audit process as implemented in PAAD's agentic-a11y skill (reviewed at commit 149926aa231e, v1.11.0). Covers pre-flight checks, reconnaissance (platform detection, tech stack ID, inventory, manifest assembly), parallel specialist dispatch (five core disabilities plus conditional platform patterns), verification phase (false-positive filtering, severity assignment), report generation with WCAG 2.2 AA/AAA conformance checklist and quick wins, and FSM modeling the overall audit lifecycle. Includes references to WCAG2ICT for non-web platform interpretation and platform-specific guideline supplements (HIG, Material Design, Xbox).

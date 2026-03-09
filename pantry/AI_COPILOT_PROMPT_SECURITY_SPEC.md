# AI Copilot Prompt Security Specification

## Document Status
- Owner: Pantry App Team
- Last Updated: March 8, 2026
- Status: Draft for implementation planning
- Scope: LLM-backed assistant flows in `ChatView`, `DashboardAISection`, and `LLMService`

## Purpose
Define mandatory security controls for malicious, ambiguous, or malformed prompting so the pantry copilot can safely read and modify local data.

## Security Goals
1. Prevent unauthorized or unintended data mutations caused by prompt injection or malformed tool input.
2. Preserve user control over destructive or bulk operations.
3. Minimize sensitive data exposure to external LLM APIs.
4. Provide traceability and rollback for AI-initiated changes.

## Threat Model

### In-Scope Threats
1. Prompt injection from user input, OCR text, barcode metadata, or imported recipe text.
2. Malformed tool arguments that bypass assumptions in model-layer handlers.
3. Ambiguous fuzzy matching causing edits/deletes on the wrong item.
4. Over-broad data serialization leaking unnecessary personal data.
5. Repeated tool calls creating runaway writes.

### Out-of-Scope (for this spec phase)
1. Device compromise / jailbreak.
2. Transport-layer compromise outside Apple/Anthropic TLS guarantees.
3. Cloud multi-tenant data isolation (CloudKit not active yet).

## Trust Boundaries
1. Trusted: local policy engine, schema validators, SwiftData mutation layer.
2. Partially trusted: model-generated tool calls.
3. Untrusted: free text from users, OCR receipts, barcode text, imported URLs/files.

All untrusted content must be treated as data and never as policy-bearing instructions.

## Required Control Set

### C1: Intent Classification and Action Gating
1. Every assistant turn must be classified as `READ`, `PLAN`, or `WRITE`.
2. `WRITE` classification requires:
- explicit target entity
- explicit operation
- explicit parameters
3. If intent confidence is below threshold, system must downgrade to `PLAN` and request clarification.

### C2: Two-Phase Write Execution
1. Phase A (`Propose`): generate structured action plan only.
2. Phase B (`Apply`): execute validated actions after user approval for high-risk operations.
3. High-risk operations requiring explicit approval:
- delete, archive, bulk update
- operations touching more than N records (default N=3)
- operations with fuzzy target resolution

### C3: Tool Contract Hardening
1. All tools must use strict JSON schema validation before execution.
2. Reject:
- unknown keys
- wrong types
- out-of-range values
- invalid dates/units
3. No direct execution from raw model text; only validated schema payloads.

### C4: Deterministic Entity Resolution
1. Destructive operations must resolve by stable ID, not fuzzy name alone.
2. If multiple candidates match, assistant must return a disambiguation prompt.
3. Fuzzy matching can be used for suggestions but not final destructive writes.

### C5: Policy Engine for Mutation Guardrails
1. Introduce a policy layer that evaluates each proposed tool call before execution.
2. Policy denies:
- `delete all` style requests without explicit confirmation
- bulk operations above configured threshold without approval
- repeated identical write calls within a rate window
3. Policy returns machine-readable deny reasons for user-facing explanations.

### C6: Data Minimization for LLM Context
1. Serialize only fields needed for current intent/tool.
2. Default to summary representations; expand detail only on demand.
3. Redact or omit sensitive free-form notes unless explicitly needed.

### C7: Prompt Injection Resilience
1. System instructions must explicitly ignore instruction-hierarchy overrides from user/OCR/import text.
2. OCR/import text must be wrapped and labeled as untrusted context.
3. Assistant must not treat quoted external text as tool directives.

### C8: Key and Secret Handling
1. Move API key storage to iOS Keychain.
2. Never include key material in logs, analytics, or LLM context.
3. Enforce runtime checks for missing/invalid key before network calls.

### C9: Auditing, Explainability, and Undo
1. Log each assistant write action with:
- timestamp
- originating message ID
- proposed args
- validated args
- final outcome
2. Provide user-visible “Recent AI Actions” feed.
3. Support rollback/undo for reversible mutations.

### C10: Runtime Safety Limits
1. Max tool-call depth per turn (default: 8).
2. Max tool writes per turn (default: 5).
3. Timeout and fail-safe to non-mutating response on repeated validation failures.

## Functional Requirements
1. FR-PS-1: Assistant must not perform write operations without policy validation.
2. FR-PS-2: Assistant must require explicit user confirmation for high-risk writes.
3. FR-PS-3: System must disambiguate non-unique targets before mutation.
4. FR-PS-4: System must capture immutable audit entries for all AI writes.
5. FR-PS-5: Users must be able to inspect and undo recent AI actions where possible.

## Non-Functional Requirements
1. NFR-PS-1: Validation + policy check overhead must stay under 100ms per tool call on modern devices.
2. NFR-PS-2: Security controls must not block read-only conversational responses.
3. NFR-PS-3: All denied actions must provide clear reason text for user trust.

## Proposed Architecture Changes
1. Add `CopilotPolicyService` for rule evaluation and risk scoring.
2. Add `ToolInputValidator` for strict schema/type enforcement.
3. Add `EntityResolver` for deterministic ID resolution + disambiguation.
4. Add `CopilotAuditService` and a lightweight `CopilotActionLog` model.
5. Refactor `LLMService` into:
- intent classification
- proposal generation
- policy-checked execution

## Test Strategy (TDD First)

### Unit Tests
1. Policy denies ambiguous deletes.
2. Policy requires confirmation for bulk writes above threshold.
3. Validator rejects unknown fields and invalid types.
4. Resolver returns disambiguation when >1 target candidate.
5. Injection payload in OCR text is treated as inert data.

### Integration Tests
1. End-to-end flow: user asks to remove “milk” when multiple milk items exist.
2. End-to-end flow: model proposes `delete all`; policy blocks and requests confirmation.
3. End-to-end flow: malformed tool JSON never reaches mutation layer.

### Regression Tests
1. Existing read-only copilot prompts still respond without extra friction.
2. Common valid write intents still succeed with expected confirmation UX.

## Rollout Plan
1. Phase 1: Validation + policy engine + deterministic resolution for destructive tools.
2. Phase 2: Two-phase approvals + audit log + undo.
3. Phase 3: Data minimization + prompt-injection hardening for OCR/import paths.
4. Phase 4: Runtime limits, monitoring metrics, and UX refinement.

## Success Metrics
1. 0 unconfirmed destructive AI writes in telemetry.
2. <1% ambiguous-write execution attempts without disambiguation.
3. 100% tool writes recorded in audit log.
4. No critical prompt-injection test failures in release gate suite.


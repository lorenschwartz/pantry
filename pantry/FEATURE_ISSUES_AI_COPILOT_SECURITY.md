# Feature Issue Tickets: AI Copilot + Prompt Security

## Usage
Copy each section into your issue tracker as a standalone ticket. IDs are local planning IDs.

---

## COP-SEC-001: Introduce Copilot Policy Engine for Tool Calls
- Priority: P0
- Type: Feature
- Problem:
Current assistant flows can execute tool mutations directly once a model emits tool input. There is no centralized policy enforcement for risk, bulk scope, or ambiguous targets.
- Scope:
Create `CopilotPolicyService` that evaluates every proposed tool call before execution.
- Acceptance Criteria:
1. All mutating tools run through policy evaluation.
2. Policy can return `allow`, `deny`, or `require_confirmation`.
3. Policy blocks destructive bulk actions by default.
4. Denied calls return clear reason text for UI.
5. Unit tests cover allow/deny/confirm pathways.
- Dependencies:
None (foundational).
- Risks:
May over-block valid actions initially; tune via policy config.

---

## COP-SEC-002: Add Strict Tool Input Validation Layer
- Priority: P0
- Type: Feature
- Problem:
Tool handlers currently trust parsed dictionaries too much and may accept malformed or unexpected keys/types.
- Scope:
Add `ToolInputValidator` with strict schema checks for each tool.
- Acceptance Criteria:
1. Unknown keys are rejected.
2. Wrong types are rejected.
3. Required fields enforced per tool.
4. Invalid ranges/formats (dates, quantities) rejected.
5. Validation failures never invoke mutation handlers.
6. Unit tests for every tool schema.
- Dependencies:
COP-SEC-001 recommended.
- Risks:
Schema drift if tools evolve without validator updates.

---

## COP-SEC-003: Replace Fuzzy Destructive Writes with Deterministic Resolution
- Priority: P0
- Type: Feature
- Problem:
Name-based fuzzy matching can mutate the wrong `PantryItem` or `ShoppingListItem`.
- Scope:
Introduce `EntityResolver` and require stable IDs for destructive operations.
- Acceptance Criteria:
1. Delete/update destructive writes require resolved unique ID.
2. If >1 match exists, assistant produces disambiguation prompt.
3. If 0 matches, no mutation occurs.
4. Unit tests for ambiguous and exact-match cases.
- Dependencies:
COP-SEC-002
- Risks:
Increased user prompts for ambiguous names; UX refinement needed.

---

## COP-SEC-004: Implement Two-Phase Write Flow (Propose -> Apply)
- Priority: P0
- Type: Feature
- Problem:
Assistant currently performs writes in one pass, reducing user control over risky actions.
- Scope:
Implement structured proposal objects and apply only after required confirmation.
- Acceptance Criteria:
1. Mutating requests first return a proposal summary.
2. High-risk proposals require explicit user confirmation.
3. Approved proposals execute exactly once.
4. Rejected proposals perform no writes.
5. Integration tests for approve/reject paths.
- Dependencies:
COP-SEC-001, COP-SEC-002
- Risks:
Adds interaction step; must keep low-friction for low-risk actions.

---

## COP-SEC-005: Harden Prompt Handling Against Injection (OCR/Imports/User Text)
- Priority: P0
- Type: Feature
- Problem:
Untrusted text may contain hidden instructions that the model could interpret as higher-priority directives.
- Scope:
Add explicit trust labeling and prompt construction rules for untrusted content.
- Acceptance Criteria:
1. OCR/imported text always tagged as untrusted.
2. System prompt includes hard rule to ignore hierarchy overrides from untrusted text.
3. Untrusted text never directly becomes tool-call payload.
4. Adversarial tests for common injection patterns pass.
- Dependencies:
COP-SEC-002
- Risks:
False positives that reduce helpfulness for advanced prompts.

---

## COP-SEC-006: Minimize LLM Context Data by Intent
- Priority: P1
- Type: Feature
- Problem:
Current serialization often includes broad datasets; not all fields are needed for each task.
- Scope:
Add intent-scoped serializers with least-privilege field selection.
- Acceptance Criteria:
1. Read intents use summaries by default.
2. Detail fields included only when required by selected tool.
3. Sensitive free-text notes excluded unless explicitly requested.
4. Tests validate field-level output for key tools.
- Dependencies:
COP-SEC-001
- Risks:
Over-minimization may reduce response quality for complex asks.

---

## COP-SEC-007: Move LLM API Key Storage to Keychain
- Priority: P1
- Type: Security Feature
- Problem:
API key is currently stored in `UserDefaults`, which is weaker than Keychain for secrets.
- Scope:
Implement `KeychainService` and migrate assistant key storage.
- Acceptance Criteria:
1. New keys write to Keychain only.
2. Existing `UserDefaults` key migrates once then is removed.
3. Assistant reads keys from Keychain for runtime calls.
4. Unit tests cover migration logic.
- Dependencies:
None.
- Risks:
Migration edge cases for existing users.

---

## COP-SEC-008: Add AI Action Audit Log Model and Viewer
- Priority: P1
- Type: Feature
- Problem:
No user-facing trace of what AI changed and why.
- Scope:
Add `CopilotActionLog` model, logging service, and settings/debug viewer.
- Acceptance Criteria:
1. Every AI write logs before/after payload and status.
2. Log includes timestamp, originating prompt snippet, and tool name.
3. User can inspect recent actions in-app.
4. Integration tests verify logs for successful and denied actions.
- Dependencies:
COP-SEC-001, COP-SEC-004
- Risks:
Need to avoid logging sensitive fields excessively.

---

## COP-SEC-009: Add Undo for Reversible AI Actions
- Priority: P1
- Type: Feature
- Problem:
Users need fast recovery from mistaken assistant actions.
- Scope:
Implement undo commands for common reversible mutations (add/update/delete with tombstone metadata).
- Acceptance Criteria:
1. Last AI action can be undone from action feed.
2. Undo restores previous state for supported operations.
3. Unsupported operations clearly indicate non-reversible status.
4. Tests verify state restoration correctness.
- Dependencies:
COP-SEC-008
- Risks:
Complexity around cascading relationship updates.

---

## COP-SEC-010: Add Runtime Safety Limits and Loop Guards
- Priority: P1
- Type: Security Feature
- Problem:
Unbounded tool loops or repeated retries can create excessive writes.
- Scope:
Enforce per-turn limits for tool depth, write count, and repeated failures.
- Acceptance Criteria:
1. Max tool-call depth enforced.
2. Max mutating calls per turn enforced.
3. Repeated validation failures trigger fail-safe no-write response.
4. Tests cover guard activation scenarios.
- Dependencies:
COP-SEC-001, COP-SEC-002
- Risks:
Too-strict limits may interrupt valid complex workflows.

---

## COP-SEC-011: Build Adversarial Prompt Security Test Suite
- Priority: P0
- Type: Testing Feature
- Problem:
No dedicated suite exists to prevent prompt-security regressions.
- Scope:
Create unit/integration tests for injection, malformed tool payloads, ambiguous entity targeting, and policy bypass attempts.
- Acceptance Criteria:
1. Test fixtures include OCR-style injection strings.
2. Malformed JSON payload tests prove validator protection.
3. Ambiguous name tests prove resolver disambiguation.
4. Suite runs in standard test command and gates release checklist.
- Dependencies:
COP-SEC-001, COP-SEC-002, COP-SEC-003, COP-SEC-005
- Risks:
Maintenance burden as prompt/tool contracts evolve.

---

## COP-SEC-012: Copilot Home Briefing with Safe Action Cards
- Priority: P2
- Type: Product Feature
- Problem:
AI feels chat-centric, not proactive and operationally safe.
- Scope:
Add daily briefing cards on Dashboard with proposal-based actions (never direct destructive actions).
- Acceptance Criteria:
1. Dashboard shows expiring/low-stock/meal/shopping proposals.
2. Each proposal explains rationale and impact.
3. Actions route through policy + confirmation flow.
4. No direct destructive action from briefing cards.
- Dependencies:
COP-SEC-001, COP-SEC-004
- Risks:
Requires UX iteration to avoid clutter.

---

## Recommended Delivery Order
1. COP-SEC-001
2. COP-SEC-002
3. COP-SEC-003
4. COP-SEC-004
5. COP-SEC-005
6. COP-SEC-011
7. COP-SEC-007
8. COP-SEC-008
9. COP-SEC-009
10. COP-SEC-010
11. COP-SEC-006
12. COP-SEC-012


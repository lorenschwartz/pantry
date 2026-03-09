# AI Copilot Security TDD Implementation Plan

## Document Status
- Last Updated: March 8, 2026
- Branch: `codex/ai-copilot-security-tdd-plan`
- Scope: Implement security tickets `COP-SEC-001` to `COP-SEC-012` without breaking existing assistant UX.

## Planning Rules
1. Follow Red-Green-Refactor for every capability.
2. Add failing tests first in `pantryTests/`.
3. Keep changes incremental; each ticket should be shippable.
4. No direct mutation path should bypass policy + validation once core tickets land.

## Baseline Current Touchpoints
- Assistant orchestration: `pantry/ServicesLLMService.swift`
- Assistant UI entrypoints: `pantry/ViewsChatChatView.swift`, `pantry/ViewsDashboardDashboardView.swift`
- OCR input source: `pantry/ServicesReceiptScanService.swift`
- Existing test pattern references:
  - `pantryTests/ServicesLLMServiceTests.swift`
  - `pantryTests/ServicesReceiptScanServiceTests.swift`

## Phase 0: Safety Harness and Scaffolding (TDD)

### Ticket Focus
- COP-SEC-011 (test suite scaffolding)

### Tests First
1. Create `pantryTests/ServicesCopilotSecurityRegressionTests.swift`
2. Add failing tests for:
- malformed tool payload rejected
- ambiguous destructive target rejected
- injection-like OCR text treated as data

### Production Changes
1. Add placeholders/stubs only as needed to compile:
- `pantry/ServicesCopilotPolicyService.swift`
- `pantry/ServicesToolInputValidator.swift`
- `pantry/ServicesEntityResolver.swift`

### Exit Criteria
1. New test file exists and fails for intended reasons.
2. No behavior change in production yet besides compile scaffolding.

## Phase 1: Policy Engine and Strict Validation

### Ticket Focus
- COP-SEC-001, COP-SEC-002

### Tests First
1. Create `pantryTests/ServicesCopilotPolicyServiceTests.swift`
2. Create `pantryTests/ServicesToolInputValidatorTests.swift`
3. Add failing cases:
- policy returns `require_confirmation` for destructive bulk actions
- policy returns `deny` for `delete all` without confirmation signal
- validator rejects unknown fields
- validator rejects wrong type for quantity/date
- validator enforces required fields

### Production Changes
1. Implement `CopilotPolicyService` (pure functions + rule config).
2. Implement `ToolInputValidator` with per-tool schemas mirroring tool definitions.
3. Refactor `LLMService` execution path:
- Validate tool input before invoking any tool handler.
- Policy-check validated tool call before mutation.

### Exit Criteria
1. Policy + validator unit tests pass.
2. Existing assistant tests remain green.
3. Invalid tool payloads do not invoke write handlers.

## Phase 2: Deterministic Resolution for Destructive Writes

### Ticket Focus
- COP-SEC-003

### Tests First
1. Create `pantryTests/ServicesEntityResolverTests.swift`
2. Add failing cases:
- multiple pantry matches -> disambiguation required
- exact ID match -> allow destructive op
- no matches -> no-op with user-facing guidance

### Production Changes
1. Implement `EntityResolver` for pantry/shopping/recipe entities.
2. Update destructive tool handlers in `LLMService`:
- `remove_pantry_item`
- destructive update paths as applicable
3. Return structured disambiguation responses where needed.

### Exit Criteria
1. No destructive mutation executes from fuzzy non-unique match.
2. Resolver tests pass across pantry and shopping entities.

## Phase 3: Two-Phase Writes (Propose -> Apply)

### Ticket Focus
- COP-SEC-004

### Tests First
1. Create `pantryTests/ServicesCopilotActionPlannerTests.swift`
2. Add failing cases:
- mutating request returns proposal object
- high-risk proposal requires explicit approval token/flag
- rejected proposal performs zero writes

### Production Changes
1. Add `pantry/ServicesCopilotActionPlanner.swift`
2. Introduce proposal model (non-SwiftData value type initially):
- action type
- targets
- proposed args
- risk level
3. Refactor `LLMService` to:
- plan first
- execute only approved plans

### Exit Criteria
1. Writes flow through proposal state.
2. High-risk actions are never auto-applied.

## Phase 4: Injection Hardening and Trust Labels

### Ticket Focus
- COP-SEC-005

### Tests First
1. Extend `pantryTests/ServicesReceiptScanServiceTests.swift` with adversarial text fixtures.
2. Add/extend `pantryTests/ServicesLLMServiceTests.swift`:
- untrusted OCR text cannot escalate privileges
- injected instruction strings do not bypass policy/validation

### Production Changes
1. Add trust labels in prompt-building path in `LLMService`.
2. Ensure OCR/import text is wrapped as untrusted data blocks.
3. Update system prompt to include explicit instruction hierarchy defense.

### Exit Criteria
1. Injection fixtures cannot produce unvalidated destructive writes.
2. Existing benign OCR flows still work.

## Phase 5: Keychain Migration and Secret Handling

### Ticket Focus
- COP-SEC-007

### Tests First
1. Create `pantryTests/ServicesKeychainServiceTests.swift` (logic-only wrappers/mocks).
2. Add failing migration tests:
- reads old UserDefaults key once
- writes to Keychain
- clears migrated UserDefaults key

### Production Changes
1. Add `pantry/ServicesKeychainService.swift`.
2. Refactor key access in `LLMService`.
3. Keep backward-compatible one-time migration path.

### Exit Criteria
1. API key no longer stored in UserDefaults after migration.
2. Assistant still authenticates correctly with existing users.

## Phase 6: Audit Log and Undo

### Ticket Focus
- COP-SEC-008, COP-SEC-009

### Tests First
1. Create `pantryTests/ModelsCopilotActionLogTests.swift`
2. Create `pantryTests/ServicesCopilotAuditServiceTests.swift`
3. Create `pantryTests/ServicesCopilotUndoServiceTests.swift`
4. Add failing cases:
- successful write logs metadata
- denied write logs reason
- undo restores prior state for supported actions

### Production Changes
1. Add model:
- `pantry/ModelsCopilotActionLog.swift` (and add to schema in `pantry/pantryApp.swift`)
2. Add services:
- `pantry/ServicesCopilotAuditService.swift`
- `pantry/ServicesCopilotUndoService.swift`
3. Add lightweight UI viewer:
- `pantry/ViewsSettingsCopilotActionsView.swift`

### Exit Criteria
1. Every AI write (allow/deny/fail) has an audit record.
2. Undo works for supported reversible actions.

## Phase 7: Runtime Limits, Data Minimization, Dashboard Safe Actions

### Ticket Focus
- COP-SEC-010, COP-SEC-006, COP-SEC-012

### Tests First
1. Add `pantryTests/ServicesCopilotRuntimeGuardTests.swift`
2. Add `pantryTests/ServicesLLMContextSerializerTests.swift`
3. Add integration tests for Dashboard proposal cards:
- proposals generated safely
- card actions route through policy confirmation path

### Production Changes
1. Add runtime guard service:
- `pantry/ServicesCopilotRuntimeGuard.swift`
2. Add intent-scoped serializer:
- `pantry/ServicesLLMContextSerializer.swift`
3. Refactor dashboard AI section for proposal-based cards:
- `pantry/ViewsDashboardDashboardView.swift`

### Exit Criteria
1. Per-turn call/write limits enforced.
2. Context payloads are least-privilege by default.
3. Dashboard actions are proposal-based, not direct destructive writes.

## Suggested PR Slicing
1. PR1: Phase 0 + Phase 1
2. PR2: Phase 2 + Phase 3
3. PR3: Phase 4 + Phase 5
4. PR4: Phase 6
5. PR5: Phase 7

## Release Gate Checklist
1. All new security tests pass on simulator target.
2. Existing assistant happy-path UX verified manually.
3. No direct mutation path in `LLMService` bypasses policy + validation.
4. Keychain migration tested from a pre-migration local store.
5. Audit log and undo behavior validated on-device.


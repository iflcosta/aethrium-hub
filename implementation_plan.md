# Debugging Agent Execution, Model Updates, and Command Center Redesign

The objective is twofold:
1. Fix `POST /agents/{slug}/run` failures and update agent models to meet the new technical requirements.
2. Completely redesign the Command Center from a bottom bar to a resizable right-side drawer panel with isolated agent conversations.

## User Review Required

> [!IMPORTANT]
> - All agent models will be updated to `gemini-3.1-pro-preview` (Technical) and `gemini-2.5-flash` (Support/Ops).
> - The Command Center will now be a right-side drawer that overlays content.
> - Message histories will be isolated per agent.

## Proposed Changes

### Backend Service

#### [Backend] [agents/*.py](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/backend/agents/)
- Update models:
  - `carlos`, `rafael`, `viktor` -> `gemini-3.1-pro-preview`
  - All others -> `gemini-2.5-flash`

#### [Backend] [agents/base_agent.py](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/backend/agents/base_agent.py)
- Ensure `ChatGoogleGenerativeAI` uses the correct `GOOGLE_API_KEY`.
- Fix memory/instance management for Prisma to ensure connections are active during [run()](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/backend/agents/base_agent.py#46-124).

#### [Backend] [routers/agents.py](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/backend/routers/agents.py)
- Use a central, connected Prisma client to avoid "connection not started" errors during background task execution.

---

### Command Center Redesign

#### [Frontend] [useCommandStore.ts](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/src/store/useCommandStore.ts)
- Change `isExpanded` to `isOpen`.
- Add `width: number` (persistence via localStorage).
- Replace `thread: Message[]` with `threads: Record<string, Message[]>`.
- Add actions: [toggle()](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/src/app/logs/page.tsx#33-41), `setWidth()`, [addMessage(agentSlug, message)](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/src/store/useCommandStore.ts#56-57), `getCurrentThread()`.

#### [Frontend] [CommandCenter/index.tsx](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/src/components/CommandCenter/index.tsx) [NEW]
- Implement fixed right-side panel (100vh).
- Transform-based transitions.
- Resize handle on left edge (8px).
- Header with MONOSPACE label + Mode pills.
- DM Mode: Horizontal agent selector + isolated thread view.
- Task Mode: Form with Priority + Agent selector.
- Meeting Mode: Topic + Agent checkboxes.
- Input area with Arrow Send button + Slash command tips.

#### [Frontend] [layout.tsx](file:///c:/Users/Iago%20Lopes/.gemini/antigravity/scratch/aethrium-hub/src/app/layout.tsx)
- Remove bottom padding.
- Add always-visible `CC` trigger tab on right edge.
- Implement global keyboard listeners (Ctrl+K, Escape).

## Verification Plan

### Automated Tests
- `python backend/test_run.py`: Verify Carlos execution returns 200/ExecutionID.
- `GET /health` verification.

### Manual Verification
- Resize trigger on right edge.
- Drag resize handle (verify 260px-600px range).
- Verify different threads for Carlos vs Rafael.
- Test `/dm`, `/task`, `/meeting` modes.

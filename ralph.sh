#!/bin/bash
set -e

# Parse arguments
AGENT="claude"
ITERATIONS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --agent)
      AGENT="$2"
      shift 2
      ;;
    *)
      if [ -z "$ITERATIONS" ]; then
        ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$ITERATIONS" ]; then
  echo "Usage: $0 [--agent claude|codex] <iterations>"
  exit 1
fi

# Set command based on agent
if [ "$AGENT" = "claude" ]; then
  CMD="claude --permission-mode acceptEdits"
  PROMPT_FLAG="-p"
elif [ "$AGENT" = "codex" ]; then
  CMD="/Users/shanewalker/.nvm/versions/node/v22.12.0/bin/codex exec --full-auto"
  PROMPT_FLAG=""
else
  echo "Error: Invalid agent '$AGENT'. Must be 'claude' or 'codex'."
  exit 1
fi

for ((i=1; i<=$ITERATIONS; i++ )); do
  echo "=== $AGENT iteration $i ==="
  echo ""

  result=$($CMD $PROMPT_FLAG "@ralph/PRD.json @ralph/progress.txt

# TWO-PHASE TASK SYSTEM

Read ralph/progress.txt to determine what phase to run.
The most recent entry is at the TOP of the file.
Read from the start until you hit '=== END OF ENTRY ===' to get the latest iteration info.

- If most recent entry says 'NEXT: EXECUTE [task-id]' → Run EXECUTION PHASE for that task
- Otherwise → Run PLANNING PHASE for next task

---

# PLANNING PHASE

Use this phase when no execution is pending.

## Task Selection
Select ONE task from ralph/PRD.json with status='pending' that you judge highest value to work on next.

Consider:
- Task status: Only select tasks with status='pending'
- Dependencies: Check 'dependencies' array - all must have status='completed'
- Logical flow: What makes sense given completed work?
- Impact: What provides most value?

Explicitly state your selection:
- Selected task ID and title
- Rationale for selection

## Create Implementation Plan

1. Read the task spec from ralph/PRD.json (title, description, dependencies)
2. Explore the codebase to understand context and patterns
3. Create detailed implementation plan at: ralph/plans/[task-id]-plan.md

Plan format:
\`\`\`markdown
# [Task Title]

## Overview
[Brief description]

## Context
[Relevant files, existing patterns, architecture notes]

## Implementation Steps
1. [Specific actionable step with file paths]
2. [Specific actionable step with file paths]
...

## Files to Create
- path/to/file.ts - [purpose]

## Files to Modify
- path/to/file.ts - [what changes]

## Testing Strategy
[How to verify it works]

## Type Checking
Run: pnpm typecheck
\`\`\`

## Update PRD
In ralph/PRD.json, update the task:
- Change \"status\": \"pending\" to \"status\": \"planned\"
- Verify \"planRef\" points to your plan file (ralph/plans/[task-id]-plan.md)

## Document
PREPEND to ralph/progress.txt (add at the very top of the file):

## [Date] - Planned: [Task Title]

**Task ID:** [task-id]
**Plan:** [plan file path]
**Rationale:** [Why selected]

**NEXT: EXECUTE [task-id]**

=== END OF ENTRY ===


---

# EXECUTION PHASE

Use this phase when ralph/progress.txt says 'NEXT: EXECUTE [task-id]'.

## Load Plan
1. Read the task-id from ralph/progress.txt
2. Load task from ralph/PRD.json
3. Read the implementation plan from planRef path (ralph/plans/[task-id]-plan.md)
4. Follow the plan step-by-step

## Implementation
- Execute each step from the plan in order
- Stay focused on plan scope
- Implement completely and correctly

## Verification
1. Test your implementation
2. Run: pnpm typecheck
   - Fix errors from your changes
   - Document pre-existing errors

## Update PRD
In ralph/PRD.json:
- Change \"status\": \"planned\" to \"status\": \"completed\"

## Document Progress
PREPEND to ralph/progress.txt (add at the very top of the file):

## [Date] - Completed: [Task Title]

**Task ID:** [task-id]
**Plan:** [plan file path]

**What was done:**
- [Bullet points]

**Technical details:**
- [Implementation specifics]
- [Patterns/libraries used]

**Files created:**
- [List with purpose]

**Files modified:**
- [List with changes]

**Deviations from plan:**
- [Changes from plan and why, or \"None\"]

**Next task recommendation:** [Recommend next task considering dependencies]

=== END OF ENTRY ===

## Git

git add and commit your changes with a ralph prefix
ralph: Complete [Task Title] ([task-id])
only commit after an execution phase
only commit files you created/modified for this task

NEVER commit ralph/plans/*.md files

## Completion Check
If ALL tasks in ralph/PRD.json have status='completed', output: <promise>COMPLETE</promise>
")

  echo "$result"
  echo ""
  echo "-----------------------------------"
  echo ""

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "🎉 All tasks complete!"
    exit 0
  fi
done

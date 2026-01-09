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

Check ralph/progress.txt top entry (read until '=== END OF ENTRY ==='):
- If 'NEXT: EXECUTE [task-id]' → Run EXECUTION
- Otherwise → Run PLANNING

## PLANNING
1. Select ONE pending task from PRD.json (check dependencies completed)
2. State: task ID, title, rationale
3. Create ralph/plans/[task-id]-plan.md:
   - Overview, Context, Implementation Steps (with file paths), Files to Create/Modify, Testing, Type Checking
4. Update PRD.json: status \"pending\" → \"planned\"
5. PREPEND to progress.txt:
   ## [Date] - Planned: [Task Title]
   **Task ID:** [task-id]
   **Plan:** [path]
   **Rationale:** [why]
   **NEXT: EXECUTE [task-id]**
   === END OF ENTRY ===

## EXECUTION
1. Load task-id from progress.txt, read PRD.json task + plan from planRef
2. Implement plan step-by-step
3. Test + run \`tsc --noEmit\` (TypeScript compile check, fix your errors, note pre-existing)
4. Update PRD.json: status \"planned\" → \"completed\"
5. PREPEND to progress.txt:
   ## [Date] - Completed: [Task Title]
   **Task ID:** [task-id]
   **Plan:** [path]
   **What was done:** [bullets]
   **Technical details:** [specifics]
   **Files created:** [list]
   **Files modified:** [list]
   **Deviations:** [changes or \"None\"]
   **Next task recommendation:** [suggest next]
   === END OF ENTRY ===
6. Git commit (execution only): \`ralph: Complete [Task Title] ([task-id])\`
   - Only commit files you created/modified
   - NEVER commit ralph/plans/*.md

If all PRD.json tasks completed: output <promise>COMPLETE</promise>
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

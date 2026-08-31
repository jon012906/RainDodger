# Branch Goals — the Mission of the Current Branch

**Load when:** starting any session or task, and when using `@branch`.

Every feature branch (`docs/`, `feat/`, `fix/`) carries a goal file defining its mission, stored at `.opencode/branch-goals/<branch-name>.md` (gitignored, workspace metadata only).

- The user creates branches with `/branch <name> "<goal>"` — the goal is stored at branch creation time and each branch has its own goal
- **Before any work on a session, read the current branch's goal:**
  1. Determine the current branch: `git branch --show-current`
  2. Read `.opencode/branch-goals/<branch>.md` if it exists
  3. If no goal file exists, ask the user what the goal is — do not assume
- The branch goal is the ground truth for every Planner plan, Executor implementation, and Reviewer verdict: work that does not serve the branch goal should be challenged
- If the user's request conflicts with the branch goal, surface the conflict and let the user decide

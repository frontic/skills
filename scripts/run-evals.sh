#!/bin/bash
# Eval runner for skills against a target project
# Usage: ./scripts/run-evals.sh <skill-name> <target-project> [options]
#
# Options:
#   --iteration NAME   Iteration name (default: auto-generated timestamp)
#   --from N           Start from eval N (inclusive, default: 1)
#   --to N             End at eval N (inclusive, default: last eval)
#   --resume           Skip evals that already have non-empty responses
#   --only-grade       Only run grading on existing responses (skip execution)

set -euo pipefail

# Allow running claude CLI from within a Claude Code session
export CLAUDECODE=
export CLAUDE_CODE_ENTRYPOINT=

# Parse arguments
SKILL_NAME=""
TARGET_PROJECT=""
ITERATION=""
FROM_EVAL=""
TO_EVAL=""
RESUME=false
ONLY_GRADE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iteration) ITERATION="$2"; shift 2 ;;
    --from) FROM_EVAL="$2"; shift 2 ;;
    --to) TO_EVAL="$2"; shift 2 ;;
    --resume) RESUME=true; shift ;;
    --only-grade) ONLY_GRADE=true; shift ;;
    -*)
      echo "Unknown option: $1"
      echo "Usage: $0 <skill-name> <target-project> [--iteration NAME] [--from N] [--to N] [--resume] [--only-grade]"
      exit 1 ;;
    *)
      if [ -z "$SKILL_NAME" ]; then
        SKILL_NAME="$1"
      elif [ -z "$TARGET_PROJECT" ]; then
        TARGET_PROJECT="$1"
      else
        echo "Unexpected argument: $1"
        exit 1
      fi
      shift ;;
  esac
done

if [ -z "$SKILL_NAME" ] || [ -z "$TARGET_PROJECT" ]; then
  echo "Usage: $0 <skill-name> <target-project> [--iteration NAME] [--from N] [--to N] [--resume] [--only-grade]"
  exit 1
fi

[ -z "$ITERATION" ] && ITERATION="iteration-$(date +%Y%m%d-%H%M)"

SKILLS_REPO="$(cd "$(dirname "$0")/.." && pwd)"
EVALS_FILE="$SKILLS_REPO/$SKILL_NAME/evals/evals.json"
SKILL_DIR="$SKILLS_REPO/$SKILL_NAME"
WORKSPACE="$SKILLS_REPO/$SKILL_NAME/${SKILL_NAME}-workspace/$ITERATION"

MODEL="${EVAL_MODEL:-claude-sonnet-4-6}"
GRADER_MODEL="${GRADER_MODEL:-claude-haiku-4-5}"

# Validate inputs
if [ ! -f "$EVALS_FILE" ]; then
  echo "Error: Evals file not found: $EVALS_FILE"
  exit 1
fi
if [ ! -d "$TARGET_PROJECT" ]; then
  echo "Error: Target project not found: $TARGET_PROJECT"
  exit 1
fi
if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "Error: SKILL.md not found in $SKILL_DIR"
  exit 1
fi

EVAL_COUNT=$(python3 -c "import json; print(len(json.load(open('$EVALS_FILE'))['evals']))")

# Determine eval range
[ -z "$FROM_EVAL" ] && FROM_EVAL=1
[ -z "$TO_EVAL" ] && TO_EVAL="$EVAL_COUNT"

echo "=== Eval Runner ==="
echo "Skill:      $SKILL_NAME"
echo "Project:    $TARGET_PROJECT"
echo "Iteration:  $ITERATION"
echo "Evals:      $FROM_EVAL-$TO_EVAL of $EVAL_COUNT"
echo "Model:      $MODEL"
echo "Grader:     $GRADER_MODEL"
echo "Resume:     $RESUME"
echo "Only grade: $ONLY_GRADE"
echo ""

mkdir -p "$WORKSPACE"

# Save metadata (merge if exists for resume runs)
python3 -c "
import json, os
from datetime import datetime, timezone
bench_file = '$WORKSPACE/benchmark.json'
meta = {}
if os.path.exists(bench_file):
    with open(bench_file) as f:
        meta = json.load(f)
meta['metadata'] = {
    'skill_name': '$SKILL_NAME',
    'skill_path': '$SKILL_DIR/SKILL.md',
    'project': '$(basename "$TARGET_PROJECT")',
    'project_path': '$TARGET_PROJECT',
    'executor_model': '$MODEL',
    'grader_model': '$GRADER_MODEL',
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'iteration': '$ITERATION',
    'eval_range': '$FROM_EVAL-$TO_EVAL'
}
with open(bench_file, 'w') as f:
    json.dump(meta, f, indent=2)
"

# Skill symlink management
SKILL_LINK="$TARGET_PROJECT/.claude/skills/$SKILL_NAME"

ensure_skill() {
  if [ ! -e "$SKILL_LINK" ]; then
    mkdir -p "$TARGET_PROJECT/.claude/skills"
    ln -sf "$SKILL_DIR" "$SKILL_LINK"
  fi
}

remove_skill() {
  if [ -L "$SKILL_LINK" ]; then
    rm "$SKILL_LINK"
  elif [ -d "$SKILL_LINK" ]; then
    mv "$SKILL_LINK" "${SKILL_LINK}.bak"
  fi
}

restore_skill() {
  if [ -e "${SKILL_LINK}.bak" ]; then
    mv "${SKILL_LINK}.bak" "$SKILL_LINK"
  elif [ ! -e "$SKILL_LINK" ]; then
    ln -sf "$SKILL_DIR" "$SKILL_LINK"
  fi
}

has_valid_response() {
  local response_file="$1"
  if [ -f "$response_file" ]; then
    local size
    size=$(wc -c < "$response_file" | tr -d ' ')
    [ "$size" -gt 10 ]
  else
    return 1
  fi
}

run_eval() {
  local eval_id="$1"
  local config="$2"  # with_skill or without_skill
  local eval_dir="$WORKSPACE/eval-$eval_id/$config"
  mkdir -p "$eval_dir"

  # Skip if resume mode and valid response exists
  if [ "$RESUME" = true ] && has_valid_response "$eval_dir/response.txt"; then
    echo "  [$config] Skipping eval $eval_id (response exists, --resume)"
    return 0
  fi

  echo "  [$config] Running eval $eval_id..."

  # Toggle skill
  if [ "$config" = "without_skill" ]; then
    remove_skill
  else
    ensure_skill
  fi

  # Extract prompt to a temp file (avoids shell quoting issues)
  local prompt_file
  prompt_file=$(mktemp)
  python3 -c "
import json, sys
evals = json.load(open('$EVALS_FILE'))['evals']
for e in evals:
    if e['id'] == $eval_id:
        sys.stdout.write(e['prompt'])
        break
" > "$prompt_file"

  local start_time=$(date +%s)

  # Run eval — pipe prompt from file, capture stderr for debugging
  cd "$TARGET_PROJECT"
  cat "$prompt_file" | claude --print \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    --no-session-persistence \
    --disallowed-tools "Edit Write NotebookEdit Bash TodoWrite EnterPlanMode AskUserQuestion Task" \
    - > "$eval_dir/response.txt" 2>"$eval_dir/stderr.log" || true
  cd - > /dev/null

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo "{\"duration_seconds\": $duration}" > "$eval_dir/timing.json"

  # Report result
  local resp_size
  resp_size=$(wc -c < "$eval_dir/response.txt" | tr -d ' ')
  if [ "$resp_size" -le 10 ]; then
    echo "  [$config] WARNING: Empty response for eval $eval_id (${resp_size} bytes)"
    if [ -s "$eval_dir/stderr.log" ]; then
      echo "  [$config] stderr: $(head -3 "$eval_dir/stderr.log")"
    fi
  else
    echo "  [$config] Done eval $eval_id (${resp_size} bytes, ${duration}s)"
  fi

  rm -f "$prompt_file"

  # Restore skill
  if [ "$config" = "without_skill" ]; then
    restore_skill
  fi
}

grade_eval() {
  local eval_id="$1"
  local config="$2"
  local eval_dir="$WORKSPACE/eval-$eval_id/$config"

  # Skip grading if no valid response
  if ! has_valid_response "$eval_dir/response.txt"; then
    echo "  [$config] Skipping grading for eval $eval_id (no valid response)"
    echo '{"error": "no_response", "summary": {"passed": 0, "failed": 0, "total": 0, "pass_rate": 0.0}}' > "$eval_dir/grading.json"
    return 0
  fi

  # Skip if resume mode and valid grading exists
  if [ "$RESUME" = true ] && [ -f "$eval_dir/grading.json" ]; then
    local has_error
    has_error=$(python3 -c "import json; d=json.load(open('$eval_dir/grading.json')); print('yes' if 'error' in d else 'no')" 2>/dev/null || echo "yes")
    if [ "$has_error" = "no" ]; then
      echo "  [$config] Skipping grading for eval $eval_id (grading exists, --resume)"
      return 0
    fi
  fi

  echo "  [$config] Grading eval $eval_id..."

  # Build grading prompt in a temp file
  local grading_file
  grading_file=$(mktemp)

  python3 << PYEOF > "$grading_file"
import json

evals = json.load(open('$EVALS_FILE'))['evals']
eval_data = None
for e in evals:
    if e['id'] == $eval_id:
        eval_data = e
        break

with open('$eval_dir/response.txt') as f:
    response = f.read()

expectations = eval_data.get('expectations', eval_data.get('assertions', []))
exp_list = '\n'.join(f'- {exp}' for exp in expectations)

prompt = f"""You are grading an AI response against specific expectations. Be strict and objective.

ORIGINAL PROMPT:
---
{eval_data['prompt']}
---

RESPONSE TO GRADE:
---
{response}
---

EXPECTATIONS TO CHECK:
{exp_list}

For each expectation, determine if the response satisfies it. Output ONLY valid JSON (no markdown, no code blocks) in this exact format:
{{"expectations": [{{"text": "expectation text", "passed": true, "evidence": "quote or observation"}}], "summary": {{"passed": 0, "failed": 0, "total": 0, "pass_rate": 0.0}}}}"""

print(prompt)
PYEOF

  cat "$grading_file" | claude --print \
    --model "$GRADER_MODEL" \
    --dangerously-skip-permissions \
    --no-session-persistence \
    --tools "" \
    - > "$eval_dir/grading_raw.txt" 2>"$eval_dir/grading_stderr.log" || true

  rm -f "$grading_file"

  # Parse and save grading JSON
  python3 -c "
import sys, json, re
with open('$eval_dir/grading_raw.txt') as f:
    text = f.read().strip()
# Try code blocks first
match = re.search(r'\`\`\`(?:json)?\s*(\{.*?\})\s*\`\`\`', text, re.DOTALL)
if match:
    text = match.group(1)
try:
    data = json.loads(text)
    print(json.dumps(data, indent=2))
except:
    match = re.search(r'\{.*\}', text, re.DOTALL)
    if match:
        try:
            data = json.loads(match.group())
            print(json.dumps(data, indent=2))
        except:
            print(json.dumps({'error': 'parse_failed', 'raw': text[:1000]}))
    else:
        print(json.dumps({'error': 'no_json', 'raw': text[:1000]}))
" > "$eval_dir/grading.json" 2>/dev/null || echo '{"error": "grading_crashed"}' > "$eval_dir/grading.json"

  # Report grading result
  local grade_summary
  grade_summary=$(python3 -c "
import json
try:
    d = json.load(open('$eval_dir/grading.json'))
    if 'error' in d:
        print(f'ERROR: {d[\"error\"]}')
    elif 'summary' in d:
        s = d['summary']
        print(f'{s[\"passed\"]}/{s[\"total\"]} passed ({s[\"pass_rate\"]:.0%})')
    else:
        print('OK (no summary)')
except:
    print('ERROR: could not read grading')
" 2>/dev/null || echo "ERROR")
  echo "  [$config] Graded eval $eval_id: $grade_summary"
}

# Main eval loop — respects --from/--to range
COMPLETED=0
SKIPPED=0

for eval_id in $(python3 -c "import json; [print(e['id']) for e in json.load(open('$EVALS_FILE'))['evals']]"); do
  # Skip evals outside the requested range
  if [ "$eval_id" -lt "$FROM_EVAL" ] || [ "$eval_id" -gt "$TO_EVAL" ]; then
    continue
  fi

  echo ""
  echo "--- Eval $eval_id / $EVAL_COUNT (range: $FROM_EVAL-$TO_EVAL) ---"

  if [ "$ONLY_GRADE" = false ]; then
    run_eval "$eval_id" "without_skill"
  fi
  grade_eval "$eval_id" "without_skill"

  if [ "$ONLY_GRADE" = false ]; then
    run_eval "$eval_id" "with_skill"
  fi
  grade_eval "$eval_id" "with_skill"

  COMPLETED=$((COMPLETED + 1))
done

echo ""
echo "=== Done ==="
echo "Completed:  $COMPLETED evals (range: $FROM_EVAL-$TO_EVAL)"
echo "Results in: $WORKSPACE"

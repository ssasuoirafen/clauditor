#!/bin/sh
# session-start-review-nudge.sh
# SessionStart hook: emits additionalContext when .claude/ was last audited
# more than THRESHOLD_DAYS ago. Non-blocking, exit 0 always.

MARKER="${HOME}/.claude/audit-claude-last-review"
THRESHOLD_DAYS=30

# Returns the number of days between an ISO date string (YYYY-MM-DD) and today.
# Prints a non-negative integer, or "unknown" if the date cannot be parsed.
days_since() {
  marker_date="$1"

  # Validate format: must be YYYY-MM-DD (10 chars, digits and hyphens only)
  case "$marker_date" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) echo "unknown"; return ;;
  esac

  # Convert dates to seconds-since-epoch using date -d (GNU) or date -j (BSD/macOS).
  # On this Windows/Git Bash host, GNU date with -d is available.
  marker_epoch=$(date -d "$marker_date" +%s 2>/dev/null) || { echo "unknown"; return; }
  today_epoch=$(date +%s 2>/dev/null) || { echo "unknown"; return; }

  diff_secs=$((today_epoch - marker_epoch))
  # Guard against negative diff (marker set in the future)
  if [ "$diff_secs" -lt 0 ]; then
    echo "0"
  else
    echo $((diff_secs / 86400))
  fi
}

# --- main ---

# No marker -> never audited
if [ ! -f "$MARKER" ]; then
  printf '{"additionalContext": ".claude/ has never been audited; consider running /audit-claude"}\n'
  exit 0
fi

# Read the first line; trim whitespace
marker_date=$(head -n 1 "$MARKER" 2>/dev/null | tr -d '[:space:]')

days=$(days_since "$marker_date")

# Unparseable marker -> treat as stale
if [ "$days" = "unknown" ]; then
  printf '{"additionalContext": ".claude/ last audit date is unreadable; consider running /audit-claude"}\n'
  exit 0
fi

if [ "$days" -ge "$THRESHOLD_DAYS" ]; then
  printf '{"additionalContext": ".claude/ last audited %s days ago; consider running /audit-claude"}\n' "$days"
fi

exit 0

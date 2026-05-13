#!/usr/bin/env bash
# install.sh — wire every supported agent runner to skills/
#
# Idempotent. Safe to re-run after a git clone, after a pull, or anytime
# the symlinks get clobbered (e.g. by Windows checkout, by an aggressive
# antivirus, or by a runner that overwrote them with a real directory).

set -euo pipefail

# The runner config folders that should point at our canonical skills/ dir.
# Add more here when new runners gain skill support.
RUNNERS=(.agents .claude .codex .gemini .opencode)

# Resolve the repo root from this script's location so it works regardless
# of the user's current working directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d "skills" ]; then
  echo "✗ skills/ directory not found in $SCRIPT_DIR" >&2
  echo "  Run this script from the root of the francais-skills repository." >&2
  exit 1
fi

linked=0
skipped=0
fixed=0

for runner in "${RUNNERS[@]}"; do
  target="$runner/skills"
  mkdir -p "$runner"

  if [ -L "$target" ]; then
    # Already a symlink — check it points to ../skills.
    current="$(readlink "$target")"
    if [ "$current" = "../skills" ]; then
      echo "  $runner/skills → ../skills (already correct)"
      skipped=$((skipped + 1))
      continue
    fi
    echo "  $runner/skills → $current (replacing with ../skills)"
    rm -f "$target"
    ln -s ../skills "$target"
    fixed=$((fixed + 1))
  elif [ -e "$target" ]; then
    # Exists but is not a symlink — likely a real directory.
    echo "✗ $target exists and is not a symlink." >&2
    echo "  Move or delete it manually, then re-run install.sh." >&2
    exit 1
  else
    ln -s ../skills "$target"
    echo "✓ $runner/skills → ../skills"
    linked=$((linked + 1))
  fi
done

echo ""
echo "Done. $linked created, $fixed replaced, $skipped already correct."
echo ""
echo "Skills available to: ${RUNNERS[*]}"

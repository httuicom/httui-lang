#!/usr/bin/env bash
# Install repository git hooks into .git/hooks/.
#
# Run once after cloning, or whenever the hook scripts in scripts/hooks/
# change. The hooks are versioned in this repo so contributors share the
# same checks.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DST="$REPO_ROOT/.git/hooks"

if [[ ! -d "$HOOKS_SRC" ]]; then
  echo "scripts/hooks/ not found at $HOOKS_SRC" >&2
  exit 1
fi

mkdir -p "$HOOKS_DST"

for hook in "$HOOKS_SRC"/*; do
  name="$(basename "$hook")"
  target="$HOOKS_DST/$name"
  cp "$hook" "$target"
  chmod +x "$target"
  echo "installed: $name"
done

echo
echo "Hooks installed into $HOOKS_DST"
echo "To bypass them in an emergency, use git --no-verify (but please don't)."

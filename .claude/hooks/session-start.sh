#!/bin/bash
# Installs Heretic and its dev tools into .venv for Claude Code cloud sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Preferred path: install exactly what uv.lock specifies (CPU PyTorch wheels
# from download.pytorch.org). If the environment's network policy blocks the
# PyTorch index, fall back to PyTorch from PyPI without touching uv.lock.
if uv sync --all-groups; then
  echo "Installed from uv.lock."
else
  echo "uv sync failed (PyTorch index likely blocked); falling back to PyPI." >&2
  [ -d .venv ] || uv venv -p 3.12
  uv pip install --no-sources -e . --group dev
  # Keep `uv run` from re-syncing against the unreachable index.
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo 'export UV_NO_SYNC=1' >> "$CLAUDE_ENV_FILE"
  fi
fi

# Put the venv on PATH so `heretic`, `ruff`, `ty` and `python` work directly.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export VIRTUAL_ENV=\"$CLAUDE_PROJECT_DIR/.venv\"" >> "$CLAUDE_ENV_FILE"
  echo "export PATH=\"$CLAUDE_PROJECT_DIR/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

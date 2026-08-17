#!/usr/bin/env bash
set -euo pipefail

# Explicit one-time ownership transition: remove every pinned application from
# the macOS Dock. This intentionally leaves `persistent-others` untouched, so
# the Trash and any folder/document stacks remain. Once this migration is marked
# complete, normal apply never manages the Dock's application list.
[[ "${DOTFILES_TEST_UNAME:-$(uname -s)}" == "Darwin" ]] || exit 0

defaults write com.apple.dock persistent-apps -array

if pgrep -x Dock >/dev/null 2>&1; then
  killall Dock
fi

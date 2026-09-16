#!/bin/sh
set -eu
if [ "$(uname -s)" != Darwin ]; then
  for tool in nvim uv git node npm yarn cc tree-sitter curl tar; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing prerequisite: $tool; install with your package manager" >&2; exit 1; }
  done
  echo 'Core executables available; make setup checks supported versions.'
  exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  echo 'Install Homebrew first: https://brew.sh' >&2
  exit 1
fi
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 brew install neovim uv git node yarn tree-sitter imagemagick

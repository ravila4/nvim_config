#!/usr/bin/env sh
# Run the spec suite the way CI does. Usage: tests/run.sh [tests/some_spec.lua]
set -eu
cd "$(dirname "$0")/.."
lazy="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"
target="${1:-tests}"
exec nvim --headless -u NONE \
	--cmd "set rtp+=$PWD" \
	--cmd "set rtp+=$lazy/plenary.nvim" \
	-c "lua require('plenary.test_harness').test_directory('$target', { minimal_init = 'tests/minimal_init.lua', sequential = true })"

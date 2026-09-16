.DEFAULT_GOAL := help
.NOTPARALLEL:
.PHONY: help system-deps setup notebooks r r-prerequisite databricks check
NVIM ?= nvim
export NVIM_LOG_FILE := /dev/null

help:
	@printf '%s\n' 'make setup       Core host, locked plugins, Mason tools and parsers' 'make notebooks   Python notebook kernel and Jupytext' 'make r           R packages and IRkernel (R_EXECUTABLE / R_LIBRARY optional)' 'make databricks  Locked Databricks helpers (authentication stays manual)' 'make check       Offline read-only diagnostics' 'make system-deps System prerequisites (Homebrew installation on macOS)'

system-deps:
	@sh scripts/bootstrap-system.sh

setup:
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua setup

notebooks: setup
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua notebooks

r-prerequisite:
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua r-prerequisite

r: r-prerequisite setup
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua r

databricks: setup
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua databricks

check:
	@$(NVIM) --headless -u NONE -i NONE -l scripts/bootstrap.lua check

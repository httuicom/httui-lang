# Top-level Makefile orchestrating common tasks across the OCaml library,
# Rust LSP binary, and grammars (tree-sitter + Lezer). Intended as the
# canonical entrypoint for contributors and CI.

LEZER_REFS_DIR := grammars-lezer/lezer-httui-refs
TS_REFS_DIR    := lib/grammars/tree-sitter-httui-refs
LSP_DIR        := bin/httui-lsp

.PHONY: help install setup-hooks build build-ocaml build-grammars build-lsp \
        test test-ocaml test-grammars test-lsp \
        lint lint-ocaml lint-rust lint-js \
        clean clean-ocaml clean-grammars clean-lsp \
        regenerate-grammars audit

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all dependencies
	opam install --yes --deps-only --with-test .
	cd $(LSP_DIR) && cargo fetch
	cd $(LEZER_REFS_DIR) && npm install
	cd $(TS_REFS_DIR) && npm install

setup-hooks: ## Install git hooks (commit-msg, pre-push, pre-commit)
	bash scripts/setup-hooks.sh

build: build-ocaml build-grammars build-lsp ## Build everything

build-ocaml: ## Build OCaml library
	opam exec -- dune build

build-grammars: ## Build all grammars
	cd $(LEZER_REFS_DIR) && npm run build
	cd $(TS_REFS_DIR) && npx tree-sitter generate

build-lsp: ## Build LSP server binary
	cd $(LSP_DIR) && cargo build --all-targets

test: test-ocaml test-grammars test-lsp ## Run all tests

test-ocaml: ## Run OCaml tests
	opam exec -- dune runtest

test-grammars: ## Run grammar corpus tests
	cd $(LEZER_REFS_DIR) && npm test
	cd $(TS_REFS_DIR) && npx tree-sitter test

test-lsp: ## Run Rust tests for LSP binary
	cd $(LSP_DIR) && cargo test --all-targets

lint: lint-ocaml lint-rust lint-js ## Run all linters

lint-ocaml: ## OCaml formatter check
	opam exec -- dune build @fmt

lint-rust: ## Rust fmt + clippy
	cd $(LSP_DIR) && cargo fmt --all -- --check
	cd $(LSP_DIR) && cargo clippy --all-targets -- -D warnings

lint-js: ## JS/TS lint via eslint + prettier
	cd $(LEZER_REFS_DIR) && npx eslint --max-warnings 0 src test
	cd $(LEZER_REFS_DIR) && npx prettier --check src test

regenerate-grammars: ## Regenerate parser artifacts from grammar definitions
	cd $(LEZER_REFS_DIR) && npm run build:parser
	cd $(TS_REFS_DIR) && npx tree-sitter generate

audit: ## Run security audits across ecosystems
	cd $(LEZER_REFS_DIR) && npm audit --audit-level=moderate
	cd $(TS_REFS_DIR) && npm audit --audit-level=moderate
	cd $(LSP_DIR) && cargo audit || true   # cargo-audit may not be installed everywhere

clean: clean-ocaml clean-grammars clean-lsp ## Remove all build artifacts

clean-ocaml: ## Clean OCaml build outputs
	opam exec -- dune clean

clean-grammars: ## Clean grammar build outputs
	rm -rf $(LEZER_REFS_DIR)/dist $(LEZER_REFS_DIR)/src/parser.js $(LEZER_REFS_DIR)/src/parser.terms.js
	rm -rf $(TS_REFS_DIR)/build

clean-lsp: ## Clean Rust build outputs
	cd $(LSP_DIR) && cargo clean

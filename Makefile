# Top-level Makefile orchestrating common tasks across the OCaml library,
# the OCaml LSP binary, and grammars (tree-sitter + Lezer). Intended as
# the canonical entrypoint for contributors and CI.

LEZER_REFS_DIR := grammars-lezer/lezer-httui-refs
TS_REFS_DIR    := lib/grammars/tree-sitter-httui-refs
LEZER_HTTP_DIR := grammars-lezer/lezer-httui-http
TS_HTTP_DIR    := lib/grammars/tree-sitter-httui-http
LSP_DIR        := bin/httui-lsp

.PHONY: help install setup-hooks build build-ocaml build-grammars build-lsp \
        test test-ocaml test-grammars bench \
        lint lint-ocaml lint-js \
        clean clean-ocaml clean-grammars \
        regenerate-grammars audit

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install all dependencies
	opam install --yes --deps-only --with-test .
	cd $(LEZER_REFS_DIR) && npm install
	cd $(LEZER_HTTP_DIR) && npm install
	cd $(TS_REFS_DIR) && npm install
	cd $(TS_HTTP_DIR) && npm install

setup-hooks: ## Install git hooks (commit-msg, pre-push, pre-commit)
	bash scripts/setup-hooks.sh

build: build-ocaml build-grammars ## Build everything

build-ocaml: ## Build OCaml library + LSP binary
	opam exec -- dune build

build-grammars: ## Build all grammars
	cd $(LEZER_REFS_DIR) && npm run build
	cd $(LEZER_HTTP_DIR) && npm run build
	cd $(TS_REFS_DIR) && npx tree-sitter generate
	cd $(TS_HTTP_DIR) && npx tree-sitter generate

build-lsp: ## Build only the LSP server binary
	opam exec -- dune build $(LSP_DIR)/httui_lsp.exe

test: test-ocaml test-grammars ## Run all tests

test-ocaml: ## Run OCaml tests (library + LSP binary)
	opam exec -- dune runtest

test-grammars: ## Run grammar corpus tests
	cd $(LEZER_REFS_DIR) && npm test
	cd $(LEZER_HTTP_DIR) && npm test
	cd $(TS_REFS_DIR) && npx tree-sitter test
	cd $(TS_HTTP_DIR) && npx tree-sitter test

bench: build-ocaml ## Run perf benchmarks (analysis in-process + LSP transport)
	python3 bench/gen_fixtures.py
	dune exec bench/bench_analysis.exe -- bench/fixtures
	python3 bench/lsp_roundtrip.py

lint: lint-ocaml lint-js ## Run all linters

lint-ocaml: ## OCaml formatter check
	opam exec -- dune build @fmt

lint-js: ## JS/TS lint via eslint + prettier
	cd $(LEZER_REFS_DIR) && npx eslint --max-warnings 0 src test
	cd $(LEZER_REFS_DIR) && npx prettier --check src test
	cd $(LEZER_HTTP_DIR) && npx eslint --max-warnings 0 src test
	cd $(LEZER_HTTP_DIR) && npx prettier --check src test

regenerate-grammars: ## Regenerate parser artifacts from grammar definitions
	cd $(LEZER_REFS_DIR) && npm run build:parser
	cd $(LEZER_HTTP_DIR) && npm run build:parser
	cd $(TS_REFS_DIR) && npx tree-sitter generate
	cd $(TS_HTTP_DIR) && npx tree-sitter generate

audit: ## Run security audits across ecosystems
	cd $(LEZER_REFS_DIR) && npm audit --audit-level=moderate
	cd $(LEZER_HTTP_DIR) && npm audit --audit-level=moderate
	cd $(TS_REFS_DIR) && npm audit --audit-level=moderate
	cd $(TS_HTTP_DIR) && npm audit --audit-level=moderate

clean: clean-ocaml clean-grammars ## Remove all build artifacts

clean-ocaml: ## Clean OCaml build outputs
	opam exec -- dune clean

clean-grammars: ## Clean grammar build outputs
	rm -rf $(LEZER_REFS_DIR)/dist $(LEZER_REFS_DIR)/src/parser.js $(LEZER_REFS_DIR)/src/parser.terms.js
	rm -rf $(LEZER_HTTP_DIR)/dist $(LEZER_HTTP_DIR)/src/parser.js $(LEZER_HTTP_DIR)/src/parser.terms.js
	rm -rf $(TS_REFS_DIR)/build
	rm -rf $(TS_HTTP_DIR)/build

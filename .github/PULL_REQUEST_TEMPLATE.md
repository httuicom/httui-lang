<!--
  Public vocabulary discipline: do NOT cite internal planning vocabulary
  in the PR title, description, or anywhere else that appears on git/GitHub.
  Forbidden terms (regex): \bADR-?[0-9], \bRFC-?[0-9], \bSlice\s*[0-9],
  \bV[0-9], \bPhase\s*[0-9], \bvertical\b, \baudit\s+decision, \bStory\s*[0-9].
  Describe what the change does, not which internal plan it implements.
-->

## Summary

<!-- One or two sentences: what does this change do and why is it needed. -->

## Changes

<!-- Bullet list of the substantive changes. Focus on what's externally visible
     or impactful; skip mechanical rename/format cleanup unless that's the point. -->

## Test plan

<!-- How did you validate this works? CI checks alone are not enough for UI/UX
     changes — describe manual validation when applicable. -->

## General checklist

- [ ] Subject is conventional-commits style and ≤ 72 characters
- [ ] No internal planning vocabulary in branch name, commit messages, PR text,
      code comments, or identifiers
- [ ] Build is green locally (`make build`)
- [ ] Tests are green locally (`make test`)
- [ ] Lint is clean locally (`make lint`)
- [ ] Documentation updated when behavior changes (README, CHANGELOG)

## Grammar bump checklist

<!--
  Required when this PR modifies grammar.js, refs.grammar, scanner.c, or
  bumps an external tree-sitter grammar submodule. Delete this section if
  the PR does not touch grammars.
-->

### Tree-sitter grammars

- [ ] Diff of `grammar.js` reviewed line by line (not only CI)
  - [ ] Node name changes that affect consumer code are intentional
  - [ ] New node kinds are mapped in `spec/token-kinds.md` if user-visible
- [ ] Diff of `src/scanner.c` reviewed (if present)
  - [ ] No new unbounded allocations
  - [ ] All input access is bounds-checked
  - [ ] Build is clean under ASan + UBSan (CI job: sanitizers)
- [ ] Corpus regression test passes (`tree-sitter test`)
- [ ] Real-world fixture parses without error (10+ representative files)

### Lezer grammars

- [ ] Diff of `refs.grammar` reviewed line by line
- [ ] Bundle size budget respected (CI job: bundle-size)

### Both engines (when grammars are owned dual-mode)

- [ ] Cross-grammar sync test passes (CI job: cross-grammar-sync)
- [ ] If one engine was updated, the other engine grammar received a
      companion update (or the divergence is intentional and added to the
      allowlist with a one-line justification)

### Downstream

- [ ] OCaml `httui_lang` semantic walk compiles with new CST
- [ ] Performance bench did not regress beyond the budget (CI job: bench)
- [ ] CHANGELOG.md updated with motivation for the bump
- [ ] OWNERS.md entry exists for the grammar

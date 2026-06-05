(lang dune 3.10)
(name httui_lang)
(version 0.1.0)
(license MIT)
(authors "João Ferreira <joao@httui.com>")
(maintainers "João Ferreira <joao@httui.com>")
(homepage "https://httui.com")
(source (github httuicom/httui-lang))
(documentation "https://github.com/httuicom/httui-lang#readme")

(generate_opam_files true)

(package
 (name httui_lang)
 (synopsis "Language layer for httui — parsing, semantics, type inference")
 (description "Tree-sitter and Lezer grammars, semantic analysis, type inference, and LSP support for httui executable blocks and references.")
 (depends
  (ocaml (>= 5.1.0))
  dune))

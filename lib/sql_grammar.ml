(* Tree-sitter SQL grammar (multi-dialect, vendored from
   @derekstride/tree-sitter-sql) exposed to OCaml. Like the HTTP grammar, the
   parser is process-wide and reused across calls — the server is
   single-threaded by design. *)

external language_ptr : unit -> nativeint = "caml_tree_sitter_sql_language"

let language = lazy (Tree_sitter.Language.of_address (language_ptr ()))
let parser = lazy (Tree_sitter.Parser.create (Lazy.force language))
let parse source = Tree_sitter.Parser.parse_string (Lazy.force parser) source

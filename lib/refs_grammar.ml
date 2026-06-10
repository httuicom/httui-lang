(* Tree-sitter grammar for httui refs, exposed to OCaml. The parser is
   process-wide and the server is single-threaded by design; reusing one
   parser instance avoids per-call setup. *)

external language_ptr : unit -> nativeint
  = "caml_tree_sitter_httui_refs_language"

let language = lazy (Tree_sitter.Language.of_address (language_ptr ()))
let parser = lazy (Tree_sitter.Parser.create (Lazy.force language))
let parse source = Tree_sitter.Parser.parse_string (Lazy.force parser) source

(* SQL CST access via the vendored tree-sitter-sql grammar. Phase 1 only
   parses and exposes a light walk over the named nodes; semantic tokens,
   schema completion and ref-vs-column type checks build on this in later
   phases. Offsets are byte offsets into the parsed SQL text. *)

type node = { kind : string; start_ : int; stop_ : int }

let parse source = Sql_grammar.parse source

let named_children node =
  let rec go i acc =
    if i < 0 then acc
    else
      match Tree_sitter.Node.child node i with
      | Some c when Tree_sitter.Node.is_named c -> go (i - 1) (c :: acc)
      | _ -> go (i - 1) acc
  in
  go (Tree_sitter.Node.child_count node - 1) []

(* Pre-order walk yielding every named node as {kind; start_; stop_}. The
   base shifts byte offsets so callers embedding SQL inside a larger document
   (a ```db-* fence) get doc-absolute positions. *)
let walk ?(base = 0) source =
  let tree = parse source in
  let root = Tree_sitter.Tree.root_node tree in
  let out = ref [] in
  let rec go node =
    (if Tree_sitter.Node.is_named node then
       let kind = Tree_sitter.Node.kind node in
       out :=
         {
           kind;
           start_ = base + Tree_sitter.Node.start_byte node;
           stop_ = base + Tree_sitter.Node.end_byte node;
         }
         :: !out);
    List.iter go (named_children node)
  in
  go root;
  List.rev !out

(* Distinct node kinds present in [source] — used by tests/diagnostics to
   confirm the grammar resolves the expected structure. *)
let kinds source =
  walk source |> List.map (fun n -> n.kind) |> List.sort_uniq compare

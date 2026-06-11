(* Extracts highlightable HTTP tokens from a ```http block's content via
   the tree-sitter CST. Offsets are doc-absolute (content offsets shifted
   by the block's position). Subtrees carrying ERROR/MISSING are skipped:
   a half-typed request line must not produce misleading tokens. *)

type kind = Method | Header_name | Header_value
type token = { start_ : int; stop_ : int; kind : kind }

let named_children node =
  let rec go i acc =
    if i < 0 then acc
    else
      match Tree_sitter.Node.child node i with
      | Some c when Tree_sitter.Node.is_named c -> go (i - 1) (c :: acc)
      | _ -> go (i - 1) acc
  in
  go (Tree_sitter.Node.child_count node - 1) []

let token_of node ~base ~kind =
  {
    start_ = base + Tree_sitter.Node.start_byte node;
    stop_ = base + Tree_sitter.Node.end_byte node;
    kind;
  }

let rec collect node ~base acc =
  let open Tree_sitter.Node in
  if is_error node || has_error node then
    (* descend anyway: an ERROR inside one line must not silence the
       rest of the block *)
    List.fold_left (fun acc c -> collect c ~base acc) acc (named_children node)
  else
    match kind node with
    | "request_line" ->
        List.fold_left
          (fun acc c ->
            if kind c = "method" then token_of c ~base ~kind:Method :: acc
            else acc)
          acc (named_children node)
    | "header_line" ->
        List.fold_left
          (fun acc c ->
            match kind c with
            | "header_name" -> token_of c ~base ~kind:Header_name :: acc
            | "header_value" -> token_of c ~base ~kind:Header_value :: acc
            | _ -> acc)
          acc (named_children node)
    | _ ->
        List.fold_left
          (fun acc c -> collect c ~base acc)
          acc (named_children node)

let of_block (b : Block.t) =
  if b.lang <> "http" || String.length b.content = 0 then []
  else
    let tree = Http_grammar.parse b.content in
    let root = Tree_sitter.Tree.root_node tree in
    List.rev (collect root ~base:b.content_offset [])

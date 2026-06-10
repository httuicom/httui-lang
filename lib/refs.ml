(* Extracts {{...}} occurrences from a block's content via the
   tree-sitter CST. Offsets are doc-absolute (content offsets shifted by
   the block's position). ERROR/MISSING subtrees are skipped: while the
   user types, half-written refs must not produce false diagnostics. *)

type occurrence = {
  name : string;  (** first identifier ([req1] in [{{req1.body.id}}]) *)
  has_path : bool;  (** a dot path follows the first identifier *)
  name_start : int;  (** doc-absolute byte range of [name] *)
  name_stop : int;
  ref_start : int;  (** doc-absolute byte range of the whole ref *)
  ref_stop : int;
  text : string;  (** ref body text ([req1.body.id]) *)
  path_segments : (int * int) list;
      (** doc-absolute ranges of path identifiers ([body], [id]) *)
}

let named_children node =
  let rec go i acc =
    if i < 0 then acc
    else
      match Tree_sitter.Node.child node i with
      | Some c when Tree_sitter.Node.is_named c -> go (i - 1) (c :: acc)
      | _ -> go (i - 1) acc
  in
  go (Tree_sitter.Node.child_count node - 1) []

let rec collect_refs node ~content ~base acc =
  let open Tree_sitter.Node in
  if is_error node then acc
  else if kind node = "ref" then
    if has_error node then acc (* half-typed ref — not analyzable yet *)
    else
      match
        List.find_opt (fun c -> kind c = "ref_body") (named_children node)
      with
      | None -> acc (* empty {{}} — nothing to analyze *)
      | Some body -> (
          match
            List.find_opt (fun c -> kind c = "identifier") (named_children body)
          with
          | None -> acc
          | Some ident ->
              let dot_path =
                List.find_opt
                  (fun c -> kind c = "dot_path")
                  (named_children body)
              in
              let path_segments =
                match dot_path with
                | None -> []
                | Some dp ->
                    named_children dp
                    |> List.concat_map (fun seg ->
                        named_children seg
                        |> List.filter (fun c -> kind c = "identifier")
                        |> List.map (fun id ->
                            (base + start_byte id, base + end_byte id)))
              in
              let occ =
                {
                  name =
                    String.sub content (start_byte ident)
                      (end_byte ident - start_byte ident);
                  has_path = Option.is_some dot_path;
                  name_start = base + start_byte ident;
                  name_stop = base + end_byte ident;
                  ref_start = base + start_byte node;
                  ref_stop = base + end_byte node;
                  text =
                    String.sub content (start_byte body)
                      (end_byte body - start_byte body);
                  path_segments;
                }
              in
              occ :: acc)
  else
    List.fold_left
      (fun acc c -> collect_refs c ~content ~base acc)
      acc (named_children node)

let of_block (b : Block.t) =
  if String.length b.content = 0 then []
  else
    let tree = Refs_grammar.parse b.content in
    let root = Tree_sitter.Tree.root_node tree in
    List.rev (collect_refs root ~content:b.content ~base:b.content_offset [])

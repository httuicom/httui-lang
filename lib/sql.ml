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

(* --- schema-aware completion --------------------------------------------- *)

(* Column/table schema supplied by the caller (the LSP reads it from the
   app's introspection cache). Kept here so completion stays a pure,
   testable function over a known schema. *)
type column = { name : string; data_type : string option }
type table = { schema : string option; name : string; columns : column list }
type completion = { label : string; detail : string option; is_table : bool }

let is_word_char c =
  (c >= 'a' && c <= 'z')
  || (c >= 'A' && c <= 'Z')
  || (c >= '0' && c <= '9')
  || c = '_'

(* Identifier ending exactly at [stop] (exclusive), scanning back over word
   chars. Returns its start, or [stop] when there is none. *)
let word_start text stop =
  let i = ref stop in
  while !i > 0 && is_word_char text.[!i - 1] do
    decr i
  done;
  !i

(* The last keyword_* token that ends at or before [limit]. Lexical via the
   CST so a half-typed tail (`SELECT … FROM `) still classifies. *)
let last_keyword_before text limit =
  walk text
  |> List.filter (fun n ->
      n.stop_ <= limit
      && String.length n.kind >= 8
      && String.sub n.kind 0 8 = "keyword_")
  |> List.fold_left
       (fun best n ->
         match best with Some b when b.stop_ >= n.stop_ -> best | _ -> Some n)
       None
  |> Option.map (fun n -> String.sub n.kind 8 (String.length n.kind - 8))

let table_completion (t : table) =
  {
    label = t.name;
    detail =
      (match t.schema with Some s -> Some (s ^ " schema") | None -> None);
    is_table = true;
  }

let column_completions (t : table) =
  List.map
    (fun (c : column) ->
      {
        label = c.name;
        detail =
          (match c.data_type with
          | Some d -> Some (t.name ^ "." ^ c.name ^ " : " ^ d)
          | None -> Some t.name);
        is_table = false;
      })
    t.columns

(* Context-aware completions at byte [offset] in SQL [text]:
   - after a `table.` qualifier -> that table's columns
   - after FROM/JOIN/INTO/UPDATE/TABLE -> table names
   - otherwise -> columns of every table + table names
   The partial word under the cursor is matched as a case-insensitive prefix. *)
let complete ~(tables : table list) ~text ~offset =
  let offset = max 0 (min offset (String.length text)) in
  let ws = word_start text offset in
  let prefix = String.lowercase_ascii (String.sub text ws (offset - ws)) in
  (* `table.` qualifier: a dot immediately before the partial word, preceded
     by an identifier naming a table. *)
  let qualifier =
    if ws > 0 && text.[ws - 1] = '.' then
      let qs = word_start text (ws - 1) in
      if qs < ws - 1 then
        let q = String.lowercase_ascii (String.sub text qs (ws - 1 - qs)) in
        List.find_opt
          (fun (t : table) -> String.lowercase_ascii t.name = q)
          tables
      else None
    else None
  in
  let raw =
    match qualifier with
    | Some t -> column_completions t
    | None -> (
        match last_keyword_before text ws with
        | Some ("from" | "join" | "into" | "update" | "table") ->
            List.map table_completion tables
        | _ ->
            List.concat_map column_completions tables
            @ List.map table_completion tables)
  in
  List.filter
    (fun c ->
      String.length prefix = 0
      || String.length c.label >= String.length prefix
         && String.lowercase_ascii (String.sub c.label 0 (String.length prefix))
            = prefix)
    raw

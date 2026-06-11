(* Reference analysis over a list of blocks: scope, diagnostics, hover
   and completion. Blocks can only reference aliases declared in blocks
   ABOVE them in the document (DAG by construction). A bare [{{KEY}}]
   (no dot path) may be an environment variable, which this layer cannot
   verify — it is never flagged.

   [shapes] maps an alias to the inferred shape of its last successful
   response (supplied by the caller; this layer never performs IO).
   Field-level findings are warnings: the shape is an inference from the
   last run, not ground truth. *)

type severity = Error | Warning

type diagnostic = {
  start_ : int;  (** doc-absolute byte range *)
  stop_ : int;
  message : string;
  severity : severity;
}

type hover = { h_start : int; h_stop : int; markdown : string }

(** aliases declared by blocks strictly before index [i] *)
let aliases_above blocks ~index =
  List.filteri (fun j _ -> j < index) blocks
  |> List.filter_map (fun (b : Block.t) ->
      match b.alias with Some a -> Some (a, b) | None -> None)

let is_db_lang lang = String.length lang > 3 && String.sub lang 0 3 = "db-"
let prev_name = "$prev"

(* mirror of the runtime [$prev]: the closest block above that the
   collector surfaces — executable AND aliased *)
let prev_decl blocks ~index =
  List.filteri (fun j _ -> j < index) blocks
  |> List.filter (fun (b : Block.t) -> Block.is_executable b && b.alias <> None)
  |> List.rev
  |> function
  | [] -> None
  | b :: _ -> Some b

(* (shape, declared-by-a-db-block) for [name], when both the declaration
   and an inferred shape exist *)
let shape_for ~shapes ~scope name =
  match (List.assoc_opt name shapes, List.assoc_opt name scope) with
  | Some shape, Some (decl : Block.t) -> Some (shape, is_db_lang decl.lang)
  | _ -> None

type typed_ctx = {
  resolve : string list -> Shape.resolution;
  fields : string list -> (string * Shape.t) list option;
}

(* typed resolvers for a ref head: named refs navigate the envelope,
   [$prev] navigates the previous block's response directly *)
let typed_ctx ~shapes ~blocks ~index ~scope name =
  if name = prev_name then
    match prev_decl blocks ~index with
    | Some (decl : Block.t) -> (
        match Option.bind decl.alias (fun a -> List.assoc_opt a shapes) with
        | Some shape ->
            let db = is_db_lang decl.lang in
            Some
              {
                resolve = Shape.resolve_prev ~response:shape ~db;
                fields = Shape.fields_at_prev ~response:shape ~db;
              }
        | None -> None)
    | None -> None
  else
    match shape_for ~shapes ~scope name with
    | Some (shape, db) ->
        Some
          {
            resolve = Shape.resolve_ref ~response:shape ~db;
            fields = Shape.fields_at ~response:shape ~db;
          }
    | None -> None

(* path segment texts paired with their doc-absolute ranges *)
let segments_of (b : Block.t) (r : Refs.occurrence) =
  List.map
    (fun (s, e) ->
      (String.sub b.content (s - b.content_offset) (e - s), (s, e)))
    r.path_segments

let path_until segs ~index name =
  String.concat "."
    (name :: (List.filteri (fun j _ -> j < index) segs |> List.map fst))

let field_diagnostic ~resolve (r : Refs.occurrence) segs =
  match (resolve (List.map fst segs) : Shape.resolution) with
  | Found _ | Opaque -> None
  | Missing { index; segment; available } ->
      let start_, stop_ = snd (List.nth segs index) in
      let hint =
        match Shape.suggest segment available with
        | Some s -> Printf.sprintf " — did you mean '%s'?" s
        | None -> ""
      in
      Some
        {
          start_;
          stop_;
          message =
            Printf.sprintf
              "Field '%s' not found in '%s' (inferred from the last run)%s"
              segment
              (path_until segs ~index r.name)
              hint;
          severity = Warning;
        }
  | Not_object { index; segment; parent } ->
      let start_, stop_ = snd (List.nth segs index) in
      Some
        {
          start_;
          stop_;
          message =
            Printf.sprintf "Cannot access '%s' — '%s' is a %s, not an object"
              segment
              (path_until segs ~index r.name)
              parent;
          severity = Warning;
        }

let diagnostics ?(shapes = []) blocks =
  List.concat
    (List.mapi
       (fun i (b : Block.t) ->
         if not (Block.is_executable b) then []
         else
           let scope = aliases_above blocks ~index:i in
           Refs.of_block b
           |> List.filter_map (fun (r : Refs.occurrence) ->
               let typo_check () =
                 Option.bind (typed_ctx ~shapes ~blocks ~index:i ~scope r.name)
                   (fun ctx ->
                     field_diagnostic ~resolve:ctx.resolve r (segments_of b r))
               in
               if r.name = prev_name then
                 if prev_decl blocks ~index:i = None then
                   Some
                     {
                       start_ = r.name_start;
                       stop_ = r.name_stop;
                       message = "No previous block to reference with {{$prev}}";
                       severity = Error;
                     }
                 else typo_check ()
               else if not r.has_path then None
               else if not (List.mem_assoc r.name scope) then
                 Some
                   {
                     start_ = r.name_start;
                     stop_ = r.name_stop;
                     message =
                       Printf.sprintf
                         "Unknown block alias '%s' — no block above declares \
                          alias=%s"
                         r.name r.name;
                     severity = Error;
                   }
               else typo_check ()))
       blocks)

let block_index_at blocks ~offset =
  let rec go i = function
    | [] -> None
    | (b : Block.t) :: rest ->
        if
          offset >= b.content_offset
          && offset <= b.content_offset + String.length b.content
        then Some (i, b)
        else go (i + 1) rest
  in
  go 0 blocks

let fields_markdown fields =
  fields
  |> List.map (fun (k, s) -> Printf.sprintf "- `%s`: %s" k (Shape.type_name s))
  |> String.concat "\n"

(* hover for the path segment under the cursor, typed against the
   alias's inferred shape *)
let segment_hover ~resolve (r : Refs.occurrence) segs ~offset =
  Option.bind
    (List.find_index (fun (_, (s, e)) -> offset >= s && offset < e) segs)
    (fun k ->
      let upto = List.filteri (fun j _ -> j <= k) segs in
      let h_start, h_stop = snd (List.nth segs k) in
      let path = path_until segs ~index:(k + 1) r.name in
      match (resolve (List.map fst upto) : Shape.resolution) with
      | Found s ->
          let body =
            match s with
            | Shape.Object_ fields when fields <> [] ->
                Printf.sprintf "**%s** — object\n\n%s" path
                  (fields_markdown fields)
            | s -> Printf.sprintf "**%s** — `%s`" path (Shape.type_name s)
          in
          Some
            {
              h_start;
              h_stop;
              markdown = body ^ "\n\n_inferred from the last successful run_";
            }
      | Missing { segment; available; _ } ->
          let hint =
            match Shape.suggest segment available with
            | Some s -> Printf.sprintf " — did you mean '%s'?" s
            | None -> ""
          in
          Some
            {
              h_start;
              h_stop;
              markdown =
                Printf.sprintf "**%s** — field not found in the last response%s"
                  path hint;
            }
      | Not_object _ | Opaque -> None)

(* [env_keys] comes from the caller (the IO shell reads names +
   [is_secret] from storage; values never reach this layer). *)
let hover_at ?(env_keys = []) ?(shapes = []) blocks ~offset =
  match block_index_at blocks ~offset with
  | None -> None
  | Some (i, b) ->
      Refs.of_block b
      |> List.find_opt (fun (r : Refs.occurrence) ->
          offset >= r.ref_start && offset < r.ref_stop)
      |> Option.map (fun (r : Refs.occurrence) ->
          let scope = aliases_above blocks ~index:i in
          let typed_hover =
            match typed_ctx ~shapes ~blocks ~index:i ~scope r.name with
            | Some ctx when r.has_path ->
                segment_hover ~resolve:ctx.resolve r (segments_of b r) ~offset
            | _ -> None
          in
          match typed_hover with
          | Some h -> h
          | None when r.name = prev_name ->
              let markdown =
                match prev_decl blocks ~index:i with
                | Some (decl : Block.t) ->
                    Printf.sprintf
                      "**%s** — previous block (alias '%s', line %d)\n\n\
                       `{{%s}}`"
                      prev_name
                      (Option.value decl.alias ~default:"")
                      (decl.open_line + 1) r.text
                | None ->
                    Printf.sprintf "**%s** — no previous block to reference"
                      prev_name
              in
              { h_start = r.ref_start; h_stop = r.ref_stop; markdown }
          | None ->
              let markdown =
                match
                  ( r.has_path,
                    List.assoc_opt r.name scope,
                    List.assoc_opt r.name env_keys )
                with
                | _, Some (decl : Block.t), _ ->
                    Printf.sprintf
                      "**%s** — block alias declared on line %d (` ```%s `)\n\n\
                       `{{%s}}`"
                      r.name (decl.open_line + 1) decl.lang r.text
                | true, None, _ ->
                    Printf.sprintf
                      "**%s** — unknown block alias (no block above declares \
                       it)"
                      r.name
                | false, None, Some is_secret ->
                    Printf.sprintf
                      "**%s** — environment variable in the active \
                       environment%s"
                      r.name
                      (if is_secret then " (secret — value never shown)" else "")
                | false, None, None ->
                    Printf.sprintf
                      "**%s** — environment variable or block alias (resolved \
                       at run time)"
                      r.name
              in
              { h_start = r.ref_start; h_stop = r.ref_stop; markdown })

type completion_item = {
  label : string;
  is_env : bool;
  secret : bool;
  field_type : string option;
      (** [Some type] when the item is a field of an inferred shape *)
}

(* "req1.response.bo" -> alias + complete segments (the partial last
   segment is the client's filter prefix, not a path step); [None] when
   the text between the braces is not a plain dotted path *)
let parse_path_prefix typed =
  let valid c =
    (c >= 'a' && c <= 'z')
    || (c >= 'A' && c <= 'Z')
    || (c >= '0' && c <= '9')
    || c = '_' || c = '.' || c = '[' || c = ']' || c = '$'
  in
  if not (String.for_all valid typed) then None
  else
    match String.split_on_char '.' typed with
    | alias :: (_ :: _ as rest) ->
        let strip_index s =
          match String.index_opt s '[' with
          | Some i -> String.sub s 0 i
          | None -> s
        in
        let complete =
          List.filteri (fun j _ -> j < List.length rest - 1) rest
          |> List.map strip_index
        in
        if alias = "" || List.exists (fun s -> s = "") complete then None
        else Some (alias, complete)
    | _ -> None

(* completion inside an open [{{] before the cursor (no closing [}}]
   between). Without a dot it offers the aliases in scope plus the
   environment variable names supplied by the caller; after a dot it
   offers the fields of the alias's inferred shape. *)
let completion_at ?(env_keys = []) ?(shapes = []) doc blocks ~offset =
  match block_index_at blocks ~offset with
  | None -> []
  | Some (i, _) -> (
      let open_pos =
        let rec back j =
          if j < 1 then None
          else if doc.[j - 1] = '{' && doc.[j] = '{' then Some (j + 1)
          else if doc.[j - 1] = '}' && doc.[j] = '}' then None
          else if doc.[j] = '\n' then None
          else back (j - 1)
        in
        if offset = 0 then None
        else back (min (offset - 1) (String.length doc - 1))
      in
      match open_pos with
      | None -> []
      | Some p -> (
          let scope = aliases_above blocks ~index:i in
          let typed = String.sub doc p (offset - p) in
          match parse_path_prefix typed with
          | Some (alias, segments) -> (
              match typed_ctx ~shapes ~blocks ~index:i ~scope alias with
              | None -> []
              | Some ctx -> (
                  match ctx.fields segments with
                  | None -> []
                  | Some fields ->
                      List.map
                        (fun (k, s) ->
                          {
                            label = k;
                            is_env = false;
                            secret = false;
                            field_type = Some (Shape.type_name s);
                          })
                        fields))
          | None ->
              List.map
                (fun (a, _) ->
                  {
                    label = a;
                    is_env = false;
                    secret = false;
                    field_type = None;
                  })
                scope
              @ List.map
                  (fun (k, secret) ->
                    { label = k; is_env = true; secret; field_type = None })
                  env_keys))

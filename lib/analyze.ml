(* Reference analysis over a list of blocks: scope, diagnostics, hover
   and completion. Blocks can only reference aliases declared in blocks
   ABOVE them in the document (DAG by construction). A bare [{{KEY}}]
   (no dot path) may be an environment variable, which this layer cannot
   verify — it is never flagged. *)

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

let diagnostics blocks =
  List.concat
    (List.mapi
       (fun i (b : Block.t) ->
         if not (Block.is_executable b) then []
         else
           let scope = aliases_above blocks ~index:i in
           Refs.of_block b
           |> List.filter_map (fun (r : Refs.occurrence) ->
               if r.has_path && not (List.mem_assoc r.name scope) then
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
               else None))
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

(* [env_keys] comes from the caller (the IO shell reads names +
   [is_secret] from storage; values never reach this layer). *)
let hover_at ?(env_keys = []) blocks ~offset =
  match block_index_at blocks ~offset with
  | None -> None
  | Some (i, b) ->
      Refs.of_block b
      |> List.find_opt (fun (r : Refs.occurrence) ->
          offset >= r.ref_start && offset < r.ref_stop)
      |> Option.map (fun (r : Refs.occurrence) ->
          let scope = aliases_above blocks ~index:i in
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
                  "**%s** — unknown block alias (no block above declares it)"
                  r.name
            | false, None, Some is_secret ->
                Printf.sprintf
                  "**%s** — environment variable in the active environment%s"
                  r.name
                  (if is_secret then " (secret — value never shown)" else "")
            | false, None, None ->
                Printf.sprintf
                  "**%s** — environment variable or block alias (resolved at \
                   run time)"
                  r.name
          in
          { h_start = r.ref_start; h_stop = r.ref_stop; markdown })

type completion_item = { label : string; is_env : bool; secret : bool }

(* completion inside an open [{{] before the cursor (no closing [}}]
   between) — offers the aliases in scope for the enclosing block plus
   the environment variable names supplied by the caller *)
let completion_at ?(env_keys = []) doc blocks ~offset =
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
      | Some _ ->
          List.map
            (fun (a, _) -> { label = a; is_env = false; secret = false })
            (aliases_above blocks ~index:i)
          @ List.map
              (fun (k, secret) -> { label = k; is_env = true; secret })
              env_keys)

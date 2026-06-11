(* Abstract semantic tokens: alias declarations and refs, fence info
   strings, and HTTP request structure. The LSP layer maps each kind to
   a token type name according to the client's announced capabilities
   (server-side downgrade) and encodes positions; this module stays
   protocol-free. *)

type kind =
  | Alias
  | Env_var
  | Ref_path
  | Http_method
  | Http_header_name
  | Http_header_value
  | Fence_lang
  | Fence_info

type t = {
  t_start : int;  (** doc-absolute byte range *)
  t_stop : int;
  kind : kind;
  unresolved : bool;  (** ref with path whose alias is not in scope *)
  declaration : bool;  (** [alias=...] declaration site in the info string *)
}

let plain ~start_ ~stop_ kind =
  {
    t_start = start_;
    t_stop = stop_;
    kind;
    unresolved = false;
    declaration = false;
  }

(* Fence tokens for the info string. LSP tokens must not overlap, so the
   token carrying the alias declaration is split: [Fence_info] covers
   only the [alias=] prefix and the value keeps its [Alias] token. *)
let fence_tokens (b : Block.t) =
  let lang =
    if String.length b.lang = 0 then []
    else
      [
        plain ~start_:b.lang_offset
          ~stop_:(b.lang_offset + String.length b.lang)
          Fence_lang;
      ]
  in
  let infos =
    List.filter_map
      (fun (s, e) ->
        match b.alias_offset with
        | Some v when s < v && v < e ->
            if v > s then Some (plain ~start_:s ~stop_:v Fence_info) else None
        | _ -> Some (plain ~start_:s ~stop_:e Fence_info))
      b.info_tokens
  in
  lang @ infos

(* Carve [holes] (sorted, disjoint) out of [s, e); returns the remaining
   sub-spans. Used to keep HTTP tokens from overlapping ref tokens —
   LSP semantic tokens must be disjoint. *)
let subtract_holes ~s ~e holes =
  let rec go cur holes acc =
    match holes with
    | [] -> if cur < e then (cur, e) :: acc else acc
    | (hs, he) :: rest ->
        if he <= cur then go cur rest acc
        else if hs >= e then go cur [] acc
        else
          let acc = if hs > cur then (cur, hs) :: acc else acc in
          go (max cur he) rest acc
  in
  List.rev (go s holes [])

let http_tokens (b : Block.t) ~ref_spans =
  Http.of_block b
  |> List.concat_map (fun (tok : Http.token) ->
      let kind =
        match tok.kind with
        | Http.Method -> Http_method
        | Http.Header_name -> Http_header_name
        | Http.Header_value -> Http_header_value
      in
      subtract_holes ~s:tok.start_ ~e:tok.stop_ ref_spans
      |> List.map (fun (s, e) -> plain ~start_:s ~stop_:e kind))

let of_blocks blocks =
  List.concat
    (List.mapi
       (fun i (b : Block.t) ->
         if not (Block.is_executable b) then []
         else
           let scope = Analyze.aliases_above blocks ~index:i in
           let declaration =
             match (b.alias, b.alias_offset) with
             | Some a, Some off ->
                 [
                   {
                     t_start = off;
                     t_stop = off + String.length a;
                     kind = Alias;
                     unresolved = false;
                     declaration = true;
                   };
                 ]
             | _ -> []
           in
           let occurrences = Refs.of_block b in
           let ref_spans =
             List.map
               (fun (r : Refs.occurrence) -> (r.ref_start, r.ref_stop))
               occurrences
             |> List.sort compare
           in
           let refs =
             occurrences
             |> List.concat_map (fun (r : Refs.occurrence) ->
                 let is_prev = r.name = Analyze.prev_name in
                 let known =
                   if is_prev then Analyze.prev_decl blocks ~index:i <> None
                   else List.mem_assoc r.name scope
                 in
                 let name_kind =
                   if is_prev || r.has_path || known then Alias else Env_var
                 in
                 {
                   t_start = r.name_start;
                   t_stop = r.name_stop;
                   kind = name_kind;
                   unresolved = (is_prev || r.has_path) && not known;
                   declaration = false;
                 }
                 :: List.map
                      (fun (s, e) ->
                        {
                          t_start = s;
                          t_stop = e;
                          kind = Ref_path;
                          unresolved = false;
                          declaration = false;
                        })
                      r.path_segments)
           in
           declaration @ fence_tokens b @ http_tokens b ~ref_spans @ refs)
       blocks)
  |> List.sort (fun a b -> compare a.t_start b.t_start)

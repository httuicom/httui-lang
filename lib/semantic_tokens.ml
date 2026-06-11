(* Abstract semantic tokens for refs: alias declarations in info strings,
   ref names and path segments. The LSP layer maps each kind to a token
   type name according to the client's announced capabilities (server-side
   downgrade) and encodes positions; this module stays protocol-free. *)

type kind = Alias | Env_var | Ref_path

type t = {
  t_start : int;  (** doc-absolute byte range *)
  t_stop : int;
  kind : kind;
  unresolved : bool;  (** ref with path whose alias is not in scope *)
  declaration : bool;  (** [alias=...] declaration site in the info string *)
}

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
           let refs =
             Refs.of_block b
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
           declaration @ refs)
       blocks)
  |> List.sort (fun a b -> compare a.t_start b.t_start)

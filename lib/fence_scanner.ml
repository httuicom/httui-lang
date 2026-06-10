(* Border module: discovers fenced blocks by scanning lines. Deliberately
   replaceable — if discovery ever moves to a markdown CST, only this
   module changes; the analyses consume [Block.t list] and never see
   markdown. Unclosed fences extend to end of document so the editor
   keeps analysis while the user is still typing the closing fence. *)

let fence_prefix line =
  (* up to 3 leading spaces, then a run of >= 3 backticks *)
  let n = String.length line in
  let i = ref 0 in
  while !i < n && !i < 3 && line.[!i] = ' ' do
    incr i
  done;
  let start = !i in
  while !i < n && line.[!i] = '`' do
    incr i
  done;
  let ticks = !i - start in
  if ticks >= 3 then Some (ticks, !i) else None

let is_closing line ~ticks =
  match fence_prefix line with
  | Some (t, after) when t >= ticks ->
      String.for_all
        (fun c -> c = ' ')
        (String.sub line after (String.length line - after))
  | _ -> false

(* "http alias=req1 timeout=30000" -> lang + assoc pairs with the byte
   offset of each value inside the info string *)
let parse_info info =
  let tokens =
    let out = ref [] in
    let n = String.length info in
    let i = ref 0 in
    while !i < n do
      while !i < n && info.[!i] = ' ' do
        incr i
      done;
      let start = !i in
      while !i < n && info.[!i] <> ' ' do
        incr i
      done;
      if !i > start then
        out := (start, String.sub info start (!i - start)) :: !out
    done;
    List.rev !out
  in
  match tokens with
  | [] -> ("", [])
  | (_, lang) :: rest ->
      let pairs =
        List.filter_map
          (fun (off, tok) ->
            match String.index_opt tok '=' with
            | Some eq ->
                let key = String.sub tok 0 eq in
                let value =
                  String.sub tok (eq + 1) (String.length tok - eq - 1)
                in
                Some (key, (value, off + eq + 1))
            | None -> None)
          rest
      in
      (lang, pairs)

let scan doc =
  let blocks = ref [] in
  let len = String.length doc in
  let pos = ref 0 in
  let line_no = ref 0 in
  let in_block = ref None in
  (* (ticks, lang, alias, alias_off, content_start, open_line) *)
  let buf = Buffer.create 256 in
  while !pos <= len do
    let eol =
      match String.index_from_opt doc !pos '\n' with Some i -> i | None -> len
    in
    let line = String.sub doc !pos (eol - !pos) in
    (match !in_block with
    | None -> (
        match fence_prefix line with
        | Some (ticks, after) ->
            let info = String.sub line after (String.length line - after) in
            let lang, pairs = parse_info info in
            let alias, alias_off =
              match List.assoc_opt "alias" pairs with
              | Some (v, off_in_info) ->
                  (Some v, Some (!pos + after + off_in_info))
              | None -> (None, None)
            in
            let content_start = if eol >= len then len else eol + 1 in
            Buffer.clear buf;
            in_block :=
              Some (ticks, lang, alias, alias_off, content_start, !line_no)
        | None -> ())
    | Some (ticks, lang, alias, alias_off, content_start, open_line) ->
        if is_closing line ~ticks then begin
          blocks :=
            {
              Block.lang;
              alias;
              alias_offset = alias_off;
              content = Buffer.contents buf;
              content_offset = content_start;
              open_line;
            }
            :: !blocks;
          in_block := None
        end
        else begin
          Buffer.add_string buf line;
          if eol < len then Buffer.add_char buf '\n'
        end);
    pos := eol + 1;
    incr line_no
  done;
  (match !in_block with
  | Some (_, lang, alias, alias_off, content_start, open_line) ->
      blocks :=
        {
          Block.lang;
          alias;
          alias_offset = alias_off;
          content = Buffer.contents buf;
          content_offset = content_start;
          open_line;
        }
        :: !blocks
  | None -> ());
  List.rev !blocks

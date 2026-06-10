(* Byte offset <-> LSP position conversion. LSP positions count UTF-16
   code units per line; document text is UTF-8. *)

type t = { line : int; character : int }

let line_start_before doc offset =
  let rec back i =
    if i <= 0 then 0 else if doc.[i - 1] = '\n' then i else back (i - 1)
  in
  back offset

let line_of_offset doc offset =
  let line = ref 0 in
  for i = 0 to min offset (String.length doc) - 1 do
    if doc.[i] = '\n' then incr line
  done;
  !line

(* UTF-16 units between two byte offsets on the same line *)
let utf16_units doc ~from ~until =
  let units = ref 0 in
  let i = ref from in
  let stop = min until (String.length doc) in
  while !i < stop do
    let b = Char.code doc.[!i] in
    if b < 0x80 then (
      incr units;
      incr i)
    else if b < 0xE0 then (
      incr units;
      i := !i + 2)
    else if b < 0xF0 then (
      incr units;
      i := !i + 3)
    else (
      units := !units + 2;
      i := !i + 4)
  done;
  !units

let of_offset doc offset =
  let offset = max 0 (min offset (String.length doc)) in
  let line = line_of_offset doc offset in
  let ls = line_start_before doc offset in
  { line; character = utf16_units doc ~from:ls ~until:offset }

let to_offset doc { line; character } =
  let len = String.length doc in
  (* find the start of [line] *)
  let rec find_line i l =
    if l = 0 || i >= len then i
    else if doc.[i] = '\n' then find_line (i + 1) (l - 1)
    else find_line (i + 1) l
  in
  let ls = find_line 0 line in
  (* consume [character] UTF-16 units without crossing the line end *)
  let i = ref ls and units = ref 0 in
  while !i < len && doc.[!i] <> '\n' && !units < character do
    let b = Char.code doc.[!i] in
    if b < 0x80 then (
      incr units;
      incr i)
    else if b < 0xE0 then (
      incr units;
      i := !i + 2)
    else if b < 0xF0 then (
      incr units;
      i := !i + 3)
    else (
      units := !units + 2;
      i := !i + 4)
  done;
  !i

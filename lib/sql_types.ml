(* A small type lattice that normalises the many native SQL column types
   (Postgres / MySQL / SQLite) and the inferred ref shape types down to a
   handful of comparable categories. Used by the cross-language check:
   `WHERE col = {{ref}}` warns when the column category and the ref category
   are genuinely incompatible. Leniency is deliberate — a false squiggle
   erodes trust faster than a missed one, so anything [Unknown] passes. *)

type t = Number | String | Boolean | Json | Datetime | Unknown

let to_string = function
  | Number -> "number"
  | String -> "string"
  | Boolean -> "boolean"
  | Json -> "json"
  | Datetime -> "datetime"
  | Unknown -> "unknown"

let contains ~needle s =
  let nl = String.length needle and sl = String.length s in
  let rec go i =
    if i + nl > sl then false
    else if String.sub s i nl = needle then true
    else go (i + 1)
  in
  nl = 0 || go 0

(* Column data-type string (from information_schema / PRAGMA) -> category.
   Substring matching mirrors SQLite's affinity algorithm and covers the
   common PG/MySQL spellings (int4, bigint, varchar, timestamptz, jsonb…). *)
let of_column raw =
  let s = String.lowercase_ascii (String.trim raw) in
  let has n = contains ~needle:n s in
  if has "bool" then Boolean
  else if has "json" then Json
  else if
    has "int" || has "serial" || has "numeric" || has "decimal" || has "real"
    || has "double" || has "float" || has "money"
  then Number
  else if has "timestamp" || has "date" || has "time" then Datetime
  else if
    has "char" || has "text" || has "clob" || has "uuid" || has "string"
    || has "enum" || has "name"
  then String
  else Unknown

(* Inferred ref shape type name (Shape.type_name: "number" | "string" |
   "boolean" | "null" | "object" | "array<…>") -> category. *)
let of_shape_type name =
  match String.lowercase_ascii name with
  | "number" -> Number
  | "string" -> String
  | "boolean" -> Boolean
  | "object" -> Json
  | s when String.length s >= 5 && String.sub s 0 5 = "array" -> Json
  | _ -> Unknown

(* Two categories are compatible unless both are known and different.
   `Datetime` and `String` are treated as compatible (dates flow as ISO
   strings on the value path). *)
let compatible a b =
  a = b || a = Unknown || b = Unknown
  || (a = Datetime && b = String)
  || (a = String && b = Datetime)

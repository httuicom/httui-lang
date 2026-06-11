(* A fenced executable block as pure data. This record is the contract
   between block discovery (fence scanner today, possibly a markdown CST
   in the future) and every analysis: producers may change, the analysis
   never learns where blocks came from. *)

type t = {
  lang : string;  (** info-string language token ("http", "db-postgres") *)
  lang_offset : int;
      (** byte offset (doc-absolute) of the lang token; meaningful only when
          [lang] is non-empty *)
  alias : string option;  (** [alias=...] from the info string *)
  alias_offset : int option;
      (** byte offset (doc-absolute) of the alias value, when present *)
  info_tokens : (int * int) list;
      (** doc-absolute spans of each [key=value] info-string token after the
          lang *)
  content : string;  (** fence body, without the fence lines *)
  content_offset : int;  (** byte offset (doc-absolute) of [content] *)
  open_line : int;  (** 0-based line of the opening fence *)
}

let is_executable t =
  t.lang = "http" || (String.length t.lang > 3 && String.sub t.lang 0 3 = "db-")

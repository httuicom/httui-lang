(* httui-lsp — Language Server for httui blocks and references.

   Pure OCaml: an IO shell (stdio framing + JSON-RPC dispatch) around the
   pure [Httui_lang] library. Storage access, when it arrives, is
   read-only by design; the server never touches the OS keychain — secret
   values exist only on the execution path, outside this process. *)

module T = Lsp.Types

let docs : (string, T.DocumentUri.t * string) Hashtbl.t = Hashtbl.create 16

(* --- stdio framing ----------------------------------------------------- *)

let read_message () =
  let len = ref (-1) in
  let rec read_headers () =
    let line = input_line stdin in
    let line =
      let n = String.length line in
      if n > 0 && line.[n - 1] = '\r' then String.sub line 0 (n - 1) else line
    in
    if line = "" then ()
    else begin
      (match String.index_opt line ':' with
      | Some i ->
          let key = String.lowercase_ascii (String.sub line 0 i) in
          if key = "content-length" then
            len :=
              int_of_string
                (String.trim
                   (String.sub line (i + 1) (String.length line - i - 1)))
      | None -> ());
      read_headers ()
    end
  in
  read_headers ();
  if !len < 0 then failwith "missing content-length header";
  really_input_string stdin !len

let write_packet packet =
  let body = Yojson.Safe.to_string (Jsonrpc.Packet.yojson_of_t packet) in
  Printf.printf "Content-Length: %d\r\n\r\n%s" (String.length body) body;
  flush stdout

let respond id json =
  write_packet (Jsonrpc.Packet.Response (Jsonrpc.Response.ok id json))

let respond_error id code message =
  write_packet
    (Jsonrpc.Packet.Response
       (Jsonrpc.Response.error id
          (Jsonrpc.Response.Error.make ~code ~message ())))

let notify method_ json =
  write_packet
    (Jsonrpc.Packet.Notification
       (Jsonrpc.Notification.create ~method_
          ~params:(Jsonrpc.Structured.t_of_yojson json)
          ()))

(* --- analysis glue ------------------------------------------------------ *)

let position_of_offset text off =
  let p = Httui_lang.Doc_position.of_offset text off in
  T.Position.create ~line:p.line ~character:p.character

let range_of_offsets text ~start ~stop =
  T.Range.create
    ~start:(position_of_offset text start)
    ~end_:(position_of_offset text stop)

let offset_of_position text (pos : T.Position.t) =
  Httui_lang.Doc_position.to_offset text
    { line = pos.line; character = pos.character }

(* shapes are read per request/publish: they change whenever the user
   runs a block, and the read is microseconds against a local sqlite *)
let shapes_for_uri uri =
  Schema_store.shapes_for ~file_path:(T.DocumentUri.to_path uri)

let values_for_uri uri =
  Result_store.values_for ~file_path:(T.DocumentUri.to_path uri)

let publish_diagnostics uri text =
  let blocks = Httui_lang.Fence_scanner.scan text in
  let diagnostics =
    Httui_lang.Analyze.diagnostics ~shapes:(shapes_for_uri uri) blocks
    |> List.map (fun (d : Httui_lang.Analyze.diagnostic) ->
        T.Diagnostic.create
          ~range:(range_of_offsets text ~start:d.start_ ~stop:d.stop_)
          ~severity:
            (match d.severity with
            | Httui_lang.Analyze.Error -> T.DiagnosticSeverity.Error
            | Httui_lang.Analyze.Warning -> T.DiagnosticSeverity.Warning)
          ~source:"httui" ~message:(`String d.message) ())
  in
  let params = T.PublishDiagnosticsParams.create ~uri ~diagnostics () in
  notify "textDocument/publishDiagnostics"
    (T.PublishDiagnosticsParams.yojson_of_t params)

let doc_updated uri text =
  Hashtbl.replace docs (T.DocumentUri.to_string uri) (uri, text);
  publish_diagnostics uri text

(* --- handlers ----------------------------------------------------------- *)

let params_json (params : Jsonrpc.Structured.t option) =
  match params with Some p -> Jsonrpc.Structured.yojson_of_t p | None -> `Null

(* --- semantic tokens legend (per-client, server-side downgrade) --------- *)

(* Token types are unique per range and clients silently ignore types
   outside their announced capabilities, so the legend is computed at
   initialize: an httui.* kind is registered only when the client
   announced it; otherwise its LSP-standard fallback takes the slot. *)

let legend_types =
  ref [ "keyword"; "parameter"; "property"; "string"; "variable" ]

let legend_modifiers = ref ([] : string list)

let compute_legend ~announced_types ~announced_modifiers =
  let pick preferred fallback =
    if List.mem preferred announced_types then preferred else fallback
  in
  let names =
    [
      pick "httui.alias" "variable";
      pick "httui.env_var" "variable";
      pick "httui.ref_path" "property";
      pick "httui.http_method" "keyword";
      pick "httui.http_header_name" "property";
      pick "httui.http_header_value" "string";
      pick "httui.fence_lang" "keyword";
      pick "httui.fence_info" "parameter";
    ]
  in
  legend_types := List.sort_uniq compare names;
  legend_modifiers :=
    List.filter
      (fun m -> List.mem m announced_modifiers)
      [ "declaration"; "unresolved"; "secret" ]

let type_index (kind : Httui_lang.Semantic_tokens.kind) =
  let name =
    let mem n = List.mem n !legend_types in
    match kind with
    | Httui_lang.Semantic_tokens.Alias ->
        if mem "httui.alias" then "httui.alias" else "variable"
    | Httui_lang.Semantic_tokens.Env_var ->
        if mem "httui.env_var" then "httui.env_var" else "variable"
    | Httui_lang.Semantic_tokens.Ref_path ->
        if mem "httui.ref_path" then "httui.ref_path" else "property"
    | Httui_lang.Semantic_tokens.Http_method ->
        if mem "httui.http_method" then "httui.http_method" else "keyword"
    | Httui_lang.Semantic_tokens.Http_header_name ->
        if mem "httui.http_header_name" then "httui.http_header_name"
        else "property"
    | Httui_lang.Semantic_tokens.Http_header_value ->
        if mem "httui.http_header_value" then "httui.http_header_value"
        else "string"
    | Httui_lang.Semantic_tokens.Fence_lang ->
        if mem "httui.fence_lang" then "httui.fence_lang" else "keyword"
    | Httui_lang.Semantic_tokens.Fence_info ->
        if mem "httui.fence_info" then "httui.fence_info" else "parameter"
  in
  let rec idx i = function
    | [] -> 0
    | x :: rest -> if x = name then i else idx (i + 1) rest
  in
  idx 0 !legend_types

let modifier_bits (t : Httui_lang.Semantic_tokens.t) =
  List.fold_left
    (fun bits (i, m) ->
      let active =
        (m = "declaration" && t.declaration)
        || (m = "unresolved" && t.unresolved)
        || (m = "secret" && t.secret)
      in
      if active then bits lor (1 lsl i) else bits)
    0
    (List.mapi (fun i m -> (i, m)) !legend_modifiers)

let on_initialize (r : Jsonrpc.Request.t) =
  (try
     let p = T.InitializeParams.t_of_yojson (params_json r.params) in
     match p.capabilities.textDocument with
     | Some td -> (
         match td.semanticTokens with
         | Some st ->
             compute_legend ~announced_types:st.tokenTypes
               ~announced_modifiers:st.tokenModifiers
         | None -> compute_legend ~announced_types:[] ~announced_modifiers:[])
     | None -> compute_legend ~announced_types:[] ~announced_modifiers:[]
   with _ -> compute_legend ~announced_types:[] ~announced_modifiers:[]);
  let capabilities =
    T.ServerCapabilities.create
      ~textDocumentSync:
        (`TextDocumentSyncOptions
           (T.TextDocumentSyncOptions.create ~openClose:true
              ~change:T.TextDocumentSyncKind.Full ()))
      ~hoverProvider:(`Bool true)
      ~completionProvider:
        (T.CompletionOptions.create ~triggerCharacters:[ "{" ] ())
      ~semanticTokensProvider:
        (`SemanticTokensOptions
           (T.SemanticTokensOptions.create
              ~legend:
                (T.SemanticTokensLegend.create ~tokenTypes:!legend_types
                   ~tokenModifiers:!legend_modifiers)
              ~full:(`Full (T.SemanticTokensOptions.create_full ~delta:true ()))
              ()))
      ~definitionProvider:(`Bool true) ~referencesProvider:(`Bool true)
      ~renameProvider:(`Bool true) ()
  in
  let serverInfo =
    T.InitializeResult.create_serverInfo ~name:"httui-lsp"
      ~version:Httui_lang.Version.v ()
  in
  let result = T.InitializeResult.create ~capabilities ~serverInfo () in
  respond r.id (T.InitializeResult.yojson_of_t result)

let with_doc id uri k =
  match Hashtbl.find_opt docs (T.DocumentUri.to_string uri) with
  | None -> respond id `Null
  | Some (_, text) -> k text

let on_hover (r : Jsonrpc.Request.t) =
  let p = T.HoverParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      match
        Httui_lang.Analyze.hover_at
          ~env_keys:
            (Env_store.keys_for
               ~file_path:(T.DocumentUri.to_path p.textDocument.uri))
          ~shapes:(shapes_for_uri p.textDocument.uri)
          ~values:(values_for_uri p.textDocument.uri)
          blocks ~offset
      with
      | None -> respond r.id `Null
      | Some h ->
          let hover =
            T.Hover.create
              ~contents:
                (`MarkupContent
                   (T.MarkupContent.create ~kind:T.MarkupKind.Markdown
                      ~value:h.markdown))
              ~range:(range_of_offsets text ~start:h.h_start ~stop:h.h_stop)
              ()
          in
          respond r.id (T.Hover.yojson_of_t hover))

let on_completion (r : Jsonrpc.Request.t) =
  let p = T.CompletionParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      let items =
        Httui_lang.Analyze.completion_at
          ~env_keys:
            (Env_store.keys_for
               ~file_path:(T.DocumentUri.to_path p.textDocument.uri))
          ~shapes:(shapes_for_uri p.textDocument.uri)
          text blocks ~offset
        |> List.map (fun (it : Httui_lang.Analyze.completion_item) ->
            match it.field_type with
            | Some type_ ->
                T.CompletionItem.create ~label:it.label
                  ~kind:T.CompletionItemKind.Field ~detail:type_ ()
            | None ->
                if it.is_env then
                  T.CompletionItem.create ~label:it.label
                    ~kind:T.CompletionItemKind.Constant
                    ~detail:
                      (if it.secret then "environment variable (secret)"
                       else "environment variable")
                    ()
                else
                  T.CompletionItem.create ~label:it.label
                    ~kind:T.CompletionItemKind.Variable ~detail:"block alias" ())
      in
      respond r.id (`List (List.map T.CompletionItem.yojson_of_t items)))

(* Encode tokens to the LSP delta-position int stream. Tokens arrive
   sorted by start offset, so a single forward cursor over the document
   converts every offset to (line, char) in O(doc) total — the previous
   per-token [Doc_position.of_offset] was O(offset) each, i.e. O(n^2)
   over the whole document and the dominant cost on large files. *)
let encode_tokens text tokens =
  let n = String.length text in
  let cur = ref 0 and line = ref 0 and line_start = ref 0 in
  let advance_to off =
    while !cur < off && !cur < n do
      if text.[!cur] = '\n' then begin
        incr line;
        line_start := !cur + 1
      end;
      incr cur
    done
  in
  let prev_line = ref 0 and prev_char = ref 0 in
  let data =
    List.concat_map
      (fun (t : Httui_lang.Semantic_tokens.t) ->
        advance_to t.t_start;
        let char =
          Httui_lang.Doc_position.utf16_units text ~from:!line_start
            ~until:t.t_start
        in
        let length =
          Httui_lang.Doc_position.utf16_units text ~from:t.t_start
            ~until:t.t_stop
        in
        let dl = !line - !prev_line in
        let dc = if dl = 0 then char - !prev_char else char in
        prev_line := !line;
        prev_char := char;
        [ dl; dc; length; type_index t.kind; modifier_bits t ])
      tokens
  in
  Array.of_list data

let compute_token_data ~env_keys text =
  encode_tokens text
    (Httui_lang.Semantic_tokens.of_blocks ~env_keys
       (Httui_lang.Fence_scanner.scan text))

(* Last full result per document, for delta requests: uri -> (resultId,
   data). Monotonic ids keep delta bookkeeping trivial. *)
let token_results : (string, string * int array) Hashtbl.t = Hashtbl.create 16
let result_id_counter = ref 0

let next_result_id () =
  incr result_id_counter;
  string_of_int !result_id_counter

let store_tokens uri data =
  let id = next_result_id () in
  Hashtbl.replace token_results (T.DocumentUri.to_string uri) (id, data);
  id

(* Minimal prefix/suffix diff of two int streams into a single LSP edit
   (the encoding rust-analyzer uses). Empty list when identical. *)
let diff_tokens old_ new_ =
  let lo = Array.length old_ and ln = Array.length new_ in
  let p = ref 0 in
  while !p < lo && !p < ln && old_.(!p) = new_.(!p) do
    incr p
  done;
  let s = ref 0 in
  while
    !s < lo - !p && !s < ln - !p && old_.(lo - 1 - !s) = new_.(ln - 1 - !s)
  do
    incr s
  done;
  let delete_count = lo - !p - !s in
  let new_len = ln - !p - !s in
  if delete_count = 0 && new_len = 0 then []
  else
    let data = if new_len = 0 then None else Some (Array.sub new_ !p new_len) in
    [ T.SemanticTokensEdit.create ~deleteCount:delete_count ?data ~start:!p () ]

let on_semantic_tokens (r : Jsonrpc.Request.t) =
  let p = T.SemanticTokensParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let env_keys =
        Env_store.keys_for ~file_path:(T.DocumentUri.to_path p.textDocument.uri)
      in
      let data = compute_token_data ~env_keys text in
      let result_id = store_tokens p.textDocument.uri data in
      respond r.id
        (T.SemanticTokens.yojson_of_t
           (T.SemanticTokens.create ~data ~resultId:result_id ())))

let on_semantic_tokens_delta (r : Jsonrpc.Request.t) =
  let p = T.SemanticTokensDeltaParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let env_keys =
        Env_store.keys_for ~file_path:(T.DocumentUri.to_path p.textDocument.uri)
      in
      let data = compute_token_data ~env_keys text in
      let uri_s = T.DocumentUri.to_string p.textDocument.uri in
      match Hashtbl.find_opt token_results uri_s with
      | Some (prev_id, old_data) when prev_id = p.previousResultId ->
          let edits = diff_tokens old_data data in
          let result_id = store_tokens p.textDocument.uri data in
          respond r.id
            (T.SemanticTokensDelta.yojson_of_t
               (T.SemanticTokensDelta.create ~edits ~resultId:result_id ()))
      | _ ->
          (* unknown/stale previousResultId — the spec allows replying
             with a full result instead of a delta *)
          let result_id = store_tokens p.textDocument.uri data in
          respond r.id
            (T.SemanticTokens.yojson_of_t
               (T.SemanticTokens.create ~data ~resultId:result_id ())))

(* --- alias navigation: definition / references / rename ----------------- *)

let location_of_range text uri ~start ~stop =
  T.Location.create ~uri ~range:(range_of_offsets text ~start ~stop)

let on_definition (r : Jsonrpc.Request.t) =
  let p = T.DefinitionParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      match Httui_lang.Analyze.symbol_at blocks ~offset with
      | Some { decl_range = Some (s, e); _ } ->
          let loc =
            location_of_range text p.textDocument.uri ~start:s ~stop:e
          in
          respond r.id (T.Locations.yojson_of_t (`Location [ loc ]))
      | _ -> respond r.id `Null)

let on_references (r : Jsonrpc.Request.t) =
  let p = T.ReferenceParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      match Httui_lang.Analyze.symbol_at blocks ~offset with
      | None -> respond r.id `Null
      | Some sym ->
          let ranges =
            (if p.context.includeDeclaration then Option.to_list sym.decl_range
             else [])
            @ sym.ref_ranges
          in
          let locs =
            List.map
              (fun (s, e) ->
                location_of_range text p.textDocument.uri ~start:s ~stop:e)
              ranges
          in
          respond r.id (`List (List.map T.Location.yojson_of_t locs)))

let on_rename (r : Jsonrpc.Request.t) =
  let p = T.RenameParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      match Httui_lang.Analyze.symbol_at blocks ~offset with
      (* positional [$prev] has no name to rewrite *)
      | Some { decl_range = Some (ds, de); ref_ranges; alias }
        when alias <> Httui_lang.Analyze.prev_name ->
          let edits =
            List.map
              (fun (s, e) ->
                T.TextEdit.create ~newText:p.newName
                  ~range:(range_of_offsets text ~start:s ~stop:e))
              ((ds, de) :: ref_ranges)
          in
          let edit =
            T.WorkspaceEdit.create ~changes:[ (p.textDocument.uri, edits) ] ()
          in
          respond r.id (T.WorkspaceEdit.yojson_of_t edit)
      | _ -> respond r.id `Null)

let shutdown_received = ref false

let handle_request (r : Jsonrpc.Request.t) =
  match r.method_ with
  | "initialize" -> on_initialize r
  | "textDocument/hover" -> on_hover r
  | "textDocument/completion" -> on_completion r
  | "textDocument/semanticTokens/full" -> on_semantic_tokens r
  | "textDocument/semanticTokens/full/delta" -> on_semantic_tokens_delta r
  | "textDocument/definition" -> on_definition r
  | "textDocument/references" -> on_references r
  | "textDocument/rename" -> on_rename r
  | "shutdown" ->
      shutdown_received := true;
      respond r.id `Null
  | m -> respond_error r.id Jsonrpc.Response.Error.Code.MethodNotFound m

let handle_notification (n : Jsonrpc.Notification.t) =
  match n.method_ with
  | "initialized" -> ()
  | "textDocument/didOpen" ->
      let p = T.DidOpenTextDocumentParams.t_of_yojson (params_json n.params) in
      doc_updated p.textDocument.uri p.textDocument.text
  | "textDocument/didChange" -> (
      let p =
        T.DidChangeTextDocumentParams.t_of_yojson (params_json n.params)
      in
      (* Full sync: the last change event carries the whole document. *)
      match List.rev p.contentChanges with
      | last :: _ -> doc_updated p.textDocument.uri last.text
      | [] -> ())
  | "textDocument/didClose" ->
      let p = T.DidCloseTextDocumentParams.t_of_yojson (params_json n.params) in
      Hashtbl.remove docs (T.DocumentUri.to_string p.textDocument.uri)
  | "exit" -> exit (if !shutdown_received then 0 else 1)
  (* custom: the client signals that a block ran, so inferred shapes may
     have changed — re-publish diagnostics for every open document *)
  | "httui/refresh" ->
      Hashtbl.iter (fun _ (uri, text) -> publish_diagnostics uri text) docs
  | _ -> ()

(* --- cancellation + main loop ------------------------------------------- *)

(* A dedicated reader thread parses incoming messages and enqueues them;
   [$/cancelRequest] ids are recorded as they arrive so the main loop can
   skip a stale request before doing its work. Processing stays
   single-threaded (only the main loop touches docs/stores/stdout), so
   the only shared state is the queue and the cancelled-id set. *)
let queue : Jsonrpc.Packet.t Queue.t = Queue.create ()
let queue_mutex = Mutex.create ()
let queue_cond = Condition.create ()
let eof = ref false
let cancelled : (Jsonrpc.Id.t, unit) Hashtbl.t = Hashtbl.create 16

let record_cancel id =
  Mutex.lock queue_mutex;
  (* cancels for already-completed requests would otherwise leak; the set
     is advisory, so dropping it wholesale past a cap is safe *)
  if Hashtbl.length cancelled > 256 then Hashtbl.clear cancelled;
  Hashtbl.replace cancelled id ();
  Mutex.unlock queue_mutex

let take_cancelled id =
  Mutex.lock queue_mutex;
  let c = Hashtbl.mem cancelled id in
  if c then Hashtbl.remove cancelled id;
  Mutex.unlock queue_mutex;
  c

let reader_thread () =
  (try
     while true do
       let body = read_message () in
       match
         try Some (Jsonrpc.Packet.t_of_yojson (Yojson.Safe.from_string body))
         with _ -> None
       with
       | Some (Jsonrpc.Packet.Notification n) when n.method_ = "$/cancelRequest"
         -> (
           match
             try Some (T.CancelParams.t_of_yojson (params_json n.params))
             with _ -> None
           with
           | Some cp -> record_cancel cp.id
           | None -> ())
       | Some pkt ->
           Mutex.lock queue_mutex;
           Queue.push pkt queue;
           Condition.signal queue_cond;
           Mutex.unlock queue_mutex
       | None -> ()
     done
   with End_of_file -> ());
  Mutex.lock queue_mutex;
  eof := true;
  Condition.signal queue_cond;
  Mutex.unlock queue_mutex

let next_packet () =
  Mutex.lock queue_mutex;
  while Queue.is_empty queue && not !eof do
    Condition.wait queue_cond queue_mutex
  done;
  let r = if Queue.is_empty queue then None else Some (Queue.pop queue) in
  Mutex.unlock queue_mutex;
  r

let () =
  Printexc.record_backtrace true;
  (* --db <path>: app database for environment variable NAMES (read-only
     enrichment; the server runs fine without it) *)
  (let rec parse = function
     | "--db" :: path :: rest ->
         Db_conn.configure path;
         parse rest
     | _ :: rest -> parse rest
     | [] -> ()
   in
   parse (Array.to_list Sys.argv));
  set_binary_mode_in stdin true;
  set_binary_mode_out stdout true;
  let _ : Thread.t = Thread.create reader_thread () in
  let rec loop () =
    match next_packet () with
    | None -> () (* stdin closed and queue drained *)
    | Some pkt ->
        (* one malformed handler must not kill the session *)
        (try
           match pkt with
           | Jsonrpc.Packet.Request r ->
               if take_cancelled r.id then
                 respond_error r.id Jsonrpc.Response.Error.Code.RequestCancelled
                   "request cancelled"
               else handle_request r
           | Jsonrpc.Packet.Notification n -> handle_notification n
           | _ -> ()
         with _ -> ());
        loop ()
  in
  (* Persist a crash file before dying so the desktop Crashes panel can
     surface a server panic — the sidecar's stderr is discarded. *)
  try loop ()
  with e ->
    let body =
      Printf.sprintf "%s\n\n%s" (Printexc.to_string e)
        (Printexc.get_backtrace ())
    in
    ignore (Httui_lang.Crash_log.write ~source:"lsp" ~body);
    raise e

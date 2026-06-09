(* httui-lsp — Language Server for httui blocks and references.

   Pure OCaml: an IO shell (stdio framing + JSON-RPC dispatch) around the
   pure [Httui_lang] library. Storage access, when it arrives, is
   read-only by design; the server never touches the OS keychain — secret
   values exist only on the execution path, outside this process. *)

let docs : (string, string) Hashtbl.t = Hashtbl.create 16

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
       (Jsonrpc.Response.error id (Jsonrpc.Response.Error.make ~code ~message ())))

(* --- handlers ----------------------------------------------------------- *)

let params_json (params : Jsonrpc.Structured.t option) =
  match params with
  | Some p -> Jsonrpc.Structured.yojson_of_t p
  | None -> `Null

let on_initialize (r : Jsonrpc.Request.t) =
  let capabilities =
    Lsp.Types.ServerCapabilities.create
      ~textDocumentSync:
        (`TextDocumentSyncOptions
          (Lsp.Types.TextDocumentSyncOptions.create ~openClose:true
             ~change:Lsp.Types.TextDocumentSyncKind.Full ()))
      ()
  in
  let serverInfo =
    Lsp.Types.InitializeResult.create_serverInfo ~name:"httui-lsp"
      ~version:Httui_lang.version ()
  in
  let result = Lsp.Types.InitializeResult.create ~capabilities ~serverInfo () in
  respond r.id (Lsp.Types.InitializeResult.yojson_of_t result)

let shutdown_received = ref false

let handle_request (r : Jsonrpc.Request.t) =
  match r.method_ with
  | "initialize" -> on_initialize r
  | "shutdown" ->
    shutdown_received := true;
    respond r.id `Null
  | m -> respond_error r.id Jsonrpc.Response.Error.Code.MethodNotFound m

let handle_notification (n : Jsonrpc.Notification.t) =
  match n.method_ with
  | "initialized" -> ()
  | "textDocument/didOpen" ->
    let p =
      Lsp.Types.DidOpenTextDocumentParams.t_of_yojson (params_json n.params)
    in
    Hashtbl.replace docs
      (Lsp.Types.DocumentUri.to_string p.textDocument.uri)
      p.textDocument.text
  | "textDocument/didChange" ->
    let p =
      Lsp.Types.DidChangeTextDocumentParams.t_of_yojson (params_json n.params)
    in
    (* Full sync: the last change event carries the whole document. *)
    (match List.rev p.contentChanges with
     | last :: _ ->
       Hashtbl.replace docs
         (Lsp.Types.DocumentUri.to_string p.textDocument.uri)
         last.text
     | [] -> ())
  | "textDocument/didClose" ->
    let p =
      Lsp.Types.DidCloseTextDocumentParams.t_of_yojson (params_json n.params)
    in
    Hashtbl.remove docs (Lsp.Types.DocumentUri.to_string p.textDocument.uri)
  | "exit" -> exit (if !shutdown_received then 0 else 1)
  | _ -> ()

(* --- main loop ---------------------------------------------------------- *)

let () =
  set_binary_mode_in stdin true;
  set_binary_mode_out stdout true;
  try
    while true do
      let body = read_message () in
      let json = Yojson.Safe.from_string body in
      match Jsonrpc.Packet.t_of_yojson json with
      | Jsonrpc.Packet.Request r -> handle_request r
      | Jsonrpc.Packet.Notification n -> handle_notification n
      | _ -> ()
    done
  with End_of_file -> ()

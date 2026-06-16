let failures = ref 0

let check name cond =
  if cond then Printf.printf "ok - %s\n" name
  else begin
    incr failures;
    Printf.printf "FAIL - %s\n" name
  end

let doc =
  String.concat "\n"
    [
      "# nota";
      "";
      "```http alias=req1";
      "GET https://api.example.com/users";
      "```";
      "";
      "```http alias=req2";
      "GET https://x.dev/{{ghost.id}}?u={{req1.body.id}}&t={{TOKEN}}";
      "```";
      "";
    ]

let blocks = Httui_lang.Fence_scanner.scan doc

let () =
  (* --- fence scanner --- *)
  check "scan finds two blocks" (List.length blocks = 2);
  let b1 = List.nth blocks 0 and b2 = List.nth blocks 1 in
  check "first block lang" (b1.Httui_lang.Block.lang = "http");
  check "first block alias" (b1.alias = Some "req1");
  check "first block open line" (b1.open_line = 2);
  check "first block content"
    (b1.content = "GET https://api.example.com/users\n");
  check "content offset points at content"
    (String.sub doc b1.content_offset 3 = "GET");
  check "second block alias" (b2.alias = Some "req2");
  check "executable detection http" (Httui_lang.Block.is_executable b1);
  check "executable detection db"
    (Httui_lang.Block.is_executable { b1 with lang = "db-postgres" });
  check "non-executable json"
    (not (Httui_lang.Block.is_executable { b1 with lang = "json" }));

  (* unclosed fence extends to EOF *)
  let unclosed = "```http alias=a\nGET /x\n" in
  let ub = Httui_lang.Fence_scanner.scan unclosed in
  check "unclosed fence yields block"
    (List.length ub = 1 && (List.hd ub).content = "GET /x\n");

  (* info string without alias *)
  let na = Httui_lang.Fence_scanner.scan "```http\nGET /\n```\n" in
  check "no alias parsed as None" ((List.hd na).alias = None);

  (* --- diagnostics --- *)
  let diags = Httui_lang.Analyze.diagnostics blocks in
  check "one diagnostic (ghost)" (List.length diags = 1);
  (match diags with
  | [ d ] ->
      check "diagnostic targets ghost"
        (String.sub doc d.start_ (d.stop_ - d.start_) = "ghost");
      check "diagnostic message mentions alias"
        (String.length d.message > 0 && String.sub d.message 0 7 = "Unknown")
  | _ -> check "diagnostic shape" false);

  (* env-style ref without path is never flagged *)
  let env_only = "```http alias=a\nGET /{{TOKEN}}\n```\n" in
  check "bare key not flagged"
    (Httui_lang.Analyze.diagnostics (Httui_lang.Fence_scanner.scan env_only)
    = []);

  (* forward reference is flagged (refs only see blocks above) *)
  let forward =
    "```http alias=a\nGET /{{b.body.id}}\n```\n\n```http alias=b\nGET /\n```\n"
  in
  check "forward ref flagged"
    (List.length
       (Httui_lang.Analyze.diagnostics (Httui_lang.Fence_scanner.scan forward))
    = 1);

  (* half-typed ref produces no diagnostics *)
  let half = "```http alias=a\nGET /{{x.\n```\n" in
  check "half-typed ref ignored"
    (Httui_lang.Analyze.diagnostics (Httui_lang.Fence_scanner.scan half) = []);

  (* refs inside non-executable fences are ignored *)
  let nonexec = "```json\n{\"x\": \"{{ghost.id}}\"}\n```\n" in
  check "non-executable block ignored"
    (Httui_lang.Analyze.diagnostics (Httui_lang.Fence_scanner.scan nonexec) = []);

  (* --- hover --- *)
  let ghost_off = b2.content_offset + 20 in
  (match Httui_lang.Analyze.hover_at blocks ~offset:ghost_off with
  | Some h ->
      check "hover on unknown alias"
        (String.length h.markdown > 0 && String.sub doc h.h_start 2 = "{{")
  | None -> check "hover on unknown alias" false);
  let req1_off = b2.content_offset + 35 in
  (match Httui_lang.Analyze.hover_at blocks ~offset:req1_off with
  | Some h ->
      check "hover on declared alias mentions line"
        (String.length h.markdown > 0
        &&
        let needle = "line 3" in
        let rec has i =
          i + String.length needle <= String.length h.markdown
          && (String.sub h.markdown i (String.length needle) = needle
             || has (i + 1))
        in
        has 0)
  | None -> check "hover on declared alias mentions line" false);
  check "hover outside refs is none"
    (Httui_lang.Analyze.hover_at blocks ~offset:b2.content_offset = None);

  (* --- completion --- *)
  let after_open = b2.content_offset + 35 in
  let labels items =
    List.map (fun (i : Httui_lang.Analyze.completion_item) -> i.label) items
  in
  check "completion offers scope aliases"
    (labels (Httui_lang.Analyze.completion_at doc blocks ~offset:after_open)
    = [ "req1" ]);
  check "completion outside braces empty"
    (Httui_lang.Analyze.completion_at doc blocks ~offset:(b2.content_offset + 4)
    = []);
  let with_env =
    Httui_lang.Analyze.completion_at
      ~env_keys:[ ("BASE_URL", false); ("API_TOKEN", true) ]
      doc blocks ~offset:after_open
  in
  check "completion appends env keys"
    (labels with_env = [ "req1"; "BASE_URL"; "API_TOKEN" ]);
  check "env completion carries secret flag"
    (List.exists
       (fun (i : Httui_lang.Analyze.completion_item) ->
         i.label = "API_TOKEN" && i.is_env && i.secret)
       with_env);

  (* hover on a bare key known to the active environment *)
  let env_doc = "```http alias=a\nGET /{{API_TOKEN}}\n```\n" in
  let env_blocks = Httui_lang.Fence_scanner.scan env_doc in
  (match
     Httui_lang.Analyze.hover_at
       ~env_keys:[ ("API_TOKEN", true) ]
       env_blocks ~offset:23
   with
  | Some h ->
      check "hover marks secret env var"
        (let needle = "secret" in
         let rec has i =
           i + String.length needle <= String.length h.markdown
           && (String.sub h.markdown i (String.length needle) = needle
              || has (i + 1))
         in
         has 0)
  | None -> check "hover marks secret env var" false);

  (* --- semantic tokens --- *)
  let toks = Httui_lang.Semantic_tokens.of_blocks blocks in
  (* per block: fence lang + [alias=] info + alias declaration + method;
     plus refs in req2: ghost (1 name + 1 segment) + req1 (1 name + 2
     segments) + TOKEN (1 name) *)
  check "token count" (List.length toks = 14);
  (* the `secret` modifier marks env-var refs whose key is is_secret *)
  check "secret env var ref carries the secret modifier"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Env_var && t.secret)
       (Httui_lang.Semantic_tokens.of_blocks
          ~env_keys:[ ("TOKEN", true) ]
          blocks));
  check "env var ref is not secret without the is_secret flag"
    (List.for_all
       (fun (t : Httui_lang.Semantic_tokens.t) -> not t.secret)
       (Httui_lang.Semantic_tokens.of_blocks
          ~env_keys:[ ("TOKEN", false) ]
          blocks));
  (match toks with
  | first :: _ ->
      check "first token is the fence lang"
        (first.kind = Httui_lang.Semantic_tokens.Fence_lang
        && String.sub doc first.t_start (first.t_stop - first.t_start) = "http"
        )
  | [] -> check "first token is the fence lang" false);
  check "fence info covers only the alias= prefix"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Fence_info
         && String.sub doc t.t_start (t.t_stop - t.t_start) = "alias=")
       toks);
  check "req1 declaration keeps its alias token"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.declaration
         && t.kind = Httui_lang.Semantic_tokens.Alias
         && String.sub doc t.t_start (t.t_stop - t.t_start) = "req1")
       toks);
  check "GET is a method token"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Http_method
         && String.sub doc t.t_start (t.t_stop - t.t_start) = "GET")
       toks);
  check "ghost name token is unresolved"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.unresolved
         && String.sub doc t.t_start (t.t_stop - t.t_start) = "ghost")
       toks);
  check "TOKEN is env var kind"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Env_var
         && String.sub doc t.t_start (t.t_stop - t.t_start) = "TOKEN")
       toks);
  check "tokens sorted by position"
    (let rec sorted = function
       | (a : Httui_lang.Semantic_tokens.t) :: (b :: _ as rest) ->
           a.t_start <= b.t_start && sorted rest
       | _ -> true
     in
     sorted toks);

  (* refs inside header values: HTTP tokens are carved around the ref so
     LSP tokens never overlap *)
  let hdr_doc =
    "```http alias=a\nGET /x\nAuthorization: Bearer {{TOKEN}}\n```\n"
  in
  let hdr_toks =
    Httui_lang.Semantic_tokens.of_blocks (Httui_lang.Fence_scanner.scan hdr_doc)
  in
  check "header tokens never overlap ref tokens"
    (let rec disjoint = function
       | (a : Httui_lang.Semantic_tokens.t) :: (b :: _ as rest) ->
           a.t_stop <= b.t_start && disjoint rest
       | _ -> true
     in
     disjoint hdr_toks);
  check "header name and carved value are emitted"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Http_header_name
         && String.sub hdr_doc t.t_start (t.t_stop - t.t_start)
            = "Authorization")
       hdr_toks
    && List.exists
         (fun (t : Httui_lang.Semantic_tokens.t) ->
           t.kind = Httui_lang.Semantic_tokens.Http_header_value)
         hdr_toks);

  (* db blocks only carry fence tokens, never http structure *)
  let db_doc = "```db-postgres alias=q1 limit=50\nSELECT 1\n```\n" in
  let db_toks =
    Httui_lang.Semantic_tokens.of_blocks (Httui_lang.Fence_scanner.scan db_doc)
  in
  check "db block emits fence tokens"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Fence_lang)
       db_toks
    && List.exists
         (fun (t : Httui_lang.Semantic_tokens.t) ->
           t.kind = Httui_lang.Semantic_tokens.Fence_info
           && String.sub db_doc t.t_start (t.t_stop - t.t_start) = "limit=50")
         db_toks);
  check "db block emits no http tokens"
    (not
       (List.exists
          (fun (t : Httui_lang.Semantic_tokens.t) ->
            match t.kind with
            | Httui_lang.Semantic_tokens.Http_method
            | Httui_lang.Semantic_tokens.Http_header_name
            | Httui_lang.Semantic_tokens.Http_header_value ->
                true
            | _ -> false)
          db_toks));

  (* a request line that does not parse yields no http tokens *)
  let broken = "```http alias=a\nget lowercase\n```\n" in
  check "broken request line yields no method token"
    (not
       (List.exists
          (fun (t : Httui_lang.Semantic_tokens.t) ->
            t.kind = Httui_lang.Semantic_tokens.Http_method)
          (Httui_lang.Semantic_tokens.of_blocks
             (Httui_lang.Fence_scanner.scan broken))));

  (* --- shapes: typed path resolution --- *)
  let module S = Httui_lang.Shape in
  let body =
    S.Object_
      [
        ("id", S.Scalar "number");
        ("name", S.Scalar "string");
        ("items", S.Array_ (Some (S.Object_ [ ("sku", S.Scalar "string") ])));
        ("empty", S.Array_ None);
      ]
  in
  let user_shape = S.Object_ [ ("body", body) ] in
  check "resolve scalar field"
    (S.resolve_ref ~response:user_shape ~db:false [ "response"; "body"; "id" ]
    = S.Found (S.Scalar "number"));
  check "envelope exposes status"
    (S.resolve_ref ~response:user_shape ~db:false [ "status" ]
    = S.Found (S.Scalar "string"));
  check "missing field reports level and candidates"
    (match
       S.resolve_ref ~response:user_shape ~db:false
         [ "response"; "body"; "nme" ]
     with
    | S.Missing { index = 2; segment = "nme"; available } ->
        List.mem "name" available
    | _ -> false);
  check "entering a scalar is not_object"
    (match
       S.resolve_ref ~response:user_shape ~db:false
         [ "response"; "body"; "id"; "x" ]
     with
    | S.Not_object { index = 3; parent = "number"; _ } -> true
    | _ -> false);
  check "arrays auto-descend into the sampled element"
    (S.resolve_ref ~response:user_shape ~db:false
       [ "response"; "body"; "items"; "sku" ]
    = S.Found (S.Scalar "string"));
  check "empty array sample is opaque"
    (S.resolve_ref ~response:user_shape ~db:false
       [ "response"; "body"; "empty"; "x" ]
    = S.Opaque);
  let db_shape =
    S.Object_
      [
        ( "results",
          S.Array_
            (Some
               (S.Object_
                  [
                    ( "rows",
                      S.Array_ (Some (S.Object_ [ ("id", S.Scalar "number") ]))
                    );
                  ])) );
      ]
  in
  check "db view accepts first-row column at response level"
    (S.resolve_ref ~response:db_shape ~db:true [ "response"; "id" ]
    = S.Found (S.Scalar "number"));
  check "without db view the column is missing"
    (match S.resolve_ref ~response:db_shape ~db:false [ "response"; "id" ] with
    | S.Missing _ -> true
    | _ -> false);
  check "fields at the ref root are the envelope"
    (S.fields_at ~response:user_shape ~db:false []
    = Some [ ("response", user_shape); ("status", S.Scalar "string") ]);
  check "fields after a path are the object keys"
    (match
       S.fields_at ~response:user_shape ~db:false [ "response"; "body" ]
     with
    | Some fields -> List.map fst fields = [ "id"; "name"; "items"; "empty" ]
    | None -> false);
  check "type_name flattens arrays"
    (S.type_name (S.Array_ (Some (S.Scalar "string"))) = "array<string>");
  check "suggest tolerates one edit on short names"
    (S.suggest "nme" [ "name"; "items" ] = Some "name");
  check "suggest rejects distant candidates"
    (S.suggest "zz" [ "id"; "name" ] = None);

  (* --- analyze with shapes --- *)
  let typed_doc =
    String.concat "\n"
      [
        "```http alias=req1";
        "GET /u";
        "```";
        "";
        "```http alias=req2";
        "GET /x?a={{req1.response.body.id}}&b={{req1.response.body.nme}}";
        "```";
        "";
      ]
  in
  let typed_blocks = Httui_lang.Fence_scanner.scan typed_doc in
  let shapes = [ ("req1", user_shape) ] in
  let find_sub needle =
    let n = String.length needle in
    let rec go i =
      if i + n > String.length typed_doc then failwith ("not found: " ^ needle)
      else if String.sub typed_doc i n = needle then i
      else go (i + 1)
    in
    go 0
  in
  check "no shapes, no field diagnostics"
    (Httui_lang.Analyze.diagnostics typed_blocks = []);
  (match Httui_lang.Analyze.diagnostics ~shapes typed_blocks with
  | [ d ] ->
      check "typo squiggle targets the bad segment"
        (String.sub typed_doc d.start_ (d.stop_ - d.start_) = "nme"
        && d.severity = Httui_lang.Analyze.Warning);
      check "typo message suggests the close field"
        (let needle = "did you mean 'name'?" in
         let rec has i =
           i + String.length needle <= String.length d.message
           && (String.sub d.message i (String.length needle) = needle
              || has (i + 1))
         in
         has 0)
  | l ->
      check "typo squiggle targets the bad segment" false;
      check "typo message suggests the close field" (List.length l = -1));
  let hover_md off =
    match Httui_lang.Analyze.hover_at ~shapes typed_blocks ~offset:off with
    | Some h -> h.markdown
    | None -> ""
  in
  let has_sub hay needle =
    let n = String.length needle in
    let rec go i =
      i + n <= String.length hay && (String.sub hay i n = needle || go (i + 1))
    in
    go 0
  in
  check "hover on a leaf segment shows its type"
    (has_sub (hover_md (find_sub "id}}&b")) "`number`");
  check "hover on an object segment lists fields"
    (let md = hover_md (find_sub "body.id") in
     has_sub md "object" && has_sub md "`name`: string");
  check "hover on a typo says not found with hint"
    (let md = hover_md (find_sub "nme") in
     has_sub md "not found" && has_sub md "did you mean 'name'?");
  let compl_doc =
    "```http alias=req1\n\
     GET /u\n\
     ```\n\n\
     ```http alias=req2\n\
     GET /x?a={{req1.response.body.\n\
     ```\n"
  in
  let compl_blocks = Httui_lang.Fence_scanner.scan compl_doc in
  let dot =
    let rec go i =
      if String.sub compl_doc i 14 = "response.body." then i + 14 else go (i + 1)
    in
    go 0
  in
  check "path completion offers the shape's fields with types"
    (Httui_lang.Analyze.completion_at ~shapes compl_doc compl_blocks ~offset:dot
    |> List.map (fun (i : Httui_lang.Analyze.completion_item) ->
        (i.label, i.field_type))
    = [
        ("id", Some "number");
        ("name", Some "string");
        ("items", Some "array<object>");
        ("empty", Some "array");
      ]);
  check "path completion without a shape is empty"
    (Httui_lang.Analyze.completion_at compl_doc compl_blocks ~offset:dot = []);

  (* --- $prev and numeric segments --- *)
  check "numeric segment consumes one array level"
    (S.resolve_ref ~response:user_shape ~db:false
       [ "response"; "body"; "items"; "0"; "sku" ]
    = S.Found (S.Scalar "string"));
  check "numeric segment into a scalar is not_object"
    (match
       S.resolve_ref ~response:user_shape ~db:false
         [ "response"; "body"; "id"; "0" ]
     with
    | S.Not_object _ -> true
    | _ -> false);
  check "prev resolution roots at the response, no envelope"
    (S.resolve_prev ~response:user_shape ~db:false [ "body"; "id" ]
    = S.Found (S.Scalar "number"));
  check "prev resolution arms the db view at the root"
    (S.resolve_prev ~response:db_shape ~db:true [ "id" ]
    = S.Found (S.Scalar "number"));
  let prev_doc =
    String.concat "\n"
      [
        "```http alias=req1";
        "GET /u";
        "```";
        "";
        "```http alias=req2";
        "GET /x?a={{$prev.body.id}}&b={{$prev.body.nme}}";
        "```";
        "";
      ]
  in
  let prev_blocks = Httui_lang.Fence_scanner.scan prev_doc in
  let find_in haystack needle =
    let n = String.length needle in
    let rec go i =
      if i + n > String.length haystack then failwith ("not found: " ^ needle)
      else if String.sub haystack i n = needle then i
      else go (i + 1)
    in
    go 0
  in
  check "prev ref parses with its segments"
    (match Httui_lang.Refs.of_block (List.nth prev_blocks 1) with
    | [ a; b ] ->
        a.name = "$prev" && b.name = "$prev" && List.length a.path_segments = 2
    | _ -> false);
  (match Httui_lang.Analyze.diagnostics ~shapes prev_blocks with
  | [ d ] ->
      check "prev typo squiggle targets the bad segment"
        (String.sub prev_doc d.start_ (d.stop_ - d.start_) = "nme"
        && d.severity = Httui_lang.Analyze.Warning)
  | l -> check "prev typo squiggle targets the bad segment" (List.length l = -1));
  check "prev without a block above is an error"
    (match
       Httui_lang.Analyze.diagnostics
         (Httui_lang.Fence_scanner.scan
            "```http alias=a\nGET /{{$prev.body}}\n```\n")
     with
    | [ d ] -> d.severity = Httui_lang.Analyze.Error
    | _ -> false);
  check "prev hover on a leaf segment shows its type"
    (match
       Httui_lang.Analyze.hover_at ~shapes prev_blocks
         ~offset:(find_in prev_doc "id}}&b")
     with
    | Some h -> has_sub h.markdown "`number`"
    | None -> false);
  check "prev hover on the name shows the previous block"
    (match
       Httui_lang.Analyze.hover_at ~shapes prev_blocks
         ~offset:(find_in prev_doc "$prev.body.id" + 1)
     with
    | Some h -> has_sub h.markdown "previous block" && has_sub h.markdown "req1"
    | None -> false);
  let prev_compl_doc =
    "```http alias=req1\n\
     GET /u\n\
     ```\n\n\
     ```http alias=req2\n\
     GET /x?a={{$prev.body.\n\
     ```\n"
  in
  let prev_compl_blocks = Httui_lang.Fence_scanner.scan prev_compl_doc in
  let prev_dot = find_in prev_compl_doc "$prev.body." + 11 in
  check "prev path completion offers the response fields"
    (Httui_lang.Analyze.completion_at ~shapes prev_compl_doc prev_compl_blocks
       ~offset:prev_dot
    |> List.map (fun (it : Httui_lang.Analyze.completion_item) -> it.label)
    = [ "id"; "name"; "items"; "empty" ]);
  check "prev is not offered in the alias list"
    (Httui_lang.Analyze.completion_at ~shapes prev_compl_doc prev_compl_blocks
       ~offset:(find_in prev_compl_doc "{{$prev" + 2)
    |> List.for_all (fun (it : Httui_lang.Analyze.completion_item) ->
        it.label <> "$prev"));
  check "prev name paints as an alias token"
    (List.exists
       (fun (t : Httui_lang.Semantic_tokens.t) ->
         t.kind = Httui_lang.Semantic_tokens.Alias
         && String.sub prev_doc t.t_start (t.t_stop - t.t_start) = "$prev")
       (Httui_lang.Semantic_tokens.of_blocks prev_blocks));

  (* --- value previews --- *)
  let module V = Httui_lang.Json_value in
  let resp_v =
    V.Object_
      [
        ( "body",
          V.Object_
            [
              ("id", V.Number "7");
              ("tags", V.Array_ [ V.String "a"; V.String "b" ]);
            ] );
      ]
  in
  check "value at a path"
    (V.resolve_ref ~response:resp_v ~status:"success" ~db:false
       [ "response"; "body"; "id" ]
    = Some (V.Number "7"));
  check "value of status"
    (V.resolve_ref ~response:resp_v ~status:"success" ~db:false [ "status" ]
    = Some (V.String "success"));
  check "value numeric segment indexes the real array"
    (V.resolve_ref ~response:resp_v ~status:"s" ~db:false
       [ "response"; "body"; "tags"; "1" ]
    = Some (V.String "b"));
  check "value navigation is strict"
    (V.resolve_ref ~response:resp_v ~status:"s" ~db:false
       [ "response"; "body"; "tags"; "x" ]
    = None);
  check "preview truncates long values"
    ( V.preview ~max_len:10 (V.String "0123456789012345xyz") |> fun s ->
      String.length s <= 16 && has_sub s "\xe2\x80\xa6" );
  check "db view value reads the first-row column"
    (V.resolve_prev
       ~response:
         (V.Object_
            [
              ( "results",
                V.Array_
                  [
                    V.Object_
                      [
                        ("rows", V.Array_ [ V.Object_ [ ("id", V.Number "1") ] ]);
                      ];
                  ] );
            ])
       ~db:true [ "id" ]
    = Some (V.Number "1"));
  check "db view shape accepts the numeric results shortcut"
    (S.resolve_ref ~response:db_shape ~db:true
       [ "response"; "0"; "rows"; "0"; "id" ]
    = S.Found (S.Scalar "number"));
  let vals = [ ("req1", (resp_v, "success")) ] in
  check "hover appends the last value"
    (match
       Httui_lang.Analyze.hover_at ~shapes ~values:vals typed_blocks
         ~offset:(find_sub "id}}&b")
     with
    | Some h -> has_sub h.markdown "last value: `7`"
    | None -> false);
  check "hover on the alias name shows the full-path value"
    (match
       Httui_lang.Analyze.hover_at ~shapes ~values:vals typed_blocks
         ~offset:(find_sub "req1.response.body.id")
     with
    | Some h -> has_sub h.markdown "last value: `7`"
    | None -> false);

  (* --- positions (UTF-16 with multibyte) --- *)
  let mdoc = "caf\xc3\xa9 {{x}}\n" in
  let p = Httui_lang.Doc_position.of_offset mdoc 5 in
  check "utf16 column after multibyte" (p.line = 0 && p.character = 4);
  check "offset/position roundtrip"
    (Httui_lang.Doc_position.to_offset mdoc p = 5);

  (* --- crash log --- *)
  let crash_dir =
    Filename.concat (Filename.get_temp_dir_name ()) "httui_crash_test"
  in
  (try Sys.rmdir crash_dir with _ -> ());
  let name =
    Httui_lang.Crash_log.write_to ~dir:crash_dir ~source:"lsp" ~body:"boom\nbt"
  in
  check "crash write returns a name"
    (match name with
    | Some n -> Filename.check_suffix n "-lsp.log"
    | None -> false);
  check "crash file holds the body"
    (match name with
    | Some n ->
        let ic = open_in_bin (Filename.concat crash_dir n) in
        let len = in_channel_length ic in
        let s = really_input_string ic len in
        close_in ic;
        s = "boom\nbt"
    | None -> false);
  check "crash source is sanitized of separators"
    (match
       Httui_lang.Crash_log.write_to ~dir:crash_dir ~source:"a/b" ~body:"x"
     with
    | Some n -> Filename.check_suffix n "-a_b.log"
    | None -> false);

  if !failures > 0 then exit 1

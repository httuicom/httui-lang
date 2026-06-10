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
  (* 2 alias declarations + ghost (1 name + 1 segment)
     + req1 ref (1 name + 2 segments) + TOKEN (1 name) *)
  check "token count" (List.length toks = 8);
  (match toks with
  | first :: _ ->
      check "first token is req1 declaration"
        (first.declaration
        && first.kind = Httui_lang.Semantic_tokens.Alias
        && String.sub doc first.t_start (first.t_stop - first.t_start) = "req1"
        )
  | [] -> check "first token is req1 declaration" false);
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

  (* --- positions (UTF-16 with multibyte) --- *)
  let mdoc = "caf\xc3\xa9 {{x}}\n" in
  let p = Httui_lang.Doc_position.of_offset mdoc 5 in
  check "utf16 column after multibyte" (p.line = 0 && p.character = 4);
  check "offset/position roundtrip"
    (Httui_lang.Doc_position.to_offset mdoc p = 5);

  if !failures > 0 then exit 1

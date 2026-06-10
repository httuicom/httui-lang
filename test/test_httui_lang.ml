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
  check "completion offers scope aliases"
    (Httui_lang.Analyze.completion_at doc blocks ~offset:after_open = [ "req1" ]);
  check "completion outside braces empty"
    (Httui_lang.Analyze.completion_at doc blocks ~offset:(b2.content_offset + 4)
    = []);

  (* --- positions (UTF-16 with multibyte) --- *)
  let mdoc = "caf\xc3\xa9 {{x}}\n" in
  let p = Httui_lang.Doc_position.of_offset mdoc 5 in
  check "utf16 column after multibyte" (p.line = 0 && p.character = 4);
  check "offset/position roundtrip"
    (Httui_lang.Doc_position.to_offset mdoc p = 5);

  if !failures > 0 then exit 1

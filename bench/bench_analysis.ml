(* In-process analysis benchmark: measures the pure-OCaml analysis path
   (no stdio, no JSON) over the canonical fixtures, so the numbers are
   the algorithm cost alone — the transport floor lives in
   lsp_roundtrip.py.

   Run via [make bench] or:
     dune exec bench/bench_analysis.exe -- [fixtures-dir]
   (default fixtures-dir: bench/fixtures)

   Reports p50/p95/p99 per operation per fixture. ADR-010 budgets:
   retoken viewport <16ms p95, diagnostics publish <100ms p95. *)

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let now () = Unix.gettimeofday ()

let percentile sorted p =
  let n = Array.length sorted in
  sorted.(int_of_float (Float.round (float_of_int (n - 1) *. p)))

let report name samples =
  Array.sort compare samples;
  let ms x = x *. 1e3 in
  Printf.printf "%-40s n=%5d  p50=%.4fms  p95=%.4fms  p99=%.4fms  max=%.4fms\n"
    name (Array.length samples)
    (ms (percentile samples 0.50))
    (ms (percentile samples 0.95))
    (ms (percentile samples 0.99))
    (ms samples.(Array.length samples - 1))

(* Time [f ()] [iters] times after [warmup] discarded runs. [f] returns a
   value we keep via [Sys.opaque_identity] so the optimizer cannot hoist
   the work out of the loop. *)
let bench ?(warmup = 50) ?(iters = 1000) f =
  for _ = 1 to warmup do
    ignore (Sys.opaque_identity (f ()))
  done;
  let samples = Array.make iters 0.0 in
  for i = 0 to iters - 1 do
    let t = now () in
    ignore (Sys.opaque_identity (f ()));
    samples.(i) <- now () -. t
  done;
  samples

(* Offset just past the first [{{] in the doc — a realistic completion
   trigger point. Falls back to 0 if the doc has no refs. *)
let first_ref_open doc =
  match Str.search_forward (Str.regexp_string "{{") doc 0 with
  | i -> i + 2
  | exception Not_found -> 0

(* Offset inside the first ref name — a realistic hover point. *)
let first_ref_name doc = first_ref_open doc

let run_fixture path =
  let doc = read_file path in
  Printf.printf "\n# %s (%d bytes, %d lines)\n" (Filename.basename path)
    (String.length doc)
    (String.fold_left (fun n c -> if c = '\n' then n + 1 else n) 0 doc);
  let blocks = Httui_lang.Fence_scanner.scan doc in
  let comp_off = first_ref_open doc in
  let hover_off = first_ref_name doc in
  report "Fence_scanner.scan"
    (bench (fun () -> Httui_lang.Fence_scanner.scan doc));
  report "Analyze.diagnostics"
    (bench (fun () -> Httui_lang.Analyze.diagnostics blocks));
  report "Semantic_tokens.of_blocks"
    (bench (fun () -> Httui_lang.Semantic_tokens.of_blocks blocks));
  report "Analyze.completion_at"
    (bench (fun () ->
         Httui_lang.Analyze.completion_at doc blocks ~offset:comp_off));
  report "Analyze.hover_at"
    (bench (fun () -> Httui_lang.Analyze.hover_at blocks ~offset:hover_off));
  (* didChange cost = scan + diagnostics (what publish_diagnostics does). *)
  report "didChange (scan + diagnostics)"
    (bench (fun () ->
         let b = Httui_lang.Fence_scanner.scan doc in
         Httui_lang.Analyze.diagnostics b))

let () =
  let dir =
    if Array.length Sys.argv > 1 then Sys.argv.(1) else "bench/fixtures"
  in
  List.iter
    (fun f ->
      let path = Filename.concat dir f in
      if Sys.file_exists path then run_fixture path
      else Printf.eprintf "missing fixture: %s\n" path)
    [ "medium.md"; "large.md" ]

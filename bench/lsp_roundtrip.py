#!/usr/bin/env python3
"""LSP transport benchmark: spawn-to-initialize and request round-trip.

Measures the httui-lsp binary over its real transport (stdio, LSP framing)
with no external dependencies. This is the harness baseline — as server
features land (hover, completion, semantic tokens), each gets a section
here and budgets gate CI.

Usage:
  python3 bench/lsp_roundtrip.py [path-to-httui-lsp]
  (default: _build/default/bin/httui-lsp/httui_lsp.exe)
"""

import json
import statistics
import subprocess
import sys
import time
from pathlib import Path

DEFAULT_SERVER = "_build/default/bin/httui-lsp/httui_lsp.exe"
WARMUP = 200
ITERATIONS = 5000


class LspClient:
    def __init__(self, server_path):
        self.proc = subprocess.Popen(
            [server_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )
        self.next_id = 1

    def send(self, payload):
        body = json.dumps(payload).encode()
        frame = b"Content-Length: %d\r\n\r\n" % len(body) + body
        self.proc.stdin.write(frame)
        self.proc.stdin.flush()

    def recv(self):
        length = None
        while True:
            line = self.proc.stdout.readline().strip()
            if not line:
                break
            key, _, value = line.partition(b":")
            if key.lower() == b"content-length":
                length = int(value)
        if length is None:
            raise RuntimeError("missing content-length in server response")
        return json.loads(self.proc.stdout.read(length))

    def request(self, method, params=None):
        rid = self.next_id
        self.next_id += 1
        payload = {"jsonrpc": "2.0", "id": rid, "method": method}
        if params is not None:
            payload["params"] = params
        self.send(payload)
        # Skip any server-initiated notifications (e.g. publishDiagnostics
        # emitted after a didOpen/didChange) queued ahead of our response.
        while True:
            msg = self.recv()
            if msg.get("id") == rid:
                return msg

    def notify(self, method, params=None):
        payload = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            payload["params"] = params
        self.send(payload)

    def recv_until_method(self, method):
        """Drain messages until a notification with `method` arrives,
        returning it. Used to time edit -> server notification cycles."""
        while True:
            msg = self.recv()
            if msg.get("method") == method:
                return msg


# p95 by operation name, filled by report(); used by the CI budget gate.
RESULTS = {}

# ADR-010 "Hard fail" thresholds (the generous column, not the tight p95
# targets) — shared CI runners are too noisy to gate on the p95 budgets,
# but a hard-fail breach is a real regression on any machine.
HARD_FAIL_MS = {
    "didChange->diagnostics": 300.0,
    "semanticTokens/full": 200.0,
}


def percentile(sorted_values, p):
    return sorted_values[round((len(sorted_values) - 1) * p)]


def report(name, samples_ms):
    samples_ms.sort()
    RESULTS[name] = percentile(samples_ms, 0.95)
    print(
        f"{name:40s} n={len(samples_ms):>5}  "
        f"p50={percentile(samples_ms, 0.50):.4f}ms  "
        f"p95={percentile(samples_ms, 0.95):.4f}ms  "
        f"p99={percentile(samples_ms, 0.99):.4f}ms  "
        f"max={samples_ms[-1]:.4f}ms"
    )


def check_budgets():
    """Exit non-zero if any operation breached its ADR-010 hard-fail
    budget. Matches by name prefix so fixture suffixes are ignored."""
    breaches = []
    for name, p95 in RESULTS.items():
        for prefix, limit in HARD_FAIL_MS.items():
            if name.startswith(prefix) and p95 > limit:
                breaches.append(f"  {name}: p95 {p95:.1f}ms > hard-fail {limit:.0f}ms")
    if breaches:
        print("\nBUDGET BREACH (ADR-010 hard-fail):")
        print("\n".join(breaches))
        sys.exit(1)
    print("\nbudgets OK (within ADR-010 hard-fail thresholds)")


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv
    server = args[0] if args else DEFAULT_SERVER
    if not Path(server).exists():
        sys.exit(f"server binary not found: {server} (run `dune build` first)")

    t0 = time.perf_counter()
    client = LspClient(server)
    init = client.request(
        "initialize",
        {"processId": None, "rootUri": None, "capabilities": {}},
    )
    spawn_ms = (time.perf_counter() - t0) * 1e3
    name = init["result"]["serverInfo"]["name"]
    print(f"server: {name}  spawn -> initialize: {spawn_ms:.3f} ms")
    client.notify("initialized", {})

    doc = "# bench\n\n```http alias=req1\nGET https://api.example.com\n```\n" * 30
    client.notify(
        "textDocument/didOpen",
        {
            "textDocument": {
                "uri": "file:///tmp/bench.md",
                "languageId": "markdown",
                "version": 1,
                "text": doc,
            }
        },
    )

    # Round-trip floor: an unknown method still exercises framing, JSON
    # parse and dispatch on both sides (server answers MethodNotFound).
    def probe():
        client.request("httui/benchProbe")

    for _ in range(WARMUP):
        probe()
    samples = []
    for _ in range(ITERATIONS):
        t = time.perf_counter()
        probe()
        samples.append((time.perf_counter() - t) * 1e3)
    report("request round-trip (dispatch)", samples)

    # Fixture-based E2E: the canonical ADR-010 fixtures over the real
    # transport. This captures what the in-process bench (bench_analysis.ml)
    # cannot: stdio framing + JSON encode/decode of a large payload on top
    # of the server's analysis. The gap between the two benches IS the
    # transport cost.
    fixtures = Path(__file__).parent / "fixtures"
    for fixture in ("medium.md", "large.md"):
        path = fixtures / fixture
        if not path.exists():
            print(f"  (skip {fixture}: run bench/gen_fixtures.py first)")
            continue
        text = path.read_text()
        uri = f"file:///tmp/{fixture}"
        client.notify(
            "textDocument/didOpen",
            {"textDocument": {"uri": uri, "languageId": "markdown",
                              "version": 1, "text": text}},
        )
        client.recv_until_method("textDocument/publishDiagnostics")

        # Edit-to-diagnostics: full-sync re-send, then read until the
        # server republishes diagnostics — exactly ADR-010's "diagnostic
        # publish after edit" budget (<100ms p95).
        version = 2
        samples = []
        for _ in range(300):
            t = time.perf_counter()
            client.notify(
                "textDocument/didChange",
                {"textDocument": {"uri": uri, "version": version},
                 "contentChanges": [{"text": text}]},
            )
            client.recv_until_method("textDocument/publishDiagnostics")
            samples.append((time.perf_counter() - t) * 1e3)
            version += 1
        report(f"didChange->diagnostics [{fixture} {len(text)//1024}KB]", samples)

        # semanticTokens/full request latency on the fixture.
        samples = []
        for _ in range(300):
            t = time.perf_counter()
            client.request("textDocument/semanticTokens/full",
                           {"textDocument": {"uri": uri}})
            samples.append((time.perf_counter() - t) * 1e3)
        report(f"semanticTokens/full [{fixture}]", samples)

    client.request("shutdown")
    client.notify("exit")
    client.proc.wait(timeout=5)

    if check:
        check_budgets()


if __name__ == "__main__":
    main()

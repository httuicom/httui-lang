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
        return self.recv()

    def notify(self, method, params=None):
        payload = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            payload["params"] = params
        self.send(payload)


def percentile(sorted_values, p):
    return sorted_values[round((len(sorted_values) - 1) * p)]


def report(name, samples_ms):
    samples_ms.sort()
    print(
        f"{name:32s} n={len(samples_ms):>5}  "
        f"p50={percentile(samples_ms, 0.50):.4f}ms  "
        f"p95={percentile(samples_ms, 0.95):.4f}ms  "
        f"p99={percentile(samples_ms, 0.99):.4f}ms  "
        f"max={samples_ms[-1]:.4f}ms"
    )


def main():
    server = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SERVER
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

    # didChange ingestion: full-sync document replace per notification,
    # measured via a probe request behind each batch (notifications have
    # no response of their own).
    version = 2
    samples = []
    for _ in range(1000):
        t = time.perf_counter()
        client.notify(
            "textDocument/didChange",
            {
                "textDocument": {"uri": "file:///tmp/bench.md", "version": version},
                "contentChanges": [{"text": doc}],
            },
        )
        probe()
        samples.append((time.perf_counter() - t) * 1e3)
        version += 1
    report("didChange(2KB doc) + probe", samples)

    client.request("shutdown")
    client.notify("exit")
    client.proc.wait(timeout=5)


if __name__ == "__main__":
    main()

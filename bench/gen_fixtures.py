#!/usr/bin/env python3
"""Generate the canonical benchmark fixtures (ADR-010).

Deterministic — no randomness with a free seed, no timestamps — so the
output is reproducible and diffable. Re-run to regenerate:

    python3 bench/gen_fixtures.py

Produces:
  bench/fixtures/medium.md  — ~500 lines, 10 blocks (5 HTTP + 5 SQL), ~20 refs
  bench/fixtures/large.md   — ~5000 lines, 50 blocks (mixed), ~200 refs

Refs only point at blocks declared above (DAG by construction), so they
exercise real scope resolution rather than dangling lookups.
"""

from pathlib import Path

FIXTURES = Path(__file__).parent / "fixtures"

# A short rota of prose lines, cycled deterministically to pad the doc to
# the target length between blocks. Realistic markdown: headings, lists,
# paragraphs.
PROSE = [
    "",
    "Some explanatory prose about the request below and what it returns.",
    "",
    "- a bullet point describing a field",
    "- another bullet describing an edge case",
    "",
    "## Section heading",
    "",
    "A longer paragraph that talks through the data flow between blocks "
    "and why the reference chain matters for the downstream query.",
    "",
    "> A blockquote with a caveat about pagination.",
    "",
]


def http_block(n, refs):
    """An HTTP block aliased req{n}. `refs` are (alias, field) pairs to
    earlier blocks, woven into header values and the query."""
    lines = [f"```http alias=req{n} timeout=30000"]
    if refs:
        a, f = refs[0]
        lines.append(f"GET https://api.example.com/items?parent={{{{{a}.response.body.{f}}}}}")
    else:
        lines.append("GET https://api.example.com/items?page=1")
    lines.append("Authorization: Bearer {{TOKEN}}")
    if len(refs) > 1:
        a, f = refs[1]
        lines.append(f"X-Parent-Id: {{{{{a}.response.body.{f}}}}}")
    lines.append("Content-Type: application/json")
    lines.append("")
    if len(refs) > 2:
        a, f = refs[2]
        lines.append('{"ref": "{{%s.response.body.%s}}", "page": 1}' % (a, f))
    else:
        lines.append('{"page": 1}')
    lines.append("```")
    return lines


def db_block(n, refs):
    """A db-postgres block aliased q{n}, referencing earlier blocks in the
    WHERE clause (converted to bind params by the runtime, but the refs
    still parse + resolve here)."""
    lines = [f"```db-postgres alias=q{n}"]
    if refs:
        conds = " AND ".join(
            f"{f} = {{{{{a}.response.body.{f}}}}}" for a, f in refs
        )
        lines.append(f"SELECT id, name, created_at FROM items WHERE {conds}")
    else:
        lines.append("SELECT id, name, created_at FROM items LIMIT 100")
    lines.append("```")
    return lines


FIELDS = ["id", "name", "parent_id", "owner_id", "status"]


def gen(n_blocks, target_lines):
    """Build a doc with n_blocks executable blocks (alternating HTTP/SQL),
    each referencing up to 3 earlier blocks, padded with prose to roughly
    target_lines."""
    out = ["# Benchmark fixture", ""]
    aliases = []  # (kind, n) declared so far, for upward refs
    prose_i = 0
    for b in range(n_blocks):
        is_http = b % 2 == 0
        n = b + 1
        # Pick up to 3 earlier aliases (closest-first) to reference.
        refs = []
        for prev_kind, prev_n in reversed(aliases):
            alias = f"req{prev_n}" if prev_kind == "http" else f"q{prev_n}"
            field = FIELDS[(prev_n + len(refs)) % len(FIELDS)]
            refs.append((alias, field))
            if len(refs) == 4:
                break
        out.append(f"### Block {n}")
        out.append("")
        if is_http:
            out += http_block(n, refs)
            aliases.append(("http", n))
        else:
            out += db_block(n, refs)
            aliases.append(("db", n))
        out.append("")
        # Pad with prose until we have spent our per-block line budget.
        per_block = target_lines // n_blocks
        pad = max(0, per_block - 12)
        for _ in range(pad):
            out.append(PROSE[prose_i % len(PROSE)])
            prose_i += 1
    return "\n".join(out) + "\n"


def main():
    FIXTURES.mkdir(parents=True, exist_ok=True)
    medium = gen(n_blocks=10, target_lines=500)
    large = gen(n_blocks=50, target_lines=5400)
    (FIXTURES / "medium.md").write_text(medium)
    (FIXTURES / "large.md").write_text(large)
    for name, text in (("medium", medium), ("large", large)):
        n_lines = text.count("\n")
        n_blocks = text.count("```http") + text.count("```db-")
        n_refs = text.count("{{") - text.count("{{TOKEN}}")
        print(f"{name}.md: {n_lines} lines, {n_blocks} blocks, ~{n_refs} refs")


if __name__ == "__main__":
    main()

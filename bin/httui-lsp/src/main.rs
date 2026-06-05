// LSP server for httui.
//
// This binary wraps the OCaml language layer (in ../lib) via FFI and
// depends on httui-core for SQLite, keychain, and vault operations. The
// implementation is bootstrapped from the existing httui-mcp template
// (argument parsing, db pool, executor registry) and gains LSP-specific
// request handling on top.

fn main() {
    eprintln!(
        "httui-lsp v{} — not yet implemented",
        env!("CARGO_PKG_VERSION")
    );
    std::process::exit(1);
}

# Security Policy

## Supported Versions

This project is in active early development. Only the latest commit on
`main` is supported. Once tagged releases begin, this section will list
the supported version range.

| Version | Supported |
|---|---|
| `main` (latest) | yes |
| any other | no |

## Reporting an Issue

Please do not report sensitive issues through public GitHub issues.

Use one of the following private channels:

- **GitHub Security Advisories** (preferred): open a draft advisory at
  <https://github.com/httuicom/httui-lang/security/advisories/new>
- **Email**: send details to `security@httui.com`

Please include a description of the issue, steps to reproduce, and the
affected component.

## Response Timeline

- New reports acknowledged within **3 business days**
- Preliminary assessment shared within **10 business days**
- Fixes released as soon as they have been validated; coordinated
  disclosure is the default unless the reporter requests otherwise

## Scope

In scope: issues in code maintained by this repository (OCaml lib,
tree-sitter and Lezer grammars, LSP server binary, FFI bindings).

Out of scope:

- Issues affecting unsupported branches or forks
- Issues in upstream dependencies that have an active fix tracked
  by the upstream maintainers

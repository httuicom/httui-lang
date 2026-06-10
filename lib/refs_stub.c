#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

const void *tree_sitter_httui_refs(void);

CAMLprim value caml_tree_sitter_httui_refs_language(value unit) {
  CAMLparam1(unit);
  CAMLreturn(caml_copy_nativeint((intnat)tree_sitter_httui_refs()));
}

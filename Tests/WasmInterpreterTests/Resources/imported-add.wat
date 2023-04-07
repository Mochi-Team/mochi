(module
  (import "imports" "imported_add_func" (func $imported_add_func (param $rhs i32) (param $lhs i64) (result i32)))
  (func (export "integer_provider_func") (result i32)
    i32.const -3333
    i64.const 42
    (call $imported_add_func)))

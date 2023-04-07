(module
  (type (;0;) (func (param i64) (result i64)))
  (func (;0;) (type 0) (param i64) (result i64)
    local.get 0
    i64.const 2
    i64.lt_u
    if  ;; label = @1
      local.get 0
      return
    end
    local.get 0
    i64.const 2
    i64.sub
    call 0
    local.get 0
    i64.const 1
    i64.sub
    call 0
    i64.add
    return)
  (export "fib" (func 0)))

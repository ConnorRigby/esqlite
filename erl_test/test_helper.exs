:code.ensure_loaded(:esqlite_test)
case :esqlite_test.test() do
  :error -> System.halt(1)
  other -> other
end

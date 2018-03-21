{:module, Esqlite3Nif} = :code.ensure_loaded(Esqlite3Nif)
{:module, mod} = :code.ensure_loaded(:esqlite_test)
:eunit.test({:inparallel, mod})
ExUnit.start()

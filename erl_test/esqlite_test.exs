defmodule EsqliteErlangTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @tag :esqlite_erlang
  test "Runs Erlang tests" do
    assert Code.ensure_loaded?(:esqlite_test)
    output = capture_io(&:esqlite_test.test/0)
    unless output =~ "tests pass" do
      flunk(output)
    end
  end
end

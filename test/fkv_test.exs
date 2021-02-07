defmodule FkvTest do
  use ExUnit.Case
  doctest Fkv

  test "greets the world" do
    assert Fkv.hello() == :world
  end
end

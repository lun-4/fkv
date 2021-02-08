defmodule Fkv.ManyNodeTest do
  use ExUnit.Case, async: true

  setup do
    registry = Fkv.ManyNodeRegistry

    _ =
      start_supervised!({Registry, [keys: :duplicate, name: registry]},
        id: Fkv.ManyNodeRegistry
      )

    primary =
      start_supervised!({Fkv.Node, [primary: true, registry: registry]}, id: Fkv.Test.Primary)

    secondary =
      start_supervised!({Fkv.Node, [primary: false, registry: registry]}, id: Fkv.Test.Secondary)

    %{primary: primary, secondary: secondary}
  end

  test "get/set many node", %{primary: primary, secondary: secondary} do
    assert Fkv.Node.get(primary, "sex") == nil
    assert Fkv.Node.put(primary, "sex", "penis") == :ok
    Process.sleep(1000)
    assert Fkv.Node.get(secondary, "sex") == "penis"
    assert Fkv.Node.delete(secondary, "sex") != :ok
    assert Fkv.Node.delete(primary, "sex") == :ok
    assert Fkv.Node.get(secondary, "sex") == nil
    assert Fkv.Node.get(primary, "sex") == nil
  end
end

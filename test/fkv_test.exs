defmodule Fkv.NodeTest do
  use ExUnit.Case, async: true

  setup do
    node = start_supervised!(Fkv.Node)
    %{node: node}
  end

  test "get/set single node", %{node: node} do
    assert Fkv.Node.get(node, "sex") == nil
    assert Fkv.Node.put(node, "sex", "penis") == :ok
    assert Fkv.Node.get(node, "sex") == "penis"
  end
end

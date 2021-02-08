defmodule Fkv.ManyNodeTest do
  use ExUnit.Case, async: true

  setup do
    primary = start_supervised!({Fkv.Node, [primary: true]}, id: Fkv.Test.Primary)
    secondary = start_supervised!({Fkv.Node, [primary: false]}, id: Fkv.Test.Secondary)
    %{primary: primary, secondary: secondary}
  end

  test "get/set many node", %{primary: primary, secondary: secondary} do
    assert Fkv.Node.get(primary, "sex") == nil
    assert Fkv.Node.put(primary, "sex", "penis") == :ok
    Process.sleep(1000)
    assert Fkv.Node.get(secondary, "sex") == "penis"
  end
end

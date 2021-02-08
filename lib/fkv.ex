defmodule Fkv do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Fkv.Node, name: Fkv.Primary}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

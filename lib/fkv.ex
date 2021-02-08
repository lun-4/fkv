defmodule Fkv do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: Fkv.Registry,
        start: {Registry, :start_link, [[keys: :duplicate, name: Fkv.GlobalRegistry]]}
      },
      %{
        id: Fkv.Primary,
        start:
          {Fkv.Node, :start_link,
           [[primary: true, registry: Fkv.GlobalRegistry], [name: Fkv.Primary]]}
      },
      %{
        id: Fkv.Secondary,
        start:
          {Fkv.Node, :start_link,
           [[primary: false, registry: Fkv.GlobalRegistry], [name: Fkv.Secondary]]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

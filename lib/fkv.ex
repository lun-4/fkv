defmodule Fkv do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: Fkv.Registry,
        start: {Registry, :start_link, [[keys: :duplicate, name: Fkv.Registry]]}
      },
      %{
        id: Fkv.Primary,
        start: {Fkv.Node, :start_link, [[primary: true], [name: Fkv.Primary]]}
      },
      %{
        id: Fkv.Secondary,
        start: {Fkv.Node, :start_link, [[primary: false], [name: Fkv.Secondary]]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule Fkv.Node do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def put(pid, key, value) do
    GenServer.call(pid, {:put, key, value})
  end

  # -- impl --

  @impl true
  def init(opts) do
    is_primary = Keyword.get(opts, :primary)

    if is_primary do
      {:ok, _} = Registry.register(Fkv.Registry, "primary", nil)
    else
      {:ok, _} = Registry.register(Fkv.Registry, "secondary", nil)
    end

    {:ok,
     %{
       is_primary: is_primary,
       map: %{}
     }}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state.map, key), state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    # broadcast change to all nodes
    if state.is_primary do
      Registry.dispatch(Fkv.Registry, "secondary", fn entries ->
        Enum.each(entries, fn datum ->
          {pid, _} = datum
          Fkv.Node.put(pid, key, value)
        end)
      end)
    end

    {:reply, :ok, %{state | map: Map.put(state.map, key, value)}}
  end
end

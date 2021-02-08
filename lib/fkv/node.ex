defmodule Fkv.Node do
  use GenServer

  def start_link(opts, genserver_opts \\ []) do
    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def put(pid, key, value) do
    GenServer.call(pid, {:put, key, value})
  end

  def put_from_primary(pid, key, value) do
    GenServer.call(pid, {:put_from_primary, key, value})
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
          Fkv.Node.put_from_primary(pid, key, value)
        end)
      end)

      {:reply, :ok, %{state | map: Map.put(state.map, key, value)}}
    else
      {:reply, {:error, :not_primary_node}, state}
    end
  end

  @impl true
  def handle_call({:put_from_primary, key, value}, _from, state) do
    {:reply, :ok, %{state | map: Map.put(state.map, key, value)}}
  end
end

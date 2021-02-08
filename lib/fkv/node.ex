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

  def delete(pid, key) do
    GenServer.call(pid, {:delete, key})
  end

  def put_from_primary(pid, key, value) do
    GenServer.call(pid, {:put_from_primary, key, value})
  end

  def delete_from_primary(pid, key) do
    GenServer.call(pid, {:delete_from_primary, key})
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

  defp broadcast_secondaries(call_message) do
    Registry.dispatch(Fkv.Registry, "secondary", fn entries ->
      Enum.each(entries, fn datum ->
        {pid, _} = datum
        GenServer.call(pid, call_message)
      end)
    end)
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state.map, key), state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    if state.is_primary do
      broadcast_secondaries({:put_from_primary, key, value})
      {:reply, :ok, %{state | map: Map.put(state.map, key, value)}}
    else
      {:reply, {:error, :not_primary_node}, state}
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    if state.is_primary do
      broadcast_secondaries({:delete_from_primary, key})
      {:reply, :ok, %{state | map: Map.delete(state.map, key)}}
    else
      {:reply, {:error, :not_primary_node}, state}
    end
  end

  @impl true
  def handle_call({:put_from_primary, key, value}, _from, state) do
    {:reply, :ok, %{state | map: Map.put(state.map, key, value)}}
  end

  @impl true
  def handle_call({:delete_from_primary, key}, _from, state) do
    {:reply, :ok, %{state | map: Map.delete(state.map, key)}}
  end
end

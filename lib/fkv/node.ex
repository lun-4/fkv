defmodule Fkv.Node do
  use GenServer

  require Logger

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

  # -- impl --

  @impl true
  def init(opts) do
    is_primary = Keyword.get(opts, :primary)
    registry = Keyword.get(opts, :registry, Fkv.Registry)

    if is_primary do
      {:ok, _} = Registry.register(registry, "primary", nil)
    else
      {:ok, _} = Registry.register(registry, "secondary", nil)
    end

    {:ok,
     %{
       registry: registry,
       is_primary: is_primary,
       map: %{},
       replication_log: %{},
       current_sequence_number: 0
     }}
  end

  defp broadcast_secondaries(call_message, state) do
    Registry.dispatch(state.registry, "secondary", fn entries ->
      Enum.each(entries, fn {pid, _} ->
        Logger.info(
          "send replication change (primary=#{inspect(self())}): #{inspect(call_message)} to #{
            inspect(pid)
          }"
        )

        GenServer.call(pid, call_message)
      end)
    end)
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state.map, key), state}
  end

  def do_operation_from_primary(operation, state) do
    new_sequence_number = state.current_sequence_number + 1
    broadcast_secondaries({:replication_log, new_sequence_number, operation}, state)

    new_map =
      case operation do
        {:put, key, value} ->
          Map.put(state.map, key, value)

        {:delete, key} ->
          Map.delete(state.map, key)
      end

    {
      :reply,
      :ok,
      Map.merge(state, %{
        map: new_map,
        replication_log: Map.put(state.replication_log, new_sequence_number, operation),
        current_sequence_number: new_sequence_number
      })
    }
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    if state.is_primary do
      do_operation_from_primary({:put, key, value}, state)
    else
      {:reply, {:error, :not_primary_node}, state}
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    if state.is_primary do
      do_operation_from_primary({:delete, key}, state)
    else
      {:reply, {:error, :not_primary_node}, state}
    end
  end

  @impl true
  def handle_call({:replication_log, sequence_number, operation}, _from, state) do
    if state.is_primary do
      Logger.warn("WARNING! got replication log change but is primary")
    end

    Logger.info(
      "got replication change (#{inspect(self())}): #{sequence_number} #{inspect(operation)}"
    )

    new_state =
      Map.merge(state, %{
        replication_log: Map.put(state.replication_log, sequence_number, operation),
        current_sequence_number: sequence_number
      })

    new_map =
      case operation do
        {:put, key, value} ->
          Map.put(state.map, key, value)

        {:delete, key} ->
          Map.delete(state.map, key)
      end

    {:reply, :ok, %{new_state | map: new_map}}
  end
end

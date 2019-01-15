# lib/house_party/person_worker.ex
defmodule HouseParty.PersonWorker do
  use GenServer
  require Logger
  alias HouseParty.PersonWorker
  # TTL in ms (5 min)
  @timeout 300_000

  defstruct name: nil,

            # atom
            # music playing right now (see DJWorker)
            current_music: nil,
            # count of ticks (~ seconds)
            count_ticks: 0

  # Helpul external API
  def start_link(%PersonWorker{name: name} = state) when is_atom(name) do
    GenServer.start_link(__MODULE__, state, timeout: @timeout)
  end

  def start_link(name) when is_atom(name), do: start_link(%PersonWorker{name: name})
  def take(pid, fields), do: GenServer.call(pid, {:take, fields})
  def set(pid, field, value), do: GenServer.call(pid, {:set, field, value})

  # GenServer internal API
  def init(%PersonWorker{} = state) do
    schedule_work(state)
    {:ok, state}
  end

  def handle_call({:take, fields}, _from, state) do
    {:reply, {:ok, Map.take(state, fields)}, state}
  end

  def handle_call({:set, field, value}, _from, state) do
    {:reply, :ok, Map.put(state, field, value)}
  end

  # These are special swarm interfaces to control handoff and migration
  def handle_call({:swarm, :begin_handoff}, _from, state) do
    {:reply, {:resume, state}, state}
  end

  def handle_cast({:swarm, :end_handoff, state}, _init_state) do
    {:noreply, state}
  end

  def handle_cast({:swarm, :resolve_conflict, other_node_state}, state) do
    {:noreply, state}
  end

  def handle_info({:swarm, :die}, %PersonWorker{name: name} = state) do
    {:stop, :shutdown, state}
  end

  # run a clock-tick in the room
  def handle_info({:tick}, %PersonWorker{count_ticks: count_ticks} = state) do
    new_state = state |> Map.put(:count_ticks, count_ticks + 1)
    schedule_work(new_state)
    {:noreply, new_state}
  end

  # run tick approx every second (with drift)
  def schedule_work(%PersonWorker{} = _state) do
    Process.send_after(self(), {:tick}, 1_000)
  end
end

# lib/house_party/person_worker.ex
defmodule HouseParty.StatsWorker do
  use GenServer

  # Helpul external API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__, timeout: :infinity)
  end

  # get the stats for this, local node
  def local_stats(), do: GenServer.call(__MODULE__, {:local_stats})

  # GenServer internal API
  def init(state) do
    {:ok, state}
  end

  def handle_call({:local_stats}, _from, state) do
    {:reply, {:ok, local_stats()}, state}
  end

  # get the stats for all local people, return as a list of strings
  def local_stats() do
    HouseParty.get_local_people_pids() |> Enum.map(@get_person_stat_line / 1)
  end

  # get the stats as a line string, for a person by PID
  def get_person_stat_line(pid) when is_pid(pid) do
    case PersonWorker.take(pid, [:name, :current_music]) do
      %{name: name, current_music: music} -> "#{music} playing for #{name} [#{inspect(pid)}]"
      _ -> "unable to get stats for [#{inspect(pid)}]"
    end
  end
end

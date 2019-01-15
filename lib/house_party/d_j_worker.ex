# lib/house_party/d_j_worker.ex
defmodule HouseParty.DJWorker do
  use GenServer
  require Logger
  alias HouseParty.DJWorker
  alias HouseParty.PersonWorker
  # what is dead may never die
  @timeout :infinity
  @records [
    # {<title>, <duration_sec>, <artist>}
    {"Why You Get Funky on Me", 220, "Today"},
    {"What a Feeling", 400, "Arts & Crafts"},
    {"Jive Time Sucker", 296, "Force MD's"},
    {"This Is Love", 170, "Kenny Vaughan & the Art of Love"},
    {"I Can't Do Nothing for You, Man!", 263, "Flavor Flav"},
    {"Fun House", 267, "Kid 'n Play"},
    {"To da Break of Dawn", 262, "LL Cool J & Marley Marl"},
    {"Kid Vs. Play (The Battle)", 317, "Kid 'n Play"},
    {"I Ain't Going Out Like That", 222, "Zan"},
    {"Surely", 226, "Arts & Crafts"},
    {"Ain't My Type of Hype", 223, "Full Force"}
  ]

  defstruct current_music: nil,

            # music playing right now (will update PersonWorker)
            duration_sec: 0

  # Helpul external API
  def start_link(%DJWorker{} = state) do
    GenServer.start_link(__MODULE__, state, timeout: @timeout)
  end

  def start_link(), do: start_link(%DJWorker{})
  def take(pid, fields), do: GenServer.call(pid, {:take, fields})

  # GenServer internal API
  def init(%DJWorker{} = state) do
    schedule_work(state)
    {:ok, state}
  end

  def handle_call({:take, fields}, _from, state) do
    {:reply, {:ok, Map.take(state, fields)}, state}
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

  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end

  # run a clock-change_songs in the room
  def handle_info({:change_songs}, %DJWorker{} = state) do
    new_state = select_new_music(state)
    play_music(new_state)
    schedule_work(new_state)
    {:noreply, new_state}
  end

  def schedule_work(%DJWorker{duration_sec: duration_sec} = _state) do
    Process.send_after(self(), {:change_songs}, min(duration_sec, 360) * 1_000)
  end

  def select_new_music(%DJWorker{} = state) do
    {title, duration_sec, artist} = Enum.random(@records)

    state
    |> Map.merge(%{
      current_music: "#{title} (by #{artist})",
      duration_sec: duration_sec
    })
  end

  def play_music(%DJWorker{current_music: current_music} = _state) do
    # assign current_music to all people
    HouseParty.get_local_people_pids()
    |> Enum.each(fn pid -> PersonWorker.set(pid, :current_music, current_music) end)
  end
end

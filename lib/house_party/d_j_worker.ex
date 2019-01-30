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
  def start_link([]) do
    GenServer.start_link(__MODULE__, %DJWorker{}, [
      name: __MODULE__,
      timeout: @timeout,
    ])
  end

  # GenServer internal API
  def init(%DJWorker{} = state) do
    schedule_work(state)
    {:ok, state}
  end

  # run a clock-change_songs in the room
  def handle_info({:change_songs}, %DJWorker{} = state) do
    new_state = select_new_music(state)
    play_music(new_state)
    schedule_work(new_state)
    {:noreply, new_state}
  end

  # setup a basic loop, cycle after song duration
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

  def play_music(%DJWorker{current_music: music}) do
    HouseParty.get_local_people_pids()
    |> Enum.each(fn(pid) -> HouseParty.PersonWorker.set(pid, :current_music, music) end)
  end
end

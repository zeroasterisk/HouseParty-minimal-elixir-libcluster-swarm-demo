# lib/house_party.ex
defmodule HouseParty do
  require Logger
  alias HouseParty.PersonWorker
  @swarm_group_name_people :house_party_people

  # easy setup for party configurations
  def setup_party(:small), do: add_people(50)
  def setup_party(:big), do: add_people(5_000)
  def setup_party(:giant), do: add_people(15_000)

  @doc """
  Add people to the party
  """
  def add_people(n_people) when is_integer(n_people) and n_people > 0 do
    Range.new(1, n_people) |> Enum.map(fn i -> String.to_atom("person_#{i}") end) |> add_people()
  end

  def add_people(people) when is_list(people), do: people |> Enum.map(&add_person/1)
  def add_people(person) when is_atom(person), do: person |> add_person()
  # add just a single person
  defp add_person(person_name) when is_atom(person_name),
    do: add_person(%PersonWorker{name: person_name})

  defp add_person(%PersonWorker{name: person_name} = person) when is_atom(person_name) do
    name = make_person_process_name(:person, person_name)
    name |> Swarm.register_name(PersonWorker, :start_link, [person]) |> add_person_join_group()
  end

  # handle the output from Swarm.register_name and auto-join the group if possible
  defp add_person_join_group({:ok, pid}) do
    # create a group for all people processes on any node
    Swarm.join(@swarm_group_name_people, pid)
    {:ok, pid}
  end

  defp add_person_join_group({:error, {:already_registered, pid}}), do: {:ok, pid}
  defp add_person_join_group(:error), do: {:error, "unknown reason"}
  defp add_person_join_group({:error, reason}), do: {:error, reason}

  def make_person_process_name(type, name) do
    (Atom.to_string(type) <> "_" <> Atom.to_string(name)) |> String.to_atom()
  end
  def reset() do
    Swarm.publish(@swarm_group_name_people, {:swarm, :die})
  end
  def get_people_descriptions() do
    Swarm.multi_call(@swarm_group_name_people, {:describe})
  end
  def get_local_people_pids() do
    house_party_pids = Swarm.members(@swarm_group_name_people) |> MapSet.new()
    local_node_pids = Process.list() |> MapSet.new()
    MapSet.intersection(house_party_pids, local_node_pids) |> MapSet.to_list()
  end
end

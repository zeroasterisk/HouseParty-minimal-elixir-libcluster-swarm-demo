defmodule HousePartyTest do
  use ExUnit.Case
  doctest HouseParty

  test "add_people for 3 people" do
    result = HouseParty.add_people(3)
    assert Enum.count(result) == 3
    assert Enum.map(result, fn {status, _pid} -> status end) == [:ok, :ok, :ok]
    assert Enum.map(result, fn {_, pid} -> Process.alive?(pid) end) == [true, true, true]
    HouseParty.reset()
  end

  test "get_local_people_pids for 3 people" do
    started_pids =
      HouseParty.add_people(3)
      |> Enum.map(fn {_, pid} -> pid end)
      |> Enum.sort()

    people_pids = HouseParty.get_local_people_pids() |> Enum.sort()
    assert people_pids == started_pids
    HouseParty.reset()
  end
end

# lib/house_party/application.ex
defmodule HouseParty.Application do
  @moduledoc false
  require Logger
  use Application

  def start(_type, _args) do
    port = get_port(Application.get_env(:house_party, :port))
    Logger.info(fn -> "HTTP interface starting with port #{port}" end)

    # topologies for the libcluster config
    libcluster_topologies = Application.get_env(:libcluster, :topologies)

    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: HouseParty.Router, options: [port: port]),
      {HouseParty.DJWorker, []},
      {Cluster.Supervisor, [libcluster_topologies, [name: HouseParty.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: HouseParty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # get the port from configuration, as INT or STRING - defaults 4001
  defp get_port("${PORT}"), do: "PORT" |> System.get_env() |> get_port()
  defp get_port(port) when is_integer(port), do: port
  defp get_port(port) when is_bitstring(port), do: port |> Integer.parse() |> get_port()
  defp get_port({port, _}), do: port
  # default port, easier defaulting/development
  defp get_port(_), do: 4001
end

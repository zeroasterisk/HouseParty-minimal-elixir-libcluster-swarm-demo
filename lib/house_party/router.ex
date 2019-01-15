# lib/house_party/router.ex
defmodule HouseParty.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger
  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/party/small" do
    HouseParty.setup_party(:small)
    send_resp(conn, 200, stats_body())
  end

  get "/party/big" do
    HouseParty.setup_party(:big)
    send_resp(conn, 200, stats_body())
  end

  get "/stats" do
    send_resp(conn, 200, stats_body())
  end

  # "Default" route that will get called when no other route is matched
  match _ do
    send_resp(conn, 404, "not found")
  end

  defp stats_body() do
    self_stats = StatsWorker.local_stats()
    nodes = :erlang.nodes()

    node_stats =
      nodes
      |> Enum.map(fn node_name ->
        # get the local_stats via a remote call to the node
        stat_lines = ["none yet"]
        ["## #{node_name} ##" | stat_lines]
      end)

    node_stat_text = node_stats |> Enum.flatten() |> Enum.join("\n")

    """
    self: #{inspect(:erlang.node())}\nnodes: #{inspect(nodes)}

    #{node_stat_text}
    """
  end
end

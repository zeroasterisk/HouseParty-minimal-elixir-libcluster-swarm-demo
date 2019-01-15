defmodule HouseParty.MixProject do
  use Mix.Project

  def project do
    [
      app: :house_party,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {HouseParty.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:libcluster, "~> 3.0"},
      {:plug_cowboy, "~> 2.0"},
      {:swarm, "~> 3.3"}
    ]
  end
end

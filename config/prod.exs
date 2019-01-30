use Mix.Config

config :libcluster,
  debug: false,
  topologies: [
    hpgcpcluster: [
      strategy: Cluster.Strategy.Kubernetes,
      config: [
        mode: :ip, # :dns,
        # these must match the Kubernetes Deployment values
        kubernetes_node_basename: "housepartyapp",
        kubernetes_selector: "app=housepartyapp",
        # how fast are we checking for changes?
        polling_interval: 10_000,
      ]
    ]
  ]

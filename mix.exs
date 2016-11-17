defmodule Server.Mixfile do
  use Mix.Project

  def project do
    [app: :server,
     version: "0.1.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [ mod: { Server, [] },
      applications: [:logger, :registry]]
  end

  defp deps do
    [
      {:registry, git: "https://github.com/elixir-lang/registry.git"}
    ]
  end
end

defmodule UeberauthMeli.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ueberauth_meli,
      version: @version,
      name: "Ueberauth Meli",
      package: package(),
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/marciotoze/ueberauth_meli",
      homepage_url: "https://github.com/marciotoze/ueberauth_meli",
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.7"},
      {:jason, "~> 1.2"},

      # dev/test dependencies
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [extras: ["README.md", "CONTRIBUTING.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Mercado Libre to authenticate your users"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Marcio Toze"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/marciotoze/ueberauth_meli"}
    ]
  end
end

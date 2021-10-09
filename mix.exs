defmodule MixFormula.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_formula,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
    ]
  end

  def application do
    [
      extra_applications: [:eex]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A project generator based on EEx templates."
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Alex Lopez <alex.lopez.zorzano@gmail.com>"]
    ]
  end

  defp docs do
    [
      main: "Mix.Tasks.Formula"
    ]
  end
end

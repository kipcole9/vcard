defmodule Vcard.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :vcard,
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.4"}
    ]
  end
end

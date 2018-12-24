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
      {:nimble_parsec, git: "https://github.com/plataformatec/nimble_parsec"},
      {:nimble_csv, "~> 0.4"},
      {:ex_phone_number, "~> 0.1"}
    ]
  end
end

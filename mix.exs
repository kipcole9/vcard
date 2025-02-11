defmodule Vcard.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      version: @version,
      elixir: "~> 1.14",
      name: "Vcard",
      source_url: "https://github.com/kipcole9/vcard",
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      app: :vcard,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "Vcard parser and serializer"
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:nimble_csv, "~> 1.0"},
      {:ex_phone_number, "~> 0.4"}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/kipcole9/vcard",
      "Readme" => "https://github.com/kipcole9/vcard/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/kipcole9/vcard/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      # logo: "logo.png",
      extras: [
        "README.md",
        "LICENSE.md",
        "CHANGELOG.md"
      ],
      formatters: ["html"]
    ]
  end
end

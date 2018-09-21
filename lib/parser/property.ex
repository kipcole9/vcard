defmodule VCard.Parser.Property do

  def reduce("version", args) do
    version =
      args
      |> Keyword.get(:value)
      |> String.to_float

    Keyword.put(args, :value, version)
  end

  def reduce("key", args) do
    version =
      args
      |> Keyword.get(:value)
      |> String.to_float

    Keyword.put(args, :value, version)
  end

  # Parse the value as a URI if the VALUE param is "uri"
  def reduce("tel", args) do
    args
  end

  def reduce(_property, args) do
    args
  end

end
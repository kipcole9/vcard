defmodule VCard.Parser do
  import NimbleParsec
  import VCard.Parser.{Grammar, Core, Params, Types}

  def parse(vcard_text, rule \\ :parse_vcard) when is_binary(vcard_text) do
    case unwrap(apply(__MODULE__, rule, [unfold(vcard_text)])) do
      {:ok, result} -> result
      {:ok, result, rest} -> result ++ parse(rest, rule)
      {:error, reason} -> {:error, reason}
    end
  end

  @folder Regex.compile!("\r?\n[ \t]")
  defp unfold(vcard_text) when is_binary(vcard_text) do
    String.replace(vcard_text, @folder, "")
  end

  def group(vcard) when is_list(vcard) do
    Enum.group_by(vcard, &Keyword.get(&1, :group))
  end

  def cardinality(grouped_card) when is_map(grouped_card) do
    Map.new(grouped_card, fn {property, values} ->{property, length(values)} end)
  end

  defp unwrap({:ok, acc, "", _, _, _}) when is_list(acc),
    do: {:ok, acc}

  defp unwrap({:ok, acc, rest, _, _, _}) when is_list(acc),
    do: {:ok, acc, rest}

  defp unwrap({:error, reason, rest, _, {line, _}, _offset}) do
    {:error, {VCard.Parser.ParseError,
      "#{reason}. Detected on line #{inspect line} at #{inspect(rest, printable_limit: 30)}"}}
  end

  # parsec:VCard.Parser

  import NimbleParsec
  import VCard.Parser.{Grammar, Core, Params, Types}

  defparsec :parse_vcard,
    begin_line()
    |> repeat(content_line())
    |> concat(end_line())
    |> wrap

  defparsec :property,
    content_line()

  defparsec :text,
    text()

  defparsec :type,
    type_code()

  # parsec:VCard.Parser

end
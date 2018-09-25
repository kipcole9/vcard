defmodule VCard.Parser do
  import NimbleParsec
  import VCard.Parser.{Grammar, Core, Params, Types}
  import VCard.Parser.Property, only: [version: 0]

  def parse(vcard_text, rule \\ :parse_vcard) when is_binary(vcard_text) do
    apply(__MODULE__, rule, [unfold(vcard_text)])
    |> unwrap
  end

  @folder Regex.compile!("\r?\n[ \t]")
  defp unfold(vcard_text) when is_binary(vcard_text) do
    String.replace(vcard_text, @folder, "")
  end

  defp unwrap({:ok, acc, "", _, _, _}) when is_list(acc),
    do: {:ok, acc}

  defp unwrap({:error, reason, rest, _, {line, _}, _offset}) do
    {:error, {VCard.Parser.ParseError, "#{reason}. Detected on line #{inspect line} at #{inspect(rest, printable_limit: 20)}"}}
  end

  defparsec :parse_vcards,
    parsec(:parse_vcard)
    |> repeat

  defparsec :parse_vcard,
    begin_line()
    |> concat(version())
    |> repeat(content_line())
    |> lookahead(:invalid_property_check)
    |> concat(end_line())

  defparsec :property,
    content_line()

  defparsec :uri,
    uri()

  defp invalid_property_check("", _context, _line, _offset) do
    {:error, "unexpected end of vcard"}
  end

  defp invalid_property_check(rest, context, _line, _offset) do
    if Regex.match?(~r"^end:vcard"i, rest) do
      {[], context}
    else
      rest
      |> String.split(":", parts: 2)
      |> return_property_error()
    end
  end

  defp return_property_error([_rest]) do
    {:error, "Property line could not be parsed"}
  end

  defp return_property_error([property | _rest]) do
    {:error, "Property #{inspect property} is unknown or invalid"}
  end

end
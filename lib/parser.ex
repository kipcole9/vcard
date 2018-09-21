defmodule VCard.Parser do
  import NimbleParsec
  import VCard.Parser.Grammar

  def parse(vcard_text) when is_binary(vcard_text) do
    vcard_text
    |> unfold
    |> vcard
  end

  @folder Regex.compile!("\r\n[ \t]")
  def unfold(vcard) when is_binary(vcard) do
    String.replace(vcard, @folder, "")
  end

  defparsec :vcard,
    begin_line()
    |> repeat(content_line())
    |> concat(end_line())

  defparsec :content,
    content_line()

  defparsec :textt,
    text()
end
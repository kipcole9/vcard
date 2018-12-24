defmodule VCard.Parser.Core do
  import NimbleParsec

  @cr 0x0d
  @lf 0x0a

  # Allow NL line ends for simpler compatibility
  def crlf do
    choice([
      ascii_char([@cr]) |> ascii_char([@lf]),
      ascii_char([@lf])
    ])
    |> label("a newline (either CRLF or LF)")
  end

  def colon do
    ascii_char([?:])
    |> label("a colon")
  end

  def semicolon do
    ascii_char([?;])
    |> label("a semicolon")
  end

  def period do
    ascii_char([?.])
    |> label("a dot character")
  end

  def comma do
    ascii_char([?,])
    |> label("a comma")
  end

  def digit do
    ascii_char([?0..?9])
    |> label("a decimal digit")
  end

  def equals do
    ascii_char([?=])
    |> label("an equals sign")
  end

  def dquote do
    ascii_char([?"])
    |> label("a double quote character")
  end

  def hex_string do
    ascii_string([?a..?f, ?A..?F, ?0..?9], min: 1)
    |> label("a hexidecimal digit")
  end

  def alphanum_and_dash do
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-], min: 1)
    |> label("an alphanumeric character or a dash")
  end

  def alphabetic do
    ascii_string([?a..?z, ?A..?Z], min: 1)
    |> label("an alphabetic character")
  end

  def alphanumeric do
    ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)
    |> label("an alphanumeric character")
  end

  def anycase_string(string) do
    down = String.downcase(string)
    up = String.upcase(string)

    choice([
      string(down),
      string(up)
    ])
  end

  # def anycase_string(string) do
  #   string
  #   |> String.upcase
  #   |> String.to_charlist
  #   |> Enum.reverse
  #   |> char_piper
  #   |> reduce({List, :to_string, []})
  # end
  #
  # defp char_piper([c]) when c in ?A..?Z do
  #   c
  #   |> both_cases
  #   |> ascii_char
  # end
  #
  # defp char_piper([c | rest]) when c in ?A..?Z do
  #   rest
  #   |> char_piper
  #   |> ascii_char(both_cases(c))
  # end
  #
  # defp char_piper([c]) do
  #   ascii_char([c])
  # end
  #
  # defp char_piper([c | rest]) do
  #   rest
  #   |> char_piper
  #   |> ascii_char([c])
  # end
  #
  # defp both_cases(c) do
  #   [c, c + 32]
  # end

  def quoted_string do
    ignore(ascii_char([?"]))
    |> concat(qsafe_string())
    |> ignore(ascii_char([?"]))
  end

  #    SAFE-CHAR = WSP / "!" / %x23-39 / %x3C-7E / NON-ASCII
  #      ; Any character except CTLs, DQUOTE, ";", ":"
  #      ; ALSO ALLOW &NBSP 0xa0 since Apple Contacts generates it
  def safe_string do
    choice([
      non_ascii(),
      utf8_char([160]),
      ascii_char([0x20, 0x09, ?!, 0x23..0x39, 0x3c..0x7e])
    ])
    |> times(min: 1)
    |> reduce({List, :to_string, []})
  end

  #    QSAFE-CHAR = WSP / "!" / %x23-7E / NON-ASCII
  #      ; Any character except CTLs, DQUOTE
  def qsafe_string do
    choice([
      non_ascii(),
      ascii_char([0x20, 0x09, ?!, 0x23..0x7e])
    ])
    |> times(min: 1)
    |> reduce({List, :to_string, []})
  end

  #    NON-ASCII = UTF8-2 / UTF8-3 / UTF8-4
  #      ; UTF8-{2,3,4} are defined in [RFC3629]
  def non_ascii do
    ignore(string("<"))
    |> ignore(ascii_char([?U, ?u]))
    |> ignore(string("+"))
    |> concat(hex_string())
    |> ignore(string(">"))
    |> reduce(:convert_utf8)
  end

  def convert_utf8(args) do
    args
    |> Enum.map(fn x -> {y, ""} = Integer.parse(x, 16); y end)
    |> List.to_string
  end

  def text_list do
    text()
    |> repeat(ignore(comma()) |> concat(text()))
  end

  # text = *TEXT-CHAR
  #
  # TEXT-CHAR = "\\" / "\," / "\n" / WSP / NON-ASCII
  #           / %x21-2B / %x2D-5B / %x5D-7E
  #    ; Backslashes, commas, and newlines must be encoded.
  @unescaped_char [0x20, 0x09, 0x21..0x2b, 0x2d..0x5b, 0x5d..0x7e]
  @escaped_char [?\\, ?,, 0x0d]
  @others [160]

  def text do
    choice([
      non_ascii(),
      utf8_char(@others),
      ascii_char([?\\]) |> ascii_char(@escaped_char ++ @unescaped_char),
      ascii_char(@unescaped_char),
    ])
    |> repeat
    |> reduce({List, :to_string, []})
    |> post_traverse(:unescape)
  end

  # component = "\\" / "\," / "\;" / "\n" / WSP / NON-ASCII
  #           / %x21-2B / %x2D-3A / %x3C-5B / %x5D-7E
  @unescaped_component [0x20, 0x09, 0x21..0x2b, 0x2d..0x3a, 0x3c..0x5b, 0x5d..0x7e]
  @escaped_component [?\\, ?,, ?;, 0x0d]

  def component do
    choice([
      utf8_char(@others),
      ascii_char([?\\]) |> ascii_char(@escaped_component),
      ascii_char(@unescaped_component),
    ])
    |> repeat
    |> reduce({List, :to_string, []})
    |> post_traverse(:unescape)
    |> label("bad component")
  end

  # list-component = component *("," component)
  def list_component do
    component()
    |> repeat(ignore(semicolon()) |> optional(component()))
  end

  def default_nil(_, context, _, _) do
    {[nil], context}
  end

  def unescape(_rest, args, context, _, _) do
    {unescape(args), context}
  end

  def unescape(values) when is_list(values) do
    Enum.map(values, &unescape/1)
  end

  def unescape(""), do: ""
  def unescape(<< "\\n", rest :: binary>>), do: "\n" <> unescape(rest)
  def unescape(<< "\\r", rest :: binary>>), do: "\r" <> unescape(rest)
  def unescape(<< "\\,", rest :: binary>>), do: "," <> unescape(rest)
  def unescape(<< "\\;", rest :: binary>>), do: ";" <> unescape(rest)
  def unescape(<< "\\\\", rest :: binary>>), do: "\\" <> unescape(rest)
  def unescape(<< c :: binary-size(1), rest :: binary>>), do: c <> unescape(rest)
  def unescape(values) do
    values
  end
end
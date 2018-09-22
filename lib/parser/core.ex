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
    |> label("Expected a newline (either CRLF or LF)")
  end

  def colon do
    ascii_char([?:])
  end

  def semicolon do
    ascii_char([?;])
  end

  def period do
    ascii_char([?.])
  end

  def comma do
    ascii_char([?,])
  end

  def decimal_digit do
    ascii_string([?0..?9], min: 1)
  end

  def equals do
    ascii_char([?=])
  end

  def hex_string do
    ascii_string([?a..?f, ?A..?F, ?0..?9], min: 1)
  end

  def alphanum_and_dash do
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-], min: 1)
  end

  def anycase_string(string) do
    string
    |> String.upcase
    |> String.to_charlist
    |> Enum.reverse
    |> char_piper
    |> reduce({List, :to_string, []})
  end

  defp char_piper([c]) when c in ?A..?Z do
    c
    |> both_cases
    |> ascii_char
  end

  defp char_piper([c | rest]) when c in ?A..?Z do
    rest
    |> char_piper
    |> ascii_char(both_cases(c))
  end

  defp char_piper([c]) do
    ascii_char([c])
  end

  defp char_piper([c | rest]) do
    rest
    |> char_piper
    |> ascii_char([c])
  end

  defp both_cases(c) do
    [c, c + 32]
  end

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

  #
  #    iana-token = 1*(ALPHA / DIGIT / "-")
  #      ; identifier registered with IANA
  def iana_token do
    alphanum_and_dash()
  end

  #    x-name = "x-" 1*(ALPHA / DIGIT / "-")
  #      ; Names that begin with "x-" or "X-" are
  #      ; reserved for experimental use, not intended for released
  #      ; products, or for use in bilateral agreements.
  def experimental_property do
    ascii_string([?x, ?X], min: 1)
    |> ascii_string([?-], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
    |> label("an experimental property")
  end

  def experimental_param do
    ascii_string([?x, ?X], min: 1)
    |> ascii_string([?-], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
    |> label("an experimental param")
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
  @unescaped [0x20, 0x21..0x2b, 0x2d..0x5b, 0x5d..0x7e]
  @escaped [?\\, 0x0d]
  @others [160]

  def text do
    choice([
      non_ascii(),
      utf8_char(@others),
      ascii_char([?\\]) |> ascii_char(@escaped ++ @unescaped),
      ascii_char(@unescaped),
    ])
    |> repeat
    |> reduce({List, :to_string, []})
  end

  # component = "\\" / "\," / "\;" / "\n" / WSP / NON-ASCII
  #           / %x21-2B / %x2D-3A / %x3C-5B / %x5D-7E
  @unescaped_component [0x20, 0x09, 0x21..0x2b, 0x2d..0x3a, 0x3c..0x5b, 0x5d..0x7e]
  @escaped_component [?\\, ?,, ?;, 0x0d]

  def component do
    choice([
      utf8_char(@others),
      ascii_char([?\\]) |> ascii_char(@escaped_component ++ @unescaped_component),
      ascii_char(@unescaped_component),
    ])
    |> repeat
    |> reduce({List, :to_string, []})
    |> label("bad component")
  end

  # list-component = component *("," component)
  def list_component do
    component()
    |> repeat(ignore(semicolon()) |> concat(component()))
  end

end
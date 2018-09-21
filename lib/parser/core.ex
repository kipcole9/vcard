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

end
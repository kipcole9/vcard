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
  end

  def newline do
    ascii_char([@cr])
    |> ascii_char([@lf])
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
end
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
  def x_name do
    ascii_string([?x, ?X], min: 1)
    |> ascii_string([?-], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
    |> label("an x- prefixed token")
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

  def version_as_float(args) do
    args
    |> Enum.join
    |> String.to_float
  end

  #      year   = 4DIGIT  ; 0000-9999
  #      month  = 2DIGIT  ; 01-12
  #      day    = 2DIGIT  ; 01-28/29/30/31 depending on month and leap year
  #      hour   = 2DIGIT  ; 00-23
  #      minute = 2DIGIT  ; 00-59
  #      second = 2DIGIT  ; 00-58/59/60 depending on leap second
  #      zone   = utc-designator / utc-offset
  #      utc-designator = %x5A  ; uppercase "Z"
  #      utc-offset = sign hour [minute]
  def year do
    integer(4) |> unwrap_and_tag(:year)
  end

  def month do
    integer(2) |> unwrap_and_tag(:month)
  end

  def day do
    integer(2) |> unwrap_and_tag(:day)
  end

  def hour do
    integer(2) |> unwrap_and_tag(:hour)
  end

  def minute do
    integer(2) |> unwrap_and_tag(:minute)
  end

  def second do
    integer(2) |> unwrap_and_tag(:second)
  end

  def utc_designator do
    ascii_char([?Z])
  end

  def utc_offset do
    ascii_char([?+, ?-]) |> tag(:direction)
    |> concat(hour())
    |> concat(minute())
    |> tag(:offset)
  end

  def zone do
    choice([utc_designator(), utc_offset()])
  end

  #      date          = year    [month  day]
  #                    / year "-" month
  #                    / "--"     month [day]
  #                    / "--"      "-"   day
  #      date-noreduc  = year     month  day
  #                    / "--"     month  day
  #                    / "--"      "-"   day
  #      date-complete = year     month  day
  def date do
    choice([
      year() |> optional(month() |> concat(day())),
      year() |> ignore(ascii_char([?-])) |> concat(month()),
      ignore(string("---")) |> concat(day()),
      ignore(string("--")) |> concat(month()) |> optional(day())
    ])
  end

  def date_noreduc do
    choice([
      year() |> concat(month()) |> concat(day()),
      ignore(string("---")) |> concat(day()),
      ignore(string("--")) |> concat(month()) |> concat(day())
    ])
  end

  def date_complete do
    year() |> concat(month()) |> concat(day())
  end

  #      time          = hour [minute [second]] [zone]
  #                    /  "-"  minute [second]  [zone]
  #                    /  "-"   "-"    second   [zone]
  def time do
    choice([
      hour() |> optional(minute() |> optional(second())) |> optional(zone()),
      ignore(ascii_char([?-])) |> concat(minute()) |> optional(second()) |> optional(zone()),
      ignore(string("--")) |> concat(second()) |> optional(zone())
    ])
  end

  #      time-notrunc  = hour [minute [second]] [zone]
  #      time-complete = hour  minute  second   [zone]
  #      time-designator = %x54  ; uppercase "T"
  def time_notrunc do
    hour() |> optional(minute() |> optional(second())) |> optional(zone())
  end

  def time_complete do
    hour() |> concat(minute()) |> concat(second()) |> optional(zone())
  end

  def time_designator do
    ascii_char([?T])
  end

  #      date-time = date-noreduc  time-designator time-notrunc
  #      timestamp = date-complete time-designator time-complete
  def date_time do
    date_noreduc() |> ignore(time_designator()) |> concat(time_notrunc())
  end

  def timestamp do
    date_complete() |> ignore(time_designator()) |> concat(time_complete())
  end

  #      date-and-or-time = date-time / date / time-designator time
  def date_and_or_time do
    choice([
      date_time(),
      date(),
      ignore(time_designator()) |> concat(time())
    ])
  end

  @unreserved [?0..?9, ?a..?z, ?A..?Z, ?-, ?., ?_, ?~]
  @reserved [?%, ?#, ?/, ?%, ?@, ?:, ??]
  @subdelims [?!, ?$, ?&, ?', ?(, ?), ?*, ?+, ?;, ?,, ?=]

  def scheme do
    ascii_string([?a..?z, ?A..?Z, ?0..?9], min: 1)
  end

  def uri do
    scheme()
    |> ignore(colon())
    |> ascii_string(@unreserved ++ @reserved ++ @subdelims, min: 1)
    |> reduce({Enum, :join, [":"]})
  end

  def default_nil(_, context, _, _) do
    {[nil], context}
  end
end
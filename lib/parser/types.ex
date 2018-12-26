defmodule VCard.Parser.Types do
  import NimbleParsec
  import VCard.Parser.Core

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
    ascii_char([?+, ?-])
    |> concat(hour())
    |> concat(minute())
    |> post_traverse(:calculate_direction)
  end

  def calculate_direction(_rest, [{:minute, minutes}, {:hour, hours}, ?+], context, _, _) do
    {[{:tz_minute_offset, minutes}, {:tz_hour_offset, hours}], context}
  end

  def calculate_direction(_rest, [{:minute, minutes}, {:hour, hours}, ?-], context, _, _) do
    {[{:tz_minute_offset, minutes}, {:tz_hour_offset, hours * -1}], context}
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
  #
  # Also allow Version 3 dates where of the form yyyy-mm-dd
  #
  def date do
    choice([
      year() |> ignore(ascii_char([?-])) |> concat(month()) |> ignore(ascii_char([?-])) |> concat(day()),
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

  def pid do
    digit() |> optional(period() |> concat(digit()))
  end

  def type_code do
    choice([
      anycase_string("work"),
      anycase_string("home"),
      anycase_string("pref"),
      anycase_string("jpeg"),
      adr_type(),
      tel_type(),
      related_type(),
      x_name(),

      # Non-standard, lenient parse
      alphabetic()
    ])
    |> reduce({Enum, :map, [&String.downcase/1]})
    |> label("a valid type")
  end

  def mediatype do
    alphanum_and_dash()
    |> ascii_string([?/], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
    |> label("a valid mediatype")
  end

  def attribute_list do
    ignore(semicolon())
    |> concat(alphanumeric())
    |> ignore(equals())
    |> concat(alphanumeric())
    |> reduce(:tuplize)
    |> repeat
  end

  def tuplize([key, value]) do
    {key, value}
  end

  def adr_type do
    choice([
      anycase_string("postal"),
      anycase_string("parcel"),
      anycase_string("internet")
    ])
    |> label("a valid address type")
  end

  def related_type do
    choice([
      anycase_string("contact"),
      anycase_string("acquaintance"),
      anycase_string("friend"),
      anycase_string("met"),
      anycase_string("co-worker"),
      anycase_string("colleague"),
      anycase_string("co-resident"),
      anycase_string("neighbor"),
      anycase_string("child"),
      anycase_string("parent"),
      anycase_string("sibling"),
      anycase_string("spouse"),
      anycase_string("kin"),
      anycase_string("muse"),
      anycase_string("crush"),
      anycase_string("date"),
      anycase_string("sweetheart"),
      anycase_string("me"),
      anycase_string("agent"),
      anycase_string("emergency")
    ])
    |> label("a valid related type")
  end

  def tel_type do
    choice([
      anycase_string("text"),
      anycase_string("voice"),
      anycase_string("fax"),
      anycase_string("cell"),
      anycase_string("video"),
      anycase_string("pager"),
      anycase_string("textphone"),
      anycase_string("msg"),
      anycase_string("iphone"),
      anycase_string("main"),
      anycase_string("other"),
      x_name(),
    ])
    |> label("a valid tel type")
  end

  @unreserved [?0..?9, ?a..?z, ?A..?Z, ?-, ?., ?_, ?~]
  @reserved [?%, ?#, ?/, ?%, ?@, ?:, ??]
  @subdelims [?!, ?$, ?&, ?', ?(, ?), ?*, ?+, ?;, ?,, ?=]

  def scheme do
    ascii_string([?a..?z, ?A..?Z, ?0..?9, ?-], min: 1)
    |> label("a URI scheme")
  end

  def uri do
    scheme()
    |> ignore(choice([colon(), ascii_char([?\\]) |> concat(colon())]))
    |> ascii_string(@unreserved ++ @reserved ++ @subdelims, min: 1)
    |> reduce(:tag_uri)
    |> label("a URI")
  end

  def tag_uri([scheme, location]) do
    {scheme, location}
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
end
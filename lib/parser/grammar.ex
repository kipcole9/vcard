defmodule VCard.Parser.Grammar do
  import NimbleParsec
  import VCard.Parser.Core
  alias VCard.Parser.Utils

  alias VCard.Parser.Property

  # vcard-entity = 1*vcard
  #
  #    vcard = "BEGIN:VCARD" CRLF
  #            "VERSION:4.0" CRLF
  #            1*contentline
  #            "END:VCARD" CRLF
  #      ; A vCard object MUST include the VERSION and FN properties.
  #      ; VERSION MUST come immediately after BEGIN:VCARD.

  def begin_line do
    anycase_string("begin:vcard")
    |> concat(crlf())
    |> ignore
    |> label("Expected 'BEGIN:VCARD' as the first line in the vcard file")
  end

  def debug(args, context, _, _, _) do
    IO.inspect args
    {args, context}
  end

  def end_line do
    anycase_string("end:vcard")
    |> concat(crlf())
    |> ignore
    |> label("Expected 'END:VCARD' as the last line in the vcard file")
  end

  #    contentline = [group "."] name *(";" param) ":" value CRLF
  #      ; When parsing a content line, folded lines must first
  #      ; be unfolded according to the unfolding procedure
  #      ; described in Section 3.2.
  #      ; When generating a content line, lines longer than 75
  #      ; characters SHOULD be folded according to the folding
  #      ; procedure described in Section 3.2.
  #
  def content_line do
    optional(group() |> ignore(period()))
    |> concat(name())
    |> optional(params())
    |> ignore(colon())
    |> concat(value())
    |> ignore(crlf())
    |> traverse(:reduce_content_line)
  end

  def reduce_content_line(_rest, args, context, _line, _offset) do
    updated_args =
      args
      |> Keyword.get(:property)
      |> Property.reduce(args)

    {[updated_args], context}
  end

  def params do
    repeat(ignore(semicolon()) |> concat(param()))
    |> reduce(:group_params)
    |> unwrap_and_tag(:params)
  end

  def group_params(list) do
    list
    |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
    |> Map.new(fn {x, y} ->
      case List.flatten(y) do
        [one] -> {x, one}
        other -> {x, other}
      end
    end)
  end

  #    group = 1*(ALPHA / DIGIT / "-")
  def group do
    alphanum_and_dash()
    |> unwrap_and_tag(:group)
  end

  def value do
    text()
    |> unwrap_and_tag(:value)
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
      utf8_char(@others),
      ascii_char([?\\]) |> ascii_char(@escaped ++ @unescaped),
      ascii_char(@unescaped),
    ])
    |> repeat
    |> reduce({List, :to_string, []})
  end

  def debug(rest, context, _line, _offset) do
    IO.inspect rest
    {[], context}
  end

  #    name  = "SOURCE" / "KIND" / "FN" / "N" / "NICKNAME"
  #          / "PHOTO" / "BDAY" / "ANNIVERSARY" / "GENDER" / "ADR" / "TEL"
  #          / "EMAIL" / "IMPP" / "LANG" / "TZ" / "GEO" / "TITLE" / "ROLE"
  #          / "LOGO" / "ORG" / "MEMBER" / "RELATED" / "CATEGORIES"
  #          / "NOTE" / "PRODID" / "REV" / "SOUND" / "UID" / "CLIENTPIDMAP"
  #          / "URL" / "KEY" / "FBURL" / "CALADRURI" / "CALURI" / "XML"
  #          / iana-token / x-name

  #      ; Parsing of the param and value is based on the "name" as
  #      ; defined in ABNF sections below.
  #      ; Group and name are case-insensitive.

  def name do
    choice([
      known_name(),
      experimental()
    ])
    |> reduce({Utils, :downcase, []})
    |> unwrap_and_tag(:property)
  end

  def known_name do
    choice([
      anycase_string("version"),
      anycase_string("source"),
      anycase_string("kind"),
      anycase_string("fn"),
      anycase_string("nickname"),
      anycase_string("photo"),
      anycase_string("bday"),
      anycase_string("anniversary"),
      anycase_string("gender"),
      anycase_string("adr"),
      anycase_string("tel"),
      anycase_string("email"),
      anycase_string("impp"),
      anycase_string("lang"),
      anycase_string("tz"),
      anycase_string("geo"),
      anycase_string("title"),
      anycase_string("role"),
      anycase_string("logo"),
      anycase_string("org"),
      anycase_string("member"),
      anycase_string("related"),
      anycase_string("categories"),
      anycase_string("note"),
      anycase_string("prodid"),
      anycase_string("rev"),
      anycase_string("sound"),
      anycase_string("uid"),
      anycase_string("clientpidmap"),
      anycase_string("url"),
      anycase_string("key"),
      anycase_string("fburl"),
      anycase_string("caladruri"),
      anycase_string("caluri"),
      anycase_string("xml"),
      anycase_string("n"),
    ])
  end
  #
  #    iana-token = 1*(ALPHA / DIGIT / "-")
  #      ; identifier registered with IANA
  def iana_token do
    alphanum_and_dash()
  end

  #
  #    x-name = "x-" 1*(ALPHA / DIGIT / "-")
  #      ; Names that begin with "x-" or "X-" are
  #      ; reserved for experimental use, not intended for released
  #      ; products, or for use in bilateral agreements.
  def experimental do
    ascii_string([?x, ?X], min: 1)
    |> ascii_string([?-], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
  end
  #    param = language-param / value-param / pref-param / pid-param
  #          / type-param / geo-parameter / tz-parameter / sort-as-param
  #          / calscale-param / any-param
  #      ; Allowed parameters depend on property name.
  #
  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  #
  #    any-param  = (iana-token / x-name) "=" param-value *("," param-value)

  def param do
    choice([
      experimental(),
      iana_token()
    ])
    |> ignore(equals())
    |> concat(param_value())
    |> repeat(ignore(comma() |> concat(param_value())))
    |> reduce(:reduce_param)
  end

  def reduce_param([key, value]) do
    {String.downcase(key), value}
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

  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  def param_value do
    choice([
      quoted_string(),
      non_ascii(),
      safe_string(),
    ])
    |> repeat
    |> reduce(:split_at_commas)
  end

  @splitter Regex.compile!("(?<!\\\\)[,]")
  def split_at_commas(list) do
    list
    |> Enum.join
    |> String.split(@splitter)
  end

end
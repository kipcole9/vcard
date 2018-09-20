defmodule VCard.Parser.Grammar do
  import NimbleParsec
  import VCard.Parser.Core

  # vcard-entity = 1*vcard
  #
  #    vcard = "BEGIN:VCARD" CRLF
  #            "VERSION:4.0" CRLF
  #            1*contentline
  #            "END:VCARD" CRLF
  #      ; A vCard object MUST include the VERSION and FN properties.
  #      ; VERSION MUST come immediately after BEGIN:VCARD.

  def begin_line do
    string("BEGIN:VCARD")
    |> concat(crlf())
  end

  def version do
    string("VERSION")
    |> ignore(colon())
    |> concat(version_number())
    |> concat(crlf())
  end

  def version_number do
    decimal_digit()
    |> ascii_string([?.])
    |> concat(decimal_digit())
    |> reduce({Enum, :join, []})
    |> tag(:version)
  end

  def end_line do
    string("END:VCARD")
    |> concat(crlf())
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
    optional(group() |> concat(period()))
    |> concat(name())
    |> optional(params())
    |> ignore(colon())
    |> concat(value())
    |> ignore(crlf())
  end

  def params do
    repeat(ignore(semicolon()) |> concat(param()))
    |> reduce({Enum, :into, [%{}]})
    |> unwrap_and_tag(:params)
  end
  #    group = 1*(ALPHA / DIGIT / "-")
  def group do
    alphanum_and_dash()
  end

  def value do
    choice([
      text(),
      text()
    ])
    |> unwrap_and_tag(:value)
  end

  # text = *TEXT-CHAR
  #
  # TEXT-CHAR = "\\" / "\," / "\n" / WSP / NON-ASCII
  #           / %x21-2B / %x2D-5B / %x5D-7E
  #    ; Backslashes, commas, and newlines must be encoded.
  def text do
    ascii_string([?\\, ?,, 0x0d, 0x20, 0x21..0x2b, 0x2d..0x5b, 0x5d..0x7e], min: 1)
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
      experimental(),
      iana_token(),
    ])
    |> unwrap_and_tag(:property)
  end

  def known_name do
    choice([
      string("SOURCE"),
      string("KIND"),
      string("FN"),
      string("N"),
      string("NICKNAME"),
      string("PHOTO"),
      string("BDAY"),
      string("ANNIVERSARY"),
      string("GENDER"),
      string("ADR"),
      string("TEL"),
      string("EMAIL"),
      string("IMPP"),
      string("LANG"),
      string("TZ"),
      string("GEO"),
      string("TITLE"),
      string("ROLE"),
      string("LOGO"),
      string("ORG"),
      string("MEMBER"),
      string("RELATED"),
      string("CATEGORIES"),
      string("NOTE"),
      string("PRODID"),
      string("REV"),
      string("SOUND"),
      string("UID"),
      string("CLIENTPIDMAP"),
      string("URL"),
      string("KEY"),
      string("FBURL"),
      string("CALADRURI"),
      string("CALURI"),
      string("XML")
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
    |> reduce({List, :to_tuple, []})
  end

  def quoted_string do
    ignore(ascii_char([?"]))
    |> concat(qsafe_string())
  end

  #    SAFE-CHAR = WSP / "!" / %x23-39 / %x3C-7E / NON-ASCII
  #      ; Any character except CTLs, DQUOTE, ";", ":"
  def safe_string do
    ascii_string([0x20, 0x09, ?!, 0x23..0x39, 0x3c..0x7e], min: 1)
  end

  #    QSAFE-CHAR = WSP / "!" / %x23-7E / NON-ASCII
  #      ; Any character except CTLs, DQUOTE
  def qsafe_string do
    ascii_string([0x20, 0x09, ?!, 0x23..0x7e], min: 1)
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
    |> IO.inspect
    |> Enum.map(fn x -> {y, ""} = Integer.parse(x, 16); y end)
    |> IO.inspect
    |> List.to_string
  end

  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  def param_value do
    choice([
      non_ascii(),
      safe_string(),
      quoted_string()
    ])
    |> repeat
    |> reduce({Enum, :join, []})
  end

end
defmodule VCard.Parser.Grammar do
  import NimbleParsec
  import VCard.Parser.Core
  import VCard.Parser.Property

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
    |> label("\"BEGIN:VCARD\" as the first line of a vcard")
  end

  def end_line do
    anycase_string("end:vcard")
    |> concat(crlf())
    |> ignore
    |> label("\"END:VCARD\" as the last line of a vcard")
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
    |> concat(property())
    |> ignore(crlf())
  end

  #    group = 1*(ALPHA / DIGIT / "-")
  def group do
    alphanum_and_dash()
    |> unwrap_and_tag(:group)
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
  def property do
    choice([
      known_property(),
      x_property()
    ])
    |> label("a vcard property name")
    |> reduce(:tag_property)
  end

  def tag_property([name | args]) do
    [{:property, String.downcase(name)} | args]
  end

  def known_property do
    choice([
      anycase_string("version")       |> concat(version()),
      anycase_string("source")        |> concat(source()),
      anycase_string("kind")          |> concat(kind()),
      anycase_string("fn")            |> concat(fn_()),
      anycase_string("nickname")      |> concat(nickname()),
      anycase_string("photo")         |> concat(photo()),
      anycase_string("bday")          |> concat(bday()),
      anycase_string("anniversary")   |> concat(anniversary()),
      anycase_string("gender")        |> concat(gender()),
      anycase_string("adr")           |> concat(adr()),
      anycase_string("tel")           |> concat(tel()),
      anycase_string("email")         |> concat(email()),
      anycase_string("impp")          |> concat(impp()),
      anycase_string("lang")          |> concat(lang()),
      anycase_string("tz")            |> concat(tz()),
      anycase_string("geo")           |> concat(geo()),
      anycase_string("title")         |> concat(title()),
      anycase_string("role")          |> concat(role()),
      anycase_string("logo")          |> concat(logo()),
      anycase_string("org")           |> concat(org()),
      anycase_string("member")        |> concat(member()),
      anycase_string("related")       |> concat(related()),
      anycase_string("categories")    |> concat(categories()),
      anycase_string("note")          |> concat(note()),
      anycase_string("prodid")        |> concat(prodid()),
      anycase_string("rev")           |> concat(rev()),
      anycase_string("sound")         |> concat(sound()),
      anycase_string("uid")           |> concat(uid()),
      anycase_string("clientpidmap")  |> concat(clientpidmap()),
      anycase_string("url")           |> concat(url()),
      anycase_string("key")           |> concat(key()),
      anycase_string("fburl")         |> concat(fburl()),
      anycase_string("caladruri")     |> concat(caladruri()),
      anycase_string("caluri")        |> concat(caluri()),
      anycase_string("xml")           |> concat(xml()),
      anycase_string("n")             |> concat(n()),
    ])
  end

end
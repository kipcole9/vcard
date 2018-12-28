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
    |> reduce(:combine_group_and_property)
  end

  def combine_group_and_property([{:group, group}, {property, args}]) do
    {property, Keyword.put(args, :group, group)}
  end

  def combine_group_and_property([{property, args}]) do
    {property, Keyword.put(args, :group, "_default")}
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
    |> reduce(:tag_and_unescape_property)
  end

  def tag_and_unescape_property([name | args]) do
    {_, args} = Keyword.get_and_update(args, :value, fn current_value ->
      {current_value, unescape(current_value)}
    end)

    if is_atom(name) do
      {name, args}
    else
      {String.downcase(name), args}
    end
  end

  def known_property do
    choice([
      anycase_string("version")       |> replace(:version) |> concat(version()),
      anycase_string("source")        |> replace(:source) |> concat(source()),
      anycase_string("kind")          |> replace(:kind) |> concat(kind()),
      anycase_string("fn")            |> replace(:fn) |> concat(fn_()),
      anycase_string("nickname")      |> replace(:nickname) |> concat(nickname()),
      anycase_string("photo")         |> replace(:photo) |> concat(photo()),
      anycase_string("bday")          |> replace(:bday) |> concat(bday()),
      anycase_string("anniversary")   |> replace(:anniversary) |> concat(anniversary()),
      anycase_string("gender")        |> replace(:gender) |> concat(gender()),
      anycase_string("adr")           |> replace(:adr) |> concat(adr()),
      anycase_string("tel")           |> replace(:tel) |> concat(tel()),
      anycase_string("email")         |> replace(:email) |> concat(email()),
      anycase_string("impp")          |> replace(:impp) |> concat(impp()),
      anycase_string("lang")          |> replace(:lang) |> concat(lang()),
      anycase_string("tz")            |> replace(:tz) |> concat(tz()),
      anycase_string("geo")           |> replace(:geo) |> concat(geo()),
      anycase_string("title")         |> replace(:title) |> concat(title()),
      anycase_string("role")          |> replace(:role) |> concat(role()),
      anycase_string("logo")          |> replace(:logo) |> concat(logo()),
      anycase_string("org")           |> replace(:org) |> concat(org()),
      anycase_string("member")        |> replace(:member) |> concat(member()),
      anycase_string("related")       |> replace(:related) |> concat(related()),
      anycase_string("categories")    |> replace(:categories) |> concat(categories()),
      anycase_string("note")          |> replace(:note) |> concat(note()),
      anycase_string("prodid")        |> replace(:prodid) |> concat(prodid()),
      anycase_string("rev")           |> replace(:rev) |> concat(rev()),
      anycase_string("sound")         |> replace(:sound) |> concat(sound()),
      anycase_string("uid")           |> replace(:uid) |> concat(uid()),
      anycase_string("clientpidmap")  |> replace(:clientpidmap) |> concat(clientpidmap()),
      anycase_string("url")           |> replace(:url) |> concat(url()),
      anycase_string("key")           |> replace(:key) |> concat(key()),
      anycase_string("fburl")         |> replace(:fburl) |> concat(fburl()),
      anycase_string("caladruri")     |> replace(:caladruri) |> concat(caladruri()),
      anycase_string("caluri")        |> replace(:caluri) |> concat(caluri()),
      anycase_string("xml")           |> replace(:xml) |> concat(xml()),
      anycase_string("n")             |> replace(:n) |> concat(n()),
    ])
  end

end
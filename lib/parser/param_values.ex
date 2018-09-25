defmodule VCard.Parser.ParamValues do
  import NimbleParsec
  import VCard.Parser.Core
  import VCard.Parser.Types

  # 5.1.  LANGUAGE
  #
  #    The LANGUAGE property parameter is used to identify data in multiple
  #    languages.  There is no concept of "default" language, except as
  #    specified by any "Content-Language" MIME header parameter that is
  #    present [RFC3282].  The value of the LANGUAGE property parameter is a
  #    language tag as defined in Section 2 of [RFC5646].
  #
  #    Examples:
  #
  #      ROLE;LANGUAGE=tr:hoca
  #
  #    ABNF:
  #
  #            language-param = "LANGUAGE=" Language-Tag
  #              ; Language-Tag is defined in section 2.1 of RFC 5646
  def param_value(:language) do
    param_value(:any)
  end

  # 5.2.  VALUE
  #
  #    The VALUE parameter is OPTIONAL, used to identify the value type
  #    (data type) and format of the value.  The use of these predefined
  #    formats is encouraged even if the value parameter is not explicitly
  #    used.  By defining a standard set of value types and their formats,
  #    existing parsing and processing code can be leveraged.  The
  #    predefined data type values MUST NOT be repeated in COMMA-separated
  #    value lists except within the N, NICKNAME, ADR, and CATEGORIES
  #    properties.
  #
  #    ABNF:
  #
  #      value-param = "VALUE=" value-type
  #
  #      value-type = "text"
  #                 / "uri"
  #                 / "date"
  #                 / "time"
  #                 / "date-time"
  #                 / "date-and-or-time"
  #                 / "timestamp"
  #                 / "boolean"
  #                 / "integer"
  #                 / "float"
  #                 / "utc-offset"
  #                 / "language-tag"
  #                 / iana-token  ; registered as described in section 12
  #                 / x-name
  def param_value(:value) do
    choice([
      anycase_string("text"),
      anycase_string("uri"),
      anycase_string("date"),
      anycase_string("time"),
      anycase_string("date-time"),
      anycase_string("date-and-or-time"),
      anycase_string("timestampe"),
      anycase_string("boolean"),
      anycase_string("integer"),
      anycase_string("float"),
      anycase_string("utc-offset"),
      anycase_string("language-tag"),
      anycase_string("x-name"),
      anycase_string("iana-token"),
    ])
  end

  # 5.3.  PREF
  #
  #    The PREF parameter is OPTIONAL and is used to indicate that the
  #    corresponding instance of a property is preferred by the vCard
  #    author.  Its value MUST be an integer between 1 and 100 that
  #    quantifies the level of preference.  Lower values correspond to a
  #    higher level of preference, with 1 being most preferred.
  #
  #    When the parameter is absent, the default MUST be to interpret the
  #    property instance as being least preferred.
  #
  #    Note that the value of this parameter is to be interpreted only in
  #    relation to values assigned to other instances of the same property
  #    in the same vCard.  A given value, or the absence of a value, MUST
  #    NOT be interpreted on its own.
  #
  #    This parameter MAY be applied to any property that allows multiple
  #    instances.
  #
  #    ABNF:
  #
  #            pref-param = "PREF=" (1*2DIGIT / "100")
  #                                 ; An integer between 1 and 100.
  def param_value(:pref) do
    integer(min: 1, max: 3)
    |> label("an integer between 1 and 100")
  end

  # 5.4.  ALTID
  #
  #    The ALTID parameter is used to "tag" property instances as being
  #    alternative representations of the same logical property.  For
  #    example, translations of a property in multiple languages generates
  #    multiple property instances having different LANGUAGE (Section 5.1)
  #    parameter that are tagged with the same ALTID value.
  #
  #    This parameter's value is treated as an opaque string.  Its sole
  #    purpose is to be compared for equality against other ALTID parameter
  #    values.
  #
  #    Two property instances are considered alternative representations of
  #    the same logical property if and only if their names as well as the
  #    value of their ALTID parameters are identical.  Property instances
  #    without the ALTID parameter MUST NOT be considered an alternative
  #    representation of any other property instance.  Values for the ALTID
  #    parameter are not globally unique: they MAY be reused for different
  #    property names.
  #
  #    Property instances having the same ALTID parameter value count as 1
  #    toward cardinality.  Therefore, since N (Section 6.2.2) has
  #    cardinality *1 and TITLE (Section 6.6.1) has cardinality *, these
  #    three examples would be legal:
  #
  #      N;ALTID=1;LANGUAGE=jp:<U+5C71><U+7530>;<U+592A><U+90CE>;;;
  #      N;ALTID=1;LANGUAGE=en:Yamada;Taro;;;
  #      (<U+XXXX> denotes a UTF8-encoded Unicode character.)
  #
  #      TITLE;ALTID=1;LANGUAGE=fr:Patron
  #      TITLE;ALTID=1;LANGUAGE=en:Boss
  #
  #      TITLE;ALTID=1;LANGUAGE=fr:Patron
  #      TITLE;ALTID=1;LANGUAGE=en:Boss
  #      TITLE;ALTID=2;LANGUAGE=en:Chief vCard Evangelist
  #
  #    while this one would not:
  #
  #      N;ALTID=1;LANGUAGE=jp:<U+5C71><U+7530>;<U+592A><U+90CE>;;;
  #      N:Yamada;Taro;;;
  #      (Two instances of the N property.)
  #
  #    and these three would be legal but questionable:
  #
  #      TITLE;ALTID=1;LANGUAGE=fr:Patron
  #      TITLE;ALTID=2;LANGUAGE=en:Boss
  #      (Should probably have the same ALTID value.)
  #
  #      TITLE;ALTID=1;LANGUAGE=fr:Patron
  #      TITLE:LANGUAGE=en:Boss
  #      (Second line should probably have ALTID=1.)
  #
  #      N;ALTID=1;LANGUAGE=jp:<U+5C71><U+7530>;<U+592A><U+90CE>;;;
  #      N;ALTID=1;LANGUAGE=en:Yamada;Taro;;;
  #      N;ALTID=1;LANGUAGE=en:Smith;John;;;
  #      (The last line should probably have ALTID=2.  But that would be
  #       illegal because N has cardinality *1.)
  #
  #    The ALTID property MAY also be used in may contexts other than with
  #    the LANGUAGE parameter.  Here's an example with two representations
  #    of the same photo in different file formats:
  #
  #      PHOTO;ALTID=1:data:image/jpeg;base64,...
  #      PHOTO;ALTID=1;data:image/jp2;base64,...
  #
  #    ABNF:
  #
  #            altid-param = "ALTID=" param-value
  def param_value(:altid) do
    param_value(:any)
  end

  # 5.5.  PID
  #
  #    The PID parameter is used to identify a specific property among
  #    multiple instances.  It plays a role analogous to the UID property
  #    (Section 6.7.6) on a per-property instead of per-vCard basis.  It MAY
  #    appear more than once in a given property.  It MUST NOT appear on
  #    properties that may have only one instance per vCard.  Its value is
  #    either a single small positive integer or a pair of small positive
  #    integers separated by a dot.  Multiple values may be encoded in a
  #    single PID parameter by separating the values with a comma ",".  See
  #    Section 7 for more details on its usage.
  #
  #    ABNF:
  #
  #            pid-param = "PID=" pid-value *("," pid-value)
  #            pid-value = 1*DIGIT ["." 1*DIGIT]
  def param_value(:pid) do
    pid()
    |> repeat(ignore(comma()) |> concat(pid()))
    |> label("a comma-separated list of PID's")
  end

  # 5.6.  TYPE
  #
  #    The TYPE parameter has multiple, different uses.  In general, it is a
  #    way of specifying class characteristics of the associated property.
  #    Most of the time, its value is a comma-separated subset of a
  #    predefined enumeration.  In this document, the following properties
  #    make use of this parameter: FN, NICKNAME, PHOTO, ADR, TEL, EMAIL,
  #    IMPP, LANG, TZ, GEO, TITLE, ROLE, LOGO, ORG, RELATED, CATEGORIES,
  #    NOTE, SOUND, URL, KEY, FBURL, CALADRURI, and CALURI.  The TYPE
  #    parameter MUST NOT be applied on other properties defined in this
  #    document.
  #
  #    The "work" and "home" values act like tags.  The "work" value implies
  #    that the property is related to an individual's work place, while the
  #    "home" value implies that the property is related to an individual's
  #    personal life.  When neither "work" nor "home" is present, it is
  #    implied that the property is related to both an individual's work
  #    place and personal life in the case that the KIND property's value is
  #    "individual", or to none in other cases.
  #
  #    ABNF:
  #
  #            type-param = "TYPE=" type-value *("," type-value)
  #
  #            type-value = "work" / "home" / type-param-tel
  #                       / type-param-related / iana-token / x-name
  #              ; This is further defined in individual property sections.
  def param_value(:type) do
    type()
    |> repeat(ignore(comma()) |> concat(type()))
  end

  # 5.7.  MEDIATYPE
  #
  #    The MEDIATYPE parameter is used with properties whose value is a URI.
  #    Its use is OPTIONAL.  It provides a hint to the vCard consumer
  #    application about the media type [RFC2046] of the resource identified
  #    by the URI.  Some URI schemes do not need this parameter.  For
  #    example, the "data" scheme allows the media type to be explicitly
  #    indicated as part of the URI [RFC2397].  Another scheme, "http",
  #    provides the media type as part of the URI resolution process, with
  #    the Content-Type HTTP header [RFC2616].  The MEDIATYPE parameter is
  #    intended to be used with URI schemes that do not provide such
  #    functionality (e.g., "ftp" [RFC1738]).
  #
  #    ABNF:
  #
  #      mediatype-param = "MEDIATYPE=" mediatype
  #      mediatype = type-name "/" subtype-name *( ";" attribute "=" value )
  #        ; "attribute" and "value" are from [RFC2045]
  #        ; "type-name" and "subtype-name" are from [RFC4288]
  def param_value(:mediatype) do
    mediatype()
    |> concat(attribute_list())
  end

  # 5.8.  CALSCALE
  #
  #    The CALSCALE parameter is identical to the CALSCALE property in
  #    iCalendar (see [RFC5545], Section 3.7.1).  It is used to define the
  #    calendar system in which a date or date-time value is expressed.  The
  #    only value specified by iCalendar is "gregorian", which stands for
  #    the Gregorian system.  It is the default when the parameter is
  #    absent.  Additional values may be defined in extension documents and
  #
  #    registered with IANA (see Section 10.3.4).  A vCard implementation
  #    MUST ignore properties with a CALSCALE parameter value that it does
  #    not understand.
  #
  #    ABNF:
  #
  #            calscale-param = "CALSCALE=" calscale-value
  #
  #            calscale-value = "gregorian" / iana-token / x-name
  def param_value(:calscale) do
    choice([
      anycase_string("gregorian"),
      x_name(
    )])
  end

  # 5.9.  SORT-AS
  #
  #    The "sort-as" parameter is used to specify the string to be used for
  #    national-language-specific sorting.  Without this information,
  #    sorting algorithms could incorrectly sort this vCard within a
  #    sequence of sorted vCards.  When this property is present in a vCard,
  #    then the given strings are used for sorting the vCard.
  #
  #    This parameter's value is a comma-separated list that MUST have as
  #    many or fewer elements as the corresponding property value has
  #    components.  This parameter's value is case-sensitive.
  #
  #    ABNF:
  #
  #      sort-as-param = "SORT-AS=" sort-as-value
  #
  #      sort-as-value = param-value *("," param-value)
  #
  #    Examples: For the case of surname and given name sorting, the
  #    following examples define common sort string usage with the N
  #    property.
  #
  #            FN:Rene van der Harten
  #            N;SORT-AS="Harten,Rene":van der Harten;Rene,J.;Sir;R.D.O.N.
  #
  #            FN:Robert Pau Shou Chang
  #            N;SORT-AS="Pau Shou Chang,Robert":Shou Chang;Robert,Pau;;
  #
  #            FN:Osamu Koura
  #            N;SORT-AS="Koura,Osamu":Koura;Osamu;;
  #
  #            FN:Oscar del Pozo
  #            N;SORT-AS="Pozo,Oscar":del Pozo Triscon;Oscar;;
  #
  #            FN:Chistine d'Aboville
  #            N;SORT-AS="Aboville,Christine":d'Aboville;Christine;;
  #
  #            FN:H. James de Mann
  #            N;SORT-AS="Mann,James":de Mann;Henry,James;;
  #
  #    If sorted by surname, the results would be:
  #
  #            Christine d'Aboville
  #            Rene van der Harten
  #            Osamu Koura
  #            H. James de Mann
  #            Robert Pau Shou Chang
  #            Oscar del Pozo
  #
  #    If sorted by given name, the results would be:
  #
  #            Christine d'Aboville
  #            H. James de Mann
  #            Osamu Koura
  #            Oscar del Pozo
  #            Rene van der Harten
  #            Robert Pau Shou Chang
  def param_value(:sort_as) do
    text_list()
  end

  # 5.10.  GEO
  #
  #    The GEO parameter can be used to indicate global positioning
  #    information that is specific to an address.  Its value is the same as
  #    that of the GEO property (see Section 6.5.2).
  #
  #    ABNF:
  #
  #      geo-parameter = "GEO=" DQUOTE URI DQUOTE
  def param_value(:geo) do
    ignore(dquote()) |> concat(uri()) |> ignore(dquote())
  end

  # 5.11.  TZ
  #
  #    The TZ parameter can be used to indicate time zone information that
  #    is specific to an address.  Its value is the same as that of the TZ
  #    property.
  #
  #    ABNF:
  #
  #      tz-parameter = "TZ=" (param-value / DQUOTE URI DQUOTE)
  def param_value(:tz) do
    choice([
      ignore(dquote()) |> concat(utc_offset()) |> ignore(dquote()),
      text()
     ])
  end

  def param_value(:uri) do
    uri()
  end

  #    Default parameter type
  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  def param_value(_) do
    choice([
      quoted_string(),
      non_ascii(),
      safe_string()
    ])
    |> repeat
  end
end
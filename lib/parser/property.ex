defmodule VCard.Parser.Property do
  import NimbleParsec
  import VCard.Parser.Core
  import VCard.Parser.Params, except: [value: 0]

  # 6.1.3.  SOURCE
  #
  #    Purpose:  To identify the source of directory information contained
  #       in the content type.
  #
  #    Value type:  uri
  #
  #    Cardinality:  *
  #
  #    Special notes:  The SOURCE property is used to provide the means by
  #       which applications knowledgable in the given directory service
  #       protocol can obtain additional or more up-to-date information from
  #       the directory service.  It contains a URI as defined in [RFC3986]
  #       and/or other information referencing the vCard to which the
  #       information pertains.  When directory information is available
  #       from more than one source, the sending entity can pick what it
  #       considers to be the best source, or multiple SOURCE properties can
  #       be included.
  #
  #    ABNF:
  #
  #      SOURCE-param = "VALUE=uri" / pid-param / pref-param / altid-param
  #                   / mediatype-param / any-param
  #      SOURCE-value = URI
  #
  #    Examples:
  #
  #      SOURCE:ldap://ldap.example.com/cn=Babs%20Jensen,%20o=Babsco,%20c=US
  def source do
    optional(params([:value, :pid, :pref, :altid, :mediatype, :any]))
    |> ignore(colon())
    |> concat(text())
    |> unwrap_and_tag(:value)
  end

  # 6.2.1.  FN
  #
  #    Purpose:  To specify the formatted text corresponding to the name of
  #       the object the vCard represents.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  1*
  #
  #    Special notes:  This property is based on the semantics of the X.520
  #       Common Name attribute [CCITT.X520.1988].  The property MUST be
  #       present in the vCard object.
  #
  #    ABNF:
  #
  #      FN-param = "VALUE=text" / type-param / language-param / altid-param
  #               / pid-param / pref-param / any-param
  #      FN-value = text
  #
  #    Example:
  #
  #          FN:Mr. John Q. Public\, Esq.
  def fn_ do
    optional(params([:value, :type, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.2.2.  N
  #
  #    Purpose:  To specify the components of the name of the object the
  #       vCard represents.
  #
  #    Value type:  A single structured text value.  Each component can have
  #       multiple values.
  #
  #    Cardinality:  *1
  #
  #    Special note:  The structured property value corresponds, in
  #       sequence, to the Family Names (also known as surnames), Given
  #       Names, Additional Names, Honorific Prefixes, and Honorific
  #       Suffixes.  The text components are separated by the SEMICOLON
  #       character (U+003B).  Individual text components can include
  #       multiple text values separated by the COMMA character (U+002C).
  #       This property is based on the semantics of the X.520 individual
  #       name attributes [CCITT.X520.1988].  The property SHOULD be present
  #       in the vCard object when the name of the object the vCard
  #       represents follows the X.520 model.
  #
  #       The SORT-AS parameter MAY be applied to this property.
  #
  #    ABNF:
  #
  #      N-param = "VALUE=text" / sort-as-param / language-param
  #              / altid-param / any-param
  #      N-value = list-component 4(";" list-component)
  #
  #    Examples:
  #
  #              N:Public;John;Quinlan;Mr.;Esq.
  #
  #              N:Stevenson;John;Philip,Paul;Dr.;Jr.,M.D.,A.C.P.
  def n do
    optional(params([:value, :sort_as, :language, :altid, :any]))
    |> ignore(colon())
    |> concat(list_component() |> tag(:value))
  end

  # 6.2.3.  NICKNAME
  #
  #    Purpose:  To specify the text corresponding to the nickname of the
  #       object the vCard represents.
  #
  #    Value type:  One or more text values separated by a COMMA character
  #       (U+002C).
  #
  #    Cardinality:  *
  #
  #    Special note:  The nickname is the descriptive name given instead of
  #       or in addition to the one belonging to the object the vCard
  #       represents.  It can also be used to specify a familiar form of a
  #       proper name specified by the FN or N properties.
  #
  #    ABNF:
  #
  #      NICKNAME-param = "VALUE=text" / type-param / language-param
  #                     / altid-param / pid-param / pref-param / any-param
  #      NICKNAME-value = text-list
  #
  #    Examples:
  #
  #              NICKNAME:Robbie
  #
  #              NICKNAME:Jim,Jimmie
  #
  #              NICKNAME;TYPE=work:Boss
  def nickname do
    optional(params([:value, :type, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text_list() |> tag(:value))
  end

  # 6.4.1.  TEL
  #
  #    Purpose:  To specify the telephone number for telephony communication
  #       with the object the vCard represents.
  #
  #    Value type:  By default, it is a single free-form text value (for
  #       backward compatibility with vCard 3), but it SHOULD be reset to a
  #       URI value.  It is expected that the URI scheme will be "tel", as
  #       specified in [RFC3966], but other schemes MAY be used.
  #
  #    Cardinality:  *
  #
  #    Special notes:  This property is based on the X.520 Telephone Number
  #       attribute [CCITT.X520.1988].
  #
  #       The property can include the "PREF" parameter to indicate a
  #       preferred-use telephone number.
  #
  #       The property can include the parameter "TYPE" to specify intended
  #       use for the telephone number.  The predefined values for the TYPE
  #       parameter are:
  #
  #    +-----------+-------------------------------------------------------+
  #    | Value     | Description                                           |
  #    +-----------+-------------------------------------------------------+
  #    | text      | Indicates that the telephone number supports text     |
  #    |           | messages (SMS).                                       |
  #    | voice     | Indicates a voice telephone number.                   |
  #    | fax       | Indicates a facsimile telephone number.               |
  #    | cell      | Indicates a cellular or mobile telephone number.      |
  #    | video     | Indicates a video conferencing telephone number.      |
  #    | pager     | Indicates a paging device telephone number.           |
  #    | textphone | Indicates a telecommunication device for people with  |
  #    |           | hearing or speech difficulties.                       |
  #    +-----------+-------------------------------------------------------+
  #
  #       The default type is "voice".  These type parameter values can be
  #       specified as a parameter list (e.g., TYPE=text;TYPE=voice) or as a
  #       value list (e.g., TYPE="text,voice").  The default can be
  #       overridden to another set of values by specifying one or more
  #       alternate values.  For example, the default TYPE of "voice" can be
  #       reset to a VOICE and FAX telephone number by the value list
  #       TYPE="voice,fax".
  #
  #       If this property's value is a URI that can also be used for
  #       instant messaging, the IMPP (Section 6.4.3) property SHOULD be
  #       used in addition to this property.
  #
  #    ABNF:
  #
  #      TEL-param = TEL-text-param / TEL-uri-param
  #      TEL-value = TEL-text-value / TEL-uri-value
  #        ; Value and parameter MUST match.
  #
  #      TEL-text-param = "VALUE=text"
  #      TEL-text-value = text
  #
  #      TEL-uri-param = "VALUE=uri" / mediatype-param
  #      TEL-uri-value = URI
  #
  #      TEL-param =/ type-param / pid-param / pref-param / altid-param
  #                 / any-param
  #
  #      type-param-tel = "text" / "voice" / "fax" / "cell" / "video"
  #                     / "pager" / "textphone" / iana-token / x-name
  #        ; type-param-tel MUST NOT be used with a property other than TEL.
  #
  #    Example:
  #
  #      TEL;VALUE=uri;PREF=1;TYPE="voice,home":tel:+1-555-555-5555;ext=5555
  #      TEL;VALUE=uri;TYPE=home:tel:+33-01-23-45-67
  def tel do
    optional(params([:value, :type, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.4.2.  EMAIL
  #
  #    Purpose:  To specify the electronic mail address for communication
  #       with the object the vCard represents.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The property can include tye "PREF" parameter to
  #       indicate a preferred-use email address when more than one is
  #       specified.
  #
  #       Even though the value is free-form UTF-8 text, it is likely to be
  #       interpreted by a Mail User Agent (MUA) as an "addr-spec", as
  #       defined in [RFC5322], Section 3.4.1.  Readers should also be aware
  #       of the current work toward internationalized email addresses
  #       [RFC5335bis].
  #
  #    ABNF:
  #
  #      EMAIL-param = "VALUE=text" / pid-param / pref-param / type-param
  #                  / altid-param / any-param
  #      EMAIL-value = text
  #
  #    Example:
  #
  #            EMAIL;TYPE=work:jqpublic@xyz.example.com
  #
  #            EMAIL;PREF=1:jane_doe@example.com
  def email do
    optional(params([:value, :type, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.7.6.  UID
  #
  #    Purpose:  To specify a value that represents a globally unique
  #       identifier corresponding to the entity associated with the vCard.
  #
  #    Value type:  A single URI value.  It MAY also be reset to free-form
  #       text.
  #
  #    Cardinality:  *1
  #
  #    Special notes:  This property is used to uniquely identify the object
  #       that the vCard represents.  The "uuid" URN namespace defined in
  #       [RFC4122] is particularly well suited to this task, but other URI
  #       schemes MAY be used.  Free-form text MAY also be used.
  #
  #    ABNF:
  #
  #      UID-param = UID-uri-param / UID-text-param
  #      UID-value = UID-uri-value / UID-text-value
  #        ; Value and parameter MUST match.
  #
  #      UID-uri-param = "VALUE=uri"
  #      UID-uri-value = URI
  #
  #      UID-text-param = "VALUE=text"
  #      UID-text-value = text
  #
  #      UID-param =/ any-param
  #
  #    Example:
  #
  #            UID:urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6
  def uid do
    optional(params([:value]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.7.7.  CLIENTPIDMAP
  #
  #    Purpose:  To give a global meaning to a local PID source identifier.
  #
  #    Value type:  A semicolon-separated pair of values.  The first field
  #       is a small integer corresponding to the second field of a PID
  #       parameter instance.  The second field is a URI.  The "uuid" URN
  #       namespace defined in [RFC4122] is particularly well suited to this
  #       task, but other URI schemes MAY be used.
  #
  #    Cardinality:  *
  #
  #    Special notes:  PID source identifiers (the source identifier is the
  #       second field in a PID parameter instance) are small integers that
  #       only have significance within the scope of a single vCard
  #       instance.  Each distinct source identifier present in a vCard MUST
  #       have an associated CLIENTPIDMAP.  See Section 7 for more details
  #       on the usage of CLIENTPIDMAP.
  #
  #       PID source identifiers MUST be strictly positive.  Zero is not
  #       allowed.
  #
  #       As a special exception, the PID parameter MUST NOT be applied to
  #       this property.
  #
  #    ABNF:
  #
  #      CLIENTPIDMAP-param = any-param
  #      CLIENTPIDMAP-value = 1*DIGIT ";" URI
  #
  #    Example:
  #
  #      TEL;PID=3.1,4.2;VALUE=uri:tel:+1-555-555-5555
  #      EMAIL;PID=4.1,5.2:jdoe@example.com
  #      CLIENTPIDMAP:1;urn:uuid:3df403f4-5924-4bb7-b077-3c711d9eb34b
  #      CLIENTPIDMAP:2;urn:uuid:d89c9c7a-2e1b-4832-82de-7e992d95faa5
  def clientpidmap do
    optional(params([:any]))
    |> ignore(colon())
    |> concat(integer(min: 1) |> ignore(semicolon()) |> concat(text()) |> tag(:value))
  end

  # 6.7.9.  VERSION
  #
  #    Purpose:  To specify the version of the vCard specification used to
  #       format this vCard.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  1
  #
  #    Special notes:  This property MUST be present in the vCard object,
  #       and it must appear immediately after BEGIN:VCARD.  The value MUST
  #       be "4.0" if the vCard corresponds to this specification.  Note
  #       that earlier versions of vCard allowed this property to be placed
  #       anywhere in the vCard object, or even to be absent.
  #
  #    ABNF:
  #
  #      VERSION-param = "VALUE=text" / any-param
  #      VERSION-value = "4.0"
  #
  #    Example:
  #
  #            VERSION:4.0
  def version do
    anycase_string("version")
    |> replace("version")
    |> unwrap_and_tag(:property)
    |> ignore(colon())
    |> concat(version_number())
    |> ignore(crlf())
    |> label("a version property")
    |> wrap
  end

  def version_number do
    decimal_digit()
    |> ascii_string([?.], min: 1)
    |> concat(decimal_digit())
    |> reduce({Enum, :join, []})
    |> unwrap_and_tag(:value)
    |> label("a version number")
  end

end
defmodule VCard.Parser.Property do
  import NimbleParsec
  import VCard.Parser.Core
  import VCard.Parser.Types
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

  # 6.1.4.  KIND
  #
  #    Purpose:  To specify the kind of object the vCard represents.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *1
  #
  #    Special notes:  The value may be one of the following:
  #
  #       "individual"  for a vCard representing a single person or entity.
  #          This is the default kind of vCard.
  #
  #       "group"  for a vCard representing a group of persons or entities.
  #          The group's member entities can be other vCards or other types
  #          of entities, such as email addresses or web sites.  A group
  #          vCard will usually contain MEMBER properties to specify the
  #          members of the group, but it is not required to.  A group vCard
  #          without MEMBER properties can be considered an abstract
  #          grouping, or one whose members are known empirically (perhaps
  #          "IETF Participants" or "Republican U.S. Senators").
  #
  #          All properties in a group vCard apply to the group as a whole,
  #          and not to any particular MEMBER.  For example, an EMAIL
  #          property might specify the address of a mailing list associated
  #          with the group, and an IMPP property might refer to a group
  #          chat room.
  #
  #       "org"  for a vCard representing an organization.  An organization
  #          vCard will not (in fact, MUST NOT) contain MEMBER properties,
  #          and so these are something of a cross between "individual" and
  #          "group".  An organization is a single entity, but not a person.
  #          It might represent a business or government, a department or
  #          division within a business or government, a club, an
  #          association, or the like.
  #
  #          All properties in an organization vCard apply to the
  #          organization as a whole, as is the case with a group vCard.
  #          For example, an EMAIL property might specify the address of a
  #          contact point for the organization.
  #
  #       "location"  for a named geographical place.  A location vCard will
  #          usually contain a GEO property, but it is not required to.  A
  #          location vCard without a GEO property can be considered an
  #          abstract location, or one whose definition is known empirically
  #          (perhaps "New England" or "The Seashore").
  #
  #          All properties in a location vCard apply to the location
  #          itself, and not with any entity that might exist at that
  #          location.  For example, in a vCard for an office building, an
  #          ADR property might give the mailing address for the building,
  #          and a TEL property might specify the telephone number of the
  #          receptionist.
  #
  #       An x-name.  vCards MAY include private or experimental values for
  #          KIND.  Remember that x-name values are not intended for general
  #          use and are unlikely to interoperate.
  #
  #       An iana-token.  Additional values may be registered with IANA (see
  #          Section 10.3.4).  A new value's specification document MUST
  #          specify which properties make sense for that new kind of vCard
  #          and which do not.
  #
  #       Implementations MUST support the specific string values defined
  #       above.  If this property is absent, "individual" MUST be assumed
  #       as the default.  If this property is present but the
  #       implementation does not understand its value (the value is an
  #       x-name or iana-token that the implementation does not support),
  #       the implementation SHOULD act in a neutral way, which usually
  #       means treating the vCard as though its kind were "individual".
  #       The presence of MEMBER properties MAY, however, be taken as an
  #       indication that the unknown kind is an extension of "group".
  #
  #       Clients often need to visually distinguish contacts based on what
  #       they represent, and the KIND property provides a direct way for
  #       them to do so.  For example, when displaying contacts in a list,
  #       an icon could be displayed next to each one, using distinctive
  #       icons for the different kinds; a client might use an outline of a
  #       single person to represent an "individual", an outline of multiple
  #       people to represent a "group", and so on.  Alternatively, or in
  #       addition, a client might choose to segregate different kinds of
  #       vCards to different panes, tabs, or selections in the user
  #       interface.
  #
  #       Some clients might also make functional distinctions among the
  #       kinds, ignoring "location" vCards for some purposes and
  #       considering only "location" vCards for others.
  #
  #       When designing those sorts of visual and functional distinctions,
  #       client implementations have to decide how to fit unsupported kinds
  #       into the scheme.  What icon is used for them?  The one for
  #       "individual"?  A unique one, such as an icon of a question mark?
  #       Which tab do they go into?  It is beyond the scope of this
  #       specification to answer these questions, but these are things
  #       implementers need to consider.
  #
  #    ABNF:
  #
  #      KIND-param = "VALUE=text" / any-param
  #      KIND-value = "individual" / "group" / "org" / "location"
  #                 / iana-token / x-name
  #
  #    Example:
  #
  #       This represents someone named Jane Doe working in the marketing
  #       department of the North American division of ABC Inc.
  #
  #          BEGIN:VCARD
  #          VERSION:4.0
  #          KIND:individual
  #          FN:Jane Doe
  #          ORG:ABC\, Inc.;North American Division;Marketing
  #          END:VCARD
  #
  #    This represents the department itself, commonly known as ABC
  #    Marketing.
  #
  #          BEGIN:VCARD
  #          VERSION:4.0
  #          KIND:org
  #          FN:ABC Marketing
  #          ORG:ABC\, Inc.;North American Division;Marketing
  #          END:VCARD
  def kind do
    optional(params([:value, :any]))
    |> ignore(colon())
    |> concat(choice([
        anycase_string("individual"),
        anycase_string("group"),
        anycase_string("org"),
        anycase_string("location"),
        x_name()
     ]) |> unwrap_and_tag(:value) |> label("a individual, group, org, location or an x- name"))
  end

  # 6.1.5.  XML
  #
  #    Purpose:  To include extended XML-encoded vCard data in a plain
  #       vCard.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The content of this property is a single XML 1.0
  #       [W3C.REC-xml-20081126] element whose namespace MUST be explicitly
  #       specified using the xmlns attribute and MUST NOT be the vCard 4
  #       namespace ("urn:ietf:params:xml:ns:vcard-4.0").  (This implies
  #       that it cannot duplicate a standard vCard property.)  The element
  #       is to be interpreted as if it was contained in a <vcard> element,
  #       as defined in [RFC6351].
  #
  #       The fragment is subject to normal line folding and escaping, i.e.,
  #       replace all backslashes with "\\", then replace all newlines with
  #       "\n", then fold long lines.
  #
  #       Support for this property is OPTIONAL, but implementations of this
  #       specification MUST preserve instances of this property when
  #       propagating vCards.
  #
  #       See [RFC6351] for more information on the intended use of this
  #       property.
  #
  #    ABNF:
  #
  #      XML-param = "VALUE=text" / altid-param
  #      XML-value = text
  def xml do
    optional(params([:value, :altid]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
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

  # 6.2.4.  PHOTO
  #
  #    Purpose:  To specify an image or photograph information that
  #       annotates some aspect of the object the vCard represents.
  #
  #    Value type:  A single URI.
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      PHOTO-param = "VALUE=uri" / altid-param / type-param
  #                  / mediatype-param / pref-param / pid-param / any-param
  #      PHOTO-value = URI
  #
  #    Examples:
  #
  #        PHOTO:http://www.example.com/pub/photos/jqpublic.gif
  #
  #        PHOTO:data:image/jpeg;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhv
  #         AQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bm
  #         ljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0
  #         <...remainder of base64-encoded data...>
  def photo do
    optional(params([:value, :type, :altid, :pid, :pref, :mediatype, :any]))
    |> ignore(colon())
    |> concat(text_list() |> tag(:value))
  end

  # 6.2.5.  BDAY
  #
  #    Purpose:  To specify the birth date of the object the vCard
  #       represents.
  #
  #    Value type:  The default is a single date-and-or-time value.  It can
  #       also be reset to a single text value.
  #
  #    Cardinality:  *1
  #
  #    ABNF:
  #
  #      BDAY-param = BDAY-param-date / BDAY-param-text
  #      BDAY-value = date-and-or-time / text
  #        ; Value and parameter MUST match.
  #
  #      BDAY-param-date = "VALUE=date-and-or-time"
  #      BDAY-param-text = "VALUE=text" / language-param
  #
  #      BDAY-param =/ altid-param / calscale-param / any-param
  #        ; calscale-param can only be present when BDAY-value is
  #        ; date-and-or-time and actually contains a date or date-time.
  #
  #    Examples:
  #
  #              BDAY:19960415
  #              BDAY:--0415
  #              BDAY;19531015T231000Z
  #              BDAY;VALUE=text:circa 1800
  def bday do
    optional(params([:value, :altid, :calscale, :any]))
    |> ignore(colon())
    |> concat(date() |> tag(:value))
  end

  # 6.2.6.  ANNIVERSARY
  #
  #    Purpose:  The date of marriage, or equivalent, of the object the
  #       vCard represents.
  #
  #    Value type:  The default is a single date-and-or-time value.  It can
  #       also be reset to a single text value.
  #
  #    Cardinality:  *1
  #
  #    ABNF:
  #
  #      ANNIVERSARY-param = "VALUE=" ("date-and-or-time" / "text")
  #      ANNIVERSARY-value = date-and-or-time / text
  #        ; Value and parameter MUST match.
  #
  #      ANNIVERSARY-param =/ altid-param / calscale-param / any-param
  #        ; calscale-param can only be present when ANNIVERSARY-value is
  #        ; date-and-or-time and actually contains a date or date-time.
  #
  #    Examples:
  #
  #              ANNIVERSARY:19960415
  def anniversary do
    optional(params([:value, :altid, :calscale, :any]))
    |> ignore(colon())
    |> concat(date_and_or_time() |> tag(:value))
  end

  # 6.2.7.  GENDER
  #
  #    Purpose:  To specify the components of the sex and gender identity of
  #       the object the vCard represents.
  #
  #    Value type:  A single structured value with two components.  Each
  #       component has a single text value.
  #
  #    Cardinality:  *1
  #
  #    Special notes:  The components correspond, in sequence, to the sex
  #       (biological), and gender identity.  Each component is optional.
  #
  #       Sex component:  A single letter.  M stands for "male", F stands
  #          for "female", O stands for "other", N stands for "none or not
  #          applicable", U stands for "unknown".
  #
  #       Gender identity component:  Free-form text.
  #
  #    ABNF:
  #
  #                    GENDER-param = "VALUE=text" / any-param
  #                    GENDER-value = sex [";" text]
  #
  #                    sex = "" / "M" / "F" / "O" / "N" / "U"
  #
  #    Examples:
  #
  #      GENDER:M
  #      GENDER:F
  #      GENDER:M;Fellow
  #      GENDER:F;grrrl
  #      GENDER:O;intersex
  #      GENDER:;it's complicated
  def gender do
    optional(params([:value, :any]))
    |> ignore(colon())
    |> concat(sex()
    |> concat(gender_identity())
    |> tag(:value))
  end

  def sex do
    choice([
      anycase_string("m"),
      anycase_string("f"),
      anycase_string("o"),
      anycase_string("n"),
      anycase_string("u"),
      lookahead(:default_nil)
    ])
  end

  def gender_identity do
    choice([
      ignore(semicolon()) |> concat(text()),
      lookahead(:default_nil)
    ])
  end

  # 6.3.1.  ADR
  #
  #    Purpose:  To specify the components of the delivery address for the
  #       vCard object.
  #
  #    Value type:  A single structured text value, separated by the
  #       SEMICOLON character (U+003B).
  #
  #    Cardinality:  *
  #
  #    Special notes:  The structured type value consists of a sequence of
  #       address components.  The component values MUST be specified in
  #       their corresponding position.  The structured type value
  #       corresponds, in sequence, to
  #          the post office box;
  #          the extended address (e.g., apartment or suite number);
  #          the street address;
  #          the locality (e.g., city);
  #          the region (e.g., state or province);
  #          the postal code;
  #          the country name (full name in the language specified in
  #          Section 5.1).
  #
  #       When a component value is missing, the associated component
  #       separator MUST still be specified.
  #
  #       Experience with vCard 3 has shown that the first two components
  #       (post office box and extended address) are plagued with many
  #       interoperability issues.  To ensure maximal interoperability,
  #       their values SHOULD be empty.
  #
  #       The text components are separated by the SEMICOLON character
  #       (U+003B).  Where it makes semantic sense, individual text
  #       components can include multiple text values (e.g., a "street"
  #       component with multiple lines) separated by the COMMA character
  #       (U+002C).
  #
  #       The property can include the "PREF" parameter to indicate the
  #       preferred delivery address when more than one address is
  #       specified.
  #
  #       The GEO and TZ parameters MAY be used with this property.
  #
  #       The property can also include a "LABEL" parameter to present a
  #       delivery address label for the address.  Its value is a plain-text
  #       string representing the formatted address.  Newlines are encoded
  #       as \n, as they are for property values.
  #
  #    ABNF:
  #
  #      label-param = "LABEL=" param-value
  #
  #      ADR-param = "VALUE=text" / label-param / language-param
  #                / geo-parameter / tz-parameter / altid-param / pid-param
  #                / pref-param / type-param / any-param
  #
  #      ADR-value = ADR-component-pobox ";" ADR-component-ext ";"
  #                  ADR-component-street ";" ADR-component-locality ";"
  #                  ADR-component-region ";" ADR-component-code ";"
  #                  ADR-component-country
  #      ADR-component-pobox    = list-component
  #      ADR-component-ext      = list-component
  #      ADR-component-street   = list-component
  #      ADR-component-locality = list-component
  #      ADR-component-region   = list-component
  #      ADR-component-code     = list-component
  #      ADR-component-country  = list-component
  #
  #    Example: In this example, the post office box and the extended
  #    address are absent.
  #
  #      ADR;GEO="geo:12.3457,78.910";LABEL="Mr. John Q. Public, Esq.\n
  #       Mail Drop: TNE QB\n123 Main Street\nAny Town, CA  91921-1234\n
  #       U.S.A.":;;123 Main Street;Any Town;CA;91921-1234;U.S.A.
  def adr do
    optional(params([:value, :label, :language, :geo, :tz, :altid, :pid, :pref, :type, :any]))
    |> ignore(colon())
    |> concat(list_component() |> tag(:value))
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

  # 6.4.3.  IMPP
  #
  #    Purpose:  To specify the URI for instant messaging and presence
  #       protocol communications with the object the vCard represents.
  #
  #    Value type:  A single URI.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The property may include the "PREF" parameter to
  #       indicate that this is a preferred address and has the same
  #       semantics as the "PREF" parameter in a TEL property.
  #
  #
  #
  # Perreault                    Standards Track                   [Page 36]
  #
  # RFC 6350                          vCard                      August 2011
  #
  #
  #       If this property's value is a URI that can be used for voice
  #       and/or video, the TEL property (Section 6.4.1) SHOULD be used in
  #       addition to this property.
  #
  #       This property is adapted from [RFC4770], which is made obsolete by
  #       this document.
  #
  #    ABNF:
  #
  #      IMPP-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                 / mediatype-param / altid-param / any-param
  #      IMPP-value = URI
  #
  #    Example:
  #
  #        IMPP;PREF=1:xmpp:alice@example.com
  #
  def impp do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.4.4.  LANG
  #
  #    Purpose:  To specify the language(s) that may be used for contacting
  #       the entity associated with the vCard.
  #
  #    Value type:  A single language-tag value.
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      LANG-param = "VALUE=language-tag" / pid-param / pref-param
  #                 / altid-param / type-param / any-param
  #      LANG-value = Language-Tag
  #
  #    Example:
  #
  #        LANG;TYPE=work;PREF=1:en
  #        LANG;TYPE=work;PREF=2:fr
  #        LANG;TYPE=home:fr
  def lang do
    optional(params([:value, :type, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.5.1.  TZ
  #
  #    Purpose:  To specify information related to the time zone of the
  #       object the vCard represents.
  #
  #    Value type:  The default is a single text value.  It can also be
  #       reset to a single URI or utc-offset value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  It is expected that names from the public-domain
  #       Olson database [TZ-DB] will be used, but this is not a
  #       restriction.  See also [IANA-TZ].
  #
  #       Efforts are currently being directed at creating a standard URI
  #       scheme for expressing time zone information.  Usage of such a
  #       scheme would ensure a high level of interoperability between
  #       implementations that support it.
  #
  #       Note that utc-offset values SHOULD NOT be used because the UTC
  #       offset varies with time -- not just because of the usual daylight
  #       saving time shifts that occur in may regions, but often entire
  #       regions will "re-base" their overall offset.  The actual offset
  #       may be +/- 1 hour (or perhaps a little more) than the one given.
  #
  #    ABNF:
  #
  #      TZ-param = "VALUE=" ("text" / "uri" / "utc-offset")
  #      TZ-value = text / URI / utc-offset
  #        ; Value and parameter MUST match.
  #
  #      TZ-param =/ altid-param / pid-param / pref-param / type-param
  #                / mediatype-param / any-param
  #
  #    Examples:
  #
  #      TZ:Raleigh/North America
  #
  #      TZ;VALUE=utc-offset:-0500
  #        ; Note: utc-offset format is NOT RECOMMENDED.
  def tz do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(choice([
        utc_offset() |> tag(:value),
        text() |> unwrap_and_tag(:value)
       ])
    )
  end

  # 6.5.2.  GEO
  #
  #    Purpose:  To specify information related to the global positioning of
  #       the object the vCard represents.
  #
  #    Value type:  A single URI.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The "geo" URI scheme [RFC5870] is particularly well
  #       suited for this property, but other schemes MAY be used.
  #
  #    ABNF:
  #
  #      GEO-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                / mediatype-param / altid-param / any-param
  #      GEO-value = URI
  #
  #    Example:
  #
  #            GEO:geo:37.386013,-122.082932
  def geo do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  # 6.6.1.  TITLE
  #
  #    Purpose:  To specify the position or job of the object the vCard
  #       represents.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  This property is based on the X.520 Title attribute
  #       [CCITT.X520.1988].
  #
  #    ABNF:
  #
  #      TITLE-param = "VALUE=text" / language-param / pid-param
  #                  / pref-param / altid-param / type-param / any-param
  #      TITLE-value = text
  #
  #    Example:
  #
  #            TITLE:Research Scientist
  def title do
    optional(params([:value, :type, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text()
    |> unwrap_and_tag(:value))
  end

  # 6.6.2.  ROLE
  #
  #    Purpose:  To specify the function or part played in a particular
  #       situation by the object the vCard represents.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  This property is based on the X.520 Business Category
  #       explanatory attribute [CCITT.X520.1988].  This property is
  #       included as an organizational type to avoid confusion with the
  #       semantics of the TITLE property and incorrect usage of that
  #       property when the semantics of this property is intended.
  #
  #    ABNF:
  #
  #      ROLE-param = "VALUE=text" / language-param / pid-param / pref-param
  #                 / type-param / altid-param / any-param
  #      ROLE-value = text
  #
  #    Example:
  #
  #            ROLE:Project Leader
  def role do
    optional(params([:value, :type, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text()
    |> unwrap_and_tag(:value))
  end

  # 6.6.3.  LOGO
  #
  #    Purpose:  To specify a graphic image of a logo associated with the
  #       object the vCard represents.
  #
  #    Value type:  A single URI.
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      LOGO-param = "VALUE=uri" / language-param / pid-param / pref-param
  #                 / type-param / mediatype-param / altid-param / any-param
  #      LOGO-value = URI
  #
  #    Examples:
  #
  #      LOGO:http://www.example.com/pub/logos/abccorp.jpg
  #
  #      LOGO:data:image/jpeg;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvc
  #       AQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bm
  #       ljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0
  #       <...the remainder of base64-encoded data...>
  def logo do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  # 6.6.4.  ORG
  #
  #    Purpose:  To specify the organizational name and units associated
  #       with the vCard.
  #
  #    Value type:  A single structured text value consisting of components
  #       separated by the SEMICOLON character (U+003B).
  #
  #    Cardinality:  *
  #
  #    Special notes:  The property is based on the X.520 Organization Name
  #       and Organization Unit attributes [CCITT.X520.1988].  The property
  #       value is a structured type consisting of the organization name,
  #       followed by zero or more levels of organizational unit names.
  #
  #       The SORT-AS parameter MAY be applied to this property.
  #
  #    ABNF:
  #
  #      ORG-param = "VALUE=text" / sort-as-param / language-param
  #                / pid-param / pref-param / altid-param / type-param
  #                / any-param
  #      ORG-value = component *(";" component)
  #
  #    Example: A property value consisting of an organizational name,
  #    organizational unit #1 name, and organizational unit #2 name.
  #
  #            ORG:ABC\, Inc.;North American Division;Marketing
  def org do
    optional(params([:value, :type, :sort_as, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(component()
    |> repeat(ignore(semicolon()) |> concat(component()))
    |> tag(:value))
  end

  # 6.6.5.  MEMBER
  #
  #    Purpose:  To include a member in the group this vCard represents.
  #
  #    Value type:  A single URI.  It MAY refer to something other than a
  #       vCard object.  For example, an email distribution list could
  #       employ the "mailto" URI scheme [RFC6068] for efficiency.
  #
  #    Cardinality:  *
  #
  #    Special notes:  This property MUST NOT be present unless the value of
  #       the KIND property is "group".
  #
  #    ABNF:
  #
  #      MEMBER-param = "VALUE=uri" / pid-param / pref-param / altid-param
  #                   / mediatype-param / any-param
  #      MEMBER-value = URI
  #
  #    Examples:
  #
  #      BEGIN:VCARD
  #      VERSION:4.0
  #      KIND:group
  #      FN:The Doe family
  #      MEMBER:urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af
  #      MEMBER:urn:uuid:b8767877-b4a1-4c70-9acc-505d3819e519
  #      END:VCARD
  #      BEGIN:VCARD
  #      VERSION:4.0
  #      FN:John Doe
  #      UID:urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af
  #      END:VCARD
  #      BEGIN:VCARD
  #      VERSION:4.0
  #      FN:Jane Doe
  #      UID:urn:uuid:b8767877-b4a1-4c70-9acc-505d3819e519
  #      END:VCARD
  #
  #      BEGIN:VCARD
  #      VERSION:4.0
  #      KIND:group
  #      FN:Funky distribution list
  #      MEMBER:mailto:subscriber1@example.com
  #      MEMBER:xmpp:subscriber2@example.com
  #      MEMBER:sip:subscriber3@example.com
  #      MEMBER:tel:+1-418-555-5555
  #      END:VCARD
  def member do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  # 6.6.6.  RELATED
  #
  #    Purpose:  To specify a relationship between another entity and the
  #       entity represented by this vCard.
  #
  #    Value type:  A single URI.  It can also be reset to a single text
  #       value.  The text value can be used to specify textual information.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The TYPE parameter MAY be used to characterize the
  #       related entity.  It contains a comma-separated list of values that
  #       are registered with IANA as described in Section 10.2.  The
  #       registry is pre-populated with the values defined in [xfn].  This
  #       document also specifies two additional values:
  #
  #       agent:  an entity who may sometimes act on behalf of the entity
  #          associated with the vCard.
  #
  #       emergency:  indicates an emergency contact
  #
  #    ABNF:
  #
  #      RELATED-param = RELATED-param-uri / RELATED-param-text
  #      RELATED-value = URI / text
  #        ; Parameter and value MUST match.
  #
  #      RELATED-param-uri = "VALUE=uri" / mediatype-param
  #      RELATED-param-text = "VALUE=text" / language-param
  #
  #      RELATED-param =/ pid-param / pref-param / altid-param / type-param
  #                     / any-param
  #
  #      type-param-related = related-type-value *("," related-type-value)
  #        ; type-param-related MUST NOT be used with a property other than
  #        ; RELATED.
  #
  #      related-type-value = "contact" / "acquaintance" / "friend" / "met"
  #                         / "co-worker" / "colleague" / "co-resident"
  #                         / "neighbor" / "child" / "parent"
  #                         / "sibling" / "spouse" / "kin" / "muse"
  #                         / "crush" / "date" / "sweetheart" / "me"
  #                         / "agent" / "emergency"
  #
  #    Examples:
  #
  #    RELATED;TYPE=friend:urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6
  #    RELATED;TYPE=contact:http://example.com/directory/jdoe.vcf
  #    RELATED;TYPE=co-worker;VALUE=text:Please contact my assistant Jane
  #     Doe for any inquiries.
  def related do
    optional(params([:value, :type, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(choice([
        uri(),
        text()
      ])
    |> unwrap_and_tag(:value))
  end

  # 6.7.1.  CATEGORIES
  #
  #    Purpose:  To specify application category information about the
  #       vCard, also known as "tags".
  #
  #    Value type:  One or more text values separated by a COMMA character
  #       (U+002C).
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      CATEGORIES-param = "VALUE=text" / pid-param / pref-param
  #                       / type-param / altid-param / any-param
  #      CATEGORIES-value = text-list
  #
  #    Example:
  #
  #            CATEGORIES:TRAVEL AGENT
  #
  #            CATEGORIES:INTERNET,IETF,INDUSTRY,INFORMATION TECHNOLOGY
  def categories do
    optional(params([:value, :type, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text_list()
    |> tag(:value))
  end

  # 6.7.2.  NOTE
  #
  #    Purpose:  To specify supplemental information or a comment that is
  #       associated with the vCard.
  #
  #    Value type:  A single text value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  The property is based on the X.520 Description
  #       attribute [CCITT.X520.1988].
  #
  #    ABNF:
  #
  #      NOTE-param = "VALUE=text" / language-param / pid-param / pref-param
  #                 / type-param / altid-param / any-param
  #      NOTE-value = text
  #
  #    Example:
  #
  #            NOTE:This fax number is operational 0800 to 1715
  #              EST\, Mon-Fri.
  def note do
    optional(params([:value, :type, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(text()
    |> unwrap_and_tag(:value))
  end

  # 6.7.3.  PRODID
  #
  #    Purpose:  To specify the identifier for the product that created the
  #       vCard object.
  #
  #    Type value:  A single text value.
  #
  #    Cardinality:  *1
  #
  #    Special notes:  Implementations SHOULD use a method such as that
  #       specified for Formal Public Identifiers in [ISO9070] or for
  #       Universal Resource Names in [RFC3406] to ensure that the text
  #       value is unique.
  #
  #    ABNF:
  #
  #      PRODID-param = "VALUE=text" / any-param
  #      PRODID-value = text
  #
  #    Example:
  #
  #            PRODID:-//ONLINE DIRECTORY//NONSGML Version 1//EN
  def prodid do
    optional(params([:value, :any]))
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
  end

  # 6.7.4.  REV
  #
  #    Purpose:  To specify revision information about the current vCard.
  #
  #    Value type:  A single timestamp value.
  #
  #    Cardinality:  *1
  #
  #    Special notes:  The value distinguishes the current revision of the
  #       information in this vCard for other renditions of the information.
  #
  #    ABNF:
  #
  #      REV-param = "VALUE=timestamp" / any-param
  #      REV-value = timestamp
  #
  #    Example:
  #
  #            REV:19951031T222710Z
  def rev do
    optional(params([:value, :any]))
    |> ignore(colon())
    |> concat(timestamp() |> tag(:value))
  end

  # 6.7.5.  SOUND
  #
  #    Purpose:  To specify a digital sound content information that
  #       annotates some aspect of the vCard.  This property is often used
  #       to specify the proper pronunciation of the name property value of
  #       the vCard.
  #
  #    Value type:  A single URI.
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      SOUND-param = "VALUE=uri" / language-param / pid-param / pref-param
  #                  / type-param / mediatype-param / altid-param
  #                  / any-param
  #      SOUND-value = URI
  #
  #    Example:
  #
  #      SOUND:CID:JOHNQPUBLIC.part8.19960229T080000.xyzMail@example.com
  #
  #      SOUND:data:audio/basic;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIh
  #       AQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bm
  #       ljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0
  #       <...the remainder of base64-encoded data...>
  def sound do
    optional(params([:value, :type, :mediatype, :language, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
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

  # 6.7.8.  URL
  #
  #    Purpose:  To specify a uniform resource locator associated with the
  #       object to which the vCard refers.  Examples for individuals
  #       include personal web sites, blogs, and social networking site
  #       identifiers.
  #
  #    Cardinality:  *
  #
  #    Value type:  A single uri value.
  #
  #    ABNF:
  #
  #      URL-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                / mediatype-param / altid-param / any-param
  #      URL-value = URI
  #
  #    Example:
  #
  #            URL:http://example.org/restaurant.french/~chezchic.html
  def url do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri() |> unwrap_and_tag(:value))
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

  # 6.8.1.  KEY
  #
  #    Purpose:  To specify a public key or authentication certificate
  #       associated with the object that the vCard represents.
  #
  #    Value type:  A single URI.  It can also be reset to a text value.
  #
  #    Cardinality:  *
  #
  #    ABNF:
  #
  #      KEY-param = KEY-uri-param / KEY-text-param
  #      KEY-value = KEY-uri-value / KEY-text-value
  #        ; Value and parameter MUST match.
  #
  #      KEY-uri-param = "VALUE=uri" / mediatype-param
  #      KEY-uri-value = URI
  #
  #      KEY-text-param = "VALUE=text"
  #      KEY-text-value = text
  #
  #      KEY-param =/ altid-param / pid-param / pref-param / type-param
  #                 / any-param
  #
  #    Examples:
  #
  #      KEY:http://www.example.com/keys/jdoe.cer
  #
  #      KEY;MEDIATYPE=application/pgp-keys:ftp://example.com/keys/jdoe
  #
  #      KEY:data:application/pgp-keys;base64,MIICajCCAdOgAwIBAgICBE
  #       UwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05l
  #       <... remainder of base64-encoded data ...>
  def key do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(choice([uri(), text()])
    |> unwrap_and_tag(:value))
  end

  # 6.9.1.  FBURL
  #
  #    Purpose:  To specify the URI for the busy time associated with the
  #       object that the vCard represents.
  #
  #    Value type:  A single URI value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  Where multiple FBURL properties are specified, the
  #       default FBURL property is indicated with the PREF parameter.  The
  #       FTP [RFC1738] or HTTP [RFC2616] type of URI points to an iCalendar
  #       [RFC5545] object associated with a snapshot of the next few weeks
  #       or months of busy time data.  If the iCalendar object is
  #       represented as a file or document, its file extension should be
  #       ".ifb".
  #
  #    ABNF:
  #
  #      FBURL-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                  / mediatype-param / altid-param / any-param
  #      FBURL-value = URI
  #
  #    Examples:
  #
  #      FBURL;PREF=1:http://www.example.com/busy/janedoe
  #      FBURL;MEDIATYPE=text/calendar:ftp://example.com/busy/project-a.ifb
  def fburl do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  # 6.9.2.  CALADRURI
  #
  #    Purpose:  To specify the calendar user address [RFC5545] to which a
  #       scheduling request [RFC5546] should be sent for the object
  #       represented by the vCard.
  #
  #    Value type:  A single URI value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  Where multiple CALADRURI properties are specified,
  #       the default CALADRURI property is indicated with the PREF
  #       parameter.
  #
  #    ABNF:
  #
  #      CALADRURI-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                      / mediatype-param / altid-param / any-param
  #      CALADRURI-value = URI
  #
  #    Example:
  #
  #      CALADRURI;PREF=1:mailto:janedoe@example.com
  #      CALADRURI:http://example.com/calendar/jdoe
  def caladruri do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  # 6.9.3.  CALURI
  #
  #    Purpose:  To specify the URI for a calendar associated with the
  #       object represented by the vCard.
  #
  #    Value type:  A single URI value.
  #
  #    Cardinality:  *
  #
  #    Special notes:  Where multiple CALURI properties are specified, the
  #       default CALURI property is indicated with the PREF parameter.  The
  #       property should contain a URI pointing to an iCalendar [RFC5545]
  #
  #       object associated with a snapshot of the user's calendar store.
  #       If the iCalendar object is represented as a file or document, its
  #       file extension should be ".ics".
  #
  #    ABNF:
  #
  #      CALURI-param = "VALUE=uri" / pid-param / pref-param / type-param
  #                   / mediatype-param / altid-param / any-param
  #      CALURI-value = URI
  #
  #    Examples:
  #
  #      CALURI;PREF=1:http://cal.example.com/calA
  #      CALURI;MEDIATYPE=text/calendar:ftp://ftp.example.com/calA.ics
  def caluri do
    optional(params([:value, :type, :mediatype, :altid, :pid, :pref, :any]))
    |> ignore(colon())
    |> concat(uri()
    |> unwrap_and_tag(:value))
  end

  def x_property do
    ascii_string([?x, ?X], min: 1)
    |> ascii_string([?-], min: 1)
    |> concat(alphanum_and_dash())
    |> reduce({Enum, :join, []})
    |> ignore(colon())
    |> concat(text() |> unwrap_and_tag(:value))
    |> label("an x- prefix property")
  end
end
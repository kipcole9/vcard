defmodule VCard.Parser.Params do
  import NimbleParsec
  import VCard.Parser.ParamValues
  import VCard.Parser.Core
  import VCard.Parser.Types

  NimbleCSV.define VCard.Parser.Params.Splitter, separator: ",", escape: "\""
  alias VCard.Parser.Params.Splitter

  @all_param_types [:language, :value, :pref, :pid, :type, :geo, :tz, :sort_as, :calscale, :encoding, :any]

  # Generates a `choice/2` parser for the desired
  # parameters
  def params(valid_params \\ @all_param_types) do
    repeat(ignore(semicolon()) |> concat(param(valid_params)))
    |> reduce(:group_params)
    |> unwrap_and_tag(:params)
  end

  #    param = language-param / value-param / pref-param / pid-param
  #          / type-param / geo-parameter / tz-parameter / sort-as-param
  #          / calscale-param / any-param
  #      ; Allowed parameters depend on property name.
  #
  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  #
  #    any-param  = (iana-token / x-name) "=" param-value *("," param-value)
  def param([valid_param]) do
    param(valid_param)
  end

  def param(valid_params) when is_list(valid_params) do
    valid_params
    |> Enum.map(&param/1)
    |> choice()
  end

  def param(valid_param) when is_atom(valid_param) do
    apply(__MODULE__, valid_param, [])
    |> ignore(equals())
    |> concat(param_value(valid_param))
    |> repeat(ignore(comma() |> concat(param_value(valid_param))))
    |> reduce(:reduce_param)
  end

  # Here follows the list of valid parameters
  # noting that not all properties support all
  # parameters
  def value do
    anycase_string("value")
  end

  def pid do
    anycase_string("pid")
  end

  def pref do
    anycase_string("pref")
  end

  def altid do
    anycase_string("altid")
  end

  def mediatype do
    anycase_string("mediatype")
  end

  def type do
    anycase_string("type")
  end

  def language do
    anycase_string("language")
  end

  def sort_as do
    anycase_string("sort_as")
  end

  def encoding do
    anycase_string("encoding")
  end

  def calscale do
    anycase_string("calscale")
  end

  def label do
    anycase_string("label")
  end

  def geo do
    anycase_string("geo")
  end

  def tz do
    anycase_string("tz")
  end

  def any do
    x_name()
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

  def split_at_commas(list) do
    Splitter.parse_enumerable(["" | list])
    |> List.flatten
  end

  def reduce_param([key | values]) do
    {String.downcase(key), unescape(values)}
  end

end
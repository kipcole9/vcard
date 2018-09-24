defmodule VCard.Parser.Params do
  import NimbleParsec
  import VCard.Parser.Core

  NimbleCSV.define VCard.Parser.Params.Splitter, separator: ",", escape: "\""
  alias VCard.Parser.Params.Splitter

  @all_param_types [:language, :value, :pref, :pid, :type, :geo, :tz, :sort_as, :calscale, :any]

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
    apply(__MODULE__, valid_param, [])
    |> ignore(equals())
    |> concat(param_value())
    |> repeat(ignore(comma() |> concat(param_value())))
    |> reduce(:reduce_param)
  end

  def param(valid_params) do
    valid_params
    |> Enum.map(fn param -> apply(__MODULE__, param, []) end)
    |> choice()
    |> ignore(equals())
    |> concat(param_value())
    |> repeat(ignore(comma() |> concat(param_value())))
    |> wrap
    |> reduce(:reduce_param)
  end

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

  #    param-value = *SAFE-CHAR / DQUOTE *QSAFE-CHAR DQUOTE
  def param_value do
    choice([
      quoted_string(),
      non_ascii(),
      safe_string()
    ])
    |> repeat
  end

  def what(rest, args, context, _, _) do
    IO.puts "Args #{inspect args}"
    IO.puts "Rest #{rest}"
    {args, context}
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

  def reduce_param([[key | values]]) do
    {String.downcase(key), values}
  end

end
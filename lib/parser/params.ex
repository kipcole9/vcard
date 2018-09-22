defmodule VCard.Parser.Params do
  import NimbleParsec
  import VCard.Parser.Core

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

  def any do
    experimental_param()
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

  @splitter Regex.compile!("(?<!\\\\)[,]")
  def split_at_commas(list) do
    list
    |> Enum.join
    |> String.split(@splitter)
  end

  def reduce_param([key, value]) do
    {String.downcase(key), value}
  end

end
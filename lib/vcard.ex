defmodule VCard do
  @type key :: atom | String.t()
  @type value :: any

  @type t :: [{key, value}]
  @type t(value) :: [{key, value}]

  @spec version(t) :: String.t()
  def version(vcard) do
    vcard
    |> get(:version)
    |> get(:value)
  end

  @spec get(t, key) :: value
  def get(vcard, key) when is_list(vcard) do
    case :lists.keyfind(key, 1, vcard) do
      {^key, value} -> value
      false -> nil
    end
  end

  @doc """
  Get first property that also matches
  the param spec. Params will be checked
  in `params` and `group`.
  """
  def get(vcard, key, params) do

  end

  @spec get_all(t, key) :: [value]
  def get_all(vcard, key) when is_list(vcard) do
    fun = fn
      {^key, val} -> {true, val}
      {_, _} -> false
    end

    :lists.filtermap(fun, vcard)
  end

  @spec count(t, key) :: non_neg_integer
  def count(vcard, key) when is_list(vcard) do
    vcard
    |> get_all(key)
    |> Enum.count
  end

  def cardinality(vcard) do
    vcard
    |> Enum.group_by(fn {property, _args} -> property end)
    |> Enum.map(fn {property, args} -> {property, Enum.count(args)} end)
  end

  def group(vcard) when is_list(vcard) do
    Enum.group_by(vcard, fn {_property, args} -> Keyword.get(args, :group) end)
  end

end

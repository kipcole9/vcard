defmodule VCard.Parser.Utils do

  def upcase(list) when is_list(list) do
    list
    |> Enum.map(&String.upcase/1)
    |> Enum.join
  end

  def downcase(list) when is_list(list) do
    list
    |> Enum.map(&String.downcase/1)
    |> Enum.join
  end

end
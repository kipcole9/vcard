defmodule VcardTest do
  use ExUnit.Case
  doctest VCard

  @number_of_examples File.ls!("test/examples") |> Enum.count

  for i <- 1..@number_of_examples do
    test "Test of example #{i}" do
      card = File.read!("test/examples/example_#{unquote(i)}.vcf")
      parsed = VCard.Parser.parse(card)
      refute match?({:error, _}, parsed)
    end
  end
end

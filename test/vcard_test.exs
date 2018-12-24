defmodule VcardTest do
  use ExUnit.Case
  doctest VCard

  for i <- 1..4 do
    test "Test of example #{i}" do
      card = File.read!("test/examples/example_#{unquote(i)}.vcf")
      parsed = VCard.Parser.parse(card)
      assert match?({:ok, _}, parsed)
    end
  end
end

defmodule VcardTest do
  use ExUnit.Case
  doctest Vcard

  describe "parsing vcards" do
    test "greets the world" do
      assert Vcard.hello() == :world
    end
  end
end

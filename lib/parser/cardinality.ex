defmodule VCard.Parser.Cardinality do
  @moduledoc false

  #  +-------------+--------------------------------------------------+
  #  | Cardinality | Meaning                                          |
  #  +-------------+--------------------------------------------------+
  #  |      1      | Exactly one instance per vCard MUST be present.  |
  #  |      *1     | Exactly one instance per vCard MAY be present.   |
  #  |      1*     | One or more instances per vCard MUST be present. |
  #  |      *      | One or more instances per vCard MAY be present.  |
  #  +-------------+--------------------------------------------------+
  #
  # Properties defined in a vCard instance may have multiple values
  # depending on the property cardinality.  The general rule for encoding
  # multi-valued properties is to simply create a new content line for
  # each value (including the property name).  However, it should be
  # noted that some value types support encoding multiple values in a
  # single content line by separating the values with a comma ",".  This
  # approach has been taken for several of the content types defined
  # below (date, time, integer, float).

  @doc false
  def cardinality_valid?(property, count) do
    valid_range = cardinality(property)
    case cardinality_valid?(property, count, valid_range) do
      true -> :ok
      false -> {:error, "Invalid cardinality for #{inspect property}. " <>
                        "Valid cardinality is #{inspect valid_range}"}
    end
  end

  @doc false
  def cardinality_valid?(property, count, [min, :infinity]) when count >= min do: true
  def cardinality_valid?(property, count, [min, max]) when count >= min and count <= max, do: true
  def cardinality_valid?(property, count, [min, max]) when count >= min and count <= max, do: false

  @doc false
  def cardinality("source"), do: [0, :infinity]
  def cardinality("kind"), do: [0, 1]
  def cardinality("fn"), do: [1, :infinity]
  def cardinality("nickname"), do: [0, :infinity]
  def cardinality("photo"), do: [0, :infinity]
  def cardinality("bday"), do: [0, 1]
  def cardinality("anniversary"), do: [0, 1]
  def cardinality("gender"), do: [0, 1]
  def cardinality("adr"), do: [0, :infinity]
  def cardinality("tel"), do: [0, :infinity]
  def cardinality("email"), do: [0, :infinity]
  def cardinality("impp"), do: [0, :infinity]
  def cardinality("lang"), do: [0, :infinity]
  def cardinality("tz"), do: [0, :infinity]
  def cardinality("geo"), do: [0, :infinity]
  def cardinality("title"), do: [0, :infinity]
  def cardinality("role"), do: [0, :infinity]
  def cardinality("logo"), do: [0, :infinity]
  def cardinality("org"), do: [0, :infinity]
  def cardinality("member"), do: [0, :infinity]
  def cardinality("related"), do: [0, :infinity]
  def cardinality("categories"), do: [0, :infinity]
  def cardinality("note"), do: [0, :infinity]
  def cardinality("prodid"), do: [0, 1]
  def cardinality("rev"), do: [0, 1]
  def cardinality("sound"), do: [0, :infinity]
  def cardinality("uid"), do: [0, 1]
  def cardinality("clientpidmap"), do: [0, :infinity]
  def cardinality("url"), do: [0, :infinity]
  def cardinality("key"), do: [0, :infinity]
  def cardinality("fburl"), do: [0, :infinity]
  def cardinality("caladruri"), do: [0, :infinity]
  def cardinality("caluri"), do: [0, :infinity]
  def cardinality("xml"), do: [0, :infinity]
  def cardinality("n"), do: [0, 1]
  def cardinality(_), do: [0, :infinity]
end
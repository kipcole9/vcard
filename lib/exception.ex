defmodule VCard.Parser.ParseError do
  @moduledoc """
  Exception raised when a vcard cannot
  be parsed (there is unparsed content).
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
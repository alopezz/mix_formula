defmodule ElixirProject.Extensions do
  def random_ascii_string(length) do
    for _a <- 1..length do
      Stream.concat(?A..?Z, ?a..?z)
      |> Enum.random
    end
    |> to_string
  end
end

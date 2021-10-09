defmodule <%= String.split(formula.name, "_") |> Enum.map(&String.capitalize/1) |> Enum.join %> do
<%= if formula.include_hello == "yes" do %>
  def hello do
    IO.puts("hello world!")
  end
<% end %>
end

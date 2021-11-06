defmodule <%= String.split(formula.name, "_") |> Enum.map(&String.capitalize/1) |> Enum.join %> do
<%= if formula.include_hello == "yes" do %>
  def hello do
    IO.puts("hello, your secret is '<%= ElixirProject.Extensions.random_ascii_string(64) %>'!")
  end
<% end %>
end

defmodule TouchFilesModifyContext do

  use MixFormula.Hook

  pre_hook "modify name", with: %{name: name} do
    {:cont, %{name: modify_name(name)}}
  end

  pre_hook "touch pre", with: context do
    File.touch("#{context.name}_pre")
  end

  def modify_name(name) do
    String.split(name, "_")
    |> Enum.reverse
    |> Enum.join("-")
  end
  
end

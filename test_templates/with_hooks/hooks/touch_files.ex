defmodule TouchFiles do

  use MixFormula.Hook

  pre_hook "touch pre" do
    File.touch("pre")
  end

  pre_hook "touch pre from context", with: context do
    File.touch("#{context.name}_pre")
  end

  post_hook "touch post" do
    File.touch("post")
  end

  post_hook "touch post from context", with: %{name: name} do
    modified_name = String.split(name, "_")
    |> Enum.reverse
    |> Enum.join("-")
    File.touch("#{modified_name}_post")
  end
  
end

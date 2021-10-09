defmodule FailingHook do

  use MixFormula.Hook

  post_hook "halt" do
    {:halt, "for no reason"}
  end
  
end

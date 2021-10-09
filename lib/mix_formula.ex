defmodule MixFormula do
  @moduledoc """
  Top level module and entry point for `MixFormula`.
  """
  alias MixFormula.Template

  @doc """
  Render the given template.
  """
  @spec render(binary(), keyword() | map()) :: {:ok | :error, binary()}
  def render(template_path, input_bindings \\ []) do
    with {:ok, template} <- Template.from_path(template_path),
         {:ok, template} <- Template.update_context(template, input_bindings),
         {:ok, gen_root} <- Template.generate(template) do
      {:ok, "Template rendered in '#{gen_root}'"}
    end
  end
end

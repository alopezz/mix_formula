defmodule MixFormula do
  @moduledoc """
  Top level module and entry point for `MixFormula`.
  """
  alias MixFormula.Template

  @doc """
  Render the given template or path to template.
  """
  @spec render(binary() | %Template{}, keyword() | map()) :: {:ok | :error, binary()}
  def render(template_or_path, input_bindings \\ [])

  def render(%Template{} = template, input_bindings) do
    with {:ok, template} <- Template.update_context(template, input_bindings),
         {:ok, gen_root} <- Template.generate(template) do
      {:ok, "Template rendered in '#{gen_root}'"}
    end
  end

  def render(template_path, input_bindings) do
    with {:ok, template} <- Template.from_path(template_path) do
      render(template, input_bindings)
    end
  end

  @doc """
  Get a template struct from a path.
  """
  @spec load_template(binary()) :: {:ok | :error, binary()}
  def load_template(template_path), do: Template.from_path(template_path)
end

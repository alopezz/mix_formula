defmodule Mix.Tasks.Formula do
  @moduledoc """
  Create a project from a project template based on EEx.

  ```
  mix formula <path/to/template> [<formula_field>=<formula_value> ...]
  ```

  A template is a folder containing at least:

  - A folder with a name containing EEx tags, which will represent the
    root of the generated project.
  - A `formula.json` file, which is a mapping from fields to default values.

  The generated project will be a copy of the template with EEx
  expressions rendered and evaluated.

  Values inside `formula.json` can also be templates, and will be rendered
  with EEx.

  Only *formula fields* defined in `formula.json` can be set with this
  invocation. Any unset field will default to the value defined on
  `formula.json`.

  """

  @shortdoc "Create a project from a template based on EEx"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    shell = Mix.shell()
    shell.error("No arguments were provided")
    shell.cmd("mix help formula")
  end

  @impl Mix.Task
  def run([template_path | args]) do
    input_bindings =
      Enum.map(args, fn arg ->
        [name, value] = String.split(arg, "=")
        {String.to_atom(name), value}
      end)

    case MixFormula.render(template_path, input_bindings) do
      {:ok, msg} -> Mix.shell().info(msg)
      {:error, msg} -> Mix.shell().error(msg)
    end
  end
end

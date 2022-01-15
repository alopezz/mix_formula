defmodule MixFormula.Template do
  alias MixFormula.{Template, Context, HookRunner}

  defstruct tree: %{}, context: %Context{}, hooks: %HookRunner{}

  def from_path(path) do
    with :ok <- load_extensions(path),
         {:ok, template_root} <- find_folder_with_tags(path),
         {:ok, context} <- load_formula_json(path),
         {:ok, hooks} <- load_hooks(path, context),
         {:ok, tree} <- build_tree(Path.join(path, template_root)) do
      {:ok,
       %Template{
         tree: tree,
         context: context,
         hooks: hooks
       }}
    end
  end

  def update_context(template, new_bindings) do
    case MixFormula.Context.update(template.context, new_bindings) do
      {:ok, context} ->
        {:ok,
         %{template | context: context, hooks: HookRunner.set_context(template.hooks, context)}}

      {:error, key} ->
        {:error,
         "The provided input parameter #{key} is not present in the template's formula.json"}
    end
  end

  def generate(template, root \\ ".") do
    with {:ok, template} <-
           Template.update_context(template, Context.resolve_templates(template.context)),
         {:error, {root_dir, message}} <-
           HookRunner.run_between_hooks(template.hooks, fn context ->
             evaluate_tree(context.bindings, template.tree)
             |> generate_from_tree(root)
           end) do
      # Clean up if we get an error with a root directory for the
      # generation; every other case just passes through
      File.rm_rf!(root_dir)
      {:error, message}
    end
  end

  def variables(template) do
    template.context.variables
  end

  # Recursively build a tree by looking at the contents of the folder
  # at path
  defp build_tree(path) do
    node = Path.basename(path)

    with {:ok, files} <- File.ls(path),
         paths <- Enum.map(files, &Path.join(path, &1)),
         {:ok, children} <- build_children_from_files(paths) do
      {:ok, {:folder, node, children}}
    end
  end

  defp build_children_from_files(files) do
    map_until_error(files, &build_child_from_path/1)
  end

  defp build_child_from_path(path) do
    if File.dir?(path) do
      build_tree(path)
    else
      with {:ok, contents} <- File.read(path) do
        {:file, Path.basename(path), contents}
      end
    end
  end

  defp evaluate_tree(bindings, {:folder, node, children}) do
    case EEx.eval_string(node, formula: bindings) do
      "" ->
        nil

      name ->
        {:folder, name,
         children
         |> Enum.map(fn child -> evaluate_tree(bindings, child) end)
         |> Enum.reject(&is_nil/1)}
    end
  end

  defp evaluate_tree(bindings, {:file, name, contents}) do
    case EEx.eval_string(name, formula: bindings) do
      "" -> nil
      name -> {:file, name, EEx.eval_string(contents, formula: bindings)}
    end
  end

  defp generate_from_tree({:folder, node, children}, root) do
    new_root = Path.join(root, node)

    with :ok <- File.mkdir(new_root),
         :ok <- each_until_error(children, fn child -> generate_from_tree(child, new_root) end) do
      {:ok, new_root}
    else
      {:error, reason} -> {:error, mkdir_error_to_string(reason, new_root)}
    end
  end

  defp generate_from_tree({:file, name, contents}, root) do
    File.write(Path.join(root, name), contents)
  end

  defp mkdir_error_to_string(reason, path) do
    case reason do
      :eacces -> "Missing search or write permissions for the parent directories of #{path}"
      :eexist -> "There is already a file or directory named #{path}"
      :enoent -> "A component of #{path} does not exist"
      :enospc -> "There is no space left on the device"
    end
  end

  # Call fun on each of the elements of enumerable, stopping early if
  # an error tuple is found. Returns the error tuple in case of error,
  # `:ok` otherwise.
  defp each_until_error(enumerable, fun) do
    Enum.find(
      enumerable,
      :ok,
      fn entry ->
        case fun.(entry) do
          {:error, _} -> true
          _ -> false
        end
      end
    )
  end

  # Map fun on each of the elements of enumerable, stopping early if
  # an error tuple is found. Returns the error tuple in case of error,
  # otherwise the equivelent result of `{:ok, Enum.map(enumerable, fun)}`,
  # with `{:ok, thing}` results automatically unwrapped to `thing`.
  defp map_until_error(enumerable, fun) do
    with {:ok, reversed_result} <-
           Enum.reduce_while(
             enumerable,
             {:ok, []},
             fn entry, acc ->
               {:ok, acc_list} = acc

               case fun.(entry) do
                 {:error, err} -> {:halt, {:error, err}}
                 {:ok, result} -> {:cont, {:ok, [result | acc_list]}}
                 result -> {:cont, {:ok, [result | acc_list]}}
               end
             end
           ) do
      {:ok, Enum.reverse(reversed_result)}
    end
  end

  # Return the name of the folder to be used as the root of the
  # rendered project
  defp find_folder_with_tags(path) do
    {:ok, files} = File.ls(path)

    Enum.find(
      files,
      fn f ->
        full_path = Path.join(path, f)
        File.dir?(full_path) and String.contains?(f, "<%") and String.contains?(f, "%>")
      end
    )
    |> case do
      nil -> {:error, "Couldn't find a proper template root"}
      folder -> {:ok, folder}
    end
  end

  defp load_formula_json(template_path) do
    with {:ok, map} <- formula_json_path(template_path) |> load_object_from_file() do
      {:ok, MixFormula.Context.new(map)}
    else
      _ -> {:error, "Couldn't find a valid 'formula.json' file in the template"}
    end
  end

  defp load_object_from_file(path) do
    with {:ok, contents} <- File.read(path) do
      Jason.decode(contents, objects: :ordered_objects)
    end
  end

  defp formula_json_path(path) do
    Path.join(path, "formula.json")
  end

  defp load_hooks(path, context) do
    try do
      MixFormula.HookRunner.new(hooks_folder(path), context)
    rescue
      Code.LoadError -> {:error, "Error while loading hooks"}
    else
      runner -> {:ok, runner}
    end
  end

  defp hooks_folder(path) do
    Path.join(path, "hooks")
  end

  defp load_extensions(path) do
    path
    |> extensions_folder()
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> require_files

    :ok
  end

  defp require_files(paths) do
    try do
      Enum.each(paths, &Code.require_file/1)
    rescue
      Code.LoadError -> :error
    else
      _ -> :ok
    end
  end

  defp extensions_folder(path) do
    Path.join(path, "extensions")
  end
end

defmodule MixFormula.HookRunner do
  @moduledoc """
  Logic for collecting modules containing hooks and running their hooks.
  """

  alias MixFormula.HookRunner

  defstruct modules: [], context: %{}

  def new(hooks_path, context) do
    %HookRunner{modules: find_modules(hooks_path), context: context}
  end

  def set_context(hook_runner, new_context) do
    %HookRunner{modules: hook_runner.modules, context: new_context}
  end

  def run_pre_hooks(hook_runner) do
    run_hooks(hook_runner, :run_pre_hooks)
  end

  def run_post_hooks(hook_runner, path) do
    File.cd!(
      path,
      fn -> run_hooks(hook_runner, :run_post_hooks) end
    )
  end

  @doc """
  Run the given function after all pre-hooks, and run post-hooks after the function if the function
  ran succesfully. The function must accept a context as argument and return {:ok, path} or {:error, reason},
  the path referring to the path where the post_hooks have to be run.
  """
  def run_between_hooks(hook_runner, fun) do
    with {:ok, context} <- HookRunner.run_pre_hooks(hook_runner),
         hook_runner <- HookRunner.set_context(hook_runner, context),
         {:ok, path} <- fun.(hook_runner.context) do
      case HookRunner.run_post_hooks(hook_runner, path) do
        {:ok, _context} -> {:ok, path}
        # Insert the path in the error to allow the caller to clean up
        {:error, reason} -> {:error, {path, reason}}
      end
    end
  end

  defp find_modules(path) do
    Path.join(path, "*.{ex,exs}")
    |> Path.wildcard()
    |> Enum.flat_map(&Code.compile_file/1)
    |> Enum.map(fn {m, _} -> m end)
  end

  defp run_hooks(hook_runner, key) do
    Stream.map(hook_runner.modules, &module_name/1)
    |> Stream.filter(fn module ->
      function_exported?(module, key, 1)
    end)
    |> Enum.reduce_while(
      {:ok, hook_runner.context},
      fn module, wrapped_context ->
        {:ok, context} = wrapped_context

        case apply(module, key, [context]) do
          {:error, reason} -> {:halt, {:error, reason}}
          {:ok, context} -> {:cont, {:ok, context}}
        end
      end
    )
  end

  defp module_name(module) do
    module.__info__(:module)
  end
end

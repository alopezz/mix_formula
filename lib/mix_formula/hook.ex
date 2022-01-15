defmodule MixFormula.Hook do
  defmacro __using__(_opts) do
    quote do
      # Register hook attributes to accumulate so that we automatically accumulate lists
      # of hooks.
      module = __MODULE__
      @before_compile MixFormula.Hook
      Module.register_attribute(module, :formula_pre_hooks, accumulate: true)
      Module.register_attribute(module, :formula_post_hooks, accumulate: true)
      import MixFormula.Hook, only: :macros
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def run_pre_hooks(context) do
        run_hooks(@formula_pre_hooks, context)
      end

      def run_post_hooks(context) do
        run_hooks(@formula_post_hooks, context)
      end

      def run_hooks(hooks, context) do
        Enum.reverse(hooks)
        |> Enum.reduce_while(context, &run_hook/2)
        |> case do
          {:error, reason} -> {:error, reason}
          context -> {:ok, context}
        end
      end

      def run_hook(name, context) do
        # This establishes the *rules* that hooks can follow to interrupt the generation
        # or modify the context.
        try do
          apply(__MODULE__, name, [context.bindings])
        rescue
          err -> {:halt, {:error, err}}
        else
          {:cont, context_update} -> {:cont, MixFormula.Context.update!(context, context_update)}
          {:halt, reason} -> {:halt, {:error, reason}}
          _ -> {:cont, context}
        end
      end
    end
  end

  def __register_pre_hook__(module, hook) do
    Module.put_attribute(module, :formula_pre_hooks, hook)
  end

  def __register_post_hook__(module, hook) do
    Module.put_attribute(module, :formula_post_hooks, hook)
  end

  defmacro pre_hook(name, do: block) do
    hook_macro_helper(name, &MixFormula.Hook.__register_pre_hook__/2, do: block)
  end

  defmacro pre_hook(name, [with: context], do: block) do
    hook_macro_helper(name, &MixFormula.Hook.__register_pre_hook__/2, with: context, do: block)
  end

  defmacro post_hook(name, do: block) do
    hook_macro_helper(name, &MixFormula.Hook.__register_post_hook__/2, do: block)
  end

  defmacro post_hook(name, [with: context], do: block) do
    hook_macro_helper(name, &MixFormula.Hook.__register_post_hook__/2, with: context, do: block)
  end

  defp hook_macro_helper(name, callback, opts \\ []) do
    name = String.to_atom(name)
    block = opts[:do]
    context = opts[:with] || quote(do: _)

    quote do
      def unquote(name)(unquote(context)), do: unquote(block)
      unquote(callback).(__MODULE__, unquote(name))
    end
  end
end

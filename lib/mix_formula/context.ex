defmodule MixFormula.Context do
  @moduledoc """
  Context and its operations. The context refers to the result of combining the bindings
  inside formula.json file with user input.
  """
  alias MixFormula.Context
  defstruct bindings: %{}

  def new(bindings \\ %{}) do
    %Context{bindings: bindings}
  end

  @doc """
  Update the context with new bindings. It doesn't allow to add new names into the bindings.
  Returns {:ok, new_context} if successfull or {:error, key} if a key in `new_bindings` is not
  available in the original context.
  """
  def update(context, new_bindings) do
    try do
      update!(context, new_bindings)
    rescue
      err in KeyError ->
        {:error, err.key}
    else
      updated_context -> {:ok, updated_context}
    end
  end

  @doc """
  Update the context with new bindings. Raises a KeyError if the new bindings contain
  keys not available in the original context.
  """
  def update!(context, new_bindings) do
    Enum.reduce(new_bindings, context.bindings, fn {key, value}, acc ->
      Map.replace!(acc, key, value)
    end)
    |> Context.new()
  end

  @doc """
  Look for templates inside bindings and resolve them.
  """
  def resolve_templates(context) do
    # TODO We know that this works for templates that refer non-template fields;
    # we should check what happens when templates refer to other templates
    Enum.map(context, fn {key, value} ->
      {key, EEx.eval_string(value, formula: context.bindings)}
    end)
    |> Enum.into(Context.new())
  end
end

defimpl Enumerable, for: MixFormula.Context do
  # Just delegate everything to the internal `bindings` field
  def count(context) do
    Enumerable.Map.count(context.bindings)
  end

  def member?(context, element) do
    Enumerable.Map.member?(context.bindings, element)
  end

  def reduce(context, acc, fun) do
    Enumerable.Map.reduce(context.bindings, acc, fun)
  end

  def slice(context) do
    Enumerable.Map.slice(context)
  end
end

defimpl Collectable, for: MixFormula.Context do
  def into(context) do
    # Use Map's implementation on the bindings
    {acc, map_fun} = Collectable.Map.into(context.bindings)

    fun = fn
      map_acc, :done -> MixFormula.Context.new(map_acc)
      map_acc, cmd -> map_fun.(map_acc, cmd)
    end

    {acc, fun}
  end
end

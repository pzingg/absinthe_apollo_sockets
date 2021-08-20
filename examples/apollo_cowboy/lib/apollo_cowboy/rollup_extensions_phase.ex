defmodule ApolloCowboyExample.RollupExtensionsPhase do
  @moduledoc """
  Post-Document.Result Absinthe phase that rolls up "extensions" data attached to
  a query field into the top level result.

  A phase takes an Absinthe.Blueprint document and returns another blueprint document.

  Must be used in combination with Absinthe middleware that adds "extensions" to a schema
  query object. For an example, see the `AddExtensions` middleware in the
  `ApolloCowboyExample.Schema` module.

  Defines an `install/2` function that inserts this phase into an Absinthe pipeline
  prior to execution. The `install/2` function can be passed as the `:pipeline` option
  when setting up an `AbsintheMessageHandler`.  See the example in the application `start/2`
  function.
  """

  @behaviour Absinthe.Phase

  @impl true
  @doc """
  If the excution result has a single field, and the field has a non-empty map at
  the `:extensions` key, add that map as the `:extensions` item in the
  top level result.

  See https://github.com/absinthe-graphql/absinthe/blob/master/test/absinthe/extensions_test.exs
  """
  def run(blueprint, _) do
    extensions = get_ext(blueprint.execution.result.fields)
    result =
      if is_nil(extensions) || Enum.empty?(extensions) do
        blueprint.result
      else
        Map.put(blueprint.result, :extensions, extensions)
      end
    {:ok, %{blueprint | result: result}}
  end

  @doc """
  Add this phase after the `Document.Result` phase.
  """
  def install(pipeline, _opts) do
    Absinthe.Pipeline.insert_after(pipeline, Absinthe.Phase.Document.Result, __MODULE__)
  end

  defp get_ext([field]), do: Map.get(field, :extensions)
  defp get_ext(_), do: nil
end

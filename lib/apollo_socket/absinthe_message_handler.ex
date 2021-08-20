defmodule ApolloSocket.AbsintheMessageHandler do
  @moduledoc """
  A module implementing the `ApolloSocket.MessageHandler` behaviour,
  responsible for running Absinthe on a GraphQL document.

  Options for the `init/1` callback:

  `:schema`, required - An Absinthe.Schema module defining the types for documents
  `:pubsub`, required - An Absinthe.PubSub module that will handle GraphQL subscriptions
  `:broker_sup`, required - A DynamicSupervisor module that will start and supervise
    the DataBroker workers that process the subscriptions
  `:pipeline`, optional - A function, MFA, or module with an `install/2` function
    that creates a custom pipeline for pre- or post-processing
    GraphQL responses generated by Absinthe.

  The `:pipeline` function, if specified, will receive two arguments, the
  pre-built pipeline created by `Absinthe.Pipeline.for_document/2`, and
  a keyword list of the other options (`:schema`, etc.) set by the user.
  """
  use ApolloSocket.MessageHandler

  alias ApolloSocket.OperationMessage
  require Logger

  @impl ApolloSocket.MessageHandler
  def init(opts) when is_list(opts) do
    {known_opts, _} = Keyword.split(opts, [:schema, :pipeline, :pubsub, :broker_sup])
    Enum.into(known_opts, %{})
  end

  @impl ApolloSocket.MessageHandler
  def handle_start(apollo_socket, operation_id, operation_name, graphql_doc, variables, opts) do
    absinthe_opts = [context: %{pubsub: opts[:pubsub]}]
    |> add_operation_name(operation_name)
    |> add_variables(variables)

    schema = opts[:schema]
    result =
      if opts[:pipeline] do
        pipeline =
          schema
          |> Absinthe.Pipeline.for_document(absinthe_opts)
          |> modify_pipeline(opts[:pipeline], Map.delete(opts, :pipeline))

        case Absinthe.Pipeline.run(graphql_doc, pipeline) do
          {:ok, %{result: result}, _phases} -> {:ok, result}
          {:error, reason, _phases} -> {:error, reason}
        end
      else
        Absinthe.run(graphql_doc, schema, absinthe_opts)
      end

    Logger.debug("Query result #{inspect result}")

    case result do
      {:ok, %{"subscribed" => absinthe_subscription_id}} ->

        {:ok, _} = DynamicSupervisor.start_child(opts[:broker_sup],
          data_broker_child_spec(
            opts[:pubsub],
            absinthe_subscription_id,
            operation_id,
            apollo_socket
            ))
        {:ok, opts}

      {:ok, query_response } ->
        {:reply, messages_for_result(operation_id, query_response), opts}
    end
  end

  defp data_broker_child_spec(pubsub, absinthe_subscription_id, operation_id, socket) do
    %{
      type: :worker,
      id: absinthe_subscription_id,
      restart: :temporary,
      start: { ApolloSocket.DataBroker, :start_link, [[
          pubsub: pubsub,
          absinthe_id: absinthe_subscription_id,
          operation_id: operation_id,
          apollo_socket: socket
        ]]
      }
    }
  end

  defp add_operation_name(opts, nil), do: opts
  defp add_operation_name(opts, name), do: Keyword.put(opts, :operation_name, name)

  defp add_variables(opts, nil), do: opts
  defp add_variables(opts, variables), do: Keyword.put(opts, :variables, variables)

  defp messages_for_result(operation_id, query_response) when is_map(query_response) do
    [
      OperationMessage.new_data(operation_id, query_response),
      OperationMessage.new_complete(operation_id)
    ]
  end

  defp modify_pipeline(pipeline, func, opts) when is_function(func) do
    func.(pipeline, opts)
  end

  defp modify_pipeline(pipeline, module, opts) when is_atom(module) do
    module.install(pipeline, opts)
  end

  defp modify_pipeline(pipeline, {m, f, args}, opts) when is_atom(m) and is_atom(f) and is_list(args) do
    apply(m, f, [pipeline, opts] ++ args)
  end

  defp modify_pipeline(pipeline, _func, _opts) do
    Logger.warn("invalid pipeline option, ignored")
    pipeline
  end
end

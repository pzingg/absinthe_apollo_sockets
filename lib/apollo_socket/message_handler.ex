defmodule ApolloSocket.MessageHandler do
  @moduledoc """
  An interface for managing an `ApolloSocket` websocket.

  Callbacks are invoked when the HTTP connection is upgraded to Websocket, and when the socket receives
  connection init, subscription start and stop messages.
  """
  require Logger

  alias ApolloSocket.OperationMessage

  @type apollo_socket :: %ApolloSocket{}
  @type message_handler_opts :: any()
  @type message_handler_result :: {:ok, message_handler_opts} |
    {:reply, %OperationMessage{}, message_handler_opts} |
    {:reply, list(%OperationMessage{}), message_handler_opts}

  @doc """
  Invoked when the cowboy socket handler's `websocket_init` callback is invoked,
  when the HTTP connection is upgraded to Websocket. The callback receives
  a keyword list of options to be used by the message handler.

  The callback is used to specify, for example, the Absinthe.Schema, Absinthe.PubSub,
  DataBroker supervisor and other options. Returns the filtered list of options that
  will be passed to the other callbacks in this interface. The callback must be defined in an
  implementation module.
  """
  @callback init(message_handler_opts) :: message_handler_opts

  @doc """
  Invoked when the socket receives the "connection_init" message from the server.

  The callback receives three arguments: the ApolloSocket, a map containing the
  parsed "ws" URL params when the socket was upgraded, and the message handler options.
  """
  @callback handle_connection_init(apollo_socket, map(), message_handler_opts) :: message_handler_result

  @doc """
  Invoked when the socket receives a "start" message from the GraphQL server, indicating
  the initial response from a query, mutation, or subscription.

  The callback receives six arguments: the ApolloSocket, the operation id created by
  the server to identify this query, the operation name for the query, the operation
  document (string) of the query, the variables assigned for the query, and the message
  handler options.
  """
  @callback handle_start(apollo_socket, String.t, String.t, String.t, map(), message_handler_opts) :: message_handler_result

  @doc """
  Invoked when the socket receives a "stop" message from the GraphQL server, indicating
  that the query, mutation, or subscription is complete.

  The callback receives three arguments: the ApolloSocket, the operation id for the
  query operation, and the message handler options.
  """
  @callback handle_stop(apollo_socket, String.t, message_handler_opts) :: message_handler_result

  @doc false
  def handle_connection_init(_module, _apollo_socket, _connection_params, opts) do
    {:reply, OperationMessage.new_connection_ack(), opts }
  end

  @doc false
  def handle_message(module, apollo_socket, %OperationMessage{ type: :gql_connection_init } = message, opts) do
    module.handle_connection_init(apollo_socket, message.payload, opts)
  end

  @doc false
  def handle_message(module, apollo_socket, %OperationMessage{ type: :gql_start, id: operation_id} = message, opts) do
    %{ "query" => graphql_doc } = message.payload
    operation_name = message.payload["operationName"]
    variables = message.payload["variables"]

    module.handle_start(apollo_socket, operation_id, operation_name, graphql_doc, variables, opts)
  end

  @doc false
  def handle_message(module, apollo_socket, %OperationMessage{ type: :gql_stop, id: operation_id }, opts) do
    module.handle_stop(apollo_socket, operation_id, opts)
  end

  @doc false
  def handle_message(_module, _apollo_socket, %OperationMessage{}, opts) do
    {:ok, opts}
  end

  defmacro __using__(_use_options) do
    quote location: :keep do
      @behaviour ApolloSocket.MessageHandler

      @impl true
      def handle_connection_init(apollo_socket, connection_params, opts), do:
        ApolloSocket.MessageHandler.handle_connection_init(__MODULE__, apollo_socket, connection_params, opts)

      @impl true
      def handle_start(_apollo_socket, _operation_id, _operation_name, _graphql_doc, _variables, opts) do
        {:ok, opts }
      end

      @impl true
      def handle_stop(_apollo_socket, _operation_id, opts) do
        { :ok, opts }
      end

      def handle_message(apollo_socket, %OperationMessage{} = message, opts), do:
        ApolloSocket.MessageHandler.handle_message(__MODULE__, apollo_socket, message, opts)

      defoverridable ApolloSocket.MessageHandler
    end
  end
end

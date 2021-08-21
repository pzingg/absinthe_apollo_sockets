defmodule ApolloSocket.DataBroker do
  use GenServer

  alias ApolloSocket.OperationMessage

  require Logger
  require IEx

  @moduledoc """
  This module implements a GenServer that sits as an intermediary between
  the Absinthe pubsub that is broadcasting subscription data and the websocket
  that sends that data back to the client.  This GenServer also translates
  between the Absinthe token that represents a subscription and the Apollo
  concept of an operation id which is how Apollo keeps track of a subscription.
  """

  @broker_options [
    :apollo_socket,
    :pubsub,
    :absinthe_id,
    :operation_id,
  ]

  def start_link(options) do
    {broker_options, other_options} = Keyword.split(options, @broker_options)
    GenServer.start_link(__MODULE__, broker_options, other_options)
  end

  def init(options) do
    pubsub = Keyword.get(options, :pubsub)
    absinthe_id = Keyword.get(options, :absinthe_id)
    apollo_socket = Keyword.get(options, :apollo_socket)

    subscribe_to_data(pubsub, absinthe_id)
    monitor_id = monitor_websocket(ApolloSocket.websocket(apollo_socket))

    {:ok, %{
      apollo_socket: apollo_socket,
      pubsub: pubsub,
      absinthe_id: absinthe_id,
      operation_id: Keyword.get(options, :operation_id),
      socket_monitor_id: monitor_id
      }}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    # my websocket went down.  This process can exit now
    Logger.info("id #{state.operation_id} tearing down data broker #{inspect(pid)} #{reason}")

    {:stop, :normal, state}
  end

  @response_set MapSet.new([:data, :errors, :extensions])

  @dialyzer({:no_opaque, handle_info: 2})
  def handle_info(proc_message, state) when is_map(proc_message) do
    if MapSet.subset?(Map.keys(proc_message) |> MapSet.new(), @response_set) do
      send_data_result(proc_message, state)
    else
      Logger.warn("id #{state.operation_id} ingoring non-conforming map #{inspect(proc_message)}")

      {:noreply, state}
    end
  end

  @dialyzer({:no_unused, send_data_result: 2})
  defp send_data_result(proc_message, state) when is_map(proc_message) do
    op_message = OperationMessage.new_data(state.operation_id, proc_message)
    ApolloSocket.send_message(state.apollo_socket, op_message)

    {:noreply, state}
  end

  def subscribe_to_data(nil, _), do: raise "#{__MODULE__} requires the Absinthe PubSub module to subscribe to"
  def subscribe_to_data(_, nil), do: raise "#{__MODULE__} requires an Absinthe subscription id"
  def subscribe_to_data(pubsub, absinthe_id) do
    pubsub.subscribe(absinthe_id)
  end

  def monitor_websocket(nil), do: raise "#__MODULE__ requires the pid of the hosting websocket"
  def monitor_websocket(socket) do
    Process.monitor(socket)
  end
end

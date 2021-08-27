defmodule PhoenixSample.Application do
  @moduledoc """
  A Phoenix application that supports both the Apollo Websocket protocol and
  the Phoenix Channel protocol for Absinthe subscriptions.

  In config.exs, set the value of the local variable `gql_on_phoenix_channels`
  to true to support BOTH the Phoenix Channel subscription protocol
  AND the Apollo Websocket protocol.

  Otherwise, only the Apollo Websocket protocol will be supported.
  """

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  use Application

  def start(_type, _args) do
    children = [
      # This is the supervisor that provides a set of counters in the schema
      PhoenixSample.Counter,

      # Start the Telemetry supervisor
      PhoenixSampleWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: PhoenixSample.PubSub},

      # When a subscription is created we create an intermediary process that
      # translates from the Absinthe PubSub to the Apollo socket protocol
      # This supervisor watches those subscriptions.
      {DynamicSupervisor, strategy: :one_for_one, name: PhoenixSample.BrokerSupervisor},

      # Start the Endpoint (http/https)
      PhoenixSampleWeb.Endpoint,

      # Start and Absinthe Subscription pointed at a module
      # that translates from Absinthe related notifications to
      # the Phoenix PubSub system started above
      {Absinthe.Subscription, absinthe_pubsub_module()},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixSample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PhoenixSampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc """
  Get the name of the module used for Absinthe subscriptions from
  a list of config options.
  """
  def absinthe_pubsub_module() do
    if Application.fetch_env!(:phoenix_sample, :gql_on_phoenix_channels?) do
      PhoenixSampleWeb.Endpoint
    else
      PhoenixSample.Absinthe.PubSub
    end
  end
end

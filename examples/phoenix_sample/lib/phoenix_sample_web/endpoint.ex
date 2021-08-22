defmodule PhoenixSampleWeb.Endpoint do
  @moduledoc """
  A standard Phoenix application endpoint module. The `use Absinthe.Phoenix.Endpoint`
  enables Absinthe subscriptions to be sent over Phoenix Channels, and can be
  commented out if only the Apollo socket protocol is needed.
  """
  use Phoenix.Endpoint, otp_app: :phoenix_sample

  if Application.get_env(:phoenix_sample, :gql_on_phoenix_channels?, false) do
    use Absinthe.Phoenix.Endpoint
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_phoenix_sample_key",
    signing_salt: "Utlv2Jws"
  ]

  socket "/socket", PhoenixSampleWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :phoenix_sample,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug PhoenixSampleWeb.Router

  @doc """
  Dynamic initialization of the endpoint's configuration.
  We override the Cowboy dispatcher to put our Apollo socket handler
  ahead of the Phoenix endpoint adapter.
  """
  def init(_supervisor, config) do
    absinthe_pubsub = PhoenixSample.Application.absinthe_pubsub_module()

    updated_config =
      put_in(config, [:http, :dispatch], [
        {:_,
         [
           {
             "/socket/apollo_socket",
             ApolloSocket.CowboySocketHandler,
             # ApolloSocket configuration settings
             {
               ApolloSocket.AbsintheMessageHandler,
               schema: PhoenixSample.Schema,
               pubsub: absinthe_pubsub,
               broker_sup: PhoenixSample.BrokerSupervisor
             }
           },
           {:_, Phoenix.Endpoint.Cowboy2Handler, {PhoenixSampleWeb.Endpoint, []}}
         ]}
      ])

    {:ok, updated_config}
  end
end

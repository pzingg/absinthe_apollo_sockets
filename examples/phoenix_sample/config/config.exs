# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Set this variable to 'true' to support Absinthe subscriptions on the
# Phoenix Channel protocol AS WELL AS on the Apollo Websocket protocol:
gql_on_phoenix_channels = true

# Set this variable to 'true' to support GraphQL queries on HTTP, and
# to serve GraphiQL interactive query and subscription pages.
gql_on_http = true

# Used at application start
config :phoenix_sample,
  gql_on_http?: gql_on_http,
  gql_on_phoenix_channels?: gql_on_http || gql_on_phoenix_channels

# Configures the endpoint
# The Apollo socket configuration will be initialized at runtime.
config :phoenix_sample, PhoenixSampleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "lcHcYi7X2kV8DC9nvRqMRQGUfKxok0w4EGDYmn1ZR0HFctPVLryd4sDp9Q5u9VH9",
  render_errors: [view: PhoenixSampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhoenixSample.PubSub,
  live_view: [signing_salt: "ydK4MZhU"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

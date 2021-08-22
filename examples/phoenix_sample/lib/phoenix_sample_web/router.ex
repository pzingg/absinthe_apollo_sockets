defmodule PhoenixSampleWeb.Router do
  @moduledoc """
  Configure the routing for a Phoenix web application.

  In config.exs, set the value of the local variable `gql_on_http`
  to true to serve HTTP Absinthe queries at the path "/gql",
  via a browser or other HTTP client.
  """
  use PhoenixSampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  if Application.get_env(:phoenix_sample, :gql_on_http?, false) do
    absinthe_pubsub = PhoenixSample.Application.absinthe_pubsub_module()

    # This scope provides HTTP access to GraphQL queries and may be omitted
    # if only the Apollo Websocket protocol for Absinthe subscriptions is used.
    scope "/gql" do
      pipe_through :api

      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: PhoenixSample.Schema,
        socket: PhoenixSampleWeb.UserSocket,
        interface: :simple,
        context: %{pubsub: absinthe_pubsub}

      forward "/", Absinthe.Plug, schema: PhoenixSample.Schema
    end
  end

  scope "/", PhoenixSampleWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixSampleWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PhoenixSampleWeb.Telemetry
    end
  end
end

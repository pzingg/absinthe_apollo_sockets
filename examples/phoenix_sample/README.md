# PhoenixSample

Demonstrates different ways an Absinthe GraphQL server can be exposed in
a Phoenix web application.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Configure the local variables `gql_on_phoenix_channels` and `gql_on_http`
    in the file "config/config.exs" (see below for more information)
  * Start Phoenix endpoint with `mix phx.server`, optionally after setting
    the Apollo socket path environment variable as described here.

Set the operating system environment variable `APOLLO_SOCKET_PATH` 
to configure the path (under "socket/") for the Apollo websocket
that handles the GraphQL queries, mutations and subscriptions. 
The value for the variable should be different than "websocket", 
which Phoenix reserves for its channels.

The default is "apollo_socket", meaning that you would connect using 
the URL:

ws://localhost:4000/socket/apollo_socket

After starting the dev server, you may access GraphQL over Websockets 
and HTTP via the services listed below.

Ready to run in production? Please [check the Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## GraphQL on the Apollo protocol (Websockets)

You may connect to this dev server URL with a Websocket-enabled client
to send queries and receive subscription updates:

ws://localhost:4000/socket/apollo_socket

## GraphQL on Phoenix Channels (Websockets)

In config.exs, set the value of the local variable `gql_on_phoenix_channels`
to true to support **both** the Phoenix Channel subscription protocol
**and** the Apollo Websocket protocol.

If `gql_on_phoenix_channels` has been set to true, you may also
connect to this dev server URL with a Websocket-enabled client to send
queries and receive subscription updates (passed via Phoenix Channels):

ws://localhost:4000/socket/websocket

## GraphQL on HTTP

In config.exs, set the value of the local variable `gql_on_http`
to true to serve HTTP Absinthe queries at the path "/gql",
via a browser or other HTTP client.

If `gql_on_http` was set to true, you may connect to this dev server
URL to send queries using curl or other clients:

http://localhost:4000/gql

And you may visit this dev server URL to use the interactive GraphiQL
web application to send queries and receive subscription updates:

http://localhost:4000/gql/graphiql

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

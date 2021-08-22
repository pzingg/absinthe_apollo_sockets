# ApolloCowboy

Example of ApolloSocket running on a cowboy webserver, without any Phoenix
dependencies other than the Phoenix.PubSub system.

To start the cowboy server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix run --no-halt`

After starting, connect to the Apollo socket at:

ws://localhost:8080/socket/websocket

To start the cowboy server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix run --no-halt`

Two options can be set through environment variables:

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/apollo_cowboy](https://hexdocs.pm/apollo_cowboy).

# Überauth Meli (Mercado Libre)

> Mercado Libre OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Mercado Libre for Developers](https://developers.mercadolivre.com.br/).

1. Add `:ueberauth_meli` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_meli, "~> 0.1"}]
    end
    ```

1. Add Meli to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        meli: {Ueberauth.Strategy.Meli, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Meli.OAuth,
      client_id: System.get_env("MELI_CLIENT_ID"),
      client_secret: System.get_env("MELI_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/meli

Or with options:

    /auth/meli?scope=read,write

By default the requested scope is "read". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    meli: {Ueberauth.Strategy.Meli, [default_scope: "read,write"]}
  ]
```

## License

Please see [LICENSE](https://github.com/marciotoze/ueberauth_meli/blob/master/LICENSE) for licensing details.

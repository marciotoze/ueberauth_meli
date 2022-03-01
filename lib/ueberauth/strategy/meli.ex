defmodule Ueberauth.Strategy.Meli do
  @moduledoc """
  Implements an ÜeberauthMeli strategy for authentication with mercadolibre.com
  When configuring the strategy in the Üeberauth providers, you can specify some defaults.
  * `default_scope` - The scope to request by default from mercadolibre (permissions). Default "read"
  * `oauth2_module` - The OAuth2 module to use. Default Ueberauth.Strategy.Meli.OAuth
  ```elixir
  config :ueberauth, Ueberauth,
    providers: [
      meli: { Ueberauth.Strategy.Meli, [default_scope: "read,write"] }
    ]
  ```
  """

  use Ueberauth.Strategy,
    default_scope: "read",
    oauth2_module: Ueberauth.Strategy.Meli.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Helpers

  @doc false
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    callback_url = callback_url(conn)

    callback_url =
      if String.ends_with?(callback_url, "?"),
        do: String.slice(callback_url, 0..-2),
        else: callback_url

    opts =
      opts
      |> Keyword.put(:redirect_uri, callback_url)
      |> Helpers.with_state_param(conn)

    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc false
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    params = [code: code]
    redirect_uri = get_redirect_uri(conn)

    options = %{
      options: [
        client_options: [redirect_uri: redirect_uri]
      ]
    }

    token = apply(module, :get_token!, [params, options])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      conn
      |> store_token(token)
      |> fetch_user(token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  defp store_token(conn, token) do
    put_private(conn, :meli_token, token)
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:meli_user, nil)
    |> put_private(:meli_token, nil)
  end

  @doc false
  def credentials(conn) do
    token = conn.private.meli_token
    user = conn.private[:meli_user]

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at
    }
  end

  @doc false
  def info(conn) do
    user = conn.private[:meli_user]
    phone = user["phone"]

    %Info{
      name: "#{user["first_name"]} #{user["last_name"]}",
      first_name: user["first_name"],
      last_name: user["last_name"],
      nickname: user["nickname"],
      email: user["email"],
      location: get_in(user, ["address", "city"]),
      image: get_in(user, ["thumbnail", "picture_url"]),
      phone: "#{phone["areacode"]} #{phone["number"]}",
      urls: %{profile: user["permalink"]}
    }
  end

  @doc false
  def extra(conn), do: %Extra{raw_info: %{user: conn.private[:meli_user]}}

  @doc false
  def uid(conn), do: conn.private[:meli_user]["id"]

  defp fetch_user(%Plug.Conn{assigns: %{ueberauth_failure: _fails}} = conn, _), do: conn

  defp fetch_user(conn, token) do
    case Ueberauth.Strategy.Meli.OAuth.get(token, "/users/me", []) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :meli_user, user)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp get_redirect_uri(%Plug.Conn{} = conn) do
    config = Application.get_env(:ueberauth, Ueberauth)
    redirect_uri = Keyword.get(config, :redirect_uri)

    if is_nil(redirect_uri) do
      callback_url(conn)
    else
      redirect_uri
    end
  end
end

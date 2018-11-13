defmodule OpenPublishing.Auth do
  @moduledoc """
  This module handles all authentication related functionality, i.e.
  exchanging an `access_token` for an `auth_token`, getting the associated
  `realm_id`, `user_id`, `app_id`, etc. of a token.
  """

  require Logger

  use OK.Pipe

  alias OpenPublishing.Context
  alias OpenPublishing.Auth.Context, as: AuthContext
  alias OpenPublishing.HTTP.Request

  @auth_path "auth/auth"
  @verify_path "auth/verify"

  @doc """
  Authenticate via `access_token` or `auth_token`.
  """
  @spec auth(Context.t()) :: {:ok, Context.t()} | {:error, term()}
  def auth(%Context{auth: %AuthContext{auth_token: nil, access_token: access_token}} = ctx)
      when is_binary(access_token) do
    Logger.debug(fn ->
      "Authenticating via access_token (#{String.slice(access_token, 0, 10)})"
    end)

    params = [
      api_key: access_token,
      type: "api_key"
    ]

    result =
      ctx.host
      |> Request.build_url(@auth_path, params)
      |> Request.get()
      |> Request.dispatch()
      ~>> Request.get_response()
      ~>> Poison.decode()

    case result do
      {:ok, %{"ok" => "ok", "auth_token" => bearer}} ->
        %Context{ctx | auth: %AuthContext{ctx.auth | auth_token: bearer}} |> verify()

      {:error, reason} ->
        Logger.error("Authentication failed: #{inspect(reason)}")
        result
    end
  end

  def auth(%Context{auth: %AuthContext{auth_token: auth_token}} = ctx)
      when is_binary(auth_token) do
    verify(ctx)
  end

  @spec verify(Context.t()) :: {:ok, Context.t()} | {:error, term()}
  def verify(%Context{auth: %AuthContext{auth_token: auth_token}} = ctx)
      when is_binary(auth_token) do
    Logger.debug(fn -> "Checking auth_token #{String.slice(auth_token, 0, 10)}" end)

    result =
      ctx
      |> whoami()
      |> Request.dispatch()
      ~>> Request.get_response()
      ~>> Poison.decode()
      ~>> Map.fetch("RESULT")
      ~> Map.take(["realm_id", "user_id", "app_id"])
      ~> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    case result do
      {:ok, me} ->
        {:ok, %Context{ctx | auth: Map.merge(ctx.auth, me)}}

      _ ->
        result
    end
  end

  @spec auth_header(keyword(), AuthContext.t()) :: keyword()
  def auth_header(old_header \\ [], %AuthContext{auth_token: bearer}) when is_binary(bearer) do
    old_header ++
      [
        Authorization: "Bearer #{bearer}"
      ]
  end

  @spec whoami(Context.t()) :: Request.t()
  def whoami(%Context{host: host, auth: %AuthContext{auth_token: auth_token}} = ctx)
      when is_binary(auth_token) do
    host
    |> Request.build_url("/rpc/me")
    |> Request.get(auth_header(ctx.auth))
  end
end

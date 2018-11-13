defmodule OpenPublishing.HTTP.Request do
  @moduledoc """
  HTTP wrapper to successively build a HTTP request before dispatching it.
  """

  alias HTTPoison.Request
  alias OpenPublishing.Context
  alias OpenPublishing.Auth.Context, as: AuthContext

  @timeout 30_000

  @type t :: Request.t()

  @doc """
  Finally sends the HTTP request.
  """
  def dispatch(%Request{} = request) do
    HTTPoison.request(request)
  end

  @doc """
  Build an HTTP GET request

  ## Example

      iex> OpenPublishing.HTTP.Request.get("https://api.openpublishing.com/rpc/me")
      %HTTPoison.Request{
        body: "",
        headers: [],
        method: :get,
        options: [timeout: 30000, recv_timeout: 30000],
        params: %{},
        url: "https://api.openpublishing.com/rpc/me"
      }
  """
  @spec get(String.t(), keyword, keyword) :: t()
  def get(url, headers \\ [], options \\ [timeout: @timeout, recv_timeout: @timeout]) when is_binary(url) do
    %Request{
      method: :get,
      url: url,
      headers: headers,
      options: options
    }
  end

  @doc """
  Build an HTTP POST request
  """
  @spec post(String.t(), String.t(), keyword, keyword) :: t()
  def post(url, body, headers \\ [], options \\ [timeout: @timeout, recv_timeout: @timeout]) when is_binary(url) do
    %Request{
      method: :post,
      url: url,
      body: body,
      headers: headers,
      options: options
    }
  end

  @doc """
  Builds an HTTP GET request, while extracting the host and authentication from the context.
  """
  def ctx_get(%Context{host: host} = ctx, path, params \\ []) when is_binary(path) do
    host
    |> build_url(path, params)
    |> get()
    |> add_auth(ctx)
  end

  @doc """
  Adds a header to an existing request.
  """
  def add_header(%Request{headers: existing_headers} = request, header) when is_list(header) do
    new_headers = Enum.concat(header, existing_headers)
    %Request{request | headers: new_headers}
  end

  @doc """
  Sets the body of an existing request.
  """
  def set_body(%Request{} = request, body) do
    %Request{request | body: body}
  end

  @doc """
  Adds an authentication header to an existing request.
  """
  def add_auth(%Request{} = request, %Context{auth: %AuthContext{auth_token: auth_token}})
      when is_binary(auth_token) do
    add_header(request, Authorization: "Bearer #{to_string(auth_token)}")
  end

  def add_auth(%Request{} = request, %Context{auth: %AuthContext{access_token: access_token}} = ctx)
      when is_binary(access_token) do
    {:ok, %Context{auth: %AuthContext{auth_token: auth_token}}} = OpenPublishing.Auth.auth(ctx)
    add_header(request, Authorization: "Bearer #{to_string(auth_token)}")
  end

  @doc """
  Tries to get the response body from a performed request.
  """
  @spec get_response(HTTPoison.response()) :: {:ok, String.t()} | {:error, term()}
  def get_response(%HTTPoison.Response{status_code: 200, body: body}) do
    {:ok, body}
  end

  def get_response(%HTTPoison.Response{status_code: code, body: body}) when code != 200 do
    {:error, {code, body}}
  end

  def parse_json(body) do
    Poison.decode(body)
  end

  def build_url(host, path, params \\ []) when is_list(params) do
    "https://#{host}/"
    |> URI.merge(path)
    |> URI.merge("?" <> URI.encode_query(params))
    |> to_string
  end
end

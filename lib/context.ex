defmodule OpenPublishing.Context do
  @moduledoc """
  Module which defines a struct to hold the context, i.e. host and authentication parameters
  """

  @host Map.get(System.get_env(), "API_HOST", "api.openpublishing.com")
  defstruct host: @host,
            auth: %OpenPublishing.Auth.Context{},
            verify_ssl: true

  @type t :: %__MODULE__{
          host: String.t(),
          auth: OpenPublishing.Auth.Context.t(),
          verify_ssl: boolean
        }

  @doc """
  Create a new request context by passing an `access_token` or `auth_token` and, optionally, a `host`.

  ## Example

        iex> OpenPublishing.Context.new(access_token: "1_1R_3")
        %OpenPublishing.Context{
          auth: %OpenPublishing.Auth.Context{
            access_token: "1_1R_3",
            app_id: nil,
            auth_token: nil,
            realm_id: nil,
            user_id: nil
          },
          host: "api.openpublishing.com",
          verify_ssl: true
        }
        iex> OpenPublishing.Context.new(auth_token: "secrettoken")
        %OpenPublishing.Context{
          auth: %OpenPublishing.Auth.Context{
            access_token: nil,
            app_id: nil,
            auth_token: "secrettoken",
            realm_id: nil,
            user_id: nil
          },
          host: "api.openpublishing.com",
          verify_ssl: true
        }
  """
  @spec new(String.t(), keyword()) :: t()
  def new(host \\ @host, auth_param) when is_list(auth_param) do
    %__MODULE__{
      host: host,
      auth: OpenPublishing.Auth.Context.new(auth_param)
    }
  end

  @spec auth(t()) :: {:ok, t()} | {:error, term()}
  def auth(%__MODULE__{} = ctx) do
    OpenPublishing.Auth.auth(ctx)
  end
end

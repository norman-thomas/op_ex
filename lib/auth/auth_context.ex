defmodule OpenPublishing.Auth.Context do
  @moduledoc """
  Authentication context struct.
  """

  defstruct auth_token: nil,
            access_token: nil,
            realm_id: nil,
            user_id: nil,
            app_id: nil

  @type t :: %__MODULE__{
          auth_token: String.t() | nil,
          access_token: String.t() | nil,
          realm_id: integer() | nil,
          user_id: integer() | nil,
          app_id: integer() | nil
        }

  @doc """
  Create a new authentication context by passing either an `access_token` or `auth_token`.

  ## Example

        iex> OpenPublishing.Auth.Context.new(access_token: "1_1R_3")
        %OpenPublishing.Auth.Context{
          access_token: "1_1R_3",
          app_id: nil,
          auth_token: nil,
          realm_id: nil,
          user_id: nil
        }
        iex> OpenPublishing.Auth.Context.new(auth_token: "secrettoken")
        %OpenPublishing.Auth.Context{
          access_token: nil,
          app_id: nil,
          auth_token: "secrettoken",
          realm_id: nil,
          user_id: nil
        }
  """
  @spec new([access_token: String.t()] | [auth_token: String.t()]) :: t()
  def new(access_token: access_token) do
    %__MODULE__{access_token: access_token}
  end

  def new(auth_token: auth_token) do
    %__MODULE__{auth_token: auth_token}
  end
end

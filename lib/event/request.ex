defmodule OpenPublishing.Event.Request do
  @moduledoc """
  Module for building event requests.
  """

  alias OpenPublishing.Context
  alias OpenPublishing.HTTP.Request

  @path "/rpc/event"

  defstruct ctx: nil,
            method: :list_status,
            filters: [],
            from: 0,
            resumption_token: nil

  @type context_t :: OpenPublishing.Context.t()
  @type method_t :: OpenPublishing.Event.method_t()
  @type filter_t :: OpenPublishing.Event.Filter.t()
  @type filters_t :: list(filter_t)

  @type t :: %__MODULE__{
          ctx: context_t() | nil,
          method: method_t(),
          filters: filters_t(),
          from: integer(),
          resumption_token: String.t() | nil
        }

  @doc """
  Create new event request.

  ## Example

        iex> ctx = OpenPublishing.Context.new(access_token: "1_1R_3")
        iex> OpenPublishing.Event.Request.new(ctx, :list_status, [["document", "metadata", "changed"]])
        %OpenPublishing.Event.Request{
          ctx: %OpenPublishing.Context{
            auth: %OpenPublishing.Auth.Context{
              access_token: "1_1R_1",
              app_id: nil,
              auth_token: nil,
              realm_id: nil,
              user_id: nil
            },
            host: "api.openpublishing.com",
            verify_ssl: true
          },
          filters: [["document", "metadata", "changed"]],
          from: 0,
          method: :list_status,
          resumption_token: nil
        }
  """
  @spec new(context_t(), method_t(), filters_t(), non_neg_integer()) :: t()
  def new(%Context{} = ctx, method, filters, from_ \\ 0)
      when is_list(filters) do
    %__MODULE__{
      ctx: ctx,
      method: method,
      filters: filters,
      from: from_
    }
  end

  @doc """
  Resume an event request via passed `resumption_token`.
  """
  @spec resume(context_t(), method_t(), String.t()) :: t()
  def resume(%Context{} = ctx, method, resumption_token) do
    %__MODULE__{
      ctx: ctx,
      method: method,
      resumption_token: resumption_token
    }
  end

  defp request_params(%__MODULE__{resumption_token: nil} = req) do
    [
      method: to_string(req.method),
      event_types: event_types(req.filters),
      from: from(req.from)
    ]
  end

  defp request_params(%__MODULE__{method: method, resumption_token: resumption_token}) do
    [
      method: to_string(method),
      resumption_token: resumption_token
    ]
  end

  @doc """
  Build HTTP request from event request.
  """
  @spec request(t()) :: Request.t()
  def request(%__MODULE__{ctx: ctx} = req) when not is_nil(ctx) do
    params = request_params(req)

    %Context{host: host} = ctx

    host
    |> Request.build_url(@path, params)
    |> Request.get()
    |> Request.add_auth(ctx)
  end

  defp from(val) when is_integer(val), do: val
  defp from(%DateTime{} = val), do: val
  defp from(_), do: 0

  defp event_types(filters) do
    filters
    |> Enum.map(&to_string/1)
    |> Enum.join(";")
  end
end

defmodule OpenPublishing.Event do
  @moduledoc """
  High level module for fetching events
  """

  require Logger
  use OK.Pipe

  alias OpenPublishing.HTTP.Request
  alias OpenPublishing.Event.Stream, as: EventStream
  alias OpenPublishing.Event.Request, as: EventRequest
  alias OpenPublishing.Event.Response, as: EventResponse

  defstruct realm_id: 0,
            method: :list_status,
            target: "",
            action: "",
            type: "",
            source_type: "",
            reference_id: 0,
            app_id: 0,
            last_modified: 0

  @type method_t :: :list_status | :history
  @type filter_t :: OpenPublishing.Event.Filter.t()
  @type t :: %__MODULE__{
          method: method_t(),
          realm_id: non_neg_integer(),
          target: String.t(),
          action: String.t(),
          type: String.t(),
          source_type: String.t(),
          reference_id: integer(),
          app_id: integer() | nil,
          last_modified: integer()
        }

  @spec list_status(OpenPublishing.Context.t(), list(filter_t), integer()) :: EventResponse.t()
  def list_status(%OpenPublishing.Context{} = ctx, filters, from \\ 0) do
    ctx
    |> EventRequest.new(:list_status, filters, from)
    |> request()
  end

  @spec request(EventRequest.t()) :: EventResponse.t()
  def request(req) do
    {:ok, %{"result" => response}} =
      req
      |> EventRequest.request()
      |> Request.dispatch()
      ~>> Request.get_response()
      ~>> Request.parse_json()

    %{"items" => items, "execution_timestamp" => execution_timestamp} = response
    items = items |> Enum.map(&from_gjp/1)
    next_request = get_next_request(req, response)

    %EventResponse{
      prev_request: req,
      next_request: next_request,
      execution_timestamp: execution_timestamp,
      items: items
    }
  end

  defp get_next_request(req, %{"resumption_token" => token, "execution_timestamp" => execution_timestamp})
       when is_binary(token) and byte_size(token) > 0 do
    %EventRequest{req | resumption_token: token, from: execution_timestamp}
  end

  defp get_next_request(_req, _resp) do
    nil
  end

  defp event_fields do
    Map.keys(%__MODULE__{})
  end

  defp from_gjp(item) do
    item
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
    |> Map.take(event_fields())
  end

  @doc """
  Create an event stream.

  ## Example

      iex> ctx = OpenPublishing.Context.new(access_token: "1_1R_3")
      iex> OpenPublishing.Event.stream(ctx, :list_status, [["document", "changed", "metadata"]])
      #Function<54.51129937/2 in Stream.resource/3>
  """
  def stream(%OpenPublishing.Context{} = ctx, method, filters, from \\ 0) do
    open = fn ->
      %EventStream{
        ctx: ctx,
        method: method,
        next_request:
          ctx
          |> EventRequest.new(method, filters, from)
          |> EventRequest.request(),
        data: []
      }
    end

    next = fn state ->
      stream_event(state)
    end

    close = fn _state ->
      nil
    end

    Stream.resource(
      open,
      next,
      close
    )
  end

  defp stream_event(%EventStream{data: data} = state) when length(data) > 0 do
    struct_data = data |> Enum.map(fn d -> struct!(__MODULE__, d) end)
    new_state = %EventStream{state | data: []}
    {struct_data, new_state}
  end

  defp stream_event(%EventStream{data: [], next_request: nil}) do
    {:halt, []}
  end

  defp stream_event(%EventStream{data: [], next_request: next_request, method: method, ctx: ctx} = state) do
    %{"OK" => _, "result" => response} = fetch_events(next_request)

    next_request =
      case Map.fetch(response, "resumption_token") do
        :error ->
          nil

        {:ok, resumption_token} ->
          ctx
          |> EventRequest.resume(method, resumption_token)
          |> EventRequest.request()
      end

    new_state = %EventStream{
      state
      | next_request: next_request,
        data:
          response
          |> Map.fetch!("items")
          |> Enum.map(&from_gjp/1)
    }

    stream_event(new_state)
  end

  defp fetch_events(next_request, retries \\ 0)

  defp fetch_events(next_request, retries) when retries < 3 do
    {:ok, response} =
      next_request
      |> Request.dispatch()
      ~>> Request.get_response()
      ~>> Request.parse_json()

    case response do
      {:ok, body} ->
        body

      {:error, {_, :timeout}} ->
        Logger.warn("Event fetching timed out, retrying (#{retries})")
        fetch_events(next_request, retries + 1)

      _ ->
        Logger.warn("Event fetching failed, retrying (#{retries})")
        fetch_events(next_request, retries + 1)
    end
  end

  defp fetch_events(next_request, _retries) do
    Logger.error("Request failed: #{inspect(next_request)}")
    {:error, :max_retries_reached}
  end
end

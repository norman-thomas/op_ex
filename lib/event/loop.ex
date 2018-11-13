defmodule OpenPublishing.Event.Loop do
  @moduledoc false

  alias OpenPublishing.Context
  alias OpenPublishing.Event
  alias OpenPublishing.Event.Filter
  alias OpenPublishing.Event.Stream, as: EventStream
  alias OpenPublishing.Event.Request, as: EventRequest
  alias OpenPublishing.Event.Response, as: EventResponse
  alias OpenPublishing.HTTP.Request

  defstruct event: nil,
            ctx: nil,
            request: nil,
            next_request: nil,
            response: nil

  @delay 15_000

  def subscribe(%Context{} = ctx, filters, pid, from \\ 0, infinite \\ true) when is_list(filters) do
    initial_request = EventRequest.new(:list_status, filters, from)

    state = %__MODULE__{
      ctx: ctx,
      
    }

    stream = %EventStream{
      ctx: ctx,
      method: :list_status,
      # Event.prepare(ctx, :list_status, filters, 0),
      next_request: nil,
      data: []
    }
  end

  def loop_forever(%EventStream{data: [], next_request: nil} = stream, pid) do
    :timer.sleep(@delay)
    loop_forever(stream, pid)
  end

  def loop_forever(%EventStream{data: [], next_request: _next_request} = stream, pid) do
    :timer.sleep(@delay)
    loop_forever(stream, pid)
  end

  def loop_forever(%EventStream{data: data} = stream, pid) do
    GenServer.call(pid, {data})
    stream = %EventStream{stream | data: []}
    loop_forever(stream, pid)
  end

  defp get_resumption_token(%{"OK" => _, "result" => response}) do
    case Map.fetch(response, "resumption_token") do
      :error -> nil
      {:ok, resumption_token} -> resumption_token
    end
  end

  defp get_resumption_token(_) do
    nil
  end

  defp only_guids(items) do
    items
    |> Enum.map(&Map.fetch!(&1, :GUID))
  end
end

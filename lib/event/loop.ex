defmodule OpenPublishing.Event.Loop do
  @moduledoc false
  
  alias OpenPublishing.Context
  alias OpenPublishing.Event
  alias OpenPublishing.Event.Stream, as: EventStream
  alias OpenPublishing.HTTP.Request

  def subscribe(%Context{} = ctx, filters, pid, infinite \\ true) when is_list(filters) do
    stream = %EventStream{
      ctx: ctx,
      method: :list_status,
      next_request: nil, #Event.prepare(ctx, :list_status, filters, 0),
      data: []
    }
  end

  def loop(stream) do
    nil
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
end

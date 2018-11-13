defmodule OpenPublishing.Event.Loader do
  use GenStage
  require Logger

  alias OpenPublishing.Resource
  alias OpenPublishing.Resource.Helper, as: ResourceHelper

  defmodule State do
    defstruct ctx: nil,
              aspects: %{}
  end

  def start_link(ctx, aspects) when is_list(aspects) do
    GenStage.start_link(__MODULE__, {ctx, aspects}, name: __MODULE__)
  end

  def init({ctx, aspects}) do
    state = %State{
      ctx: ctx,
      aspects: aspects
    }

    {:producer_consumer, state}
  end

  def handle_events(events, _from, %State{ctx: ctx, aspects: aspects} = state) do
    Logger.debug("Loader.handle_events:")
    Logger.debug(inspect(events))

    objects =
      events
      #|> Enum.map(fn e -> Resource.new(String.downcase(e.source_type), e.reference_id) end)
      #|> Enum.map(fn r -> Resource.add_fields(r, aspects) end)
      #|> Enum.map(fn r -> ResourceHelper.load(ctx, r) end)

    {:noreply, objects, state}
  end
end

defmodule OpenPublishing.Event.Loader do
  use GenStage
  require Logger

  alias OpenPublishing.Resource
  alias OpenPublishing.Resource.Helper, as: ResourceHelper

  defmodule State do
    defstruct ctx: nil,
              aspects: []
  end

  def start_link({ctx, aspects, name, subscribe_to}) when is_list(aspects) do
    GenStage.start_link(__MODULE__, {ctx, aspects, subscribe_to}, name: name)
  end

  def init({ctx, aspects, subscribe_to}) do
    state = %State{
      ctx: ctx,
      aspects: aspects
    }

    {:producer_consumer, state, subscribe_to: [subscribe_to]}
  end

  def handle_events(events, _from, %State{ctx: ctx, aspects: aspects} = state) do
    Logger.debug("Loader.handle_events: got #{length(events)} events")

    resources =
      events
      |> Enum.map(fn e -> Resource.new(String.downcase(e.source_type), e.reference_id) end)
      |> Resource.concat()
      |> Resource.add_fields(aspects)

    Logger.debug("Loader: requesting #{String.slice(Resource.uri(resources), 0, 100)}")
    {:ok, objects} = ResourceHelper.load(ctx, resources)

    {:noreply, objects, state}
  end
end

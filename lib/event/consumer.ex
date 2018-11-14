defmodule OpenPublishing.Event.Consumer do
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:consumer, :nothing}
  end

  def handle_events(events, _from, state) do
    # TODO work with events, i.e. index, print, etc

    Logger.debug("Consumer.handle_events: got #{length(events)} events")
    Logger.debug(inspect(events))

    {:noreply, [], state}
  end
end

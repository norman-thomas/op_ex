defmodule OpenPublishing.Event.Consumer do
  use GenStage
  require Logger

  def start_link(subscribe_to) do
    GenStage.start_link(__MODULE__, subscribe_to, name: __MODULE__)
  end

  def init(subscribe_to) do
    {:consumer, :nothing, subscribe_to: [subscribe_to]}
  end

  def handle_events(events, _from, state) do
    # TODO work with events, i.e. index, print, etc

    Logger.debug("Consumer.handle_events: got #{length(events)} events")
    Logger.debug(inspect(events))

    {:noreply, [], state}
  end
end

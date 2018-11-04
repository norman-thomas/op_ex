defmodule OpenPublishing.Event.Producer do
  @moduledoc false
  
  use GenStage

  alias OpenPublishing.Event.Request, as: EventRequest
  alias OpenPublishing.HTTP.Request, as: HTTPRequest

  def start_link(ctx, filters, from \\ 0) do
    GenStage.start_link(__MODULE__, {ctx, filters, from}, name: __MODULE__)
  end

  def init({ctx, filters, from}) do
    state = %{
      config: %EventRequest{
        ctx: ctx,
        filters: filters,
        from: from
      },
      data: []
    }

    {:producer, state}
  end

  def handle_demand(demand, %{data: data} = state)
      when demand > 0 and demand <= length(data) do
    {events, new_data} = Enum.split(data, demand)
    new_state = %{state | data: new_data}
    {:noreply, events, new_state}
  end

  def handle_demand(demand, %{data: data} = state)
      when demand > 0 and demand > length(data) do
    data = fetch_events(state)
    {events, new_data} = Enum.split(data, demand)
    new_state = %{state | data: new_data}
    {:noreply, events, new_state}
  end

  def handle_demand(demand, state) when demand == 0 do
    events = []
    {:noreply, events, state}
  end

  def fetch_events(%{config: config, data: data}) do
    fetch_next(config)
    result = []
    Enum.concat(data, result)
  end

  def fetch_next(config) do
    nil
  end
end

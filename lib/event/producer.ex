defmodule OpenPublishing.Event.Producer do
  @moduledoc false

  use GenStage
  require Logger

  alias OpenPublishing.Event
  alias OpenPublishing.Event.Request, as: EventRequest
  alias OpenPublishing.Event.Response, as: EventResponse
  alias OpenPublishing.HTTP.Request, as: HTTPRequest

  defmodule State do
    defstruct ctx: nil,
              filters: nil,
              from: 0,
              response: nil
  end

  def start_link(ctx, filters, from, name \\ __MODULE__)
      when is_integer(from) and is_atom(name) do
    GenStage.start_link(__MODULE__, {ctx, filters, from}, name: name)
  end

  def init({ctx, filters, from}) do
    state = %State{
      ctx: ctx,
      filters: filters,
      from: from,
      response: nil
    }

    {:producer, {[], state}}
  end

  def handle_demand(demand, {data, state})
      when demand > 0 and demand <= length(data) do
    Logger.debug("1 Got demand: #{demand}, length(data) is #{length(data)}")
    {events, new_data} = Enum.split(data, demand)
    {:noreply, events, {new_data, state}}
  end

  def handle_demand(demand, {data, state})
      when demand > 0 and demand > length(data) do
    Logger.debug("2 Got demand: #{demand}, length(data) is #{length(data)}")
    {fetched_data, new_state} = fetch_events(state)
    data = Enum.concat(data, fetched_data)
    {events, new_data} = Enum.split(data, demand)
    {:noreply, events, {new_data, new_state}}
  end

  def handle_demand(demand, {data, state}) when demand == 0 do
    Logger.debug("3 Got demand: #{demand}, length(data) is #{length(data)}")
    events = []
    {:noreply, events, state}
  end

  defp fetch_events(%State{response: nil, ctx: ctx, filters: filters, from: from} = state) do
    Logger.debug("Producer.fetch_events: resp=nil (current from = #{from})")
    resp = Event.list_status(ctx, filters, from)
    process_event_response(state, resp)
  end

  defp fetch_events(%State{response: %EventResponse{next_request: nil}, ctx: ctx, filters: filters, from: from} = state) do
    Logger.debug("Producer.fetch_events: next_rq=nil (current from = #{from})")
    resp = Event.list_status(ctx, filters, from)
    process_event_response(state, resp)
  end

  defp fetch_events(%State{response: %EventResponse{next_request: next_req}} = state) do
    Logger.debug("Producer.fetch_events: rest... (current from = #{state.from})")
    resp = Event.request(next_req)
    process_event_response(state, resp)
  end

  defp process_event_response(state, resp) do
    data = resp.items
    new_from = data |> Enum.map(fn e -> e.last_modified end) |> Enum.max()
    new_state = %State{state | response: resp, from: new_from}
    {data, new_state}
  end
end

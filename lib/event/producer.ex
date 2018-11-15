defmodule OpenPublishing.Event.Producer do
  @moduledoc false

  use GenStage
  require Logger

  alias OpenPublishing.Event
  alias OpenPublishing.Event.Request, as: EventRequest
  alias OpenPublishing.Event.Response, as: EventResponse
  alias OpenPublishing.HTTP.Request, as: HTTPRequest

  @interval Application.get_env(:op_ex, :refresh_interval, 30_000)

  defmodule State do
    defstruct ctx: nil,
              demand: 0,
              filters: nil,
              from: 0,
              response: nil
  end

  def start_link({ctx, filters, from, name})
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
    fetch_and_reply(demand, {data, state})
  end

  def handle_info(:refresh, {data, state}) do
    fetch_and_reply(0, {data, state})
  end

  defp fetch_and_reply(demand, {data, state}) do
    state = add_demand(state, demand)

    {fetched_data, new_state} = fetch_events(state)
    Logger.debug("fetch_and_reply: retrieved #{length(fetched_data)} events")

    data = Enum.concat(data, fetched_data)
    {events, new_data} = Enum.split(data, state.demand)

    new_state = add_demand(new_state, -length(events))

    if new_state.demand > 0 do
      Logger.debug("No new events, fetching again in #{div(@interval, 1000)} sec")
      Process.send_after(self(), :refresh, @interval)
    end

    {:noreply, events, {new_data, new_state}}
  end

  defp add_demand(state, demand) do
    buffered_demand = state.demand + demand
    %State{state | demand: buffered_demand}
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

  defp process_event_response(%State{demand: demand} = state, %EventResponse{items: data} = resp)
       when demand <= length(data) do
    new_from = data |> Enum.map(fn e -> e.last_modified end) |> Enum.max()
    new_state = %State{state | response: resp, from: new_from}
    {data, new_state}
  end

  defp process_event_response(
         %State{demand: demand} = state,
         %EventResponse{items: data, execution_timestamp: from} = resp
       ) do
    new_state = %State{state | response: resp, from: from}
    {data, new_state}
  end
end

# op-ex

Light-weight Open Publishing API Wrapper in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `op_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:op_ex, "~> 0.1.0"}
  ]
end
```

## Usage

First, obtain an access or bearer token and create a new context via:

```elixir

# using access token
ctx = OpenPublishing.Context.new(access_token: "1_1R_3")

# or
# using bearer / auth token
ctx = OpenPublishing.Context.new(auth_token: "supersecrettoken")
```

### Loading a document

```elixir

doc = OpenPublishing.Object.Document.load(ctx, 1387, [":basic"])

IO.puts "ID: #{to_string(doc.id)}"
IO.puts "Title:" <> doc.title
IO.puts "Subtitle:" <> doc.subtitle

```

### Streaming events

```elixir

event_filters = [OpenPublishing.Event.Request.document_metadata_changed]
from = DateTime.from_iso8601("2018-01-01T00:00:00Z")
events = 
  ctx
  |> OpenPublishing.Event.stream(:list_status, event_filters, from)
  |> Stream.filter(fn event -> event.app_id == 0 end)
  |> Stream.map(fn event -> event.reference_id end)
  |> Enum.take(1000)

```

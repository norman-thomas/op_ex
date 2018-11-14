# credo:disable-for-this-file

syntax_colors = [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
pretty = fn args -> IO.inspect(args, syntax_colors: syntax_colors) end

access_token = System.get_env("ACCESS_TOKEN")
{:ok, ctx} = OpenPublishing.Context.new(access_token: access_token) |> OpenPublishing.Context.auth()


filters = [OpenPublishing.Event.Filter.document_metadata_changed()]
# from = 0
# month = 30 * 24 * 60 * 60
from = (DateTime.utc_now |> DateTime.to_unix)

{:ok, prod} = OpenPublishing.Event.Producer.start_link({ctx, filters, from, :producer})
{:ok, loader} = OpenPublishing.Event.Loader.start_link({ctx, [":basic"], :loader, :producer})
{:ok, consumer} = OpenPublishing.Event.Consumer.start_link(:loader)

#GenStage.sync_subscribe(consumer, to: loader)
#GenStage.sync_subscribe(loader, to: prod)

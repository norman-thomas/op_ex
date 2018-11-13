# credo:disable-for-this-file

syntax_colors = [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
pretty = fn args -> IO.inspect(args, syntax_colors: syntax_colors) end

access_token = System.get_env("ACCESS_TOKEN")
{:ok, ctx} = OpenPublishing.Context.new(access_token: access_token) |> OpenPublishing.Context.auth()


filters = [OpenPublishing.Event.Filter.document_metadata_changed()]

{:ok, prod} = OpenPublishing.Event.Producer.start_link(ctx, filters, 0)
{:ok, loader} = OpenPublishing.Event.Loader.start_link(ctx, [":basic"])
{:ok, consumer} = OpenPublishing.Event.Consumer.start_link()

GenStage.sync_subscribe(consumer, to: loader)
GenStage.sync_subscribe(loader, to: prod)

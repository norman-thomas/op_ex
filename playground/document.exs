# credo:disable-for-this-file

syntax_colors = [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
pretty = fn args -> IO.inspect(args, syntax_colors: syntax_colors) end

access_token = System.get_env("ACCESS_TOKEN")
ctx = OpenPublishing.Context.new(access_token: access_token)

doc =
  ctx
  |> OpenPublishing.Object.Document.load(1387, [":basic", "abstract.*"])
  |> hd()

pretty.(doc)

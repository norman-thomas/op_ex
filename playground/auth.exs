# credo:disable-for-this-file

syntax_colors = [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
pretty = fn args -> IO.inspect(args, syntax_colors: syntax_colors) end

access_token = System.get_env("ACCESS_TOKEN")
OpenPublishing.Context.new(access_token: access_token) |> OpenPublishing.Context.auth()

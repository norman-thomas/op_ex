# credo:disable-for-this-file

ctx = OpenPublishing.Context.new(access_token: "1_1R_3")

doc =
  ctx
  |> OpenPublishing.Object.Document.load(1387, [":basic", "abstract.*"])
  |> hd()

syntax_colors = [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
IO.inspect(doc, syntax_colors: syntax_colors)

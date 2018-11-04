defmodule OpenPublishing.Event.Stream do
  @moduledoc false

  defstruct ctx: nil,
            method: nil,
            next_request: nil,
            data: []

  @type t :: %__MODULE__{
          ctx: OpenPublishing.Context.t(),
          method: OpenPublishing.Event.method_t(),
          next_request: OpenPublishing.HTTP.Request.t(),
          data: list()
        }
end

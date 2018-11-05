defmodule OpenPublishing.Event.Response do
  @moduledoc """
  Struct for storing event fetching response
  """

  defstruct request: nil,
            next_request: nil,
            items: [],
            execution_timestamp: 0

  @type t :: %__MODULE__{
          request: OpenPublishing.Event.Request.t() | nil,
          next_request: OpenPublishing.Event.Request.t() | nil,
          items: list(),
          execution_timestamp: non_neg_integer()
        }
end

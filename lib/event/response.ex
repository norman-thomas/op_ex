defmodule OpenPublishing.Event.Response do
  @moduledoc """
  Struct for storing event fetching response
  """

  defstruct prev_request: nil,
            next_request: nil,
            items: [],
            execution_timestamp: 0

  @type t :: %__MODULE__{
          prev_request: OpenPublishing.Event.Request.t() | nil,
          next_request: OpenPublishing.Event.Request.t() | nil,
          execution_timestamp: non_neg_integer(),
          items: list()
        }
end

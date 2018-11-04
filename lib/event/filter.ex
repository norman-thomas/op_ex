defmodule OpenPublishing.Event.Filter do
  @moduledoc """
  Struct for holding event filter specifications, i.e. `target`, `action`, `type`
  """

  @fields [:target, :action, :type]

  @enforce_keys @fields
  defstruct @fields

  @type t :: %__MODULE__{
          target: String.t() | atom | nil,
          action: String.t() | atom | nil,
          type: String.t() | atom | nil
        }

  @doc """
  Create event filter from tuple
  """
  @spec new({String.t(), String.t(), String.t()} | {atom, atom, atom}) :: t()
  def new({target, action, type}) do
    %__MODULE__{
      target: target,
      action: action,
      type: type
    }
  end

  def to_url_param(%__MODULE__{} = filter) do
    @fields
    |> Enum.map(fn item -> Map.fetch!(filter, item) end)
    |> to_url_param
  end

  def to_url_param(filter) when is_list(filter) and length(filter) == length(@fields) do
    joined =
      filter
      |> Enum.map(&to_string/1)
      |> Enum.join(",")

    "(#{joined})"
  end
end

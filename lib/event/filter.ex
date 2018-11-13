defmodule OpenPublishing.Event.Filter do
  @moduledoc """
  Struct for holding event filter specifications, i.e. `target`, `action`, `type`
  """

  @fields [:target, :action, :type]

  @enforce_keys @fields
  defstruct @fields

  @type target_t :: :document | :order | :account
  @type action_t :: :changed | :"fulfillment-changed"
  @type type_t :: :metadata | :accounting
  
  @type t :: %__MODULE__{
          target: String.t() | target_t | nil,
          action: String.t() | action_t | nil,
          type: String.t() | type_t | nil
        }

  @doc """
  Create event filter from tuple
  """
  @spec new({String.t(), String.t(), String.t()} | {target_t, action_t, type_t}) :: t()
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

  def document_metadata_changed(), do: new({"document", "changed", "metadata"})
  def order_fulfillment(), do: new({"order", "fulfillment-changed", "accounting"})
  def account_changed(), do: new({"account", "changed", ""})

  defimpl String.Chars do
    def to_string(f) do
      OpenPublishing.Event.Filter.to_url_param(f)
    end
  end
end

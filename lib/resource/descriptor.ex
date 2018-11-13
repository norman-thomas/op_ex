defmodule OpenPublishing.Resource.Descriptor do
  @moduledoc """
      Struct that describes a resource, i.e. classname, id and fields
  """

  @ensurefields [:classname]
  defstruct classname: nil,
            id: nil,
            fields: []

  @type classname_t :: String.t()
  @type id_t :: pos_integer | nil
  @type ids_t :: [id_t()] | nil
  @type fieldname_t :: String.t()
  @type t :: %__MODULE__{
          classname: classname_t() | nil,
          id: id_t,
          fields: [fieldname_t()]
        }

  @doc false
  @spec add_fields(t(), list(fieldname_t())) :: t()
  def add_fields(%__MODULE__{fields: existing_fields} = request, fields) when is_list(fields) do
    new_fields =
      existing_fields
      |> Enum.concat(fields)
      |> Enum.uniq()

    %__MODULE__{request | fields: new_fields}
  end

  @doc false
  @spec add_field(t(), fieldname_t()) :: t()
  def add_field(%__MODULE__{fields: fields} = request, field) do
    new_fields = [field | fields] |> Enum.uniq()
    %__MODULE__{request | fields: new_fields}
  end

  @doc """
  Builds the URL path for a given resource.
  """
  @spec uri(t()) :: String.t()
  def uri(%__MODULE__{id: id, fields: fields} = resource) do
    resource
    |> guid()
    |> append_fields(fields)
  end

  defp guid(%__MODULE__{classname: classname, id: id}) do
    "#{classname}.#{to_string(id)}"
  end

  defp append_fields(g, fields) do
    g <> fields_to_string(fields)
  end

  defp fields_to_string(fields) do
    cond do
      nil == fields ->
        ""

      [] == fields ->
        ""

      true ->
        fields
        |> Enum.map(&to_string/1)
        |> Enum.join(",")
        |> (fn s -> "[" <> s <> "]" end).()
    end
  end
end

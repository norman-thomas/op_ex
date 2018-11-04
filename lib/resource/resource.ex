defmodule OpenPublishing.Resource do
  @moduledoc """
  Generic resource handling module. It has convenience functions for requesting resources
  and successively adding fields to the request.
  """

  @ensurefields [:classname]
  defstruct classname: nil,
            id: nil,
            fields: []

  @type classname_t :: String.t()
  @type fieldname_t :: String.t()
  @type id_t :: pos_integer | nil
  @type ids_t :: id_t() | list(pos_integer)
  @type t :: %__MODULE__{
          classname: classname_t() | nil,
          id: ids_t,
          fields: [fieldname_t()]
        }

  @path "/resource/v2/"

  @doc """
  Builds a bare resource request.

  ## Example

      iex> OpenPublishing.Resource.new("document", 1387)
      %OpenPublishing.Resource{
        classname: "document",
        id: 1387,
        fields: []
      }
  """
  @spec new(classname_t(), ids_t()) :: t()
  def new(classname, id) do
    %__MODULE__{classname: classname, id: id}
  end

  @doc """
  Builds a bare resource search request.

  ## Example

      iex> OpenPublishing.Resource.search("document")
      %OpenPublishing.Resource{
        classname: "document",
        id: nil,
        fields: []
      }
  """
  @spec search(classname_t()) :: t()
  def search(classname) do
    %__MODULE__{classname: classname}
  end

  @doc """
  Adds multiple fields to the resource request

  ## Example

      iex> doc = OpenPublishing.Resource.new("document", 1387)
      iex> OpenPublishing.Resource.add_fields(doc, ["title", "authors"])
      %OpenPublishing.Resource{
        classname: "document",
        id: 1387,
        fields: ["title", "authors"]
      }
  """
  @spec add_fields(t(), list(fieldname_t())) :: t()
  def add_fields(%__MODULE__{fields: existing_fields} = request, fields) when is_list(fields) do
    new_fields =
      existing_fields
      |> Enum.concat(fields)
      |> Enum.uniq()

    %__MODULE__{request | fields: new_fields}
  end

  @doc """
  Adds a field to the resource request
  """
  @spec add_field(t(), fieldname_t()) :: t()
  def add_field(%__MODULE__{fields: fields} = request, field) do
    new_fields = [field | fields] |> Enum.uniq()
    %__MODULE__{request | fields: new_fields}
  end

  defp prepend_path(g) do
    @path <> g
  end

  @doc """
  Builds the URL path for a given resource.
  """
  @spec uri(t()) :: String.t()
  def uri(%__MODULE__{id: id, fields: fields} = resource) when is_integer(id) do
    resource
    |> guid()
    |> append_fields(fields)
    |> prepend_path()
  end

  def uri(%__MODULE__{id: ids, fields: fields} = resource) when is_list(ids) do
    resource
    |> guid()
    |> Enum.map(&append_fields(&1, fields))
    |> Enum.join(",")
    |> prepend_path()
  end

  @doc """
  Checks whether a given string is a GUID.
  """
  @spec is_guid?(String.t()) :: boolean()
  def is_guid?(str) when is_binary(str) do
    str =~ ~r/^[a-zA-Z_0-9]+\.[0-9]+/
  end

  def is_guid?(_) do
    false
  end

  defp guid(%__MODULE__{classname: classname, id: id}) when is_integer(id) and id >= 0 do
    "#{classname}.#{to_string(id)}"
  end

  defp guid(%__MODULE__{id: ids} = resource) when is_list(ids) do
    ids
    |> Enum.map(fn id -> guid(%__MODULE__{resource | id: id}) end)
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

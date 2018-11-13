defmodule OpenPublishing.Resource do
  @moduledoc """
  Generic resource handling module. It has convenience functions for requesting resources
  and successively adding fields to the request.
  """

  alias OpenPublishing.Resource.Descriptor

  defstruct resources: []

  @type t :: %__MODULE__{
          resources: [Descriptor.t()]
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
  @spec new(Descriptor.classname_t(), Descriptor.ids_t()) :: t()
  def new(classname, id) when is_integer(id) do
    %__MODULE__{resources: [%Descriptor{classname: classname, id: id}]}
  end

  def new(classname, ids) when is_list(ids) do
    resources = for id <- ids, do: new(classname, id)

    %__MODULE__{resources: resources}
  end

  def concat(resources) when is_list(resources) do
    rs =
      resources
      |> Enum.map(fn %__MODULE__{resources: r} -> r end)
      |> Enum.concat()

    %__MODULE__{resources: rs}
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
  @spec search(Descriptor.classname_t()) :: t()
  def search(classname) do
    %__MODULE__{resources: [%Descriptor{classname: classname}]}
  end

  @doc """
  Adds multiple fields to the resource request

  ## Example

      iex> doc = OpenPublishing.Resource.new("document", 1387)
      iex> OpenPublishing.Resource.add_fields(doc, ["title", "authors"])
      %OpenPublishing.Resource{
        resources: %OpenPublishing.Resource.Descriptor{
          classname: "document",
          id: 1387,
          fields: ["title", "authors"]
        }
      }
  """
  @spec add_fields(t(), list(Descriptor.fieldname_t())) :: t()
  def add_fields(%__MODULE__{resources: resources}, fields) when is_list(fields) do
    updated_resources = for r <- resources, do: Descriptor.add_fields(r, fields)

    %__MODULE__{resources: updated_resources}
  end

  @doc """
  Adds a field to the resource request
  """
  @spec add_field(t(), Descriptor.fieldname_t()) :: t()
  def add_field(%__MODULE__{resources: resources}, field) do
    updated_resources = for r <- resources, do: Descriptor.add_field(r, field)

    %__MODULE__{resources: updated_resources}
  end

  defp prepend_path(g) do
    @path <> g
  end

  @doc """
  Builds the URL path for a given resource.
  """
  @spec uri(t()) :: String.t()
  def uri(%__MODULE__{resources: resources}) do
    resources
    |> Enum.map(&Descriptor.uri/1)
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

  def guid(classname, id) when is_binary(classname) and is_integer(id) and id >= 0 do
    "#{classname}.#{to_string(id)}"
  end
end

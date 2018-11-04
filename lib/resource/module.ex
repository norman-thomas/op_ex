defmodule OpenPublishing.Resource.Implementation do
  @moduledoc """
  Contains macros to generate resource modules and convenience functions
  in a declarative manner.
  """

  use OK.Pipe

  alias OpenPublishing.Resource
  alias OpenPublishing.Resource.Helper

  @type context :: OpenPublishing.Context.t()
  @type ids_t :: Resource.ids_t()
  @type fieldname_t :: Resource.fieldname_t()

  @callback load(context, ids_t(), list(fieldname_t())) :: Helper.response_t()

  @doc """
  Generates a dedicated module for the specified resource class.
  The module will contain the functions `load`, `search` and `uri`
  as well as field accessor functions as specified via the nested `field` macros.

  ```elixir
  object Document do
    aspect ":basic" do
      field :id
      field :title
      field :subtitle
    end
  end
  ```
  """
  defmacro object(classname, do: block) do
    parent = __CALLER__.module
    module_name = Macro.expand(classname, __CALLER__)
    module_name = Module.concat(parent, module_name)

    quote do
      OpenPublishing.Resource.Implementation.create_module(
        unquote(classname),
        unquote(module_name),
        unquote(Macro.escape(block)),
        __ENV__
      )
    end
  end

  @doc false
  def create_module(classname, module_name, block, env) do
    classname = classname |> Module.split() |> Enum.join(".") |> Macro.underscore()

    fieldnames =
      block
      |> gather_fields()
      |> List.flatten()
      |> Enum.map(fn field -> {field, :nothing} end)

    contents =
      quote do
        @moduledoc """
        Default implementation for #{unquote(classname)} class
        """
        import OpenPublishing.Resource.Implementation
        @behaviour OpenPublishing.Resource.Implementation

        @classname unquote(classname)
        defstruct unquote(fieldnames)

        unquote(block)

        def load(ctx, id, fields \\ [])

        @doc """
        Load `#{unquote(classname)}` by `id`.

        If `id` is a list, then multiple objects will be loaded
        """
        def load(%OpenPublishing.Context{} = ctx, id, fields) when is_integer(id) do
          resource =
            unquote(classname)
            |> OpenPublishing.Resource.new(id)
            |> OpenPublishing.Resource.add_fields(fields)

          Helper.load(ctx, resource)
        end

        def load(%OpenPublishing.Context{} = ctx, ids, fields) when is_list(ids) do
          resource =
            unquote(classname)
            |> OpenPublishing.Resource.new(ids)
            |> OpenPublishing.Resource.add_fields(fields)

          Helper.load(ctx, resource)
        end

        @doc """
        Search `#{unquote(classname)}` by arbitrary filters
        """
        def search(%OpenPublishing.Context{} = ctx, filters, fields \\ []) when is_list(filters) and is_list(fields) do
          resource =
            unquote(classname)
            |> OpenPublishing.Resource.search()
            |> OpenPublishing.Resource.add_fields(fields)

          # TODO implement search filter to URL conversion
          Helper.load(ctx, resource)
        end

        @doc """
        Resource path for `#{unquote(classname)}`
        """
        @spec uri(OpenPublishing.Resource.ids_t()) :: String.t()
        def uri(id) do
          OpenPublishing.Resource.uri(%OpenPublishing.Resource{classname: unquote(classname), id: id})
        end
      end

    Module.create(module_name, contents, Macro.Env.location(env))
  end

  @doc """
  Adds aspect information to nested fields
  """
  defmacro aspect(name, do: {:__block__, _, field_list}) do
    fields =
      field_list
      |> Enum.map(fn f -> add_aspect(name, f) end)

    quote do
      unquote(fields)
    end
  end

  defmacro aspect(name, do: {:field, _, _} = f) do
    new_field = add_aspect(name, f)

    quote do
      unquote(new_field)
    end
  end

  defp add_aspect(asp, {:field, l, f}) do
    {:field, l, f ++ [aspect: asp]}
  end

  @doc """
  Generates convenience functions for accessing fields of a loaded resource
  and for requesting a field when building a resource request.
  """
  defmacro field(name, opts) do
    field_name = to_string(name)
    aspect_name = get_aspect_name(opts)
    accessor = get_accessor(name, opts)

    quote do
      @doc """
      Field `#{unquote(field_name)}`, loaded via aspect `#{unquote(aspect_name)}`
      """
      def unquote(name)(%OpenPublishing.Resource{classname: @classname} = resource) do
        OpenPublishing.Resource.add_field(resource, unquote(aspect_name))
      end

      def unquote(name)(%__MODULE__{unquote(name) => value} = resource) do
        value
      end
    end
  end

  # Macro magic below

  defp get_accessor(name, opts) when is_list(opts) do
    case Keyword.fetch(opts, :accessor) do
      {:ok, value} -> value
      _ -> name
    end
  end

  defp get_accessor(_, {:accessor, value}) do
    value
  end

  defp get_accessor(name, _) do
    name
  end

  defp get_aspect_name(opts) when is_list(opts) do
    Keyword.fetch!(opts, :aspect)
  end

  defp get_aspect_name(opts) when is_tuple(opts) do
    Keyword.fetch!([opts], :aspect)
  end

  defp gather_fields({:__block__, x, [h | t]}) do
    [gather_fields(h) | gather_fields({:__block__, x, t})]
  end

  defp gather_fields({:__block__, _x, []}) do
    []
  end

  defp gather_fields({:aspect, _line, [_aspect_name, [do: block]]}) do
    [gather_fields(block)]
  end

  defp gather_fields({:field, _line, [h]}) do
    h
  end

  defp gather_fields([]) do
    []
  end
end

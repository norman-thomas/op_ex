defmodule OpenPublishing.Resource.Helper do
  @moduledoc false
  use OK.Pipe

  alias OpenPublishing.Context
  alias OpenPublishing.HTTP.Request
  alias OpenPublishing.Resource

  @type response_t :: {:ok, any()} | {:error, term()}

  @spec load(Context.t(), Resource.t()) :: response_t()
  def load(%Context{} = ctx, %Resource{} = resource) do
    path = Resource.uri(resource)

    {:ok, response} =
      ctx
      |> Request.ctx_get(path)
      |> Request.dispatch()
      ~>> Request.get_response()
      ~>> Request.parse_json()

    case from_gjp(response) do
      {:ok, %{guids: guids, objects: objects}} -> build_tree(guids, objects)
      {:error, reason} -> {:error, reason}
    end
  end

  defp from_gjp(%{"OK" => _, "OBJECTS" => %{} = objects, "RESULTS" => guids}) do
    {:ok, %{guids: guids, objects: objects}}
  end

  defp from_gjp(%{"ERROR" => reason}) do
    {:error, reason}
  end

  defp build_tree(value, objects, processed_guids \\ [])

  defp build_tree(guid, %{} = objects, processed_guids) when is_binary(guid) do
    case Resource.is_guid?(guid) and Map.has_key?(objects, guid) do
      false ->
        guid

      true ->
        if guid in processed_guids do
          objects
          |> Map.fetch!(guid)
        else
          objects
          |> Map.fetch!(guid)
          |> build_tree(objects, processed_guids ++ [guid])
        end
    end
  end

  defp build_tree(%{} = values, %{} = objects, processed_guids) do
    values
    |> Enum.map(fn {k, v} ->
      if k in ["GUID"] do
        {String.to_atom(k), v}
      else
        {String.to_atom(k), build_tree(v, objects, processed_guids)}
      end
    end)
    |> Enum.into(%{})
  end

  defp build_tree(values, %{} = objects, processed_guids) when is_list(values) do
    values
    |> Enum.map(fn value -> build_tree(value, objects, processed_guids) end)
  end

  defp build_tree(value, %{}, _processed_guids), do: value
end

defmodule DeviceClient do
  def get_temp(ip) do
    case Tesla.get("http://#{ip}/rpc/Temperature.GetStatus?id=100") do
      {:ok, resp} ->
        Jason.decode!(resp.body) |> then(fn %{"id" => 100, "tC" => t} -> {:ok, t} end)

      {:error, _} ->
        {:error, :error}
    end
  end

  def switch_on(ip) do
    case Tesla.get("http://#{ip}/rpc/Switch.Set?id=0&on=true") do
      {:ok, _} -> {:ok, :heating}
      {:error, _} -> {:ok, :error}
    end
  end

  def switch_off(ip) do
    case Tesla.get("http://#{ip}/rpc/Switch.Set?id=0&on=false") do
      {:ok, _} -> {:ok, :idle}
      {:error, _} -> {:ok, :error}
    end
  end

  def get_status(ip) do
    case Tesla.get("http://#{ip}/rpc/Switch.GetStatus?id=0") do
      {:ok, resp} ->
        case Jason.decode!(resp.body) |> then(fn t -> Map.get(t, "output") end) do
          false -> {:ok, :idle}
          true -> {:ok, :heating}
        end

      {:error, _} ->
        {:ok, :error}
    end
  end
end

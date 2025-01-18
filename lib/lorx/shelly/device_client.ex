defmodule DeviceClient do
  def get_temp(ip) do
    "http://#{ip}/rpc/Temperature.GetStatus?id=100"
    |> Tesla.get!()
    |> then(fn r -> r.body end)
    |> Jason.decode!()
    |> then(fn %{"id" => 100, "tC" => t} -> t end)
  end

  def switch_on(ip) do
    "http://#{ip}/rpc/Switch.Set?id=0&on=true"
    |> Tesla.get!()
    |> then(fn r -> r.status end)
  end

  def switch_off(ip) do
    "http://#{ip}/rpc/Switch.Set?id=0&on=false"
    |> Tesla.get!()
    |> then(fn r -> r.status end)
  end

  def get_status(ip) do
    case "http://#{ip}/rpc/Switch.GetStatus?id=0"
         |> Tesla.get!()
         |> then(fn r -> r.body end)
         |> Jason.decode!()
         |> then(fn t -> Map.get(t, "output") end) do
      false -> :off
      true -> :on
    end
  end
end

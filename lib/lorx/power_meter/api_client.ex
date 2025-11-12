defmodule Lorx.PowerMeter.ApiClient do
  def get_consumption(ip) do
    "http://#{ip}/rpc/EM1.GetStatus?id=0"
    |> Tesla.get!()
    |> then(fn r -> r.body end)
    |> Jason.decode!()
    |> then(fn d ->
      %{
        power_factor: d["pf"],
        act_power: d["act_power"],
        voltage: d["voltage"],
        current: d["current"]
      }
    end)
  end
end

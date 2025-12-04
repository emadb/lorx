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

  def set_alarm(ip) do
    case Tesla.get("http://#{ip}/rpc/Switch.Set?id=0&on=true") do
      {:ok, _} ->
        {:ok, :on}

      {:error, e} ->
        Logger.error("PowerMeter.switch_on(#{ip})", %{error: e})
        {:ok, :error}
    end
  end

  def unset_alarm(ip) do
    case Tesla.get("http://#{ip}/rpc/Switch.Set?id=0&on=false") do
      {:ok, _} ->
        {:ok, :on}

      {:error, e} ->
        Logger.error("PowerMeter.switch_off(#{ip})", %{error: e})
        {:ok, :error}
    end
  end
end

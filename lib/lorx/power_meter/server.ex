defmodule Lorx.PowerMeter.Server do
  use GenServer, restart: :transient
  alias Lorx.PowerMeter.PowerEntry
  alias Lorx.Repo

  @fifteen_minutes 900_000
  @alarm_duration 1_500
  @overload_count_max 3

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok,
     %{
       values: [],
       last_saved: DateTime.utc_now(),
       overload_counter: 0
     }, {:continue, :setup}}
  end

  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end

  def handle_continue(:setup, state) do
    Process.send_after(self(), :check_consumption, 0)

    {:noreply, state}
  end

  def handle_info(:check_consumption, state) do
    pm_ip = Application.get_env(:lorx, :device)[:pm_ip]
    Process.send_after(self(), :check_consumption, 5000)
    value = Lorx.PowerMeter.ApiClient.get_consumption(pm_ip)

    Phoenix.PubSub.broadcast(Lorx.PubSub, "power_consumption", value)

    max_power = Application.get_env(:lorx, :device)[:max_power]
    overloads = overload?(value, max_power, state.overload_count)

    if interval_elapsed?(state.last_saved, @fifteen_minutes) do
      w = average(state.values)

      pe = %PowerEntry{
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
        w: w,
        wh: w * 0.25
      }

      Repo.insert!(pe)

      new_state = %{
        state
        | last_saved: DateTime.utc_now(),
          values: [],
          overload_counter: overloads
      }

      {:noreply, new_state}
    else
      values = state.values ++ [value]
      {:noreply, %{state | values: values, overload_counter: overloads}}
    end
  end

  def handle_info(:unset_alarm, state) do
    pm_ip = Application.get_env(:lorx, :device)[:pm_ip]
    Lorx.PowerMeter.ApiClient.unset_alarm(pm_ip)
    {:noreply, state}
  end

  # TODO: non tornare tutto lo stato
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
  end

  defp average(values) do
    values
    |> Enum.reduce(0, fn e, acc -> acc + e.act_power end)
    |> then(fn sum -> sum / Enum.count(values) end)
    |> then(fn avg -> round(avg * 1000) / 1000 end)
  end

  defp interval_elapsed?(last_saved, saving_interval) do
    delta = DateTime.add(last_saved, div(saving_interval, 1000), :second)
    DateTime.before?(delta, DateTime.utc_now())
  end

  defp overload?(%{act_power: watt}, max, count)
       when watt > max and count >= @overload_count_max do
    pm_ip = Application.get_env(:lorx, :device)[:pm_ip]
    Lorx.PowerMeter.ApiClient.set_alarm(pm_ip)
    Process.send_after(self(), :unset_alarm, @alarm_duration)
    0
  end

  defp overload?(%{act_power: watt}, max, count) when watt > max, do: count + 1
  defp overload?(%{act_power: _}, _, _), do: 0
end

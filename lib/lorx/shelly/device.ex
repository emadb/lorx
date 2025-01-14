defmodule Lorx.Device do
  use GenServer
  @threshold 0.2
  @polling_interval 1000 * 60

  defp via_tuple(id), do: {:via, Registry, {Lorx.Device.Registry, id}}

  def start_link([id]) do
    GenServer.start_link(__MODULE__, [id], name: via_tuple(id))
  end

  def init([id]) do
    {:ok, %{id: id, device: 0, schedules: [], prev_temp: 0, status: nil}, {:continue, :setup}}
  end

  def handle_continue(:setup, state) do
    Process.send_after(self(), :check_temp, @polling_interval)

    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)

    {:noreply, %{state | device: device, schedules: schedules}}
  end

  def handle_info(:check_temp, state) do
    Process.send_after(self(), :check_temp, @polling_interval)
    current_temp = DeviceClient.get_temp(state.device.ip)

    if abs(current_temp - state.prev_temp) > @threshold do
      sched = get_current_schedule(state.schedules)

      IO.inspect(current_temp, label: "Current temp")

      new_status =
        cond do
          sched.temp > current_temp + @threshold ->
            IO.inspect({sched.temp, current_temp}, label: "Switch on")
            DeviceClient.switch_on(state.device.ip)
            :on

          sched.temp <= current_temp - @threshold ->
            IO.inspect({sched.temp, current_temp}, label: "Switch off")
            DeviceClient.switch_off(state.device.ip)
            :off
        end

      {:noreply, %{state | prev_temp: current_temp, status: new_status}}
    else
      {:noreply, state}
    end

    {:noreply, state}
  end

  defp get_current_schedule(schedules) do
    Enum.find(schedules, fn s ->
      Time.compare(s.start_time, Time.utc_now()) == :lt &&
        Time.compare(s.end_time, Time.utc_now()) == :gt
    end)
  end
end

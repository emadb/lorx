defmodule Lorx.DeviceState do
  @threshold 0.2
  defstruct [:id, :device, :schedules, :prev_temp, :temp, :status]

  def init(id) do
    %__MODULE__{id: id, device: 0, schedules: [], prev_temp: 0, temp: 0, status: nil}
  end

  def load(state) do
    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)

    current_temp = DeviceClient.get_temp(device.ip)
    status = DeviceClient.get_status(device.ip)

    %__MODULE__{
      state
      | device: device,
        schedules: schedules,
        temp: current_temp,
        status: status
    }
  end

  def update_state(state) do
    current_temp = DeviceClient.get_temp(state.device.ip)
    current_status = DeviceClient.get_status(state.device.ip)
    schedules = Lorx.Management.list_schedules(state.device.id)
    sched = get_current_schedule(schedules)

    # TODO: Testare la logica per ridurre al minimo le chiamate
    if abs(current_temp - state.prev_temp) > @threshold do
      new_status =
        cond do
          sched.temp > current_temp + @threshold && current_status == :idle ->
            IO.inspect({sched.temp, current_temp}, label: "Switch on")
            DeviceClient.switch_on(state.device.ip)
            :heating

          sched.temp <= current_temp - @threshold && current_status == :heating ->
            IO.inspect({sched.temp, current_temp}, label: "Switch off")
            DeviceClient.switch_off(state.device.ip)
            :idle

          true ->
            IO.inspect({current_temp, sched.temp})
            :idle
        end

      %__MODULE__{state | prev_temp: current_temp, status: new_status}
    else
      %__MODULE__{state | prev_temp: current_temp}
    end
  end

  defp get_current_schedule(schedules) do
    now = Time.utc_now()

    Enum.find(schedules, fn %{start_time: start_time, end_time: end_time} ->
      case Time.compare(start_time, end_time) do
        :lt -> Time.compare(now, start_time) != :lt and Time.compare(now, end_time) == :lt
        _ -> Time.compare(now, start_time) != :lt or Time.compare(now, end_time) == :lt
      end
    end)
  end
end

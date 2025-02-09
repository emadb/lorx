defmodule Lorx.DeviceState do
  @threshold 0.5
  defstruct [:id, :device, :schedules, :prev_temp, :temp, :status, :target_temp, :updated?]

  def init(id) do
    %__MODULE__{id: id, device: 0, schedules: [], prev_temp: 0, temp: 0, status: nil}
  end

  def load(state) do
    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)

    current_temp = DeviceClient.get_temp(device.ip)
    status = DeviceClient.get_status(device.ip)
    sched = get_current_schedule(schedules)

    %__MODULE__{
      state
      | device: device,
        schedules: schedules,
        temp: current_temp,
        status: status,
        target_temp: sched.temp
    }
  end

  def update_state(state) do
    current_temp = DeviceClient.get_temp(state.device.ip)
    current_status = DeviceClient.get_status(state.device.ip)
    schedules = Lorx.Management.list_schedules(state.device.id)
    sched = get_current_schedule(schedules)

    new_status =
      cond do
        is_nil(sched) ->
          current_status

        sched.temp > current_temp + @threshold &&
            current_status == :idle ->
          DeviceClient.switch_on(state.device.ip)

        sched.temp < current_temp - @threshold &&
            current_status == :heating ->
          DeviceClient.switch_off(state.device.ip)

        true ->
          current_status
      end

    new_state = %__MODULE__{
      state
      | prev_temp: state.temp,
        status: new_status,
        temp: current_temp,
        target_temp: if(is_nil(sched), do: 0, else: sched.temp)
    }

    %__MODULE__{
      new_state
      | updated?: new_state != state
    }
  end

  defp get_current_schedule(schedules) do
    %NaiveDateTime{hour: h, minute: m, second: s} = NaiveDateTime.local_now()
    {:ok, now} = Time.new(h, m, s)
    day = Date.day_of_week(Date.utc_today())
    # TODO: gestire il true false come boolean invece che stringa
    schedules
    |> Enum.filter(fn %{days: days} -> Enum.at(days, day - 1) == "true" end)
    |> Enum.find(fn %{start_time: start_time, end_time: end_time} ->
      case Time.compare(start_time, end_time) do
        :lt ->
          Time.compare(now, start_time) != :lt and Time.compare(now, end_time) == :lt

        _ ->
          Time.compare(now, start_time) != :lt or Time.compare(now, end_time) == :lt
      end
    end)
  end
end

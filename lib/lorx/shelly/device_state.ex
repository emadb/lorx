defmodule Lorx.DeviceState do
  @threshold 0.5
  defstruct [:id, :device, :schedules, :prev_temp, :temp, :status, :target_temp, :updated?, :mode]

  def init(id) do
    %__MODULE__{id: id, device: 0, schedules: [], prev_temp: 0, temp: 0, status: nil, mode: :auto}
  end

  def load(%__MODULE__{} = state) do
    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)
    sched = get_current_schedule(schedules)

    state = %__MODULE__{
      state
      | device: device,
        schedules: schedules,
        target_temp: get_target_temp(sched),
        mode: :auto
    }

    with {:ok, current_temp} <- DeviceClient.get_temp(device.ip),
         {:ok, status} <- DeviceClient.get_status(device.ip) do
      %__MODULE__{
        state
        | temp: current_temp,
          status: status
      }
    else
      _ ->
        state
    end
  end

  defp get_target_temp(nil), do: 15.0
  defp get_target_temp(sched), do: sched.temp

  def update_state(%__MODULE__{mode: :on} = state) do
    with {:ok, current_temp} <- DeviceClient.get_temp(state.device.ip),
         {:ok, current_status} <- DeviceClient.get_status(state.device.ip) do
      {:ok, new_status} =
        if current_status != :heating,
          do: DeviceClient.switch_on(state.device.ip),
          else: {:ok, current_status}

      %__MODULE__{
        state
        | prev_temp: state.temp,
          status: new_status,
          temp: current_temp
      }
    else
      _ ->
        state
    end
  end

  def update_state(%__MODULE__{mode: :off} = state) do
    with {:ok, current_temp} <- DeviceClient.get_temp(state.device.ip),
         {:ok, current_status} <- DeviceClient.get_status(state.device.ip) do
      {:ok, new_status} =
        if current_status != :idle,
          do: DeviceClient.switch_off(state.device.ip),
          else: {:ok, current_status}

      %__MODULE__{
        state
        | prev_temp: state.temp,
          status: new_status,
          temp: current_temp
      }
    else
      _ ->
        state
    end
  end

  def update_state(%__MODULE__{mode: :auto} = state) do
    schedules = Lorx.Management.list_schedules(state.device.id)
    sched = get_current_schedule(schedules)

    with {:ok, current_temp} <- DeviceClient.get_temp(state.device.ip),
         {:ok, current_status} <- DeviceClient.get_status(state.device.ip) do
      {:ok, new_status} =
        cond do
          is_nil(sched) ->
            {:ok, current_status}

          sched.temp > current_temp + @threshold &&
              current_status == :idle ->
            DeviceClient.switch_on(state.device.ip)

          sched.temp < current_temp - @threshold &&
              current_status == :heating ->
            DeviceClient.switch_off(state.device.ip)

          true ->
            {:ok, current_status}
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
    else
      _ ->
        state
    end
  end

  defp get_current_schedule(schedules) do
    %NaiveDateTime{hour: h, minute: m, second: s} = NaiveDateTime.local_now()
    {:ok, now} = Time.new(h, m, s)
    day = Date.day_of_week(Date.utc_today())
    # TODO: gestire il true false come boolean invece che stringa
    schedules
    |> Enum.filter(fn %{days: days} -> Enum.at(days, day - 1) end)
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

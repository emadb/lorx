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
    Process.send_after(self(), :check_temp, 0)

    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)

    {:noreply, %{state | device: device, schedules: schedules}}
  end

  def handle_info(:check_temp, state) do
    Process.send_after(self(), :check_temp, @polling_interval)
    current_temp = DeviceClient.get_temp(state.device.ip)
    current_status = DeviceClient.get_status(state.device.ip)
    sched = get_current_schedule(state.schedules)

    Phoenix.PubSub.broadcast(Lorx.PubSub, "dashboard", %{
      device_id: state.device.id,
      temp: current_temp,
      status: current_status,
      target_temp: sched.temp
    })

    # TODO: Testare la logica per ridurre al minimo le chiamate
    if abs(current_temp - state.prev_temp) > @threshold do
      new_status =
        cond do
          sched.temp > current_temp + @threshold && current_status == :off ->
            IO.inspect({sched.temp, current_temp}, label: "Switch on")
            DeviceClient.switch_on(state.device.ip)
            :on

          sched.temp <= current_temp - @threshold && current_status == :on ->
            IO.inspect({sched.temp, current_temp}, label: "Switch off")
            DeviceClient.switch_off(state.device.ip)
            :off

          true ->
            IO.inspect({current_temp, sched.temp})
            :off
        end

      {:noreply, %{state | prev_temp: current_temp, status: new_status}}
    else
      {:noreply, state}
    end

    {:noreply, state}
  end

  defp get_current_schedule(schedules) do
    # IO.inspect(schedules, label: "SCHEDS")

    # Enum.find(schedules, fn s ->
    #   IO.inspect(
    #     {Time.utc_now(), s.start_time, s.end_time, Time.compare(s.start_time, Time.utc_now()),
    #      Time.compare(s.end_time, Time.utc_now())}
    #   )

    #   Time.compare(s.start_time, Time.utc_now()) == :lt &&
    #     Time.compare(s.end_time, Time.utc_now()) == :gt
    # end)
    now = Time.utc_now()

    Enum.find(schedules, fn %{start_time: start_time, end_time: end_time} ->
      case Time.compare(start_time, end_time) do
        :lt -> Time.compare(now, start_time) != :lt and Time.compare(now, end_time) == :lt
        _ -> Time.compare(now, start_time) != :lt or Time.compare(now, end_time) == :lt
      end
    end)
  end
end

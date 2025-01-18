defmodule Lorx.Device do
  use GenServer
  @threshold 0.2
  @polling_interval 1000 * 60

  defp via_tuple(id), do: {:via, Registry, {Lorx.Device.Registry, id}}

  def start_link([id]) do
    GenServer.start_link(__MODULE__, [id], name: via_tuple(id))
  end

  def init([id]) do
    {:ok, %{id: id, device: 0, schedules: [], prev_temp: 0, temp: 0, status: nil},
     {:continue, :setup}}
  end

  def handle_continue(:setup, state) do
    Process.send_after(self(), :check_temp, 0)

    device = Lorx.Management.get_device!(state.id)
    schedules = Lorx.Management.list_schedules(device.id)

    current_temp = DeviceClient.get_temp(device.ip)
    status = DeviceClient.get_status(device.ip)

    {:noreply,
     %{
       state
       | device: device,
         schedules: schedules,
         temp: current_temp,
         status: status
     }}
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

  def get_status(id) do
    GenServer.call(via_tuple(id), :get_status)
  end

  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
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

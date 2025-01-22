defmodule Lorx.Device do
  use GenServer

  @polling_interval 1000 * 60

  defp via_tuple(id), do: {:via, Registry, {Lorx.Device.Registry, id}}

  def start_link([id]) do
    GenServer.start_link(__MODULE__, [id], name: via_tuple(id))
  end

  def init([id]) do
    {:ok, Lorx.DeviceState.init(id), {:continue, :setup}}
  end

  def get_status(id) do
    GenServer.call(via_tuple(id), :get_status)
  end

  def handle_continue(:setup, state) do
    Process.send_after(self(), :check_temp, 0)
    new_state = Lorx.DeviceState.load(state)

    {:noreply, new_state}
  end

  def handle_info(:check_temp, state) do
    Process.send_after(self(), :check_temp, @polling_interval)
    new_state = Lorx.DeviceState.update_state(state)

    Phoenix.PubSub.broadcast(Lorx.PubSub, "dashboard", %Lorx.NotifyTemp{
      device_id: new_state.device.id,
      temp: new_state.temp,
      status: new_state.status,
      target_temp: new_state.target_temp
    })

    {:noreply, new_state}
  end

  # non tornare tutto lo stato
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
  end
end

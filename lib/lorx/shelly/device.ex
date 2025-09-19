defmodule Lorx.Device do
  use GenServer, restart: :transient

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

  def set_mode(id, mode) when mode in [:auto, :on, :off] do
    GenServer.cast(via_tuple(id), {:set_mode, mode})
  end

  def stop(id) do
    GenServer.stop(via_tuple(id), :normal)
  end

  def handle_continue(:setup, state) do
    Process.send_after(self(), :check_temp, 0)
    new_state = Lorx.DeviceState.load(state)

    {:noreply, new_state}
  end

  def handle_info(:check_temp, state) do
    polling_interval = Application.get_env(:lorx, :device)[:polling_interval]
    Process.send_after(self(), :check_temp, polling_interval)
    new_state = Lorx.DeviceState.update_state(state)

    evt_payload = %Lorx.NotifyTemp{
      device_id: new_state.device.id,
      temp: new_state.temp,
      status: new_state.status,
      target_temp: new_state.target_temp,
      mode: new_state.mode
    }

    Phoenix.PubSub.broadcast(Lorx.PubSub, "temperature_notification", evt_payload)

    if new_state.updated? do
      Phoenix.PubSub.broadcast(Lorx.PubSub, "dashboard", evt_payload)
    end

    {:noreply, new_state}
  end

  # TODO: non tornare tutto lo stato
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:set_mode, mode}, state) do
    new_state = Lorx.DeviceState.update_state(%{state | mode: mode})

    evt_payload = %Lorx.NotifyTemp{
      device_id: new_state.device.id,
      temp: new_state.temp,
      status: new_state.status,
      target_temp: new_state.target_temp,
      mode: new_state.mode
    }

    Phoenix.PubSub.broadcast(Lorx.PubSub, "dashboard", evt_payload)
    {:noreply, new_state}
  end
end

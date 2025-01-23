defmodule LorxWeb.LiveDashboard do
  alias Lorx.DeviceState
  use LorxWeb, :live_view
  alias Lorx.Device

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")

    {:ok,
     %DeviceState{
       temp: temp,
       status: status,
       target_temp: target_temp
     }} = Device.get_status(1)

    {:ok, assign(socket, temp: temp, status: status, target_temp: target_temp)}
  end

  def handle_info(
        %Lorx.NotifyTemp{} = data,
        socket
      ) do
    {:noreply,
     assign(socket, temp: data.temp, status: data.status, target_temp: data.target_temp)}
  end
end

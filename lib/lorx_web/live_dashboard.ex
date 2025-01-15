defmodule LorxWeb.LiveDashboard do
  use LorxWeb, :live_view

  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")
    {:ok, socket}
  end

  def handle_info(%{device_id: device_id, temp: temp}, socket) do
    send_update(LorxWeb.Lorx.DeviceWidget, id: device_id, temp: temp)
    {:noreply, assign(socket, temperature: temp)}
  end
end

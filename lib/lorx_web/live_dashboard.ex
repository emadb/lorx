defmodule LorxWeb.LiveDashboard do
  use LorxWeb, :live_view

  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")
    {:ok, socket}
  end

  def handle_info(
        %{device_id: device_id, temp: temp, status: status, target_temp: target_temp},
        socket
      ) do
    send_update(LorxWeb.Lorx.DeviceWidget,
      id: to_string(device_id),
      temperature: temp,
      status: status,
      target_temp: target_temp
    )

    {:noreply, assign(socket, temperature: temp, status: status, target_temp: target_temp)}
  end
end

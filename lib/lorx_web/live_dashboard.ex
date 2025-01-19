defmodule LorxWeb.LiveDashboard do
  use LorxWeb, :live_view
  alias Lorx.Device

  def mount(params, session, socket) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard")

    {:ok,
     %{
       temp: temp,
       status: status
     }} = Device.get_status(1)

    IO.inspect(socket, label: "LiveDashboard mount")
    {:ok, assign(socket, temperature: temp, status: status, target_temp: "?")}
  end

  def handle_info(
        %Lorx.NotifyTemp{} = data,
        socket
      ) do
    send_update(LorxWeb.Lorx.DeviceWidget,
      id: to_string(data.device_id),
      temperature: data.temp,
      status: data.status,
      target_temp: data.target_temp
    )

    {:noreply,
     assign(socket, temperature: data.temp, status: data.status, target_temp: data.target_temp)}
  end
end

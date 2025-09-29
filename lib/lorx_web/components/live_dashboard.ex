defmodule LorxWeb.LiveDashboard do
  use LorxWeb, :live_view
  alias Lorx.Device

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Lorx.PubSub, "status_updated")

    devices =
      Lorx.DeviceSupervisor.list_children_ids()
      |> Enum.map(fn id ->
        elem(Device.get_status(id), 1)
      end)
      |> Enum.map(fn d ->
        %{
          id: d.id,
          name: d.device.name,
          temp: d.temp,
          status: d.status,
          target_temp: d.target_temp,
          mode: d.mode
        }
      end)

    {:ok, assign(socket, devices: devices)}
  end

  def handle_info(%Lorx.NotifyTemp{} = data, socket) do
    send_update(LorxWeb.DeviceComponent, id: data.device_id, data: data)
    {:noreply, socket}
  end
end

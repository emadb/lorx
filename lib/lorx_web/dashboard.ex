defmodule LorxWeb.Lorx.DashboardView do
  alias Lorx.Management
  # use Phoenix.LiveView
  use LorxWeb, :live_view

  def render(assigns) do
    ~H"""
    Current temperature: {@temperature}°C
    """
  end

  def mount(params, session, socket) do
    device = Management.get_device!(1)
    temp = DeviceClient.get_temp(device.ip)

    Phoenix.PubSub.subscribe(Lorx.PubSub, "dashboard", link: true)

    {:ok, assign(socket, temperature: temp)}
  end

  def handle_event("inc_temperature", param, socket) do
    IO.inspect(param, label: ">>>>>")
    {:noreply, socket}
  end

  def handle_info(%{temp: temp}, socket) do
    IO.inspect(temp, label: "NOTIFICATION")
    {:noreply, assign(socket, temperature: temp)}
  end
end

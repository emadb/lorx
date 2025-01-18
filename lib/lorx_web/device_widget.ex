defmodule LorxWeb.Lorx.DeviceWidget do
  alias Lorx.Management
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="hero">
      Current temperature: {@temperature}°C <br /> Status: {@status}
      <br /> Target: {@target_temp}
    </div>
    """
  end

  def mount(socket) do
    device = Management.get_device!(1)
    temp = DeviceClient.get_temp(device.ip)
    status = DeviceClient.get_status(device.ip)

    {:ok, assign(socket, temperature: temp, status: status, target_temp: "?")}
  end

  def update(%{temperature: temp, status: status, target_temp: target_temp}, socket) do
    {:ok, assign(socket, temperature: temp, status: status, target_temp: target_temp)}
  end
end

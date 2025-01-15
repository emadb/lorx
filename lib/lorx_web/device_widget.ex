defmodule LorxWeb.Lorx.DeviceWidget do
  alias Lorx.Management
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="hero">
      Current temperature: {@temperature}°C
    </div>
    """
  end

  def mount(socket) do
    device = Management.get_device!(1)
    temp = DeviceClient.get_temp(device.ip)

    {:ok, assign(socket, temperature: temp)}
  end

  def update(%{temperature: temp}, socket) do
    {:ok, assign(socket, temperature: temp)}
  end
end

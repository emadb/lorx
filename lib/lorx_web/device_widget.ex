defmodule LorxWeb.Lorx.DeviceWidget do
  alias Lorx.Device
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="widget">
      <div class="studio">
        STUDIO <span class={to_string(@status)}></span>
      </div>
      <div class="temperature">{@temperature}°C</div>
      <div class="setpoint">{@target_temp}°C</div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     %{
       temp: temp,
       status: status
     }} = Device.get_status(1)

    IO.inspect({temp, status}, label: "DeviceWidget mount")

    {:ok, assign(socket, temperature: temp, status: status, target_temp: "?")}
  end

  def update(%{temperature: temp, status: status, target_temp: target_temp}, socket) do
    {:ok, assign(socket, temperature: temp, status: status, target_temp: target_temp)}
  end
end

defmodule LorxWeb.Lorx.DeviceWidget do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="widget">
      <div class="studio">
        STUDIO <span class={to_string(@status)}></span>
      </div>
      <div class="temperature">{@temp}°C</div>
      <div class="setpoint">{@target_temp}°C</div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{temp: temp, status: status, target_temp: target_temp}, socket) do
    {:ok, assign(socket, temp: temp, status: status, target_temp: target_temp)}
  end
end

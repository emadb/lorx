defmodule LorxWeb.DeviceComponent do
  # In Phoenix apps, the line is typically: use MyAppWeb, :live_component
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">
          {@name}
          <div class={[
            "badge",
            if(@status == :idle, do: "badge-ghost", else: "badge-primary")
          ]}>
          </div>
        </h2>

        <h1 class="text-5xl font-bold">{@temp}°C</h1>

        <div class="text-neutral-content">{@target_temp}°C</div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, Map.to_list(assigns))}
  end
end

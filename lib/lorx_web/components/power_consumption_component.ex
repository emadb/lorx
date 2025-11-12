defmodule LorxWeb.PowerConsumptionComponent do
  use LorxWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, current_consumption: nil, voltage: nil, current: nil)}
  end

  def update(assigns, socket) do
    # Handle updates from send_update
    consumption_kw =
      if assigns[:w] do
        assigns.w / 1000
      else
        socket.assigns.current_consumption
      end

    voltage = assigns[:volt] || socket.assigns.voltage
    current = assigns[:current] || socket.assigns.current

    {:ok,
     assign(socket,
       current_consumption: consumption_kw,
       voltage: voltage,
       current: current
     )}
  end

  def handle_info(power_data, socket) when is_map(power_data) do
    # Convert watts to kilowatts
    consumption_kw =
      if power_data.act_power do
        power_data.act_power / 1000
      else
        0
      end

    {:noreply,
     assign(socket,
       current_consumption: consumption_kw,
       voltage: power_data.voltage,
       current: power_data.current
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body flex flex-row">
        <div class="grid grid-cols-3 gap-4 w-full">
          <div class="text-center">
            <div class="text-sm text-gray-500 mb-1">Potenza</div>
            <%= if @current_consumption do %>
              <div class="text-xl font-bold">
                {:erlang.float_to_binary(@current_consumption, decimals: 3)} kW
              </div>
            <% else %>
              <div class="text-gray-500">--</div>
            <% end %>
          </div>

          <div class="text-center">
            <div class="text-sm text-gray-500 mb-1">Tensione</div>
            <%= if @voltage do %>
              <div class="text-xl font-bold">
                {Float.round(@voltage, 1)} V
              </div>
            <% else %>
              <div class="text-gray-500">--</div>
            <% end %>
          </div>

          <div class="text-center">
            <div class="text-sm text-gray-500 mb-1">Corrente</div>
            <%= if @current do %>
              <div class="text-xl font-bold">
                {Float.round(@current, 2)} A
              </div>
            <% else %>
              <div class="text-gray-500">--</div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

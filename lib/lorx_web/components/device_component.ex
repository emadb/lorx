defmodule LorxWeb.DeviceComponent do
  use Phoenix.LiveComponent
  alias Lorx.Device

  def mount(socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body flex flex-row justify-between items-start">
        <div class="flex flex-col gap-2">
          <h2 class="card-title">
            <div class={[
              "badge",
              if(@status == :idle,
                do: "badge-ghost",
                else: "badge-success"
              )
            ]} />
            {@name}
          </h2>

          <h1 class="text-5xl font-bold">{@temp}°</h1>
          <div class="text-neutral-content">{@target_temp}°C</div>
        </div>

        <div class="pl-4">
          <div class="flex flex-col gap-1">
            <button
              type="button"
              phx-click="set_mode"
              phx-target={@myself}
              phx-value-mode="auto"
              class={[
                "btn btn-xs sm:btn-sm whitespace-nowrap w-16",
                @mode == :auto && "btn-primary btn-active",
                @mode != :auto && "btn-outline"
              ]}
            >
              AUTO
            </button>
            <button
              type="button"
              phx-click="set_mode"
              phx-target={@myself}
              phx-value-mode="on"
              class={[
                "btn btn-xs sm:btn-sm whitespace-nowrap w-16",
                @mode == :on && "btn-primary btn-active",
                @mode != :on && "btn-outline"
              ]}
            >
              ON
            </button>
            <button
              type="button"
              phx-click="set_mode"
              phx-target={@myself}
              phx-value-mode="off"
              class={[
                "btn btn-xs sm:btn-sm whitespace-nowrap w-16",
                @mode == :off && "btn-primary btn-active",
                @mode != :off && "btn-outline"
              ]}
            >
              OFF
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) when mode in ["on", "off", "auto"] do
    atom_mode = String.to_existing_atom(mode)
    Device.set_mode(socket.assigns.id, atom_mode)
    {:noreply, assign(socket, :mode, atom_mode)}
  end

  def update(assigns, socket) do
    assigns =
      case assigns do
        %{data: %Lorx.NotifyTemp{} = data} ->
          Map.merge(
            assigns,
            Map.take(Map.from_struct(data), [:temp, :status, :target_temp, :mode])
          )

        other ->
          other
      end

    socket = assign(socket, Map.to_list(assigns))

    {:ok, socket}
  end
end

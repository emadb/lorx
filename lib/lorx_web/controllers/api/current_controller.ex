defmodule LorxWeb.Api.CurrentController do
  use LorxWeb, :controller
  alias Lorx.Device

  def index(conn, _params) do
    devices =
      Lorx.DeviceSupervisor.list_children_ids()
      |> Enum.map(fn id ->
        {:ok, state} = Device.get_status(id)

        %{
          room_name: state.device.name,
          temp: state.temp,
          status: to_string(state.status)
        }
      end)

    json(conn, devices)
  end
end

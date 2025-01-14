defmodule Lorx.DeviceSupervisor do
  alias Lorx.Management
  use DynamicSupervisor

  def start_link(_) do
    {:ok, _} = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_child(device) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Lorx.Device, [device.id]}
    )
  end

  def spawn_children do
    Management.list_devices()
    |> Enum.map(&start_child/1)
  end
end

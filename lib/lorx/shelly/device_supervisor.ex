defmodule Lorx.DeviceSupervisor do
  alias Lorx.Management
  use DynamicSupervisor

  def start_link(_) do
    {:ok, _} = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(device) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Lorx.Device, [device.id]}
    )
  end

  def stop_child(device) do
    Lorx.Device.stop(device.id)
  end

  def restart_child(device) do
    stop_child(device)
    start_child(device)
  end

  def spawn_children do
    Management.list_devices()
    |> Enum.map(&start_child/1)
  end

  def list_children_ids do
    DynamicSupervisor.which_children(Lorx.DeviceSupervisor)
    |> Enum.flat_map(fn {_, pid, _, _} ->
      Registry.keys(Lorx.Device.Registry, pid)
    end)
  end
end

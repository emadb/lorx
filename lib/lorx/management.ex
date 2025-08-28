defmodule Lorx.Management do
  import Ecto.Query, warn: false
  alias Lorx.Collector.TemperatureEntry
  alias Lorx.Management.Schedule
  alias Lorx.Repo

  alias Lorx.Management.Device

  def list_devices do
    Repo.all(Device)
  end

  def get_device!(id), do: Repo.get!(Device, id)

  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end

  def change_device(%Device{} = device, attrs \\ %{}) do
    Device.changeset(device, attrs)
  end

  def list_schedules do
    Schedule
    |> preload(:device)
    |> Repo.all()
  end

  def list_schedules(device_id) do
    Schedule
    |> where([d], d.device_id == ^device_id)
    |> preload(:device)
    |> Repo.all()
  end

  def get_schedule!(id), do: Repo.get!(Schedule, id)

  def create_schedule(attrs \\ %{}) do
    %Schedule{}
    |> Schedule.changeset(attrs)
    |> Repo.insert()
  end

  def update_schedule(%Schedule{} = schedule, attrs) do
    schedule
    |> Schedule.changeset(attrs)
    |> Repo.update()
  end

  def delete_schedule(%Schedule{} = schedule) do
    Repo.delete(schedule)
  end

  def change_schedule(%Schedule{} = schedule, attrs \\ %{}) do
    Schedule.changeset(schedule, attrs)
  end

  def get_history(from, to) do
    TemperatureEntry
    |> where([t], t.timestamp >= ^from and t.timestamp <= ^to)
    |> Repo.all()
  end

  def get_history_today() do
    start_of_today = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    end_of_today = Date.utc_today() |> DateTime.new!(~T[23:59:59], "Etc/UTC")

    TemperatureEntry
    |> where([t], t.timestamp >= ^start_of_today and t.timestamp <= ^end_of_today)
    |> Repo.all()
  end
end
